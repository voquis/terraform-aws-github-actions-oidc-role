# -------------------------------------------------------------------------------------------------
# Trust GitHub OpenID Connect Provider for GitHub Actions, to allow assuming roles without a user.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
# -------------------------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "this" {
  url            = var.url
  client_id_list = var.client_id_list

  thumbprint_list = distinct(
    concat(
      var.thumbprint_list
      [data.tls_certificate.github.certificates[0].sha1_fingerprint]
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
