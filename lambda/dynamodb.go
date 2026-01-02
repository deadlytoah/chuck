package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/google/uuid"
)

var dynamoClient *dynamodb.Client

func initDynamoDBClient(ctx context.Context) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return err
	}
	dynamoClient = dynamodb.NewFromConfig(cfg)
	return nil
}

// parseSortParam parses sort parameter in format "field:direction"
// Returns (field, direction) where direction is "asc" or "desc"
// Defaults to ("createdAt", "desc") for empty/invalid input
func parseSortParam(sortBy string) (string, string) {
	if sortBy == "" {
		return "createdAt", "desc"
	}

	// Check for field:direction format
	parts := strings.Split(sortBy, ":")
	if len(parts) == 2 {
		return parts[0], parts[1]
	}

	// Legacy support: just field name (e.g., "state")
	return sortBy, ""
}

// queryItems queries items from DynamoDB with pagination and filters
func queryItems(ctx context.Context, nextToken, filter, sortBy string, limit int) ([]Item, string, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, "", err
		}
	}

	// Determine partition key value based on filter
	archivedValue := "false"
	if filter == "archived" {
		archivedValue = "true"
	}

	// Build expression attribute values
	exprAttrValues := map[string]types.AttributeValue{
		":archived": &types.AttributeValueMemberS{Value: archivedValue},
	}

	// Build query input
	input := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("archived = :archived"),
		ExpressionAttributeValues: exprAttrValues,
		ScanIndexForward: aws.Bool(false), // Descending order by createdAt
		Limit:            aws.Int32(int32(limit)),
	}

	// Add filter expression for state filters (excluding "all" and "archived")
	if filter != "" && filter != "all" && filter != "archived" {
		input.FilterExpression = aws.String("#state = :state")
		input.ExpressionAttributeNames = map[string]string{
			"#state": "state",
		}
		exprAttrValues[":state"] = &types.AttributeValueMemberS{Value: filter}
	}

	// Handle pagination token
	if nextToken != "" {
		lastKey, err := decodeToken(nextToken)
		if err != nil {
			return nil, "", fmt.Errorf("invalid token: %w", err)
		}
		input.ExclusiveStartKey = lastKey
	}

	// Execute query
	result, err := dynamoClient.Query(ctx, input)
	if err != nil {
		return nil, "", err
	}

	// Unmarshal items
	var items []Item
	err = attributevalue.UnmarshalListOfMaps(result.Items, &items)
	if err != nil {
		return nil, "", err
	}

	// Transform S3 keys to full URLs
	for i := range items {
		if items[i].ImageURL != "" {
			items[i].ImageURL = constructS3URL(items[i].ImageURL)
		}
	}

	// Apply sorting based on sortBy parameter
	field, direction := parseSortParam(sortBy)

	switch field {
	case "updatedAt":
		sort.Slice(items, func(i, j int) bool {
			if direction == "asc" {
				return items[i].UpdatedAt < items[j].UpdatedAt
			}
			return items[i].UpdatedAt > items[j].UpdatedAt
		})
	case "createdAt":
		if direction == "asc" {
			// Reverse the default DynamoDB order (which is desc)
			sort.Slice(items, func(i, j int) bool {
				return items[i].CreatedAt < items[j].CreatedAt
			})
		}
		// For desc, no sorting needed - already in correct order from DynamoDB
	case "state":
		sort.Slice(items, func(i, j int) bool {
			return items[i].State < items[j].State
		})
	}

	// Encode next token
	var newToken string
	if result.LastEvaluatedKey != nil {
		newToken, err = encodeToken(result.LastEvaluatedKey)
		if err != nil {
			return nil, "", err
		}
	}

	return items, newToken, nil
}

// getItemByID retrieves a single item by scanning both partitions
func getItemByID(ctx context.Context, itemID string) (*Item, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	// Try archived=false first
	item, err := queryItemByID(ctx, itemID, "false")
	if err == nil && item != nil {
		return item, nil
	}

	// Try archived=true
	return queryItemByID(ctx, itemID, "true")
}

// queryItemByID queries for an item in a specific partition
func queryItemByID(ctx context.Context, itemID, archived string) (*Item, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("archived = :archived"),
		FilterExpression:       aws.String("itemId = :itemId"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":archived": &types.AttributeValueMemberS{Value: archived},
			":itemId":   &types.AttributeValueMemberS{Value: itemID},
		},
	}

	result, err := dynamoClient.Query(ctx, input)
	if err != nil {
		return nil, err
	}

	if len(result.Items) == 0 {
		return nil, nil
	}

	var item Item
	err = attributevalue.UnmarshalMap(result.Items[0], &item)
	if err != nil {
		return nil, err
	}

	return &item, nil
}

// createItemRecord creates a new item in DynamoDB
func createItemRecord(ctx context.Context, imageURL, state string) (*Item, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	now := time.Now().UTC().Format(time.RFC3339)
	item := Item{
		ItemID:    uuid.New().String(),
		ImageURL:  imageURL,
		State:     state,
		Archived:  "false",
		CreatedAt: now,
		UpdatedAt: now,
	}

	av, err := attributevalue.MarshalMap(item)
	if err != nil {
		return nil, err
	}

	_, err = dynamoClient.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      av,
	})
	if err != nil {
		return nil, err
	}

	return &item, nil
}

// updateItemRecord updates an existing item in DynamoDB
func updateItemRecord(ctx context.Context, itemID string, req UpdateItemRequest) (*Item, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	// Get existing item to know its partition
	existingItem, err := getItemByID(ctx, itemID)
	if err != nil {
		return nil, err
	}
	if existingItem == nil {
		return nil, fmt.Errorf("item not found")
	}

	// Check if archived items can be updated
	if existingItem.Archived == "true" && req.State != nil && req.Archived == nil {
		return nil, fmt.Errorf("archived items are read-only for state updates")
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// Handle unarchive - requires moving item to different partition
	if req.Archived != nil && !*req.Archived && existingItem.Archived == "true" {
		// Delete from archived=true partition
		_, err := dynamoClient.DeleteItem(ctx, &dynamodb.DeleteItemInput{
			TableName: aws.String(tableName),
			Key: map[string]types.AttributeValue{
				"archived":  &types.AttributeValueMemberS{Value: "true"},
				"createdAt": &types.AttributeValueMemberS{Value: existingItem.CreatedAt},
			},
		})
		if err != nil {
			return nil, err
		}

		// Create in archived=false partition
		existingItem.Archived = "false"
		existingItem.ArchivedAt = ""
		existingItem.UpdatedAt = now

		av, err := attributevalue.MarshalMap(existingItem)
		if err != nil {
			return nil, err
		}

		_, err = dynamoClient.PutItem(ctx, &dynamodb.PutItemInput{
			TableName: aws.String(tableName),
			Item:      av,
		})
		if err != nil {
			return nil, err
		}

		return existingItem, nil
	}

	// Build update expression
	updateExpr := "SET updatedAt = :updatedAt"
	exprAttrValues := map[string]types.AttributeValue{
		":updatedAt": &types.AttributeValueMemberS{Value: now},
	}
	exprAttrNames := map[string]string{}

	if req.State != nil {
		updateExpr += ", #state = :state"
		exprAttrValues[":state"] = &types.AttributeValueMemberS{Value: *req.State}
		exprAttrNames["#state"] = "state"
	}

	if req.Notes != nil {
		updateExpr += ", notes = :notes"
		exprAttrValues[":notes"] = &types.AttributeValueMemberS{Value: *req.Notes}
	}

	// Update item
	updateInput := &dynamodb.UpdateItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"archived":  &types.AttributeValueMemberS{Value: existingItem.Archived},
			"createdAt": &types.AttributeValueMemberS{Value: existingItem.CreatedAt},
		},
		UpdateExpression:          aws.String(updateExpr),
		ExpressionAttributeValues: exprAttrValues,
	}

	if len(exprAttrNames) > 0 {
		updateInput.ExpressionAttributeNames = exprAttrNames
	}

	_, err = dynamoClient.UpdateItem(ctx, updateInput)
	if err != nil {
		return nil, err
	}

	// Fetch updated item
	updatedItem, err := getItemByID(ctx, itemID)
	if err != nil {
		return nil, err
	}

	return updatedItem, nil
}

// archiveItemRecord archives a single item
func archiveItemRecord(ctx context.Context, itemID string) error {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return err
		}
	}

	// Get existing item
	existingItem, err := getItemByID(ctx, itemID)
	if err != nil {
		return err
	}
	if existingItem == nil {
		return fmt.Errorf("item not found")
	}

	if existingItem.Archived == "true" {
		return nil // Already archived
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// Delete from archived=false partition
	_, err = dynamoClient.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"archived":  &types.AttributeValueMemberS{Value: "false"},
			"createdAt": &types.AttributeValueMemberS{Value: existingItem.CreatedAt},
		},
	})
	if err != nil {
		return err
	}

	// Create in archived=true partition
	existingItem.Archived = "true"
	existingItem.ArchivedAt = now
	existingItem.UpdatedAt = now

	av, err := attributevalue.MarshalMap(existingItem)
	if err != nil {
		return err
	}

	_, err = dynamoClient.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      av,
	})

	return err
}

// batchArchiveItems archives multiple items
func batchArchiveItems(ctx context.Context, itemIDs []string) (archived []string, failed []string) {
	for _, itemID := range itemIDs {
		err := archiveItemRecord(ctx, itemID)
		if err != nil {
			failed = append(failed, itemID)
		} else {
			archived = append(archived, itemID)
		}
	}
	return archived, failed
}

// encodeToken encodes LastEvaluatedKey to base64 string
func encodeToken(key map[string]types.AttributeValue) (string, error) {
	data, err := json.Marshal(key)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(data), nil
}

// decodeToken decodes base64 string to LastEvaluatedKey
func decodeToken(token string) (map[string]types.AttributeValue, error) {
	data, err := base64.URLEncoding.DecodeString(token)
	if err != nil {
		return nil, err
	}

	var key map[string]types.AttributeValue
	err = json.Unmarshal(data, &key)
	if err != nil {
		return nil, err
	}

	return key, nil
}
