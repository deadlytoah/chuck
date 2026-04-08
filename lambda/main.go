package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

var (
	bucketName = os.Getenv("BUCKET_NAME")
	tableName  = os.Getenv("TABLE_NAME")
	region     = os.Getenv("REGION")
)


func handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	// Headers (CORS handled by Lambda URL config)
	headers := map[string]string{
		"Content-Type": "application/json",
	}

	// Route requests
	method := req.RequestContext.HTTP.Method
	path := req.RequestContext.HTTP.Path

	var response interface{}
	var err error
	statusCode := 0

	switch {
	case method == "GET" && path == "/folders":
		response, err = getFolders(ctx)
	case method == "POST" && path == "/folders":
		response, err = createFolder(ctx, req)
	case method == "PUT" && strings.HasPrefix(path, "/folders/"):
		folderID := strings.TrimPrefix(path, "/folders/")
		response, err = updateFolder(ctx, folderID, req)
	case method == "DELETE" && strings.HasPrefix(path, "/folders/"):
		folderID := strings.TrimPrefix(path, "/folders/")
		response, err = deleteFolder(ctx, folderID)
	case method == "GET" && path == "/items":
		response, err = getItems(ctx, req)
	case method == "POST" && path == "/items/upload":
		response, err = getUploadURLs(ctx)
	case method == "POST" && path == "/items":
		response, err = createItem(ctx, req)
	case method == "PUT" && strings.HasPrefix(path, "/items/"):
		itemID := strings.TrimPrefix(path, "/items/")
		response, err = updateItem(ctx, itemID, req)
	case method == "DELETE" && strings.HasPrefix(path, "/items/"):
		itemID := strings.TrimPrefix(path, "/items/")
		response, err = archiveItem(ctx, itemID)
	case method == "POST" && path == "/items/archive":
		response, err = batchArchive(ctx, req)
	default:
		err = fmt.Errorf("not found")
		statusCode = http.StatusNotFound
	}

	if err != nil {
		return errorResponse(headers, err, statusCode), nil
	}

	body, _ := json.Marshal(response)
	return events.APIGatewayV2HTTPResponse{
		StatusCode: http.StatusOK,
		Headers:    headers,
		Body:       string(body),
	}, nil
}

func errorResponse(headers map[string]string, err error, statusCode int) events.APIGatewayV2HTTPResponse {
	if statusCode == 0 {
		errMsg := err.Error()
		// Determine appropriate status code based on error message
		switch {
		case strings.Contains(errMsg, "is required"),
			strings.Contains(errMsg, "invalid request body"):
			statusCode = http.StatusBadRequest
		case strings.Contains(errMsg, "not found"),
			strings.Contains(errMsg, "ConditionalCheckFailedException"):
			statusCode = http.StatusNotFound
		default:
			statusCode = http.StatusInternalServerError
		}
	}
	errResp := map[string]interface{}{
		"error": err.Error(),
		"code":  http.StatusText(statusCode),
	}
	body, _ := json.Marshal(errResp)
	return events.APIGatewayV2HTTPResponse{
		StatusCode: statusCode,
		Headers:    headers,
		Body:       string(body),
	}
}

// getItems handles GET /items
func getItems(ctx context.Context, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	// Parse query params
	folderID := req.QueryStringParameters["folderId"]
	if folderID == "" {
		return nil, fmt.Errorf("folderId is required")
	}

	nextToken := req.QueryStringParameters["nextToken"]
	filter := req.QueryStringParameters["filter"]
	if filter == "" {
		filter = "all"
	}
	sortBy := req.QueryStringParameters["sort"]
	if sortBy == "" {
		sortBy = "createdAt"
	}

	limit := 20
	if limitStr := req.QueryStringParameters["limit"]; limitStr != "" {
		fmt.Sscanf(limitStr, "%d", &limit)
		if limit > 50 {
			limit = 50
		}
		if limit < 1 {
			limit = 20
		}
	}

	// Query items
	items, newToken, err := queryItems(ctx, folderID, nextToken, filter, sortBy, limit)
	if err != nil {
		return nil, err
	}

	// Build response
	resp := GetItemsResponse{
		Data: items,
		Meta: map[string]int{
			"count": len(items),
		},
	}

	if newToken != "" {
		resp.Pagination = map[string]string{
			"nextToken": newToken,
		}
	}

	return resp, nil
}

// getUploadURLs handles POST /items/upload
func getUploadURLs(ctx context.Context) (interface{}, error) {
	thumbURL, fullURL, imageKey, err := generatePresignedURLs(ctx)
	if err != nil {
		return nil, err
	}

	return UploadURLsResponse{
		Data: map[string]interface{}{
			"uploadUrls": map[string]string{
				"thumb": thumbURL,
				"full":  fullURL,
			},
			"imageUrl": imageKey,
		},
	}, nil
}

// createItem handles POST /items
func createItem(ctx context.Context, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	var createReq CreateItemRequest
	if err := json.Unmarshal([]byte(req.Body), &createReq); err != nil {
		return nil, fmt.Errorf("invalid request body: %w", err)
	}

	if createReq.FolderID == "" {
		return nil, fmt.Errorf("folderId is required")
	}

	if createReq.ImageURL == "" {
		return nil, fmt.Errorf("imageUrl is required")
	}

	if createReq.State == "" {
		createReq.State = "Unanswered"
	}

	item, err := createItemRecord(ctx, createReq.FolderID, createReq.ImageURL, createReq.State)
	if err != nil {
		return nil, err
	}

	return ItemResponse{Data: *item}, nil
}

// updateItem handles PUT /items/{id}
func updateItem(ctx context.Context, itemID string, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	var updateReq UpdateItemRequest
	if err := json.Unmarshal([]byte(req.Body), &updateReq); err != nil {
		return nil, fmt.Errorf("invalid request body: %w", err)
	}

	item, err := updateItemRecord(ctx, itemID, updateReq)
	if err != nil {
		return nil, err
	}

	return ItemResponse{Data: *item}, nil
}

// archiveItem handles DELETE /items/{id}
func archiveItem(ctx context.Context, itemID string) (interface{}, error) {
	err := archiveItemRecord(ctx, itemID)
	if err != nil {
		return nil, err
	}

	return EmptyResponse{Data: map[string]interface{}{}}, nil
}

// batchArchive handles POST /items/archive
func batchArchive(ctx context.Context, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	var batchReq BatchArchiveRequest
	if err := json.Unmarshal([]byte(req.Body), &batchReq); err != nil {
		return nil, fmt.Errorf("invalid request body: %w", err)
	}

	if len(batchReq.ItemIDs) == 0 {
		return nil, fmt.Errorf("itemIds is required")
	}

	if len(batchReq.ItemIDs) > 25 {
		return nil, fmt.Errorf("max 25 items per request")
	}

	archived, failed := batchArchiveItems(ctx, batchReq.ItemIDs)

	return BatchArchiveResponse{
		Data: map[string][]string{
			"archived": archived,
			"failed":   failed,
		},
	}, nil
}

// getFolders handles GET /folders
func getFolders(ctx context.Context) (interface{}, error) {
	folders, err := GetFolders(ctx)
	if err != nil {
		return nil, err
	}

	return GetFoldersResponse{Data: folders}, nil
}

// createFolder handles POST /folders
func createFolder(ctx context.Context, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	var createReq CreateFolderRequest
	if err := json.Unmarshal([]byte(req.Body), &createReq); err != nil {
		return nil, fmt.Errorf("invalid request body: %w", err)
	}

	if createReq.FolderID == "" {
		return nil, fmt.Errorf("folderId is required")
	}

	if createReq.Name == "" {
		return nil, fmt.Errorf("name is required")
	}

	folder, err := CreateFolder(ctx, createReq.FolderID, createReq.Name)
	if err != nil {
		return nil, err
	}

	return FolderResponse{Data: *folder}, nil
}

// updateFolder handles PUT /folders/{folderId}
func updateFolder(ctx context.Context, folderID string, req events.APIGatewayV2HTTPRequest) (interface{}, error) {
	var updateReq UpdateFolderRequest
	if err := json.Unmarshal([]byte(req.Body), &updateReq); err != nil {
		return nil, fmt.Errorf("invalid request body: %w", err)
	}

	if updateReq.Name == "" {
		return nil, fmt.Errorf("name is required")
	}

	folder, err := UpdateFolder(ctx, folderID, updateReq.Name)
	if err != nil {
		return nil, err
	}

	return FolderResponse{Data: *folder}, nil
}

// deleteFolder handles DELETE /folders/{folderId}
func deleteFolder(ctx context.Context, folderID string) (interface{}, error) {
	err := DeleteFolder(ctx, folderID)
	if err != nil {
		return nil, err
	}

	return EmptyResponse{Data: map[string]interface{}{}}, nil
}

func main() {
	lambda.Start(handler)
}
