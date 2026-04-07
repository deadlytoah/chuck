#!/bin/bash
set -e

echo "Building Next.js web release..."
cd web
if ! npm run build; then
  echo "Build failed! Aborting deployment."
  exit 1
fi
cd ..

echo ""
echo "Build successful!"
echo "Deploying to S3 bucket chuck.overcomingsh.in..."
echo "Note: Preserving images/ and lambda/ directories"
echo ""

aws s3 sync ./web/out s3://chuck.overcomingsh.in/ \
  --exclude "images/*" \
  --exclude "lambda/*" \
  --region ap-southeast-2

echo ""
echo "Deployment complete!"
