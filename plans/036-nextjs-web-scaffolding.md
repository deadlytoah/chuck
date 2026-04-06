# Plan: Initialise Next.js Web App

## Context

User wants to scaffold the Next.js web app in `web/` per
`design-web.md` and `technical-web.md`. The directory is empty
(just `.gitkeep`). The existing `deploy-web.sh` builds Flutter
and must be updated for Next.js.

## Chat Summary

User asked to initialise the web app according to the two spec
files. No prior web app code exists.

## Steps

### 1. Bootstrap Next.js in `web/`

Run from project root:
```
cd web && npx --yes create-next-app@latest . \
  --ts --tailwind --no-eslint --app --no-src-dir \
  --import-alias "@/*"
```

### 2. Configure Static Export

Edit `web/next.config.ts`:
```ts
const nextConfig = {
  output: 'export',
  images: { unoptimized: true },
  trailingSlash: true,
}
```

### 3. Create `.env.local`

```
NEXT_PUBLIC_API_URL=https://aanonry4iszhp75mjpq33jfzxe0vzpdz.lambda-url.ap-southeast-2.on.aws
NEXT_PUBLIC_S3_BASE=http://chuck.overcomingsh.in
```

### 4. Create Page Stubs

- `app/layout.tsx` — root layout with `<title>Chuck</title>`,
  Tailwind globals
- `app/page.tsx` — renders "Chuck" heading placeholder

## Critical Files

- `web/` — all new files

## Verification

1. `cd web && npm run build` — should produce `out/` directory
2. `open out/index.html` or `npx serve out` — page loads with
   "Chuck" heading
