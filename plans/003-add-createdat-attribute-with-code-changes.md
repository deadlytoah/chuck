# Plan: Add createdAt Attribute with Code Changes

## Prompt

I would like `createdAt` attribute set for new items. Would you update `./technical.md` to mention this new attribute? You found out in a separate investigation, the following should be done:

Here is the relevant code snippet:

```go
// chuck/lambda/dynamodb.go#L162-L172
func createItemRecord(ctx context.Context, imageURL, state string) (*Item, error) {
	// ...
	now := time.Now().UTC().Format(time.RFC3339)
	item := Item{
		ItemID:    uuid.New().String(),
		ImageURL:  imageURL,
		State:     state,
		Archived:  "false",
		UpdatedAt: now,
	}
	// ...
}
```

1.  Add a `CreatedAt` field to the `Item` struct in `chuck/lambda/types.go`.
2.  Set the `CreatedAt` field in the `createItemRecord` function in `chuck/lambda/dynamodb.go`.

Record your plan and then stop.

## Plan

1.  Add a `CreatedAt` field to the `Item` struct in `chuck/lambda/types.go`.
2.  Update the `createItemRecord` function in `chuck/lambda/dynamodb.go` to set the `CreatedAt` field on new items.
3.  Update the `DynamoDB Schema` section in `chuck/technical.md` to include the new `createdAt` attribute.