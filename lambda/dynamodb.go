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

// GetFolders retrieves all folders
func GetFolders(ctx context.Context) ([]Folder, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	input := &dynamodb.ScanInput{
		TableName:        aws.String(tableName),
		FilterExpression: aws.String("entityType = :entityType"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":entityType": &types.AttributeValueMemberS{Value: "folder"},
		},
	}

	result, err := dynamoClient.Scan(ctx, input)
	if err != nil {
		return nil, err
	}

	var folders []Folder
	err = attributevalue.UnmarshalListOfMaps(result.Items, &folders)
	if err != nil {
		return nil, err
	}

	return folders, nil
}

// CreateFolder creates a new folder
func CreateFolder(ctx context.Context, folderID, name string) (*Folder, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	now := time.Now().UTC().Format(time.RFC3339)
	folder := Folder{
		PK:         fmt.Sprintf("folder#%s", folderID),
		SK:         "metadata",
		EntityType: "folder",
		FolderID:   folderID,
		Name:       name,
		CreatedAt:  now,
	}

	av, err := attributevalue.MarshalMap(folder)
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

	return &folder, nil
}

// GetFolder retrieves a single folder by ID
func GetFolder(ctx context.Context, folderID string) (*Folder, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	input := &dynamodb.GetItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			"SK": &types.AttributeValueMemberS{Value: "metadata"},
		},
	}

	result, err := dynamoClient.GetItem(ctx, input)
	if err != nil {
		return nil, err
	}

	if result.Item == nil {
		return nil, nil
	}

	var folder Folder
	err = attributevalue.UnmarshalMap(result.Item, &folder)
	if err != nil {
		return nil, err
	}

	return &folder, nil
}

// UpdateFolder updates a folder's name
func UpdateFolder(ctx context.Context, folderID, name string) (*Folder, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			"SK": &types.AttributeValueMemberS{Value: "metadata"},
		},
		UpdateExpression: aws.String("SET #name = :name"),
		ExpressionAttributeNames: map[string]string{
			"#name": "name",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":name": &types.AttributeValueMemberS{Value: name},
		},
		ConditionExpression: aws.String("attribute_exists(PK)"),
		ReturnValues:        types.ReturnValueAllNew,
	}

	result, err := dynamoClient.UpdateItem(ctx, input)
	if err != nil {
		return nil, err
	}

	var folder Folder
	err = attributevalue.UnmarshalMap(result.Attributes, &folder)
	if err != nil {
		return nil, err
	}

	return &folder, nil
}

// DeleteFolder deletes a folder (must be empty)
func DeleteFolder(ctx context.Context, folderID string) error {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return err
		}
	}

	// Check if folder has items
	queryInput := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			":sk": &types.AttributeValueMemberS{Value: "item#"},
		},
		Limit: aws.Int32(1),
	}

	result, err := dynamoClient.Query(ctx, queryInput)
	if err != nil {
		return err
	}

	if len(result.Items) > 0 {
		return fmt.Errorf("folder is not empty")
	}

	// Delete folder metadata
	_, err = dynamoClient.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			"SK": &types.AttributeValueMemberS{Value: "metadata"},
		},
	})

	return err
}

// queryItems queries items from a folder with pagination and filters
func queryItems(ctx context.Context, folderID, nextToken, filter, sortBy string, limit int) ([]Item, string, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, "", err
		}
	}

	// Build sort key condition based on filter
	var skCondition string
	if filter == "archived" {
		skCondition = "item#true#"
	} else if filter == "all" {
		skCondition = "item#"
	} else {
		skCondition = "item#false#"
	}

	// Build expression attribute values
	exprAttrValues := map[string]types.AttributeValue{
		":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
		":sk": &types.AttributeValueMemberS{Value: skCondition},
	}

	// Build query input
	input := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
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

// getItemByID retrieves a single item by scanning the folder
func getItemByID(ctx context.Context, itemID string) (*Item, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	// Scan to find the item (since we don't know which folder it's in)
	input := &dynamodb.ScanInput{
		TableName:        aws.String(tableName),
		FilterExpression: aws.String("itemId = :itemId"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":itemId": &types.AttributeValueMemberS{Value: itemID},
		},
	}

	result, err := dynamoClient.Scan(ctx, input)
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
func createItemRecord(ctx context.Context, folderID, imageURL, state string) (*Item, error) {
	if dynamoClient == nil {
		if err := initDynamoDBClient(ctx); err != nil {
			return nil, err
		}
	}

	now := time.Now().UTC().Format(time.RFC3339)
	item := Item{
		PK:         fmt.Sprintf("folder#%s", folderID),
		SK:         fmt.Sprintf("item#false#%s", now),
		EntityType: "item",
		ItemID:     uuid.New().String(),
		FolderID:   folderID,
		ImageURL:   imageURL,
		State:      state,
		Archived:   false,
		CreatedAt:  now,
		UpdatedAt:  now,
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

	// Get existing item
	existingItem, err := getItemByID(ctx, itemID)
	if err != nil {
		return nil, err
	}
	if existingItem == nil {
		return nil, fmt.Errorf("item not found")
	}

	// Check if archived items can be updated
	if existingItem.Archived && req.State != nil && req.Archived == nil {
		return nil, fmt.Errorf("archived items are read-only for state updates")
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// Handle unarchive - requires moving item (changing SK)
	if req.Archived != nil && !*req.Archived && existingItem.Archived {
		// Create new item with updated SK
		newItem := *existingItem
		newItem.SK = fmt.Sprintf("item#false#%s", existingItem.CreatedAt)
		newItem.Archived = false
		newItem.ArchivedAt = ""
		newItem.UpdatedAt = now

		av, err := attributevalue.MarshalMap(newItem)
		if err != nil {
			return nil, err
		}

		// Use transaction to atomically delete old and create new
		_, err = dynamoClient.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
			TransactItems: []types.TransactWriteItem{
				{
					Delete: &types.Delete{
						TableName: aws.String(tableName),
						Key: map[string]types.AttributeValue{
							"PK": &types.AttributeValueMemberS{Value: existingItem.PK},
							"SK": &types.AttributeValueMemberS{Value: existingItem.SK},
						},
					},
				},
				{
					Put: &types.Put{
						TableName: aws.String(tableName),
						Item:      av,
					},
				},
			},
		})
		if err != nil {
			return nil, fmt.Errorf("failed to unarchive item: %w", err)
		}

		return &newItem, nil
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
			"PK": &types.AttributeValueMemberS{Value: existingItem.PK},
			"SK": &types.AttributeValueMemberS{Value: existingItem.SK},
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

	if existingItem.Archived {
		return nil // Already archived
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// Create archived version with new SK
	archivedItem := *existingItem
	archivedItem.SK = fmt.Sprintf("item#true#%s", existingItem.CreatedAt)
	archivedItem.Archived = true
	archivedItem.ArchivedAt = now
	archivedItem.UpdatedAt = now

	av, err := attributevalue.MarshalMap(archivedItem)
	if err != nil {
		return err
	}

	// Use transaction to atomically delete old and create archived version
	_, err = dynamoClient.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
		TransactItems: []types.TransactWriteItem{
			{
				Delete: &types.Delete{
					TableName: aws.String(tableName),
					Key: map[string]types.AttributeValue{
						"PK": &types.AttributeValueMemberS{Value: existingItem.PK},
						"SK": &types.AttributeValueMemberS{Value: existingItem.SK},
					},
				},
			},
			{
				Put: &types.Put{
					TableName: aws.String(tableName),
					Item:      av,
				},
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to archive item: %w", err)
	}

	return nil
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
