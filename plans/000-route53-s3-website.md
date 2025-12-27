# Plan for S3 Website Hosting with Route53

- **Prompt**: I want the public S3 bucket to be hosted on a new
  subdomain of the domain that I own on route53,
  `chuck.overcomingsh.in`. I don't need the traffic encrypted at
  this point. Can this be declared in the `./cloudformation.yaml`?
  Record the plan and then stop.

- **File**: `cloudformation.yaml`

- **Updated Plan**:
  1.  Add a `HostedZoneName` parameter to the CloudFormation
      template for the domain `overcomingsh.in`.
  2.  Define an `AWS::Route53::RecordSet` resource.
  3.  Configure the record set to create an 'A' record for
      `chuck.overcomingsh.in`.
  4.  The 'A' record will be an alias targeting the S3 bucket's
      website endpoint.
  5.  Add a new output for the website URL.
