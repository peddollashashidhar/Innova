# Copilot Instructions for Innova Codebase

## Overview
This repository contains a full-stack demo application with:
- **Angular frontend** (`angular-app/`)
- **Spring Boot backend** (`demo/`)
- **Infrastructure as Code** for AWS (EKS, ECR, VPC, IAM, etc.) in `infra/` using Terraform
- **Kubernetes manifests** in `k8s/` and **Helm charts** in `helm/`

## Architecture
- **Frontend**: Angular app, built and containerized, served via NGINX (see `angular-app/Dockerfile`, `nginx.conf`).
- **Backend**: Java Spring Boot app, built with Gradle, containerized (see `demo/Dockerfile`).
- **Infra**: Terraform provisions AWS resources (EKS, ECR, VPC, IAM, etc.).
- **Deployment**: Docker images are pushed to ECR, then deployed to EKS using Kubernetes manifests or Helm charts.

## Key Workflows
- **Angular app**:
  - Dev server: `ng serve` (see `angular-app/README.md`)
  - Build: `ng build`
  - Unit tests: `ng test`
- **Spring Boot app**:
  - Build: `./gradlew build` (Windows: `gradlew.bat build`)
  - JAR output: `demo/build/libs/`
  - Tests: `./gradlew test`
- **Infrastructure**:
  - Edit `infra/terraform.tfvars` (copy from example if needed)
  - Init: `terraform init` (in `infra/`)
  - Plan: `terraform plan -out=tfplan`
  - Apply: `terraform apply tfplan`
  - Prefer the POSIX helper `infra/scripts/refresh-aws-creds.sh` for AWS credential management (supports `aws-vault` and SSO). Windows users should prefer using WSL or Git Bash and run the POSIX helper from there.
- **Kubernetes**:
  - Update image tags in `k8s/` or `helm/` after pushing images
  - Apply manifests: `kubectl apply -f k8s/`
  - Helm deploy: `helm upgrade --install ...` (see `helm/`)

## Conventions & Patterns
- **No hardcoded AWS credentials**: Use `aws-vault` or SSO for local dev; OIDC for CI.
- **Terraform modules**: Infra is modularized under `infra/modules/` (ecr, eks, vpc).
- **Separation of concerns**: Frontend, backend, and infra are in distinct folders.
- **Scripts**: POSIX-first helpers are available under `infra/scripts/` (bash). PowerShell wrappers are provided only to forward to WSL where required.
- **Kubernetes**: Manifests and Helm charts are kept in `k8s/` and `helm/` respectively; update image references after each build.

## Integration Points
- **Frontend ↔ Backend**: Communicate via REST APIs; endpoints configured in Angular and Spring Boot.
- **CI/CD**: Not detailed here, but recommend using GitHub Actions with OIDC for AWS auth.
- **AWS**: ECR for images, EKS for orchestration, IAM for roles, VPC for networking.

## References
- `angular-app/README.md` for Angular commands
- `infra/README.md` for Terraform and AWS setup
 - POSIX helper `infra/scripts/refresh-aws-creds.sh` for credential management. Windows users can use WSL or Git Bash to run the POSIX helpers.
- `k8s/` and `helm/` for deployment manifests

---
For any unclear or missing sections, please provide feedback to improve these instructions.