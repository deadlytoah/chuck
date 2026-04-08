# Plan 043 — Enable HTTPS via CloudFront

## Context

The web app is currently served over HTTP from an S3 static website.
The specs (`design-web.md`, `technical-web.md`) require HTTPS via
CloudFront with OAC, a private S3 bucket, ACM cert, and Route 53
alias to CloudFront. Lambda CORS still allows `"*"`.

**Gap summary:**
- No CloudFront distribution; Route 53 → S3 website (HTTP)
- S3 bucket is public-read with static website hosting enabled
- Lambda CORS `AllowOrigins: ["*"]`
- `NEXT_PUBLIC_S3_BASE` uses `http://`
- `deploy-web.sh` does not invalidate CloudFront cache

**Prerequisite (manual, before stack update):**
Provision ACM certificate for `chuck.overcomingsh.in` in `us-east-1`
(required by CloudFront). Note the ARN; pass it as the
`AcmCertificateArn` stack parameter when deploying.

---

## Implementation plan

### 1. `cloudformation.yaml`

**a. Add parameter**
```yaml
AcmCertificateArn:
  Type: String
  Description: ARN of ACM cert for chuck.overcomingsh.in
    (must be in us-east-1)
```

**b. Remove mapping** `AWSRegion2S3WebsiteHostedZoneId` — no longer
needed once Route 53 points to CloudFront.

**c. S3Bucket** — make private; remove public-access block overrides
and `WebsiteConfiguration`:
```yaml
PublicAccessBlockConfiguration:
  BlockPublicAcls: true
  BlockPublicPolicy: true
  IgnorePublicAcls: true
  RestrictPublicBuckets: true
# remove WebsiteConfiguration entirely
```

**d. S3BucketPolicy** — replace both statements with OAC-only grant:
```yaml
PolicyDocument:
  Version: "2012-10-17"
  Statement:
    - Sid: AllowCloudFrontOAC
      Effect: Allow
      Principal:
        Service: cloudfront.amazonaws.com
      Action: s3:GetObject
      Resource: !Sub "${S3Bucket.Arn}/*"
      Condition:
        StringEquals:
          "AWS:SourceArn": !Sub
            "arn:aws:cloudfront::${AWS::AccountId}:\
             distribution/${CloudFrontDistribution}"
```

**e. New resources** — add after `S3BucketPolicy`:
```yaml
CloudFrontOAC:
  Type: AWS::CloudFront::OriginAccessControl
  Properties:
    OriginAccessControlConfig:
      Name: chuck-oac
      OriginAccessControlOriginType: s3
      SigningBehavior: always
      SigningProtocol: sigv4

CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      Enabled: true
      Comment: chuck web app
      Aliases:
        - chuck.overcomingsh.in
      ViewerCertificate:
        AcmCertificateArn: !Ref AcmCertificateArn
        SslSupportMethod: sni-only
        MinimumProtocolVersion: TLSv1.2_2021
      Origins:
        - Id: S3Origin
          DomainName: !GetAtt S3Bucket.RegionalDomainName
          S3OriginConfig:
            OriginAccessIdentity: ""
          OriginAccessControlId: !GetAtt CloudFrontOAC.Id
      DefaultCacheBehavior:
        TargetOriginId: S3Origin
        ViewerProtocolPolicy: redirect-to-https
        CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6
        # CachingOptimized managed policy
        AllowedMethods: [GET, HEAD]
        CachedMethods: [GET, HEAD]
        Compress: true
      CacheBehaviors:
        - PathPattern: "*.html"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods: [GET, HEAD]
          CachedMethods: [GET, HEAD]
          Compress: true
          CachePolicyId: 4135ea2d-6df8-44a3-9df3-4b5a84be39ad
          # CachingDisabled managed policy (TTL 0 for HTML)
      CustomErrorResponses:
        - ErrorCode: 403
          ResponseCode: 200
          ResponsePagePath: /index.html
        - ErrorCode: 404
          ResponseCode: 200
          ResponsePagePath: /index.html
      DefaultRootObject: index.html
      PriceClass: PriceClass_100
      HttpVersion: http2
```

**f. DnsRecord** — replace `AliasTarget` to point to CloudFront:
```yaml
DnsRecord:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneName: !Ref HostedZoneName
    Name: !Sub "${S3Bucket}."
    Type: A
    AliasTarget:
      HostedZoneId: Z2FDTNDATAQYW2   # CloudFront global hosted zone ID
      DNSName: !GetAtt CloudFrontDistribution.DomainName
```

**g. Lambda CORS** — tighten `AllowOrigins`:
```yaml
# ChuckApiFunctionUrlV2 Cors section:
AllowOrigins:
  - "https://chuck.overcomingsh.in"
```

**h. Outputs** — update `WebsiteURL`:
```yaml
WebsiteURL:
  Value: "https://chuck.overcomingsh.in"
  Description: HTTPS URL for the web app
CloudFrontDistributionId:
  Value: !Ref CloudFrontDistribution
  Description: CloudFront distribution ID (for cache invalidation)
```

---

### 2. `deploy-web.sh`

After `aws s3 sync`, add CloudFront invalidation. Retrieve the
distribution ID from the CloudFormation stack output:

```bash
STACK_NAME=chuck   # adjust if stack name differs
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId']\
.OutputValue" \
  --output text \
  --region ap-southeast-2)

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*"
```

---

### 3. `.env.local.example`

Change `NEXT_PUBLIC_S3_BASE` line:
```
NEXT_PUBLIC_S3_BASE=https://chuck.overcomingsh.in
```

---

## Assumptions

- Stack name used in `describe-stacks` call: `chuck` (verify before
  running deploy-web.sh).
- ACM certificate is provisioned manually in `us-east-1` before stack
  update; ARN passed as `AcmCertificateArn` parameter.
- `CachingOptimized` (`658327ea-...`) and `CachingDisabled`
  (`4135ea2d-...`) are AWS-managed CloudFront cache policy IDs; no
  custom policy needed.
- S3 `CorsConfiguration` is kept (images accessed via CloudFront, but
  CORS headers still needed for browser fetch of images).
- AAAA (IPv6) alias record is not added; spec only requires A record.
- `deploy-web.sh` uses `--region ap-southeast-2` for the stack lookup;
  CloudFront commands are global (no `--region` needed).
- No changes to Next.js app code — `NEXT_PUBLIC_S3_BASE` already
  handles the base URL; only the value in `.env.local` changes.
