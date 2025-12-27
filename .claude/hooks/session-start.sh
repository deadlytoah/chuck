#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_DIR="$HOME/flutter"
FLUTTER_VERSION="stable"

# Install GitHub CLI if not present
if ! command -v gh &> /dev/null; then
  echo "Installing GitHub CLI..."
  sudo apt-get update -qq
  sudo apt-get install -y gh
fi

# Install Flutter if not present
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter SDK..."
  git clone --depth 1 --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

# Add Flutter to PATH for this session
echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
export PATH="$FLUTTER_DIR/bin:$PATH"

# Precache Flutter artifacts (speeds up subsequent commands)
flutter precache --no-android --no-ios --no-fuchsia --web

# Install Flutter dependencies
cd "$CLAUDE_PROJECT_DIR/src"
flutter pub get

echo "Flutter setup complete!"
