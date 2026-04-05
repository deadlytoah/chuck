#!/bin/bash
set -e

echo "Building Flutter web release..."
cd ios
if ! flutter build web --release; then
  echo "Build failed! Aborting deployment."
  exit 1
fi
cd ..

echo ""
echo "Build successful!"
echo "Deploying to S3 bucket chuck.overcomingsh.in..."
echo "Note: Preserving images/ and lambda/ directories"
echo ""

aws s3 sync ./ios/build/web s3://chuck.overcomingsh.in/ \
  --exclude "images/*" \
  --exclude "lambda/*" \
  --region ap-southeast-2

echo ""
echo "Deployment complete!"
