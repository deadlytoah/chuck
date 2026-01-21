package main

// Item represents an item in DynamoDB
type Item struct {
	PK         string `json:"-" dynamodbav:"PK"`                           // folder#{folderId}
	SK         string `json:"-" dynamodbav:"SK"`                           // item#{archived}#{createdAt}
	EntityType string `json:"-" dynamodbav:"entityType"`                   // "item"
	ItemID     string `json:"itemId" dynamodbav:"itemId"`
	FolderID   string `json:"folderId" dynamodbav:"folderId"`
	ImageURL   string `json:"imageUrl" dynamodbav:"imageUrl"`
	State      string `json:"state" dynamodbav:"state"`
	Notes      string `json:"notes,omitempty" dynamodbav:"notes,omitempty"`
	Archived   bool   `json:"archived" dynamodbav:"archived"`
	ArchivedAt string `json:"archivedAt,omitempty" dynamodbav:"archivedAt,omitempty"`
	CreatedAt  string `json:"createdAt" dynamodbav:"createdAt"`
	UpdatedAt  string `json:"updatedAt" dynamodbav:"updatedAt"`
}

// Folder represents a folder in DynamoDB
type Folder struct {
	PK         string `json:"-" dynamodbav:"PK"`          // folder#{folderId}
	SK         string `json:"-" dynamodbav:"SK"`          // metadata
	EntityType string `json:"-" dynamodbav:"entityType"`  // "folder"
	FolderID   string `json:"folderId" dynamodbav:"folderId"`
	Name       string `json:"name" dynamodbav:"name"`
	CreatedAt  string `json:"createdAt" dynamodbav:"createdAt"`
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
	FolderID string `json:"folderId"`
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

// GetFoldersResponse for GET /folders
type GetFoldersResponse struct {
	Data []Folder `json:"data"`
}

// FolderResponse for single folder operations
type FolderResponse struct {
	Data Folder `json:"data"`
}

// CreateFolderRequest for POST /folders
type CreateFolderRequest struct {
	FolderID string `json:"folderId"`
	Name     string `json:"name"`
}

// UpdateFolderRequest for PUT /folders/{folderId}
type UpdateFolderRequest struct {
	Name string `json:"name"`
}
