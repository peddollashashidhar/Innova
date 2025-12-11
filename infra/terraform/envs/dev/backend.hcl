bucket         = "psr-innova-terraform-state-bucket"
key            = "infra/eks/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "terraform-locks"
encrypt        = true
