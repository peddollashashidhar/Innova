variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (optional)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "innova-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.100.0/24", "10.0.101.0/24"]
}

variable "node_group_desired" {
  description = "Desired capacity for the managed node group"
  type        = number
  default     = 2
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "frontend_image_tag" {
  description = "Image tag for frontend (set after pushing to ECR)"
  type        = string
  default     = "latest"
}

variable "backend_image_tag" {
  description = "Image tag for backend (set after pushing to ECR)"
  type        = string
  default     = "latest"
}

variable "github_owner" {
  description = "GitHub repository owner for OIDC trust (e.g. srpeddolla)"
  type        = string
  default     = "srpeddolla"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust (e.g. Innova)"
  type        = string
  default     = "Innova"
}

variable "github_branch" {
  description = "Branch to allow in the trust condition (e.g. refs/heads/main)"
  type        = string
  default     = "refs/heads/main"
}

variable "oidc_thumbprint" {
  description = "Thumbprint for GitHub OIDC provider (defaults to GitHub's CA thumbprint)"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "aws_secrets_to_sync" {
  description = <<EOF
Map of Kubernetes secret name -> AWS Secrets Manager mapping. Each value can be either:
- a string containing the Secrets Manager ARN (will be mapped to k8s key `value`), or
- an object { arn = string, properties = ["key1","key2"] } to map specific JSON properties into separate k8s keys.

Example:
aws_secrets_to_sync = {
  "db-credentials" = {
    arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-creds"
    properties = ["username","password"]
  }
  "jwt-secret" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:jwt-secret"
}
EOF
  type = map(any)
  default = {}
}
