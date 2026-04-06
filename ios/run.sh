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

DEFINES="--dart-define=LAMBDA_URL=${NEXT_PUBLIC_API_URL}"

if [ "$INSTALL" -eq 1 ]; then
  flutter build ipa --release $DEFINES $ARGS || exit 1
  exec flutter install $ARGS
else
  exec flutter run $DEFINES "$@"
fi
