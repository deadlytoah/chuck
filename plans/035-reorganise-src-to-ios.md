# Plan: Reorganise src/ to ios/ and add web/ placeholder

## Prompt

> As specified in @design-web.md I'm creating a new web client.
> Flutter iOS app is currently in src/. I want you to help me
> brainstorm ideas to reorganise the directory structure.
> [After discussion] Write up a plan that models like Haiku can
> follow through.

## Context

- `src/` contains the Flutter iOS app
- `web/` will contain the future Next.js web app (not yet implemented)
- `lambda/` stays at root, unchanged
- `deploy-web.sh` currently builds the Flutter web target from `src/`;
  it will continue to do so until the Next.js app is implemented
- Only `CLAUDE.md` and `deploy-web.sh` need code/config updates;
  `plans/` and `walkthroughs/` references are historical, leave them

## Steps

1. Rename `src/` to `ios/`
   - `git mv src ios`

2. Update `deploy-web.sh`
   - Line 5: change `cd src` → `cd ios`
   - Line 18: change `./src/build/web` → `./ios/build/web`

3. Update `CLAUDE.md`
   - Section "Flutter (`/src/lib`)": change heading to
     "Flutter (`/ios/lib`)"
   - Change all occurrences of `src/` to `ios/` in the Flutter
     source paths listed under that section
   - Deploy command note: verify no `src/` remains

4. Create `web/` placeholder directory
   - Add `web/.gitkeep` so the empty directory is tracked by git

5. Verify
   - Run `grep -r "src/" CLAUDE.md deploy-web.sh` to confirm no
     remaining references
   - Run `git status` to confirm only expected files changed
