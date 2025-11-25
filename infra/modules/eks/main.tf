module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # upstream module expects `subnet_ids` and `eks_managed_node_groups` naming
  subnet_ids = var.subnets

  eks_managed_node_groups = var.node_groups

  # manage aws-auth configmap (upstream name)
  manage_aws_auth_configmap = true
}
