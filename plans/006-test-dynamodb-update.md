# Plan for DynamoDB Update Test Case

## Prompt

> How would you go about writing a test case for this?

## Relevant Code

The following code in `chuck/lambda/dynamodb.go` would cause a
`ValidationException` if `req.State` was nil because
`ExpressionAttributeNames` would contain an unused key.

```/Users/hcs/Sync/Code/chuck/lambda/dynamodb.go#L262-272
	if req.Notes != nil {
		updateExpr += ", notes = :notes"
		exprAttrValues[":notes"] = &types.AttributeValueMemberS{Value: *req.Notes}
	}

	exprAttrNames := map[string]string{
		"#state": "state",
	}

	// Update item
```

## Plan

- Create a new test file: `chuck/lambda/dynamodb_test.go`.
- Define a mock DynamoDB client that implements the `Query` and
  `UpdateItem` methods from the DynamoDB client interface.
- In the mock, the `UpdateItem` method will capture the input it
  receives, allowing for assertions on its parameters.
- Write a test function that replaces the real `dynamoClient` with
  the mock.
- Call `updateItemRecord` with `req.State = nil` and `req.Notes` set
  to a value to trigger an update.
- Assert that the `ExpressionAttributeNames` map in the input passed
  to the mock `UpdateItem` method is empty.