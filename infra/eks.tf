module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnets         = module.vpc.private_subnets

  node_groups = {
    innova_nodes = {
      desired_capacity = var.node_group_desired
      max_capacity     = var.node_group_desired + 1
      min_capacity     = 1
      instance_types   = [var.node_instance_type]
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
