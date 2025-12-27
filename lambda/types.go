package main

// Item represents an item in DynamoDB
type Item struct {
	ItemID     string `json:"itemId" dynamodbav:"itemId"`
	ImageURL   string `json:"imageUrl" dynamodbav:"imageUrl"`
	State      string `json:"state" dynamodbav:"state"`
	Notes      string `json:"notes,omitempty" dynamodbav:"notes,omitempty"`
	Archived   string `json:"archived" dynamodbav:"archived"` // "true" or "false"
	ArchivedAt string `json:"archivedAt,omitempty" dynamodbav:"archivedAt,omitempty"`
	CreatedAt  string `json:"createdAt" dynamodbav:"createdAt"`
	UpdatedAt  string `json:"updatedAt" dynamodbav:"updatedAt"`
}

// GetItemsResponse for GET /items
type GetItemsResponse struct {
	Data       []Item            `json:"data"`
	Pagination map[string]string `json:"pagination,omitempty"`
	Meta       map[string]int    `json:"meta"`
}

// UploadURLsResponse for POST /items/upload
type UploadURLsResponse struct {
	Data map[string]interface{} `json:"data"`
}

// CreateItemRequest for POST /items
type CreateItemRequest struct {
	ImageURL string `json:"imageUrl"`
	State    string `json:"state"`
}

// UpdateItemRequest for PUT /items/{id}
type UpdateItemRequest struct {
	State    *string `json:"state,omitempty"`
	Notes    *string `json:"notes,omitempty"`
	Archived *bool   `json:"archived,omitempty"`
}

// BatchArchiveRequest for POST /items/archive
type BatchArchiveRequest struct {
	ItemIDs []string `json:"itemIds"`
}

// BatchArchiveResponse for POST /items/archive
type BatchArchiveResponse struct {
	Data map[string][]string `json:"data"`
}

// ItemResponse for single item operations
type ItemResponse struct {
	Data Item `json:"data"`
}

// EmptyResponse for DELETE operations
type EmptyResponse struct {
	Data map[string]interface{} `json:"data"`
}
