# -------------------------------------------------------------------------------------------------
# Required variables
# -------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  description = "Role name"
  default     = "github"
}

variable "federated_subject_claims" {
  type        = list(string)
  description = "List of github OIDC claim subjects, see https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect"
}

# -------------------------------------------------------------------------------------------------
# Optional variables
# -------------------------------------------------------------------------------------------------

variable "url" {
  type        = string
  description = "(optional) Provider URL"
  default     = "https://token.actions.githubusercontent.com"
}

variable "client_id_list" {
  type        = list(string)
  description = "(optional) Client ID list"
  default = [
    "sts.amazonaws.com",
  ]
}

variable "thumbprint_list" {
  type        = list(string)
  description = "(optional) Thumbprint list"
  default     = []
}

variable "provider_tags" {
  type        = map(any)
  description = "(optional) OIDC Provider tags"
  default     = null
}

# Variables for permissions to read/write terraform S3 state and DynamoDB lock table
variable "create_terraform_s3_backend_policy" {
  type        = bool
  description = "Whether to create and attach a policy used by the GitHub Actions IAM role to read and write to terraform state buckets and DynamoDB state lock tables"
  default     = false
}

variable "terraform_policy_name" {
  type        = string
  description = "IAM policy name to attach to GitHub Action role for access to Terraform S3 state bucket and DynamoDB state lock table."
  default     = "github-terraform"
}

variable "terraform_s3_bucket_arn" {
  type        = string
  description = "Terraform S3 state bucket arn to allow read and write permissions from GitHub Actions. Must be provided if create_terraform_s3_backend_policy=true"
  default     = null
}

variable "terraform_dynamodb_table_arn" {
  type        = string
  description = "Terraform DynamoDB state lock table arn to allow read and write permissions from GitHub Actions. Must be provided if create_terraform_s3_backend_policy=true"
  default     = null
}

# Variables for permissions to push ECR images
variable "create_ecr_push_policy" {
  type        = bool
  description = "Whether to create and attach a policy used by the GitHub Actions IAM role to push images to ECR repositories"
  default     = false
}

variable "ecr_push_policy_name" {
  type        = string
  description = "IAM policy name to attach to GitHub Action IAM role for access to push images to ECR repositories"
  default     = "github-ecr-push"
}

variable "ecr_repository_arns" {
  type        = list(string)
  description = "ECR Repository ARNs that the GitHub Actions IAM role is permitted to push images to"
  default     = []
}

# Variables for permissions to sync S3 objects in specified Buckets
variable "create_s3_sync_policy" {
  type        = bool
  description = "Whether to create and attach a policy used by the GitHub Actions IAM role to sync objects S3 buckets"
  default     = false
}

variable "s3_sync_policy_name" {
  type        = string
  description = "IAM policy name to attach to GitHub Action IAM role for access to sync objects in S3 buckets"
  default     = "github-s3-sync"
}

variable "s3_sync_bucket_arns" {
  type        = list(string)
  description = "S3 Bucket ARNs that the GitHub Actions IAM role is permitted to sync objects to"
  default     = []
}
