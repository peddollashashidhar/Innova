resource "aws_ecr_repository" "app" {
  for_each = var.repositories
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = lookup(each.value, "scan_on_push", true)
  }
  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Expire untagged images older than 7 days"
          selection = {
            tagStatus = "untagged"
            countType = "sinceImagePushed"
            countUnit = "days"
            countNumber = 7
          }
          action = { type = "expire" }
        }
      ]
    })
  }
  tags = var.tags
}
