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
  default = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e",
  ]
}

variable "provider_tags" {
  type        = map(any)
  description = "(optional) OIDC Provider tags"
  default     = null
}
