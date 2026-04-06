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
