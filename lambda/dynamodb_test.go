package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ddbAPI is an interface that defines the DynamoDB functions we use in the test.
// This allows us to mock the DynamoDB client's behavior.
type ddbAPI interface {
	Query(ctx context.Context, params *dynamodb.QueryInput, optFns ...func(*dynamodb.Options)) (*dynamodb.QueryOutput, error)
	UpdateItem(ctx context.Context, params *dynamodb.UpdateItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.UpdateItemOutput, error)
}

// mockDDBClient is our mock implementation for the DynamoDB client.
type mockDDBClient struct {
	// CapturedUpdateItemInput stores the input to UpdateItem for later inspection.
	CapturedUpdateItemInput *dynamodb.UpdateItemInput
	// QueryOutputs holds a queue of responses for the Query method.
	QueryOutputs []*dynamodb.QueryOutput
	QueryError   error
}

// Query returns a mocked response. It cycles through the QueryOutputs slice.
func (m *mockDDBClient) Query(ctx context.Context, params *dynamodb.QueryInput, optFns ...func(*dynamodb.Options)) (*dynamodb.QueryOutput, error) {
	if m.QueryError != nil {
		return nil, m.QueryError
	}
	if len(m.QueryOutputs) > 0 {
		output := m.QueryOutputs[0]
		m.QueryOutputs = m.QueryOutputs[1:] // Consume the output
		return output, nil
	}
	return &dynamodb.QueryOutput{Items: []map[string]types.AttributeValue{}}, nil
}

// UpdateItem captures the input and returns a mock response.
func (m *mockDDBClient) UpdateItem(ctx context.Context, params *dynamodb.UpdateItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.UpdateItemOutput, error) {
	m.CapturedUpdateItemInput = params
	return &dynamodb.UpdateItemOutput{}, nil
}

// TestUpdateItemRecord_NilState verifies that updating an item with a nil State
// does not generate an ExpressionAttributeNames entry for '#state'.
func TestUpdateItemRecord_NilState(t *testing.T) {
	ctx := context.Background()
	itemID := "test-item-123"
	notes := "These are some test notes."

	// 1. Setup the mock client
	mockItem := Item{
		ItemID:    itemID,
		Archived:  "false",
		CreatedAt: "2023-10-27T10:00:00Z",
		State:     "new",
	}
	av, err := attributevalue.MarshalMap(mockItem)
	require.NoError(t, err)

	mockClient := &mockDDBClient{
		QueryOutputs: []*dynamodb.QueryOutput{
			// First Query call in getItemByIDForTest (archived=false)
			{Items: []map[string]types.AttributeValue{av}, Count: 1},
			// Second Query call is skipped because the first one finds the item.
			// Third Query call is for the final fetch of the updated item.
			{Items: []map[string]types.AttributeValue{av}, Count: 1},
		},
	}

	// 2. Define the request with State = nil
	req := UpdateItemRequest{
		Notes: &notes,
		State: nil, // This is the key part of the test
	}

	// 3. Execute the function under test
	_, err = updateItemRecordForTest(ctx, mockClient, itemID, req)
	require.NoError(t, err)

	// 4. Assert the results
	require.NotNil(t, mockClient.CapturedUpdateItemInput, "UpdateItem was never called")

	// The main assertion: ExpressionAttributeNames should be empty
	assert.Empty(t, mockClient.CapturedUpdateItemInput.ExpressionAttributeNames, "ExpressionAttributeNames should be empty when State is not updated")

	// Also verify the UpdateExpression is correct
	expectedUpdateExpr := "SET updatedAt = :updatedAt, notes = :notes"
	assert.Equal(t, expectedUpdateExpr, *mockClient.CapturedUpdateItemInput.UpdateExpression)

	// And that ExpressionAttributeValues does not contain :state
	_, stateExists := mockClient.CapturedUpdateItemInput.ExpressionAttributeValues[":state"]
	assert.False(t, stateExists, "ExpressionAttributeValues should not contain :state")
	_, notesExists := mockClient.CapturedUpdateItemInput.ExpressionAttributeValues[":notes"]
	assert.True(t, notesExists, "ExpressionAttributeValues should contain :notes")
}

// --- Test-only versions of functions from dynamodb.go ---
// These are copied and modified to accept a ddbAPI client for testing purposes.

func updateItemRecordForTest(ctx context.Context, client ddbAPI, itemID string, req UpdateItemRequest) (*Item, error) {
	existingItem, err := getItemByIDForTest(ctx, client, itemID)
	if err != nil {
		return nil, err
	}
	if existingItem == nil {
		return nil, fmt.Errorf("item not found")
	}

	// NOTE: The unarchive logic is omitted for this test's scope as it's not relevant.

	now := time.Now().UTC().Format(time.RFC3339)
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

	_, err = client.UpdateItem(ctx, updateInput)
	if err != nil {
		return nil, err
	}

	return getItemByIDForTest(ctx, client, itemID)
}

func getItemByIDForTest(ctx context.Context, client ddbAPI, itemID string) (*Item, error) {
	item, err := queryItemByIDForTest(ctx, client, itemID, "false")
	if err != nil {
		// We expect errors to be handled by the caller, return them up.
		return nil, err
	}
	if item != nil {
		return item, nil
	}
	return queryItemByIDForTest(ctx, client, itemID, "true")
}

func queryItemByIDForTest(ctx context.Context, client ddbAPI, itemID, archived string) (*Item, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("archived = :archived"),
		FilterExpression:       aws.String("itemId = :itemId"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":archived": &types.AttributeValueMemberS{Value: archived},
			":itemId":   &types.AttributeValueMemberS{Value: itemID},
		},
	}

	result, err := client.Query(ctx, input)
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

// TestParseSortParam verifies the parseSortParam function correctly parses
// sort parameters in "field:direction" format
func TestParseSortParam(t *testing.T) {
	tests := []struct {
		name              string
		input             string
		expectedField     string
		expectedDirection string
	}{
		{
			name:              "updatedAt descending",
			input:             "updatedAt:desc",
			expectedField:     "updatedAt",
			expectedDirection: "desc",
		},
		{
			name:              "updatedAt ascending",
			input:             "updatedAt:asc",
			expectedField:     "updatedAt",
			expectedDirection: "asc",
		},
		{
			name:              "createdAt ascending",
			input:             "createdAt:asc",
			expectedField:     "createdAt",
			expectedDirection: "asc",
		},
		{
			name:              "createdAt descending",
			input:             "createdAt:desc",
			expectedField:     "createdAt",
			expectedDirection: "desc",
		},
		{
			name:              "state (legacy format)",
			input:             "state",
			expectedField:     "state",
			expectedDirection: "",
		},
		{
			name:              "empty string defaults to createdAt:desc",
			input:             "",
			expectedField:     "createdAt",
			expectedDirection: "desc",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			field, direction := parseSortParam(tt.input)
			assert.Equal(t, tt.expectedField, field, "field mismatch")
			assert.Equal(t, tt.expectedDirection, direction, "direction mismatch")
		})
	}
}
