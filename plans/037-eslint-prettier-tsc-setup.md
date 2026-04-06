# Plan: ESLint + Prettier + tsc for web/

## Context
The Next.js 16 web client (`web/`) has no linting or formatting
tooling. Adding ESLint, Prettier, and tsc checks enforces
correctness (React hooks rules, Next.js patterns), consistent
formatting, and type safety.

## Chat Summary
User requested enabling ESLint + Prettier + tsc for the Next.js
web client. Exploration found: Next.js 16.2.2, React 19, TS 5,
no ESLint/Prettier installed, `next lint` removed in v16,
`eslint-config-next` is a separate npm package (not bundled).
Source files: `app/page.tsx`, `app/layout.tsx`.

## Approach

### 1. Install packages
```
cd web && npm install -D \
  eslint \
  eslint-config-next \
  eslint-config-prettier \
  prettier
```
- `eslint-config-next` bundles `@next/eslint-plugin-next`,
  `eslint-plugin-react`, `eslint-plugin-react-hooks`
- `eslint-config-prettier` disables ESLint formatting rules that
  conflict with Prettier

### 2. Create `web/.eslintrc.js`
```js
module.exports = {
  extends: ['next/core-web-vitals', 'prettier'],
}
```
No `"type":"module"` in `package.json`, so CJS `.eslintrc.js`
works and avoids the `FlatCompat` complexity.

### 3. Create `web/.prettierrc`
```json
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 80,
  "tabWidth": 2
}
```

### 4. Create `web/.prettierignore`
```
.next/
out/
node_modules/
public/
next-env.d.ts
```

### 5. Update `web/package.json` scripts
Add:
```json
"lint": "eslint .",
"format": "prettier --write .",
"typecheck": "tsc --noEmit",
"check": "npm run typecheck && npm run lint && npm run format -- --check"
```

### 6. `web/tsconfig.json` — no changes needed
Already has `strict: true`, `noEmit: true`, `moduleResolution:
bundler`.

## Files to Modify/Create
- `web/package.json` — add 4 scripts + 4 devDependencies
- `web/.eslintrc.js` — create (legacy CJS config, simpler)
- `web/.prettierrc` — create
- `web/.prettierignore` — create

## Verification
```bash
cd web
npm install
npm run typecheck   # should pass (no type errors)
npm run lint        # should pass (no lint errors)
npm run format      # formats in-place
npm run check       # all three, format in --check mode
```
