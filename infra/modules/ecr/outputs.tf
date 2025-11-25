output "frontend_repo_url" {
  value = aws_ecr_repository.this_frontend.repository_url
}

output "backend_repo_url" {
  value = aws_ecr_repository.this_backend.repository_url
}
