output "ecr_frontend_repo_url" {
  value = module.ecr.frontend_repo_url
}

output "ecr_backend_repo_url" {
  value = module.ecr.backend_repo_url
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_id} --region ${var.region}"
}
