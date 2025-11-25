Terraform infrastructure for Innova app

This folder contains a starter Terraform configuration to provision AWS resources to run the Innova application on EKS.

Included resources (scaffold):
- VPC (public and private subnets)
- EKS cluster with a managed node group
- Two ECR repositories: `angular-app` and `demo` (Spring Boot)
- Kubernetes manifest templates for Deployments and Services (LoadBalancer) for frontend and backend

Prerequisites
- Terraform 1.4+ installed
- AWS CLI configured with credentials (profile or env vars)
- kubectl installed (used after apply)

Quickstart
1. Edit `terraform.tfvars` (copy from example) and set `region`, `cluster_name`, and `aws_profile` if needed.
2. Initialize Terraform:
   terraform init
3. Plan and apply:
   terraform plan -out=tfplan
   terraform apply tfplan

After apply
- Terraform will output ECR repository URLs and the kubeconfig for the cluster.
- Build and push your Docker images to the created ECR repos, then update the image references in the Kubernetes manifests under `k8s/` and apply them with kubectl.

Notes
- This is a scaffold to get you started. For production use you should configure private EKS networking, IAM roles, cluster autoscaling, logging, monitoring, and the AWS Load Balancer Controller for advanced ALB features and TLS (ACM).

Credential helper script
------------------------

This repo includes a small PowerShell helper script to run Terraform using temporary, refreshed AWS credentials.

- Script: `infra/scripts/refresh-aws-creds.ps1`
   - Modes supported: `aws-vault` and `sso` (AWS CLI v2 SSO)
   - Parameters:
      - `-Mode` : `aws-vault` or `sso` (required)
      - `-Profile` : profile name (required)
      - `-TerraformArgs` : array of terraform args (default: `('plan')`)

Examples (PowerShell)

Using aws-vault:

```powershell
Set-Location -Path 'D:\Demo\Innova\infra'
.\scripts\refresh-aws-creds.ps1 -Mode aws-vault -Profile my-aws-profile -TerraformArgs plan
```

Using AWS SSO:

```powershell
Set-Location -Path 'D:\Demo\Innova\infra'
.\scripts\refresh-aws-creds.ps1 -Mode sso -Profile innova-sso -TerraformArgs @('plan','-out=plan.out')
```

Install notes

- aws-vault (recommended for local dev):
   - Install with Chocolatey: `choco install aws-vault`
   - Or with Scoop: `scoop install aws-vault`
   - Add credentials once: `aws-vault add my-aws-profile`
- AWS CLI v2 SSO:
   - Configure a profile with SSO: `aws configure sso --profile innova-sso`
   - Authenticate interactively: `aws sso login --profile innova-sso`

Security guidance

- Do NOT commit long-lived AWS credentials into source control.
- Prefer `aws-vault` or IAM Identity Center (SSO) for local development.
- For CI, use GitHub OIDC (the Terraform role you created) instead of storing credentials.
