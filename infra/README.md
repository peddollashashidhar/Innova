# Infrastructure — EKS cluster (minimal)

This folder contains a minimal Terraform root to provision an Amazon EKS cluster and supporting VPC.

Important notes (read before applying)
- This repository uses no remote Terraform backend by default (local state). For team usage you should configure an S3 backend + DynamoDB locking.
- Creating EKS clusters incurs AWS charges — ensure you understand cost and cleanup steps.
- You need AWS credentials available (env vars or `~/.aws/credentials`) or use `aws-vault`.
- Terraform >= 1.3 required.

Top-level files
- `main.tf` — the EKS/VPC module wiring.
- `variables.tf` — variables and defaults.
- `terraform.tfvars` — default variable values (copy/update this file per-environment).

Helper scripts
- `scripts/deploy-eks.ps1` — PowerShell helper that runs `terraform init`, `plan` and optionally `apply` (interactive).
- `scripts/deploy-eks.sh` — POSIX equivalent (bash).
- `scripts/destroy-eks.ps1` / `scripts/destroy-eks.sh` — wrappers for `terraform destroy`.

Quick start (safe, interactive)
1. Install prerequisites: terraform, aws-cli and Docker (if you plan to test workloads).
2. Ensure credentials are configured and `AWS_PROFILE` or `~/.aws/credentials` matches `infra/terraform.tfvars`'s `aws_profile`.
3. (Optional) Edit `infra/terraform.tfvars` to set region, cluster name, instance type, counts.
4. Run interactive PowerShell helper from repo root:

```powershell
.
# from repo root (PowerShell)
.
infra\scripts\deploy-eks.ps1
```

Or on Linux/macOS (bash):

```bash
./infra/scripts/deploy-eks.sh
```

To tear down follow the prompts or run `scripts/destroy-eks.sh` / `destroy-eks.ps1`.

Security & team recommendations
- Configure a remote terraform backend (S3 + DynamoDB) to ensure shared state.
- Use least-privilege IAM roles (IRSA) and avoid embedding secrets in state or git.

If you'd like I can:
- Add S3 remote backend + example DynamoDB lock resource and templating for multiple environments
- Add GitHub Actions jobs to plan and apply (with OIDC) so infrastructure can be deployed in CI
- Perform a dry-run validate in this environment if you give me permission to run Terraform here (this machine needs AWS creds)
