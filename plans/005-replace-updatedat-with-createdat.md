# Plan: Replace `updatedAt` with `createdAt` as SK

## Prompt

> The app is unable to update any items because `updatedAt` is the SK
> of the DynamoDB table. I need to be able to update the items. I want
> `updatedAt` replaced by `createdAt` for the SK. Record your plan
> and then stop.

## Plan

1.  Find all instances of `updatedAt` in the codebase to identify where
    it's used as the sort key.
2.  Replace `updatedAt` with `createdAt` as the sort key in
    `cloudformation.yaml`.
3.  Update the Go lambda source in `lambda/` to use `createdAt`
    instead of `updatedAt` for DynamoDB queries and mutations.
    -   `lambda/types.go`: In `Item` struct, ensure `createdAt` is
        tagged as the sort key.
    -   `lambda/dynamodb.go`: In `queryItems`, `updateItemRecord`, and
        `archiveItemRecord`, use `createdAt` for sorting and key-based
        operations.
    -   `lambda/main.go`: In `getItems`, change the default `sortBy`
        parameter to `createdAt`.
4.  Update the Flutter source in `src/` to use `createdAt` instead of
    `updatedAt` when interacting with the backend.
    -   `src/lib/widgets/filter_bar.dart`: Default sort to `Created
        (newest first)` (`createdAt:desc`), and add `Updated (newest
        first)` (`updatedAt:desc`).
    -   `src/lib/models/item.dart`: No changes are needed.
    -   `src/test/unit_test.dart`: Review and update tests to reflect
        the new sorting logic.
5.  Run tests in `lambda/` to ensure the changes are working correctly.
6.  Deploy the updated lambda.
7.  Verify the application's update functionality.