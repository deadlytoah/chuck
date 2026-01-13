// +build migrate

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// OldItem represents an item from the old chuck-items table
type OldItem struct {
	ItemID     string `dynamodbav:"itemId"`
	ImageURL   string `dynamodbav:"imageUrl"`
	State      string `dynamodbav:"state"`
	Notes      string `dynamodbav:"notes,omitempty"`
	Archived   string `dynamodbav:"archived"` // "true" or "false" as string
	ArchivedAt string `dynamodbav:"archivedAt,omitempty"`
	CreatedAt  string `dynamodbav:"createdAt"`
	UpdatedAt  string `dynamodbav:"updatedAt"`
}

func main() {
	ctx := context.Background()

	// Load AWS config
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("Failed to load AWS config: %v", err)
	}

	client := dynamodb.NewFromConfig(cfg)

	oldTableName := "chuck-items"
	newTableName := "chuck-items-v2"
	folderID := "entryway"

	log.Println("Starting migration...")
	log.Printf("Source table: %s", oldTableName)
	log.Printf("Destination table: %s", newTableName)
	log.Printf("Target folder: %s", folderID)

	// Step 1: Create "entryway" folder in chuck-items-v2
	log.Println("\nStep 1: Creating 'entryway' folder...")
	now := time.Now().UTC().Format(time.RFC3339)
	folder := Folder{
		PK:         fmt.Sprintf("folder#%s", folderID),
		SK:         "metadata",
		EntityType: "folder",
		FolderID:   folderID,
		Name:       "Entryway",
		CreatedAt:  now,
	}

	folderAv, err := attributevalue.MarshalMap(folder)
	if err != nil {
		log.Fatalf("Failed to marshal folder: %v", err)
	}

	_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(newTableName),
		Item:      folderAv,
	})
	if err != nil {
		log.Fatalf("Failed to create folder: %v", err)
	}
	log.Println("✓ Folder created successfully")

	// Step 2: Scan all items from chuck-items
	log.Println("\nStep 2: Scanning items from old table...")
	var oldItems []OldItem
	var lastEvaluatedKey map[string]types.AttributeValue

	scanCount := 0
	for {
		scanInput := &dynamodb.ScanInput{
			TableName: aws.String(oldTableName),
		}

		if lastEvaluatedKey != nil {
			scanInput.ExclusiveStartKey = lastEvaluatedKey
		}

		result, err := client.Scan(ctx, scanInput)
		if err != nil {
			log.Fatalf("Failed to scan old table: %v", err)
		}

		var batch []OldItem
		err = attributevalue.UnmarshalListOfMaps(result.Items, &batch)
		if err != nil {
			log.Fatalf("Failed to unmarshal items: %v", err)
		}

		oldItems = append(oldItems, batch...)
		scanCount += len(batch)
		log.Printf("  Scanned %d items...", scanCount)

		lastEvaluatedKey = result.LastEvaluatedKey
		if lastEvaluatedKey == nil {
			break
		}
	}

	log.Printf("✓ Scanned %d items total", len(oldItems))

	// Step 3: Transform and write items to chuck-items-v2
	log.Println("\nStep 3: Migrating items to new table...")
	migratedCount := 0
	failedCount := 0

	for i, oldItem := range oldItems {
		// Convert archived from string to boolean
		archived := oldItem.Archived == "true"

		// Create new item with PK/SK pattern
		newItem := Item{
			PK:         fmt.Sprintf("folder#%s", folderID),
			SK:         fmt.Sprintf("item#%s#%s", oldItem.Archived, oldItem.CreatedAt),
			EntityType: "item",
			ItemID:     oldItem.ItemID,
			FolderID:   folderID,
			ImageURL:   oldItem.ImageURL,
			State:      oldItem.State,
			Notes:      oldItem.Notes,
			Archived:   archived,
			ArchivedAt: oldItem.ArchivedAt,
			CreatedAt:  oldItem.CreatedAt,
			UpdatedAt:  oldItem.UpdatedAt,
		}

		itemAv, err := attributevalue.MarshalMap(newItem)
		if err != nil {
			log.Printf("  ✗ Failed to marshal item %s: %v", oldItem.ItemID, err)
			failedCount++
			continue
		}

		_, err = client.PutItem(ctx, &dynamodb.PutItemInput{
			TableName: aws.String(newTableName),
			Item:      itemAv,
		})
		if err != nil {
			log.Printf("  ✗ Failed to write item %s: %v", oldItem.ItemID, err)
			failedCount++
			continue
		}

		migratedCount++
		if (i+1)%100 == 0 {
			log.Printf("  Migrated %d/%d items...", i+1, len(oldItems))
		}
	}

	log.Printf("\n✓ Migration complete!")
	log.Printf("  Total items: %d", len(oldItems))
	log.Printf("  Migrated: %d", migratedCount)
	log.Printf("  Failed: %d", failedCount)

	if failedCount > 0 {
		os.Exit(1)
	}
}
