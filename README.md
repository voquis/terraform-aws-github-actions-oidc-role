# Terraform module to create IAM role needed by GitHub Actions
Terraform module to create an IAM role used by GitHub Actions Open ID Connect (OIDC) Provider.
This approach trusts the GitHub Actions federated web identity and when used means there is no need to create an AWS access key and token for GitHub Actions.
For details see the (Configure AWS Credentials GitHub Action)[https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions#assuming-a-role].
To allow multiple subjects claims (to limit the origins of Actions), see the [GitHub Actions OIDC docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#examples).
For example, to allow actions from specific repositories or branches to run actions against an AWS resource.

The `sub` (subject) field is used to [populate the claim](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-wif).

Optionally, to attach a new policy to the new GitHub IAM Role that allows reading and writing to a terraform S3 backend with locking, set `create_terraform_s3_backend_policy = true` and provide the S3 state bucket and DynamoDB lock table ARNs (`s3_bucket_arn` and `dynamodb_table_arn`).

Optionally, to attach a new policy to the new GitHub IAM Role that allows pushing container images to ECR repositories, set `create_ecr_push_policy = true` and provide the ECR repository ARNs (`ecr_repository_arns`).


## Examples
### Grant repo Actions on branches access to an S3 bucket
To grant the GitHub actions running on pull requests and specific branches for selected repositories access to list the contents of an S3 bucket.

First create a role that authorises with GitHub Actions OIDC provider with specific subject claims:
```terraform
module "my_github_oidc_provider_role" {
  source  = "voquis/github-actions-oidc-role/aws"
  version = "0.0.3"

  federated_subject_claims = [
    "repo:my-org/my-repo-1:ref:refs/heads/branch-a",
    "repo:my-org/my-repo-2:ref:refs/heads/branch-b",
    "repo:my-org/my-repo-3:ref:refs/heads/branch-c",
    "repo:my-org/my-repo-4:pull_request",
    "repo:my-org/my-repo-5:ref:refs/tags/*",
  ]
}
```

Then create an encrypted private S3 bucket
```terraform
module "my_s3" {
  source  = "voquis/s3-encrypted/aws"
  version = "0.0.4"

  bucket = "my-bucket"
}
```

Create a IAM policy to be used by the role (exported from the module):
```terraform
resource "aws_iam_policy" "github" {
  description = "Permissions granted to github once the github role is assumed"
  name        = "github"
  policy      = data.aws_iam_policy_document.github.json
}

data "aws_iam_policy_document" "github" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.my_s3.s3_bucket.arn,
    ]
  }
}
```

Then attach the permissions policy to the assumed role
```terraform
resource "aws_iam_role_policy_attachment" "github" {
  role       = module.github_oidc_provider_role.iam_role.name
  policy_arn = aws_iam_policy.github.arn
}
```

An Example GitHub Action workflow to use this role (assuming the role has been set as an org or repo level secret as `AWS_ROLE_TO_ASSUME`):
```yaml
name: Publish

on:
  push:
    branches: [ branch-a ]

jobs:
  publish:
    runs-on: ubuntu-latest
    # Needs permission to create tokens for OIDC
    permissions:
      id-token: write
      contents: read
    steps:
      # Prepare AWS credentials using OIDC provider (uses id-token and contents)
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: eu-west-2
      # AWS CLI should already be installed on runner
      - run: aws s3 ls s3://my-bucket

```
