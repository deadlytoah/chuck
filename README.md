# chuck

A shared record-keeping app my family uses to sort household items
with photos. Items are photographed with the iOS app, then everyone
reviews them and picks a state — Chuck, Keep, Sell or Undecided —
from their own phone.

Built for small-scale use: 50–100 items per folder.

## Architecture

```
iOS / Web → Lambda Function URL → Go Lambda → DynamoDB
iOS / Web → S3 presigned URL    → S3 (direct PUT)
Browser   → CloudFront          → S3 (web static assets)
```

- **iOS app** (`ios/`): Flutter. In-app camera with continuous
  capture and an upload queue.
- **Web app** (`web/`): Next.js static export for iPhone Safari.
  No install; open a link and start deciding.
- **Backend** (`lambda/`): a single Go Lambda behind a Function URL
  (no API Gateway); DynamoDB single-table design; images uploaded
  straight to S3 via presigned URLs.
- **Infrastructure**: `cloudformation.yaml`. CloudFront + ACM +
  Route 53 for HTTPS, with a private S3 origin (OAC).

## Specs

The specs drive development. Each change starts as a spec update,
then a plan, then code.

| Document | Covers |
| --- | --- |
| [design.md](design.md) | Functional spec — iOS app |
| [technical.md](technical.md) | Technical spec — iOS app |
| [design-web.md](design-web.md) | Functional spec — web app |
| [technical-web.md](technical-web.md) | Technical spec — web app |
| [technical-backend.md](technical-backend.md) | Technical spec — backend and API |

## How it's built

I write the functional and technical specs and make the product,
UX and architecture decisions. AI coding agents (Claude Code)
implement them in a plan → execute → review workflow, with linting,
type checks and Playwright end-to-end tests. I review the plans and
the changes before they're committed. Plans are kept in `plans/`.

## Running and deploying

| Action | Command |
| --- | --- |
| Backend unit tests | `cd lambda && go test ./...` |
| Web checks (types, lint, format) | `cd web && npm run check` |
| Web E2E tests | `cd web && npm run test:e2e` |
| Deploy Lambda | `cd lambda && make update` |
| Deploy web app | `./deploy-web.sh` |
| Deploy full stack | `./deploy-stack.sh` |

See `technical-backend.md` for environment variables and stack
outputs.

## Known limitations

- No authentication yet. Access is by private URL, but the domain
  appears in the specs, so it isn't truly private. Planned: a simple
  family login (family name + a 4-emoji sequence from a 3×3 grid,
  designed for children), checked by the Lambda with rate limiting
  and a session cookie.