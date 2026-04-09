#!/bin/sh
# Wrapper for flutter run/install that injects env vars from
# root .env.local as --dart-define flags.
# Usage: ./run.sh [flutter run args...]
#        ./run.sh --install [flutter install args...]
# --install (-i): build release and install on device (no debugger)
set -a
. "$(dirname "$0")/../.env.local"
set +a

INSTALL=0
ARGS=""
for arg in "$@"; do
  case "$arg" in
    --install|-i) INSTALL=1 ;;
    *) ARGS="$ARGS $arg" ;;
  esac
done

DEFINES="--dart-define=LAMBDA_URL=${LAMBDA_API_URL} --dart-define=IMAGE_BASE_URL=${NEXT_PUBLIC_S3_BASE}"

if [ "$INSTALL" -eq 1 ]; then
  flutter build ios --release $DEFINES $ARGS || exit 1
  exec flutter install --release $ARGS
else
  exec flutter run $DEFINES "$@"
fi
