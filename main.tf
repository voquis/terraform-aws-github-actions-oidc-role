# -------------------------------------------------------------------------------------------------
# Trust GitHub OpenID Connect Provider for GitHub Actions, to allow assuming roles without a user.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
# -------------------------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "this" {
  url            = var.url
  client_id_list = var.client_id_list

  thumbprint_list = distinct(
    concat(
      var.thumbprint_list,
      [data.tls_certificate.this.certificates[0].sha1_fingerprint]
    )
  )

  tags = var.provider_tags
}

# -------------------------------------------------------------------------------------------------
# IAM Role to be assumed using OIDC provider
# -------------------------------------------------------------------------------------------------

# Create role and define which entities are allowed to assume this role
resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.this.arn
      ]
    }

    # Use subject (sub) condition key for iam
    # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#available-keys-for-iam
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.federated_subject_claims
    }
  }
}

# -------------------------------------------------------------------------------------------------
# Fetch certificate of endpoint, used to fetch thumbprint
# -------------------------------------------------------------------------------------------------
data "tls_certificate" "this" {
  url = var.url
}

# -------------------------------------------------------------------------------------------------
# Optional IAM policy and attachment for access to terraform state S3 buckets and DynamoDB state lock tables
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "terraform" {
  for_each = var.create_terraform_s3_backend_policy ? { k : "v" } : {}

  description = "Github Actions IAM policy to grant read/write access to terraform remote state bucket and lock table"
  name        = var.terraform_policy_name
  policy      = data.aws_iam_policy_document.terraform[each.key].json
}

resource "aws_iam_role_policy_attachment" "terraform" {
  for_each = var.create_terraform_s3_backend_policy ? { k : "v" } : {}

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.terraform[each.key].arn
}

data "aws_iam_policy_document" "terraform" {
  for_each = var.create_terraform_s3_backend_policy ? { k : "v" } : {}

  # Allow read and write from terraform S3 state bucket
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      var.terraform_s3_bucket_arn,
      "${var.terraform_s3_bucket_arn}/*",
    ]
  }
  # Allow state locking of dynamodb table
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [
      var.terraform_dynamodb_table_arn
    ]
  }
}

# -------------------------------------------------------------------------------------------------
# Optional IAM policy and attachment for pushing images to an ECR repository
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "ecr_push" {
  for_each = var.create_ecr_push_policy ? { k : "v" } : {}

  description = "Github Actions IAM policy to grant push image permissions to an ECR repository"
  name        = var.ecr_push_policy_name
  policy      = data.aws_iam_policy_document.ecr_push[each.key].json
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  for_each = var.create_ecr_push_policy ? { k : "v" } : {}

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ecr_push[each.key].arn
}

data "aws_iam_policy_document" "ecr_push" {
  for_each = var.create_ecr_push_policy ? { k : "v" } : {}

  # Allow logging in to ECR
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      # Allow pushing and pulling to/from ECR
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      # Allow managing lifecyle policy
      "ecr:GetLifecyclePolicy",
    ]

    resources = var.ecr_repository_arns
  }
}

# -------------------------------------------------------------------------------------------------
# Optional IAM policy and attachment for syncing objects to S3 buckets
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "s3_sync" {
  for_each = var.create_s3_sync_policy ? { k : "v" } : {}

  description = "Github Actions IAM policy to grant S3 sync permissions to S3 buckets"
  name        = var.s3_sync_policy_name
  policy      = data.aws_iam_policy_document.s3_sync[each.key].json
}

resource "aws_iam_role_policy_attachment" "s3_sync" {
  for_each = var.create_s3_sync_policy ? { k : "v" } : {}

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_sync[each.key].arn
}

data "aws_iam_policy_document" "s3_sync" {
  for_each = var.create_s3_sync_policy ? { k : "v" } : {}

  # Allow reading and writing from specified S3 bucket for S3 sync
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = concat(
      [for bucket_arn in var.s3_sync_bucket_arns : bucket_arn],
      [for bucket_arn in var.s3_sync_bucket_arns : "${bucket_arn}/*"],
    )
  }
}
