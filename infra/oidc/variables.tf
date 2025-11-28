variable "region" {
  description = "AWS region for the backend and role (keeps resources co-located)"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "S3 bucket name to store Terraform state (must be globally unique)."
  type        = string
  default     = "innova-terraform-state-example"
}

variable "dynamodb_table" {
  description = "DynamoDB table name used to store terraform locks."
  type        = string
  default     = "innova-terraform-locks"
}

variable "kms_alias" {
  description = "KMS alias name (without `alias/`)"
  type        = string
  default     = "innova-tfstate-key"
}

variable "github_repo" {
  description = "GitHub repository full name (owner/repo) used to limit the OIDC trust condition"
  type        = string
  default     = "peddollashashidhar/Innova"
}

variable "allowed_refs" {
  description = "List of allowed token subjects for the role: e.g., ['refs/heads/main'] or ['refs/heads/*']"
  type        = list(string)
  default     = ["refs/heads/*"]
}

variable "role_name" {
  description = "IAM Role name to create for GitHub Actions (OIDC)"
  type        = string
  default     = "github-actions-terraform-role"
}
