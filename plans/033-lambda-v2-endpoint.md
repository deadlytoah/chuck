# Plan 033: Deploy Lambda V2 to Separate Endpoint

## Prompt
User wants to deploy new Lambda code to a separate endpoint while keeping
the existing `chuck-api` Lambda untouched. This allows parallel operation
of old and new versions during migration.

## Goal
Create `chuck-api-v2` Lambda function with its own Function URL, sharing
the same IAM role but isolated from `chuck-api`.

## Current State
- `chuck-api` Lambda exists with Function URL
- `chuck-items` (v1) and `chuck-items-v2` DynamoDB tables exist
- IAM role `chuck-lambda-execution-role` has permissions for both tables
- Makefile has `update` target for `chuck-api` only

## Changes Required

### 1. Update `cloudformation.yaml`

Add these resources after existing Lambda resources (after line 211):

#### 1.1 Log Group for V2
```yaml
LambdaLogGroupV2:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /aws/lambda/chuck-api-v2
    RetentionInDays: 7
```

#### 1.2 Update IAM Role
Add V2 log group permissions to `chuck-lambda-execution-role`. Replace
the logs Resource (line 163) with:
```yaml
Resource:
  - !Sub "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/chuck-api:*"
  - !Sub "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/chuck-api-v2:*"
```

#### 1.3 Lambda Function V2
```yaml
ChuckApiFunctionV2:
  Type: AWS::Lambda::Function
  DependsOn: LambdaLogGroupV2
  Properties:
    FunctionName: chuck-api-v2
    Runtime: provided.al2
    Handler: bootstrap
    Role: !GetAtt LambdaExecutionRole.Arn
    Code:
      S3Bucket: !Ref LambdaCodeBucket
      S3Key: !Ref LambdaCodeKey
    Environment:
      Variables:
        BUCKET_NAME: !Ref S3Bucket
        TABLE_NAME: !Ref DynamoDBTableV2
        REGION: !Ref AWS::Region
    Timeout: 30
    MemorySize: 512
    Architectures:
      - arm64
```

#### 1.4 Function URL for V2
```yaml
ChuckApiFunctionUrlV2:
  Type: AWS::Lambda::Url
  Properties:
    AuthType: NONE
    TargetFunctionArn: !GetAtt ChuckApiFunctionV2.Arn
    Cors:
      AllowOrigins:
        - "*"
      AllowMethods:
        - GET
        - POST
        - PUT
        - DELETE
      AllowHeaders:
        - Content-Type
        - Authorization
        - X-Requested-With
      MaxAge: 300
```

#### 1.5 Permission for V2 URL
```yaml
ChuckApiFunctionUrlPermissionV2:
  Type: AWS::Lambda::Permission
  Properties:
    FunctionName: !Ref ChuckApiFunctionV2
    Action: lambda:InvokeFunctionUrl
    Principal: "*"
    FunctionUrlAuthType: NONE
```

#### 1.6 Add Output for V2 URL
Add to Outputs section:
```yaml
FunctionUrlV2:
  Value: !GetAtt ChuckApiFunctionUrlV2.FunctionUrl
  Description: Lambda Function URL for API V2 access
```

### 2. Update `lambda/Makefile`

Add new target for V2 deployment. Add after line 25:
```makefile
update-v2: $(BINDIR)/$(BINARY_NAME).zip
	aws lambda update-function-code --function-name chuck-api-v2 --zip-file fileb://./bin/$(BINARY_NAME).zip
```

### 3. Deploy CloudFormation Stack

Run from project root:
```bash
aws cloudformation update-stack \
  --stack-name chuck \
  --template-body file://cloudformation.yaml \
  --parameters \
    ParameterKey=LambdaCodeBucket,ParameterValue=chuck.overcomingsh.in \
    ParameterKey=LambdaCodeKey,ParameterValue=lambda/bootstrap.zip \
  --capabilities CAPABILITY_NAMED_IAM
```

### 4. Deploy Lambda Code to V2

After CloudFormation completes:
```bash
cd lambda && make update-v2
```

### 5. Verify

Get the new Function URL from CloudFormation outputs:
```bash
aws cloudformation describe-stacks --stack-name chuck \
  --query 'Stacks[0].Outputs[?OutputKey==`FunctionUrlV2`].OutputValue' \
  --output text
```

Test the endpoint:
```bash
curl -X GET "<FunctionUrlV2>/items"
```

## Summary of File Changes

| File | Action | Lines |
|------|--------|-------|
| `cloudformation.yaml` | Modify IAM role Resource | ~163 |
| `cloudformation.yaml` | Add LambdaLogGroupV2 | after 125 |
| `cloudformation.yaml` | Add ChuckApiFunctionV2 | after 211 |
| `cloudformation.yaml` | Add ChuckApiFunctionUrlV2 | after V2 function |
| `cloudformation.yaml` | Add ChuckApiFunctionUrlPermissionV2 | after V2 URL |
| `cloudformation.yaml` | Add FunctionUrlV2 output | Outputs section |
| `lambda/Makefile` | Add `update-v2` target | after line 25 |

## Rollback
Delete the V2 resources from CloudFormation if needed. The original
`chuck-api` remains untouched throughout.
