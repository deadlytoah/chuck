# Technical Specifications — Backend

Shared backend consumed by the Flutter iOS app and the Next.js web
app. See `technical.md` for iOS specifics and `technical-web.md`
for web specifics.

## Architecture Overview

```
iOS / Web → Lambda Function URL → Go Lambda → DynamoDB
iOS / Web → S3 presigned URL   → S3 (direct PUT)
Browser   → CloudFront         → S3 (web static assets)
```

- Single Lambda handles all routing internally (no API Gateway).
- Clients obtain presigned PUT URLs from Lambda, then upload
  images directly to S3, bypassing Lambda for the transfer.
- Web app is a Next.js static export served via CloudFront→S3.
- Infrastructure defined in `cloudformation.yaml` (IaC).

## Platform

| Resource      | Details                                      |
|---------------|----------------------------------------------|
| Lambda OS     | Amazon Linux 2 (`provided.al2`)              |
| Architecture  | arm64 (Graviton2)                            |
| Memory        | 512 MB                                       |
| Timeout       | 30 s                                         |
| Region        | Configurable via `REGION` env var            |
| Target env    | AWS (single-region, single-account)          |

## Technologies

| Component   | Choice           | Rationale                              |
|-------------|------------------|----------------------------------------|
| Language    | Go               | Fast cold start, small binary, simple  |
| Runtime     | `provided.al2`   | Custom runtime for Go compiled binary  |
| API layer   | Lambda Func URL  | No API Gateway overhead; direct HTTPS  |
| Database    | DynamoDB         | Serverless, on-demand, single-table    |
| Storage     | S3               | Presigned URLs offload transfer work   |
| CDN         | CloudFront       | TLS termination, SPA routing, cache    |
| DNS         | Route53          | ALIAS record to CloudFront             |
| IaC         | CloudFormation   | Declarative AWS resource provisioning  |

DynamoDB over RDS: no schema migrations, serverless scaling, and
access patterns are known and key-based.

Lambda Function URL over API Gateway: lower cost and latency for
a private family app with low traffic.

## Data Models

### Item

Stored as a DynamoDB item under a folder partition.

| Field      | Type    | Notes                                         |
|------------|---------|-----------------------------------------------|
| PK         | String  | `folder#{folderId}`                           |
| SK         | String  | `item#{archived}#{createdAt}`                 |
| entityType | String  | `"item"` (literal)                            |
| itemId     | String  | UUID, unique identifier                       |
| folderId   | String  | e.g., `"entryway"`, `"living-room"`           |
| imageUrl   | String  | S3 object key for full-size image             |
| state      | String  | Chuck/Keep/Sell/Undecided/Unanswered          |
| notes      | String  | Multi-line notes; omitted if empty            |
| archived   | Boolean | true = archived                               |
| archivedAt | String  | ISO-8601 timestamp; omitted if not archived   |
| createdAt  | String  | ISO-8601 timestamp (immutable)                |
| updatedAt  | String  | ISO-8601 timestamp, updated on every write    |

SK encodes `archived` state to enable efficient range queries for
active vs. archived items without a GSI.

### Folder

Stored in the same table as a metadata record.

| Field      | Type   | Notes                          |
|------------|--------|--------------------------------|
| PK         | String | `folder#{folderId}`            |
| SK         | String | `"metadata"` (literal)         |
| entityType | String | `"folder"` (literal)           |
| folderId   | String | Unique identifier (slug-style) |
| name       | String | Display name                   |
| createdAt  | String | ISO-8601 timestamp             |

### DynamoDB Table

- Name: `chuck-items-v2` (v1 `chuck-items` deprecated)
- PK: `PK` (String, HASH key)
- SK: `SK` (String, RANGE key)
- Billing: PAY_PER_REQUEST (on-demand)
- PITR: disabled

**Query patterns:**

| Pattern                  | Key condition                                      |
|--------------------------|----------------------------------------------------|
| Active items in folder   | `PK="folder#x" AND SK begins_with "item#false#"`   |
| Archived items in folder | `PK="folder#x" AND SK begins_with "item#true#"`    |
| All items in folder      | `PK="folder#x" AND SK begins_with "item#"`         |
| Folder metadata          | `PK="folder#x" AND SK="metadata"`                  |
| All folders              | Scan with filter `entityType="folder"`             |

### S3 Image Storage

- Bucket: `chuck.overcomingsh.in`
- Key format: `images/{uuid}/full.jpg`,
  `images/{uuid}/thumb.jpg`
- `imageUrl` in DynamoDB stores the S3 object key (not a URL).
- Thumbnail key derived from full key by string substitution
  (`s/full/thumb/`).
- Lifecycle: all objects under `images/` expire after 30 days.
- Image constraints: JPEG only, max 10 MB.
- Client resizes before upload: thumbnail ≤ 200×150 px,
  full ≤ 1200×900 px (aspect ratio preserved).

### Migration

- `migrate.go`: one-time script to move `chuck-items` records
  into `chuck-items-v2` under the `"entryway"` folder.
- Archived field was stored as string `"true"`/`"false"` in v1;
  migration converts to boolean.
- Run manually post-deployment if migrating from v1.

## Actors

- **iOS client** (Flutter): reads/writes items and folders;
  uploads images via presigned URLs.
- **Web client** (Next.js): same API surface as iOS client.
- **Go Lambda**: routes HTTP requests, reads/writes DynamoDB,
  generates presigned S3 URLs.
- **DynamoDB**: stores items and folders.
- **S3**: stores image files; delivers web app via CloudFront.
- **CloudFront**: CDN for the web app; enforces HTTPS.
- **IAM role** (`chuck-lambda-execution-role`): grants Lambda
  access to S3 `images/*` and DynamoDB table only.

## API Contracts

Base URL: Lambda Function URL (output from `deploy-stack.sh`).

### Conventions

- Response envelope: `{"data": {...}, "pagination": {...},
  "meta": {...}}`
- Error format: `{"error": "message", "code": "Bad Request"}`
- HTTP status mapping:
  - 400: validation error or missing required field
  - 404: item/folder not found or condition check failed
  - 500: unexpected error
- Concurrency: last write wins; no optimistic locking.
- Authentication: none (URL treated as private secret).

### Folder Endpoints

#### GET /folders
- Returns all folders.
- Response: `{"data": [{"folderId":"…","name":"…",
  "createdAt":"…"}]}`

#### POST /folders
- Request: `{"folderId": "clothes", "name": "Clothes"}`
- Creates a new folder.
- Response: `{"data": {folder object}}`

#### PUT /folders/{folderId}
- Request: `{"name": "New Name"}`
- Renames a folder.
- Response: `{"data": {folder object}}`

#### DELETE /folders/{folderId}
- Deletes folder only if empty (no items).
- Response: `{"data": {}}`

### Item Endpoints

#### GET /items
- Query params:
  - `folderId` (required)
  - `limit`: 1–50, default 20
  - `sort`: `createdAt` | `createdAt:asc` | `createdAt:desc`
    | `updatedAt:asc` | `updatedAt:desc` | `state`
  - `filter`: `Chuck` | `Keep` | `Sell` | `Undecided` |
    `Unanswered` | `archived` | `all` (default `all`)
  - `nextToken`: opaque cursor (base64 of DynamoDB
    LastEvaluatedKey)
- `archived` filter returns archived items; `all` returns
  active items only.
- Response: `{"data":[…],"pagination":{"nextToken":"…"},
  "meta":{"count":N}}`

#### POST /items/upload
- No request body.
- Generates a UUID, returns presigned PUT URLs for thumb
  and full images.
- Response: `{"data":{"uploadUrls":{"thumb":"…","full":"…"},
  "imageUrl":"images/{uuid}/full.jpg"}}`
- No DynamoDB record created at this step.

#### POST /items
- Request: `{"imageUrl":"images/{uuid}/full.jpg",
  "folderId":"entryway","state":"Unanswered"}`
- Creates DynamoDB record; assigns `itemId` (UUID).
- Default state: `Unanswered`.
- If this call fails after a successful upload, S3 objects
  are dangling (no automatic cleanup).
- Response: `{"data": {item object}}`

#### PUT /items/{id}
- Request (any subset): `{"state":"Sell"}`,
  `{"notes":"…"}`, `{"archived":false}`
- Images cannot be changed after creation.
- Archived items: state updates rejected; unarchive first
  via `{"archived":false}`.
- Response: `{"data": {item object}}`

#### DELETE /items/{id}
- Archives single item (sets `archived=true`,
  records `archivedAt`).
- Response: `{"data": {}}`

#### POST /items/archive
- Batch archive; max 25 items per request.
- Request: `{"itemIds":["id1","id2",…]}`
- Partial success: failures do not abort the batch.
- Response: `{"data":{"archived":[…],"failed":[…]}}`

## Deployment

### Environment Variables (Lambda)

| Variable      | Value                     |
|---------------|---------------------------|
| `BUCKET_NAME` | `chuck.overcomingsh.in`   |
| `TABLE_NAME`  | `chuck-items-v2`          |
| `REGION`      | AWS region of deployment  |

### Commands

| Action            | Command                                     |
|-------------------|---------------------------------------------|
| Deploy Lambda     | `cd lambda && make update`                  |
| Deploy web app    | `./deploy-web.sh`                           |
| Deploy full stack | `./deploy-stack.sh`                         |

`deploy-stack.sh` builds the Lambda binary, uploads to S3, then
creates or updates the CloudFormation stack. Outputs `FunctionUrl`,
`WebsiteURL`, and `CloudFrontDistributionId`. Set `HOSTED_ZONE_NAME`
env var to override `overcomingsh.in.`. After a fresh deploy,
update `web/.env.local` with the printed `NEXT_PUBLIC_API_URL`.

### CloudFormation Resources

| Resource                | Name / Detail                              |
|-------------------------|--------------------------------------------|
| S3 bucket               | `chuck.overcomingsh.in`                    |
| DynamoDB table          | `chuck-items-v2`                           |
| Lambda function         | `chuck-api-v2`                             |
| Lambda Function URL     | NONE auth, CORS restricted to web origin   |
| CloudFront distribution | `chuck.overcomingsh.in` (HTTPS)            |
| CloudFront OAC          | `chuck-oac` (sigv4)                        |
| Route53 A record        | ALIAS to CloudFront                        |
| CloudWatch log group    | `/aws/lambda/chuck-api-v2`, 7-day retention|
| IAM role                | `chuck-lambda-execution-role`              |

CloudFront: PriceClass_100 (US/EU), HTTP/2, TLS 1.2+, redirects
HTTP→HTTPS. 403/404 errors served as `index.html` (SPA routing).
HTML files use no-cache policy.

## Dependencies

### Go Modules (`lambda/`)

| Module                                          | Purpose              |
|-------------------------------------------------|----------------------|
| `github.com/aws/aws-lambda-go`                  | Lambda runtime       |
| `github.com/aws/aws-sdk-go-v2`                  | AWS SDK core         |
| `github.com/aws/aws-sdk-go-v2/config`           | AWS config loading   |
| `github.com/aws/aws-sdk-go-v2/service/dynamodb` | DynamoDB client      |
| `github.com/aws/aws-sdk-go-v2/service/s3`       | S3 presign client    |
| `github.com/stretchr/testify`                   | Test assertions      |

## Tests

### Unit Tests (`lambda/dynamodb_test.go`)

Run: `cd lambda && go test ./...`

Uses `mockDDBClient` implementing a `ddbAPI` interface; no live
AWS services required.

| Test                            | Covers                                  |
|---------------------------------|-----------------------------------------|
| `TestUpdateItemRecord_NilState` | nil State excluded from UPDATE expr     |
| `TestParseSortParam`            | sort param parsing (`field:direction`)  |

### Integration Tests (`lambda/integration_test.go`)

Require `LAMBDA_URL` env var pointing to a live Lambda endpoint.

Run: `LAMBDA_URL=https://… go test -run TestFolders ./...`

| Test                   | Covers                                       |
|------------------------|----------------------------------------------|
| `TestFoldersAPI`       | Full folder CRUD lifecycle against live API  |
| `TestFoldersAPIErrors` | Error responses (missing fields, not found)  |

## Security

| Control                  | Detail                                         |
|--------------------------|------------------------------------------------|
| Transport                | HTTPS enforced by CloudFront (TLS 1.2+)        |
| Authentication           | None; Lambda URL treated as private secret     |
| CORS                     | Restricted to `https://chuck.overcomingsh.in`  |
| S3 public access         | Blocked; access via CloudFront OAC only        |
| S3 presigned scope       | PUT to `images/*` only; GET via CloudFront OAC |
| IAM least privilege      | Lambda: `s3:GetObject`/`PutObject` on          |
|                          | `images/*`; DynamoDB CRUD on table only;       |
|                          | CloudWatch Logs write only                     |
| CloudFront signing       | OAC with sigv4; bucket policy enforces access  |
|                          | only from the CloudFront distribution ARN      |
| Log retention            | CloudWatch logs purged after 7 days            |
| Image lifecycle          | S3 auto-deletes `images/` objects after 30 days|

No auth tokens, sessions, or user accounts. Access control is
URL-based (shared within family).

## Backup Strategy

No backup is currently configured. DynamoDB PITR is disabled,
no on-demand snapshots are taken, and S3 object versioning is
off. A destructive operation — bulk-delete, bad migration, or
deployment error — would result in permanent data loss.

DynamoDB PITR and S3 object versioning for the `images/` prefix
are planned for a future update.

## Open Questions

- **Dangling S3 objects**: if `POST /items/upload` succeeds but
  `POST /items` fails, uploaded images are orphaned. No cleanup
  mechanism exists.
- **Presigned URL expiry**: duration uses AWS SDK default
  (~15 min); not explicitly configured.
- **Rate limiting**: Lambda Function URL has no built-in rate
  limit; no WAF or throttling configured.
- **Optimistic locking**: concurrent writes from multiple clients
  result in last write wins; no conflict detection.
- **Folder delete race**: `DeleteFolder` requires the folder to
  be empty, but there is no atomic check-and-delete; a race
  between listing items and deleting is possible.
- **Migration status**: `chuck-items` v1 table may still exist;
  confirm migration to `chuck-items-v2` is complete before
  decommissioning.
