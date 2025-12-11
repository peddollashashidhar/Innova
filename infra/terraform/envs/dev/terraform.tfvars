aws_region = "ap-south-1"

environment = "dev"

tags = {
	Project     = "Innova"
	CostCenter  = "RND"
	Terraform   = "true"
}

cluster_name    = "innova-dev"
cluster_version = "1.29"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
	"ap-south-1a",
	"ap-south-1b",
	"ap-south-1c",
]

public_subnet_cidrs = [
	"10.0.0.0/24",
	"10.0.1.0/24",
	"10.0.2.0/24",
]

private_subnet_cidrs = [
	"10.0.100.0/24",
	"10.0.101.0/24",
	"10.0.102.0/24",
]

ecr_repo_names = [
	"innova-frontend",
	"innova-backend",
]

eks_managed_node_groups = {
	default = {
		min_size      = 1
		max_size      = 3
		desired_size  = 2
		capacity_type = "ON_DEMAND"
		instance_types = [
			"t3.medium",
		]
	}
}
