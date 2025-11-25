resource "aws_ecr_repository" "this_frontend" {
  name = var.frontend_name
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "this_backend" {
  name = var.backend_name
  image_scanning_configuration { scan_on_push = true }
}
