variable "aws_region" {
	description = "AWS region for all resources"
	type        = string
}

variable "environment" {
	description = "Short environment identifier (dev, staging, prod, etc.)"
	type        = string
}

variable "tags" {
	description = "Extra tags to merge into the default tag set"
	type        = map(string)
	default     = {}
}

variable "cluster_name" {
	description = "Name of the EKS cluster and related resources"
	type        = string
}

variable "cluster_version" {
	description = "EKS control plane Kubernetes version"
	type        = string
}

variable "vpc_cidr" {
	description = "CIDR block for the VPC"
	type        = string
}

variable "availability_zones" {
	description = "List of availability zones to spread subnets across"
	type        = list(string)
}

variable "public_subnet_cidrs" {
	description = "CIDR blocks for public subnets"
	type        = list(string)
}

variable "private_subnet_cidrs" {
	description = "CIDR blocks for private subnets"
	type        = list(string)
}

variable "ecr_repo_names" {
	description = "ECR repositories to create"
	type        = list(string)
}

variable "eks_managed_node_groups" {
	description = "Map of managed node group definitions passed to the EKS module"
	type = map(object({
		min_size      = number
		max_size      = number
		desired_size  = number
		capacity_type = string
		instance_types = list(string)
	}))
}
