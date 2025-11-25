module "vpc" {
  source = "./modules/vpc"

  name               = "innova-vpc"
  cidr               = var.vpc_cidr
  azs                = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets     = var.public_subnet_cidrs
  private_subnets    = var.private_subnet_cidrs
  enable_nat_gateway = true
  single_nat_gateway = true
}

data "aws_availability_zones" "available" {}
