# Plan 038: Root `.env.local` Shared Config

## Context

The Lambda URL was hardcoded in
`ios/lib/providers/app_providers.dart:14` (wrong URL:
`aanonry4iszhp75mjpq33jfzxe0vzpdz...`) while `web/.env.local`
held the correct URL (`4smxwogu4abgz36ptd53ihtgri0zhsmp...`).
This caused "Unable to create folder" errors in the iOS app.
No shared source of truth existed. The URL is kept out of git
(`.env.local` gitignored) as light obscurity until login is
implemented. Goal: one `/.env.local` at repo root consumed by
both Next.js (web) and Flutter (iOS).

## Current State

- `web/.env.local` — holds:
  ```
  NEXT_PUBLIC_API_URL=https://4smxwogu4abgz36ptd53ihtgri0zhsmp.lambda-url.ap-southeast-2.on.aws
  NEXT_PUBLIC_S3_BASE=http://chuck.overcomingsh.in
  ```
- `ios/lib/providers/app_providers.dart:14` — hardcoded wrong URL
- `web/next.config.ts` — standard config, no custom env loading
- Root `.gitignore` — currently ignores: `lambda/bin`, `go.sum`,
  `log`, `.DS_Store`
- No wrapper script for `flutter run`/`flutter build`

## Steps

### 1. Create `/.env.local` at repo root

Create the file `/Users/hcs/Sync/Code/chuck/.env.local` with:
```
NEXT_PUBLIC_API_URL=https://4smxwogu4abgz36ptd53ihtgri0zhsmp.lambda-url.ap-southeast-2.on.aws
NEXT_PUBLIC_S3_BASE=http://chuck.overcomingsh.in
```

### 2. Delete `web/.env.local`

Remove `web/.env.local` — it is replaced by root `.env.local`.
Use Bash: `rm /Users/hcs/Sync/Code/chuck/web/.env.local`

### 3. Update `web/next.config.ts` to load root `.env.local`

Replace the file content with:
```ts
import type { NextConfig } from 'next'
import * as dotenv from 'dotenv'
import * as path from 'path'

dotenv.config({ path: path.resolve(__dirname, '../.env.local') })

const nextConfig: NextConfig = {
  output: 'export',
  images: { unoptimized: true },
  trailingSlash: true,
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? '',
    NEXT_PUBLIC_S3_BASE: process.env.NEXT_PUBLIC_S3_BASE ?? '',
  },
}

export default nextConfig
```

Then check if `dotenv` is already a dependency in
`web/package.json`. If not, add it: run
`cd web && npm install dotenv` from the repo root.

### 4. Create `ios/run.sh`

Create `/Users/hcs/Sync/Code/chuck/ios/run.sh`:
```sh
#!/bin/sh
# Wrapper for flutter run/build that injects env vars from
# root .env.local as --dart-define flags.
# Usage: ./run.sh [flutter run args...]
# Example: ./run.sh --release
set -a
. "$(dirname "$0")/../.env.local"
set +a
exec flutter run \
  --dart-define=LAMBDA_URL="${NEXT_PUBLIC_API_URL}" \
  "$@"
```

Make it executable: `chmod +x ios/run.sh`

### 5. Update `ios/lib/providers/app_providers.dart`

Edit line 14. Replace:
```dart
  return 'https://aanonry4iszhp75mjpq33jfzxe0vzpdz.lambda-url.ap-southeast-2.on.aws/';
```
With:
```dart
  return const String.fromEnvironment(
    'LAMBDA_URL',
    defaultValue: 'http://localhost:8080',
  );
```

The `apiBaseUrlProvider` provider at line 13-15 should then look
like:
```dart
final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'LAMBDA_URL',
    defaultValue: 'http://localhost:8080',
  );
});
```

### 6. Update root `.gitignore`

Edit `/Users/hcs/Sync/Code/chuck/.gitignore`. Add `.env.local`
as a new line. Final file:
```
lambda/bin
go.sum
log
.DS_Store
.env.local
```

### 7. Create `/.env.local.example`

Create `/Users/hcs/Sync/Code/chuck/.env.local.example`:
```
# Copy this file to .env.local and fill in values.
# Shared by web (Next.js) and iOS (Flutter).
NEXT_PUBLIC_API_URL=https://<lambda-id>.lambda-url.<region>.on.aws
NEXT_PUBLIC_S3_BASE=http://<s3-bucket-domain>
```

### 8. Update `CLAUDE.md`

In `/Users/hcs/Sync/Code/chuck/CLAUDE.md`, replace the
Quick Ref section (lines 101-103):
```
## Quick Ref
- Lambda URL: https://aanonry4iszhp75mjpq33jfzxe0vzpdz.lambda-url.
  ap-southeast-2.on.aws/
```
With:
```
## Quick Ref
- Env config: `/.env.local` (gitignored, see `.env.local.example`)
- Run iOS app: `cd ios && ./run.sh` (sources root `.env.local`)
```

## Verification

After completing steps:
1. Confirm `/.env.local` exists with correct vars
2. Confirm `web/.env.local` is gone
3. Confirm `web/next.config.ts` loads `dotenv` from root
4. Confirm `ios/run.sh` exists and is executable
5. Confirm `ios/lib/providers/app_providers.dart` uses
   `String.fromEnvironment`
6. Confirm `.env.local` is in root `.gitignore`
7. Confirm `.env.local.example` exists and is committed
8. Confirm `CLAUDE.md` Quick Ref is updated
