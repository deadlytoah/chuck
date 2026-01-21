//go:build integration

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"testing"
)

func getAPIURL() string {
	url := os.Getenv("API_URL")
	if url == "" {
		// Default to chuck-api-v2
		url = "https://f5vhix3qrw5e6oxhnb3rqldr3i0bipsw.lambda-url.us-east-1.on.aws"
	}
	return url
}

func TestFoldersAPI(t *testing.T) {
	baseURL := getAPIURL()
	client := &http.Client{}

	// Test folder ID for this test run
	testFolderID := "integration-test"
	testFolderName := "Integration Test Folder"

	// Cleanup function
	cleanup := func() {
		req, _ := http.NewRequest("DELETE", fmt.Sprintf("%s/folders/%s", baseURL, testFolderID), nil)
		client.Do(req)
	}

	// Ensure clean state before test
	cleanup()
	defer cleanup()

	t.Run("GET /folders - empty", func(t *testing.T) {
		resp, err := client.Get(fmt.Sprintf("%s/folders", baseURL))
		if err != nil {
			t.Fatalf("GET /folders failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}

		var result GetFoldersResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		// May not be empty if other folders exist, just verify structure
		if result.Data == nil {
			t.Error("Expected data field, got nil")
		}
	})

	t.Run("POST /folders - create", func(t *testing.T) {
		reqBody := CreateFolderRequest{
			FolderID: testFolderID,
			Name:     testFolderName,
		}
		body, _ := json.Marshal(reqBody)

		resp, err := client.Post(
			fmt.Sprintf("%s/folders", baseURL),
			"application/json",
			bytes.NewReader(body),
		)
		if err != nil {
			t.Fatalf("POST /folders failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(resp.Body)
			t.Fatalf("Expected status 200, got %d: %s", resp.StatusCode, string(bodyBytes))
		}

		var result FolderResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		if result.Data.FolderID != testFolderID {
			t.Errorf("Expected folderId %s, got %s", testFolderID, result.Data.FolderID)
		}

		if result.Data.Name != testFolderName {
			t.Errorf("Expected name %s, got %s", testFolderName, result.Data.Name)
		}

		if result.Data.CreatedAt == "" {
			t.Error("Expected createdAt to be set")
		}
	})

	t.Run("GET /folders - with data", func(t *testing.T) {
		resp, err := client.Get(fmt.Sprintf("%s/folders", baseURL))
		if err != nil {
			t.Fatalf("GET /folders failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}

		var result GetFoldersResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		// Find our test folder
		found := false
		for _, folder := range result.Data {
			if folder.FolderID == testFolderID {
				found = true
				if folder.Name != testFolderName {
					t.Errorf("Expected name %s, got %s", testFolderName, folder.Name)
				}
				break
			}
		}

		if !found {
			t.Error("Test folder not found in list")
		}
	})

	t.Run("PUT /folders/:id - update", func(t *testing.T) {
		updatedName := "Updated Test Folder"
		reqBody := UpdateFolderRequest{
			Name: updatedName,
		}
		body, _ := json.Marshal(reqBody)

		req, err := http.NewRequest(
			"PUT",
			fmt.Sprintf("%s/folders/%s", baseURL, testFolderID),
			bytes.NewReader(body),
		)
		if err != nil {
			t.Fatalf("Failed to create request: %v", err)
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("PUT /folders/:id failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(resp.Body)
			t.Fatalf("Expected status 200, got %d: %s", resp.StatusCode, string(bodyBytes))
		}

		var result FolderResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		if result.Data.Name != updatedName {
			t.Errorf("Expected name %s, got %s", updatedName, result.Data.Name)
		}

		if result.Data.FolderID != testFolderID {
			t.Errorf("Expected folderId %s, got %s", testFolderID, result.Data.FolderID)
		}
	})

	t.Run("DELETE /folders/:id - delete", func(t *testing.T) {
		req, err := http.NewRequest(
			"DELETE",
			fmt.Sprintf("%s/folders/%s", baseURL, testFolderID),
			nil,
		)
		if err != nil {
			t.Fatalf("Failed to create request: %v", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("DELETE /folders/:id failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(resp.Body)
			t.Fatalf("Expected status 200, got %d: %s", resp.StatusCode, string(bodyBytes))
		}

		var result EmptyResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}
	})

	t.Run("GET /folders - verify deleted", func(t *testing.T) {
		resp, err := client.Get(fmt.Sprintf("%s/folders", baseURL))
		if err != nil {
			t.Fatalf("GET /folders failed: %v", err)
		}
		defer resp.Body.Close()

		var result GetFoldersResponse
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		// Verify test folder is gone
		for _, folder := range result.Data {
			if folder.FolderID == testFolderID {
				t.Error("Test folder should have been deleted")
			}
		}
	})
}

func TestFoldersAPIErrors(t *testing.T) {
	baseURL := getAPIURL()
	client := &http.Client{}

	t.Run("POST /folders - missing folderId", func(t *testing.T) {
		reqBody := map[string]string{
			"name": "Test Folder",
		}
		body, _ := json.Marshal(reqBody)

		resp, err := client.Post(
			fmt.Sprintf("%s/folders", baseURL),
			"application/json",
			bytes.NewReader(body),
		)
		if err != nil {
			t.Fatalf("POST /folders failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("Expected status 400, got %d", resp.StatusCode)
		}
	})

	t.Run("POST /folders - missing name", func(t *testing.T) {
		reqBody := map[string]string{
			"folderId": "test-id",
		}
		body, _ := json.Marshal(reqBody)

		resp, err := client.Post(
			fmt.Sprintf("%s/folders", baseURL),
			"application/json",
			bytes.NewReader(body),
		)
		if err != nil {
			t.Fatalf("POST /folders failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusBadRequest {
			t.Errorf("Expected status 400, got %d", resp.StatusCode)
		}
	})

	t.Run("PUT /folders/:id - non-existent folder", func(t *testing.T) {
		reqBody := UpdateFolderRequest{
			Name: "Updated Name",
		}
		body, _ := json.Marshal(reqBody)

		req, err := http.NewRequest(
			"PUT",
			fmt.Sprintf("%s/folders/non-existent", baseURL),
			bytes.NewReader(body),
		)
		if err != nil {
			t.Fatalf("Failed to create request: %v", err)
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("PUT /folders/:id failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNotFound {
			bodyBytes, _ := io.ReadAll(resp.Body)
			t.Errorf("Expected status 404, got %d: %s", resp.StatusCode, string(bodyBytes))
		}
	})

	t.Run("DELETE /folders/:id - non-empty folder", func(t *testing.T) {
		// This test requires creating a folder with items first
		// Skip for now as it requires item creation
		t.Skip("Requires item creation infrastructure")
	})
}
