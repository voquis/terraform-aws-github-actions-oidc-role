output "iam_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.this
}

output "iam_role" {
  value = aws_iam_role.this
}

output "iam_policy" {
  value = aws_iam_policy.terraform
}

output "iam_role_policy_attachment" {
  value = aws_iam_role_policy_attachment.terraform
}
