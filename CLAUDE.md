## Guidelines

- Short sentences preferred
- Remove redundant words
- Use lists for complex info
- Active voice when possible
- One idea per paragraph
- Abbreviate when appropriate
- Use idiomatic patterns for language/framework (e.g., Dart, Go)

Your response: brief and concise list or list of sublists of brief
and concise items. To the point.

When you scan the directory, skip `.git/` and `log/`.

# Code and Documentation Lookup

Use jCodeMunch and jDocMunch for code and document retrieval:
- Prefer symbol search, file outlines, and targeted section
  retrieval over reading full files
- Use `search_symbols` for functions/classes/methods
- Use `get_file_outline` for file structure overview
- Use `search_sections` in jDocMunch for design docs and technical docs
- Read only what's needed to answer the question (conserves tokens)

- Flutter iOS functional design: `design.md`
- Next.js web app functional design: `design-web.md`
- Flutter iOS technical spec: `technical.md`
- Next.js web app technical spec: `technical-web.md`
- Shared backend technical spec: `technical-backend.md`
- IoC script: `cloudformation.yaml`
- Flutter source code: `src/`
- Lambda (golang) source: `lambda/`
- Deploy lambda: `cd lambda/ && make update`
- Deploy web: `./deploy-web.sh` (builds and syncs to S3, preserves
  images/ and lambda/ directories)
- IMPORTANT: Always confirm destructive actions before executing

# Plans

When I ask you to record your plan:
- First plan it, and then write your plan in a list of concise and brief items in a file.
- Determine the name of the file in `plans/###-{short description}.md` where ### is a zero-padded 3-digit serial number starting from 000.
- The serial number is to be unique in `plans/` directory.
- Also record the prompt that I used to generate the plan
- If relevant, also record the exerpts from and line numbers of the files you required to generate the plan.

# Clarifications

For each clarification request, ask me for up to 5 clarifications
with suggested options and your recommendation in a list and sublists
of brief and concise items.

# Token-Efficient Documentation

Fill each line to the 70th character column without breaking words,
and then go to next line. Use concise language without sacrificing
clarity. Avoid redundant facts in the documents.

# Walkthroughs

Save your walkthroughs in `./walkthroughs` directory.

- Determine the name of the walkthrough file in `plans/###-{short description}.md` format where ### is a zero-padded 3-digit serial number starting from 000.
- The serial number is to be unique in `./walkthroughs/` directory.

# Project Context

Functional design: `design.md` (iOS), `design-web.md` (web).
Technical specs: `technical.md` (iOS), `technical-web.md` (web),
`technical-backend.md` (shared backend).

## Codebase Structure

### Flutter (`/src/lib`)
- **models/**: `item.dart`, `queued_photo.dart`, `upload_progress.dart`
- **services/**: `api_service.dart`, `camera_queue_service.dart`,
  `camera_upload_service.dart`, `image_service.dart`, `network_
  monitor.dart`, `upload_service.dart`
- **providers/**: `app_providers.dart`, `providers.dart` (includes
  cameraQueueServiceProvider)
- **screens/**: `admin_page.dart`, `camera_screen.dart`, `home_page.
  dart`, `main_view.dart`
- **widgets/**: `bulk_actions.dart`, `camera_badge.dart`, `failed_
  upload_banner.dart`, `filter_bar.dart`, `hamburger_menu.dart`,
  `item_card.dart`, `items_grid.dart`, `upload_zone.dart`,
  `widgets.dart`
- **test/fixtures/**: Test image files (JPEG/PNG) for unit tests

### Backend (`/lambda`)
- `main.go`, `dynamodb.go`, `s3.go`, `types.go`, `dynamodb_test.go`
- Implements 6 API endpoints per technical.md

### Infrastructure (`/cloudformation.yaml`)
- S3: chuck.overcomingsh.in (web + images/)
- DynamoDB: chuck-items (PK: archived, SK: createdAt)
- Lambda: chuck-api (Function URL, Go)

## Quick Ref
- Lambda URL: https://aanonry4iszhp75mjpq33jfzxe0vzpdz.lambda-url.
  ap-southeast-2.on.aws/
