#!/bin/bash
set -e

# CloudFormation stack deployment script for chuck application
# This creates/updates the S3, DynamoDB, and Lambda resources

STACK_NAME="chuck"
TEMPLATE_FILE="cloudformation.yaml"
REGION="ap-southeast-2"

# Parameters
HOSTED_ZONE_NAME="${HOSTED_ZONE_NAME:-overcomingsh.in.}"
LAMBDA_CODE_BUCKET="chuck.overcomingsh.in"
LAMBDA_CODE_KEY="lambda/bootstrap.zip"

CF_PARAMS=(
  "ParameterKey=HostedZoneName,ParameterValue=$HOSTED_ZONE_NAME"
  "ParameterKey=LambdaCodeBucket,ParameterValue=$LAMBDA_CODE_BUCKET"
  "ParameterKey=LambdaCodeKey,ParameterValue=$LAMBDA_CODE_KEY"
)

echo "Deploying CloudFormation stack: $STACK_NAME"
echo "Region: $REGION"
echo "HostedZoneName: $HOSTED_ZONE_NAME"
echo ""

# Build and upload Lambda code to S3
echo "Building and uploading Lambda code..."
cd lambda && make deploy && cd ..

# Check if stack exists
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" = "DOES_NOT_EXIST" ]; then
  echo "Creating CloudFormation stack..."
  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters "${CF_PARAMS[@]}" \
    --region "$REGION"

  echo "Waiting for stack creation..."
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"
  echo "Stack created successfully!"
else
  echo "Updating CloudFormation stack (current status: $STACK_STATUS)..."
  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters "${CF_PARAMS[@]}" \
    --region "$REGION"

  echo "Waiting for stack update..."
  aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"
  echo "Stack updated successfully!"
fi

echo ""
echo "Fetching Lambda Function URL..."
FUNCTION_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[?OutputKey==`FunctionUrl`].OutputValue' \
  --output text \
  --region "$REGION")

echo ""
echo "Lambda Function URL: $FUNCTION_URL"
echo ""
echo "Update web/.env.local with:"
echo "NEXT_PUBLIC_API_URL=${FUNCTION_URL%/}"
