module "ecr" {
  source = "./modules/ecr"

  frontend_name = "angular-app"
  backend_name  = "demo"
}
