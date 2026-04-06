---
name: No ESM-only features in next.config.ts
description: Avoid import.meta.url and other ESM-only runtime features in next.config.ts
type: feedback
---

## Problem

Next.js compiles next.config.ts via SWC to CommonJS at runtime using
Module._compile(). ESM-only runtime features like `import.meta.url` and
`fileURLToPath` cause "exports is not defined in ES module scope" errors
even after SWC transpilation. Use `process.cwd()` instead of
`import.meta.url`-based __dirname reconstruction.

## Why

Node's module loader detects ESM-only features and treats the compiled
output as ESM, conflicting with the CJS require() loading mechanism
Next.js uses.

## How to Apply

Any time next.config.ts needs __dirname or file-relative paths, use
process.cwd() instead. Next.js always runs from the project root so
process.cwd() is reliable there.

## Example

**Bad:**
```typescript
import { fileURLToPath } from 'url';
const __dirname = dirname(fileURLToPath(import.meta.url));
```

**Good:**
```typescript
const __dirname = process.cwd();
```
