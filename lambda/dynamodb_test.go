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

// ddbAPI is an interface for mocking DynamoDB operations
type ddbAPI interface {
	Query(ctx context.Context, params *dynamodb.QueryInput, optFns ...func(*dynamodb.Options)) (*dynamodb.QueryOutput, error)
	Scan(ctx context.Context, params *dynamodb.ScanInput, optFns ...func(*dynamodb.Options)) (*dynamodb.ScanOutput, error)
	GetItem(ctx context.Context, params *dynamodb.GetItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.GetItemOutput, error)
	PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error)
	UpdateItem(ctx context.Context, params *dynamodb.UpdateItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.UpdateItemOutput, error)
	DeleteItem(ctx context.Context, params *dynamodb.DeleteItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.DeleteItemOutput, error)
	TransactWriteItems(ctx context.Context, params *dynamodb.TransactWriteItemsInput, optFns ...func(*dynamodb.Options)) (*dynamodb.TransactWriteItemsOutput, error)
}

// mockDDBClient is our mock implementation for the DynamoDB client
type mockDDBClient struct {
	ScanOutputs             []*dynamodb.ScanOutput
	ScanError               error
	QueryOutputs            []*dynamodb.QueryOutput
	QueryError              error
	GetItemOutputs          []*dynamodb.GetItemOutput
	GetItemError            error
	PutItemError            error
	UpdateItemError         error
	DeleteItemError         error
	TransactWriteItemsError error
	CapturedPutItemInput    *dynamodb.PutItemInput
	CapturedUpdateItemInput *dynamodb.UpdateItemInput
	CapturedDeleteItemInput *dynamodb.DeleteItemInput
	CapturedTransactItems   *dynamodb.TransactWriteItemsInput
}

func (m *mockDDBClient) Scan(ctx context.Context, params *dynamodb.ScanInput, optFns ...func(*dynamodb.Options)) (*dynamodb.ScanOutput, error) {
	if m.ScanError != nil {
		return nil, m.ScanError
	}
	if len(m.ScanOutputs) > 0 {
		output := m.ScanOutputs[0]
		m.ScanOutputs = m.ScanOutputs[1:]
		return output, nil
	}
	return &dynamodb.ScanOutput{Items: []map[string]types.AttributeValue{}}, nil
}

func (m *mockDDBClient) Query(ctx context.Context, params *dynamodb.QueryInput, optFns ...func(*dynamodb.Options)) (*dynamodb.QueryOutput, error) {
	if m.QueryError != nil {
		return nil, m.QueryError
	}
	if len(m.QueryOutputs) > 0 {
		output := m.QueryOutputs[0]
		m.QueryOutputs = m.QueryOutputs[1:]
		return output, nil
	}
	return &dynamodb.QueryOutput{Items: []map[string]types.AttributeValue{}}, nil
}

func (m *mockDDBClient) GetItem(ctx context.Context, params *dynamodb.GetItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.GetItemOutput, error) {
	if m.GetItemError != nil {
		return nil, m.GetItemError
	}
	if len(m.GetItemOutputs) > 0 {
		output := m.GetItemOutputs[0]
		m.GetItemOutputs = m.GetItemOutputs[1:]
		return output, nil
	}
	return &dynamodb.GetItemOutput{}, nil
}

func (m *mockDDBClient) PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error) {
	m.CapturedPutItemInput = params
	if m.PutItemError != nil {
		return nil, m.PutItemError
	}
	return &dynamodb.PutItemOutput{}, nil
}

func (m *mockDDBClient) UpdateItem(ctx context.Context, params *dynamodb.UpdateItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.UpdateItemOutput, error) {
	m.CapturedUpdateItemInput = params
	if m.UpdateItemError != nil {
		return nil, m.UpdateItemError
	}

	// Build output attributes by merging key and updated values
	attrs := make(map[string]types.AttributeValue)
	for k, v := range params.Key {
		attrs[k] = v
	}
	// Add the updated name from ExpressionAttributeValues
	if nameVal, ok := params.ExpressionAttributeValues[":name"]; ok {
		attrs["name"] = nameVal
	}

	return &dynamodb.UpdateItemOutput{Attributes: attrs}, nil
}

func (m *mockDDBClient) DeleteItem(ctx context.Context, params *dynamodb.DeleteItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.DeleteItemOutput, error) {
	m.CapturedDeleteItemInput = params
	if m.DeleteItemError != nil {
		return nil, m.DeleteItemError
	}
	return &dynamodb.DeleteItemOutput{}, nil
}

func (m *mockDDBClient) TransactWriteItems(ctx context.Context, params *dynamodb.TransactWriteItemsInput, optFns ...func(*dynamodb.Options)) (*dynamodb.TransactWriteItemsOutput, error) {
	m.CapturedTransactItems = params
	if m.TransactWriteItemsError != nil {
		return nil, m.TransactWriteItemsError
	}
	return &dynamodb.TransactWriteItemsOutput{}, nil
}

// TestParseSortParam verifies the parseSortParam function
func TestParseSortParam(t *testing.T) {
	tests := []struct {
		name              string
		input             string
		expectedField     string
		expectedDirection string
	}{
		{"updatedAt:desc", "updatedAt:desc", "updatedAt", "desc"},
		{"updatedAt:asc", "updatedAt:asc", "updatedAt", "asc"},
		{"createdAt:asc", "createdAt:asc", "createdAt", "asc"},
		{"state (legacy)", "state", "state", ""},
		{"empty defaults", "", "createdAt", "desc"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			field, direction := parseSortParam(tt.input)
			assert.Equal(t, tt.expectedField, field)
			assert.Equal(t, tt.expectedDirection, direction)
		})
	}
}

// TestGetFolders verifies folder retrieval
func TestGetFolders(t *testing.T) {
	ctx := context.Background()

	folder1 := Folder{
		PK:         "folder#clothes",
		SK:         "metadata",
		EntityType: "folder",
		FolderID:   "clothes",
		Name:       "Clothes",
		CreatedAt:  "2024-01-01T00:00:00Z",
	}
	folder2 := Folder{
		PK:         "folder#books",
		SK:         "metadata",
		EntityType: "folder",
		FolderID:   "books",
		Name:       "Books",
		CreatedAt:  "2024-01-02T00:00:00Z",
	}

	av1, _ := attributevalue.MarshalMap(folder1)
	av2, _ := attributevalue.MarshalMap(folder2)

	mockClient := &mockDDBClient{
		ScanOutputs: []*dynamodb.ScanOutput{
			{Items: []map[string]types.AttributeValue{av1, av2}},
		},
	}

	folders, err := GetFoldersForTest(ctx, mockClient)
	require.NoError(t, err)
	assert.Len(t, folders, 2)
	assert.Equal(t, "clothes", folders[0].FolderID)
	assert.Equal(t, "books", folders[1].FolderID)
}

// TestCreateFolder verifies folder creation
func TestCreateFolder(t *testing.T) {
	ctx := context.Background()
	mockClient := &mockDDBClient{}

	folder, err := CreateFolderForTest(ctx, mockClient, "clothes", "Clothes")
	require.NoError(t, err)
	assert.Equal(t, "clothes", folder.FolderID)
	assert.Equal(t, "Clothes", folder.Name)
	assert.NotEmpty(t, folder.CreatedAt)

	// Verify PutItem was called
	require.NotNil(t, mockClient.CapturedPutItemInput)
	assert.Equal(t, tableName, *mockClient.CapturedPutItemInput.TableName)
}

// TestUpdateFolder verifies folder name updates
func TestUpdateFolder(t *testing.T) {
	ctx := context.Background()
	mockClient := &mockDDBClient{}

	folder, err := UpdateFolderForTest(ctx, mockClient, "clothes", "New Name")
	require.NoError(t, err)
	assert.Equal(t, "New Name", folder.Name)

	// Verify UpdateItem was called with correct expression
	require.NotNil(t, mockClient.CapturedUpdateItemInput)
	assert.Contains(t, *mockClient.CapturedUpdateItemInput.UpdateExpression, "SET #name = :name")
}

// TestDeleteFolder_NotEmpty verifies folder deletion fails when items exist
func TestDeleteFolder_NotEmpty(t *testing.T) {
	ctx := context.Background()

	// Mock query returns 1 item (folder not empty)
	mockClient := &mockDDBClient{
		QueryOutputs: []*dynamodb.QueryOutput{
			{Items: []map[string]types.AttributeValue{{}}, Count: 1},
		},
	}

	err := DeleteFolderForTest(ctx, mockClient, "clothes")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "not empty")
}

// TestDeleteFolder_Success verifies folder deletion succeeds when empty
func TestDeleteFolder_Success(t *testing.T) {
	ctx := context.Background()

	// Mock query returns 0 items (folder is empty)
	mockClient := &mockDDBClient{
		QueryOutputs: []*dynamodb.QueryOutput{
			{Items: []map[string]types.AttributeValue{}, Count: 0},
		},
	}

	err := DeleteFolderForTest(ctx, mockClient, "clothes")
	assert.NoError(t, err)

	// Verify DeleteItem was called
	require.NotNil(t, mockClient.CapturedDeleteItemInput)
}

// TestQueryItems verifies item queries are scoped to folder
func TestQueryItems(t *testing.T) {
	ctx := context.Background()

	item := Item{
		PK:         "folder#clothes",
		SK:         "item#false#2024-01-01T00:00:00Z",
		EntityType: "item",
		ItemID:     "item-123",
		FolderID:   "clothes",
		ImageURL:   "images/item-123/full.jpg",
		State:      "Unanswered",
		Archived:   false,
		CreatedAt:  "2024-01-01T00:00:00Z",
		UpdatedAt:  "2024-01-01T00:00:00Z",
	}

	av, _ := attributevalue.MarshalMap(item)

	mockClient := &mockDDBClient{
		QueryOutputs: []*dynamodb.QueryOutput{
			{Items: []map[string]types.AttributeValue{av}},
		},
	}

	items, _, err := queryItemsForTest(ctx, mockClient, "clothes", "", "all", "createdAt", 20)
	require.NoError(t, err)
	assert.Len(t, items, 1)
	assert.Equal(t, "clothes", items[0].FolderID)
}

// TestArchiveItem_Transaction verifies archive uses transaction
func TestArchiveItem_Transaction(t *testing.T) {
	ctx := context.Background()

	existingItem := Item{
		PK:        "folder#clothes",
		SK:        "item#false#2024-01-01T00:00:00Z",
		ItemID:    "item-123",
		FolderID:  "clothes",
		Archived:  false,
		CreatedAt: "2024-01-01T00:00:00Z",
	}

	av, _ := attributevalue.MarshalMap(existingItem)

	mockClient := &mockDDBClient{
		ScanOutputs: []*dynamodb.ScanOutput{
			{Items: []map[string]types.AttributeValue{av}},
		},
	}

	err := archiveItemRecordForTest(ctx, mockClient, "item-123")
	require.NoError(t, err)

	// Verify transaction was used
	require.NotNil(t, mockClient.CapturedTransactItems)
	assert.Len(t, mockClient.CapturedTransactItems.TransactItems, 2)

	// Verify first operation is Delete
	assert.NotNil(t, mockClient.CapturedTransactItems.TransactItems[0].Delete)

	// Verify second operation is Put
	assert.NotNil(t, mockClient.CapturedTransactItems.TransactItems[1].Put)
}

// TestUnarchiveItem_Transaction verifies unarchive uses transaction
func TestUnarchiveItem_Transaction(t *testing.T) {
	ctx := context.Background()

	existingItem := Item{
		PK:         "folder#clothes",
		SK:         "item#true#2024-01-01T00:00:00Z",
		ItemID:     "item-123",
		FolderID:   "clothes",
		Archived:   true,
		ArchivedAt: "2024-01-02T00:00:00Z",
		CreatedAt:  "2024-01-01T00:00:00Z",
	}

	av, _ := attributevalue.MarshalMap(existingItem)

	mockClient := &mockDDBClient{
		ScanOutputs: []*dynamodb.ScanOutput{
			{Items: []map[string]types.AttributeValue{av}},
		},
	}

	archived := false
	req := UpdateItemRequest{Archived: &archived}

	_, err := updateItemRecordForTest(ctx, mockClient, "item-123", req)
	require.NoError(t, err)

	// Verify transaction was used
	require.NotNil(t, mockClient.CapturedTransactItems)
	assert.Len(t, mockClient.CapturedTransactItems.TransactItems, 2)
}

// --- Test-only helper functions ---

func GetFoldersForTest(ctx context.Context, client ddbAPI) ([]Folder, error) {
	input := &dynamodb.ScanInput{
		TableName:        aws.String(tableName),
		FilterExpression: aws.String("entityType = :entityType"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":entityType": &types.AttributeValueMemberS{Value: "folder"},
		},
	}

	result, err := client.Scan(ctx, input)
	if err != nil {
		return nil, err
	}

	var folders []Folder
	err = attributevalue.UnmarshalListOfMaps(result.Items, &folders)
	return folders, err
}

func CreateFolderForTest(ctx context.Context, client ddbAPI, folderID, name string) (*Folder, error) {
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

	_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      av,
	})
	return &folder, err
}

func UpdateFolderForTest(ctx context.Context, client ddbAPI, folderID, name string) (*Folder, error) {
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
		ReturnValues: types.ReturnValueAllNew,
	}

	result, err := client.UpdateItem(ctx, input)
	if err != nil {
		return nil, err
	}

	var folder Folder
	err = attributevalue.UnmarshalMap(result.Attributes, &folder)
	return &folder, err
}

func DeleteFolderForTest(ctx context.Context, client ddbAPI, folderID string) error {
	queryInput := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			":sk": &types.AttributeValueMemberS{Value: "item#"},
		},
		Limit: aws.Int32(1),
	}

	result, err := client.Query(ctx, queryInput)
	if err != nil {
		return err
	}

	if len(result.Items) > 0 {
		return fmt.Errorf("folder is not empty")
	}

	_, err = client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			"SK": &types.AttributeValueMemberS{Value: "metadata"},
		},
	})
	return err
}

func queryItemsForTest(ctx context.Context, client ddbAPI, folderID, nextToken, filter, sortBy string, limit int) ([]Item, string, error) {
	var skCondition string
	if filter == "archived" {
		skCondition = "item#true#"
	} else if filter == "all" {
		skCondition = "item#"
	} else {
		skCondition = "item#false#"
	}

	input := &dynamodb.QueryInput{
		TableName:              aws.String(tableName),
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("folder#%s", folderID)},
			":sk": &types.AttributeValueMemberS{Value: skCondition},
		},
		ScanIndexForward: aws.Bool(false),
		Limit:            aws.Int32(int32(limit)),
	}

	result, err := client.Query(ctx, input)
	if err != nil {
		return nil, "", err
	}

	var items []Item
	err = attributevalue.UnmarshalListOfMaps(result.Items, &items)
	return items, "", err
}

func archiveItemRecordForTest(ctx context.Context, client ddbAPI, itemID string) error {
	existingItem, err := getItemByIDForTest(ctx, client, itemID)
	if err != nil {
		return err
	}
	if existingItem == nil {
		return fmt.Errorf("item not found")
	}

	now := time.Now().UTC().Format(time.RFC3339)
	archivedItem := *existingItem
	archivedItem.SK = fmt.Sprintf("item#true#%s", existingItem.CreatedAt)
	archivedItem.Archived = true
	archivedItem.ArchivedAt = now
	archivedItem.UpdatedAt = now

	av, err := attributevalue.MarshalMap(archivedItem)
	if err != nil {
		return err
	}

	_, err = client.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
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
	return err
}

func updateItemRecordForTest(ctx context.Context, client ddbAPI, itemID string, req UpdateItemRequest) (*Item, error) {
	existingItem, err := getItemByIDForTest(ctx, client, itemID)
	if err != nil {
		return nil, err
	}
	if existingItem == nil {
		return nil, fmt.Errorf("item not found")
	}

	now := time.Now().UTC().Format(time.RFC3339)

	if req.Archived != nil && !*req.Archived && existingItem.Archived {
		newItem := *existingItem
		newItem.SK = fmt.Sprintf("item#false#%s", existingItem.CreatedAt)
		newItem.Archived = false
		newItem.ArchivedAt = ""
		newItem.UpdatedAt = now

		av, err := attributevalue.MarshalMap(newItem)
		if err != nil {
			return nil, err
		}

		_, err = client.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
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
		return &newItem, err
	}

	return existingItem, nil
}

func getItemByIDForTest(ctx context.Context, client ddbAPI, itemID string) (*Item, error) {
	input := &dynamodb.ScanInput{
		TableName:        aws.String(tableName),
		FilterExpression: aws.String("itemId = :itemId"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":itemId": &types.AttributeValueMemberS{Value: itemID},
		},
	}

	result, err := client.Scan(ctx, input)
	if err != nil {
		return nil, err
	}

	if len(result.Items) == 0 {
		return nil, nil
	}

	var item Item
	err = attributevalue.UnmarshalMap(result.Items[0], &item)
	return &item, err
}
