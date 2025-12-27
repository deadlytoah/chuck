# Plan to fix missing HostedZoneName parameter

- **Prompt:** Applying your change made in `./cloudformation.yaml` (you can find the diff by running `git diff cloudformation.yaml`) according to your plan in `./plans/000-route53-s3-website.md` failed with the following error: `An error occurred (ValidationError) when calling the CreateChangeSet operation: Parameters: [HostedZoneName] must have values`. Record your plan to remedify this problem and then stop.

- **Analysis:** The error indicates that the `HostedZoneName` parameter is not being provided during CloudFormation deployment. The template itself is valid, but it requires this parameter to be specified. The `S3Bucket` resource name (`chuck.overcomingsh.in`) suggests the domain is `overcomingsh.in`.

- **Plan:**
    1. Add a `Default` value to the `HostedZoneName` parameter in `cloudformation.yaml`. The value will be `overcomingsh.in.`. This will allow the template to be deployed without explicitly providing the parameter.
