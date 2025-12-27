# Fix Sort Functionality in Lambda

## Prompt
Record your plan for fixing this problem.

## Problem
Sort bar in Flutter app not working because lambda ignores `updatedAt:desc`,
`updatedAt:asc`, `createdAt:asc` parameters. Only `state` sorting implemented.

## Root Cause Analysis
- Flutter app correctly passes sort parameter (e.g., `updatedAt:desc`)
- Lambda `getItems` receives parameter correctly (confirmed via logs)
- `queryItems` function in `dynamodb.go` only handles:
  - `sortBy == "state"` (in-memory sort, lines 94-98)
  - Default: always `createdAt` descending (line 51: `ScanIndexForward: false`)
- No logic for `updatedAt` sorting or ascending `createdAt` sorting

## DynamoDB Constraints
- Table uses composite key: `archived` (partition) + `createdAt` (sort key)
- Cannot query by `updatedAt` directly (not part of key)
- Options:
  1. In-memory sort after query (simple, works for small datasets)
  2. Add GSI with `updatedAt` as sort key (complex, requires infra changes)

## Proposed Solution
Parse sort parameter format `field:direction` and implement in-memory sorting
for `updatedAt` (similar to existing `state` sort).

### Changes Required

#### `lambda/dynamodb.go` - `queryItems` function (lines 93-98)
1. Parse `sortBy` parameter to extract field and direction
2. Keep existing DynamoDB query (always fetch by `createdAt` desc via `ScanIndexForward: false`)
3. After fetching, apply in-memory sort based on parsed parameters:
   - `updatedAt:desc` - sort by UpdatedAt descending
   - `updatedAt:asc` - sort by UpdatedAt ascending
   - `createdAt:asc` - reverse the DynamoDB order
   - `createdAt:desc` or `null` or `""` - **no sorting needed** (already default)
   - `state` - keep existing state sort

### Implementation Steps
1. Add helper function `parseSortParam(sortBy string) (field, direction)`
2. Add test case in `lambda/dynamodb_test.go` for `parseSortParam`:
   - Test `"updatedAt:desc"` returns `("updatedAt", "desc")`
   - Test `"createdAt:asc"` returns `("createdAt", "asc")`
   - Test `"state"` returns `("state", "")`
   - Test `""` returns `("createdAt", "desc")` (default)
3. Modify sort logic (lines 93-98) to handle all cases
4. Test with curl commands for each sort option
5. Verify logs show correct parameter
6. Deploy and test with Flutter app

## Verification
- Curl test: `?sort=updatedAt:desc`
- Curl test: `?sort=updatedAt:asc`
- Curl test: `?sort=createdAt:asc`
- Curl test: `?sort=state`
- Flutter app: verify all dropdown options work correctly
