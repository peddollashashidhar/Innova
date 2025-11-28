# Infrastructure — EKS cluster (minimal)

This folder contains a minimal Terraform root to provision an Amazon EKS cluster and supporting VPC.

- Important notes (read before applying)

- This repository uses no remote Terraform backend by default (local state). For team usage you should configure an S3 backend + DynamoDB locking.
- Creating EKS clusters incurs AWS charges — ensure you understand cost and cleanup steps.
- You need AWS credentials available (env vars or `~/.aws/credentials`) or use `aws-vault`.
- Terraform >= 1.3 required.

Top-level files

- `main.tf` — the EKS/VPC module wiring.
- `variables.tf` — variables and defaults.
- `terraform.tfvars` — default variable values (copy/update this file per-environment).

Helper scripts (POSIX-first / WSL-friendly)

- `scripts/deploy-eks.sh` — POSIX helper that runs `terraform init`, `plan` and optionally `apply` (interactive). Use this from Git Bash / WSL / macOS / Linux.
- `scripts/destroy-eks.sh` — POSIX helper that runs `terraform destroy` (interactive confirmation).
- `scripts/refresh-aws-creds.sh` — POSIX credential helper for aws-vault or AWS SSO.
*PowerShell wrapper removed — prefer running POSIX helpers directly in WSL/Git Bash.*

Note: PowerShell-based helpers were replaced to improve cross-platform developer ergonomics and to avoid PowerShell-only flows in CI or WSL environments.

Credential helpers

- `scripts/refresh-aws-creds.sh` — small helper to establish short-lived credentials for local development. It supports two common flows:
  - aws-vault (spawn a subshell or run a command inside aws-vault exec)
  - AWS SSO (aws cli v2 `aws sso login --profile <name>` then run commands with `--profile`)

Quick start (safe, interactive)

1. Install prerequisites: terraform, aws-cli and Docker (if you plan to test workloads).
2. Ensure credentials are configured and `AWS_PROFILE` or `~/.aws/credentials` matches `infra/terraform.tfvars`'s `aws_profile`.
3. (Optional) Edit `infra/terraform.tfvars` to set region, cluster name, instance type, counts.
4. Run the POSIX helper from the repo root (recommended):

```bash
# from repo root (Git Bash / WSL / Linux / macOS)
./infra/scripts/deploy-eks.sh
```

If you are working on Windows and want to invoke helpers from PowerShell, use WSL/Git Bash directly and run the POSIX helpers from there (preferred). Example using PowerShell → WSL shorthand:

```powershell
# Open WSL shell and run the helper inside the repository's WSL path. Example:
wsl bash -lc "cd $(wslpath '$(pwd)') && ./infra/scripts/deploy-eks.sh --auto-approve"
```

Git Bash / Linux quick commands (recommended if you use Git Bash / WSL / Linux)

If you prefer Git Bash or a POSIX environment (WSL on Windows, Linux, macOS), here are copy/paste steps that avoid PowerShell entirely. These use the `refresh-aws-creds.sh` helper we added which supports aws-vault and AWS SSO.

Prerequisites (install these once):

- terraform (>= 1.3)
- aws-cli v2
- aws-vault (recommended) or AWS SSO configured profiles
- jq (optional — helpful to parse JSON)
- Optional helper: `infra/scripts/install-dev-tools.sh` — an interactive POSIX script that helps install `aws-cli` and `aws-vault` (safe/confirming steps, ideal for WSL/Git Bash/macOS).

Install (example on Debian/Ubuntu / WSL):

```bash
# terraform (see HashiCorp docs for the latest recommended method)
sudo apt-get update; sudo apt-get install -y unzip
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# aws-cli v2 (example)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install

# aws-vault (example binary install)
curl -Lo aws-vault https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-amd64
chmod +x aws-vault && sudo mv aws-vault /usr/local/bin/

# make the helper executable
chmod +x infra/scripts/refresh-aws-creds.sh
```

Using aws-vault (recommended):

```bash
# populate persistent credentials in your secure store once
aws-vault add dev-user

# run terraform commands inside aws-vault context
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform init
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform plan -out=tfplan
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform apply tfplan

# or drop into an interactive shell and run many commands
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault
```

Using AWS SSO (CLI v2):

```bash
# configure your SSO profile once
aws configure sso --profile sso-profile

# login using the SSO profile
./infra/scripts/refresh-aws-creds.sh --profile sso-profile --mode sso -- aws sts get-caller-identity

# or run terraform
./infra/scripts/refresh-aws-creds.sh --profile sso-profile --mode sso -- terraform init
./infra/scripts/refresh-aws-creds.sh --profile sso-profile --mode sso -- terraform plan
```

Notes

- These examples avoid using PowerShell entirely and work well from Git Bash or WSL on Windows.
- The helper uses `aws-vault` where available since it is recommended for local dev — it isolates credentials in an OS store rather than leaving them in plaintext files.
- If you prefer, run the oidc backend module first (`cd infra/oidc` && `terraform init && terraform apply`) to create an S3 backend and an IAM role, then add the role ARN as GitHub secret `AWS_ROLE_TO_ASSUME` to enable OIDC CI.

To tear down follow the prompts or run `scripts/destroy-eks.sh` (preferred POSIX). From PowerShell you can invoke the POSIX helper via WSL:

```powershell
wsl bash -lc "cd $(wslpath '$(pwd)') && ./infra/scripts/destroy-eks.sh"
```

Local dev: aws-vault and AWS SSO (examples)

If you use aws-vault (highly recommended for local dev), prefer running terraform inside the aws-vault session so credentials are never written to disk.

Use the POSIX helper from Git Bash / WSL / macOS / Linux instead (preferred):

```bash
# start an interactive shell with creds from the named profile
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault

# run a single command
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform plan
```

Bash / macOS / Linux (aws-vault interactive shell):

```bash
# start an interactive shell with creds from the named profile
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault

# run a single command inside the aws-vault session
./infra/scripts/refresh-aws-creds.sh --profile dev-user --mode aws-vault -- terraform plan
```

AWS SSO (AWS CLI v2 + SSO profile):

If you're on Windows and still want to run a command via PowerShell, call the POSIX helper in WSL directly. Example (from PowerShell):

```powershell
wsl bash -lc "cd $(wslpath '$(pwd)') && ./infra/scripts/refresh-aws-creds.sh --profile sso-profile --mode sso -- aws sts get-caller-identity"
```

Bash example:

```bash
./infra/scripts/refresh-aws-creds.sh --profile sso-profile --mode sso -- aws sts get-caller-identity
```

Notes and tips

- Prefer using aws-vault when you can — it isolates credentials and can spawn a temporary shell with environment variables set.
- If using SSO, the AWS CLI caches SSO session tokens under `~/.aws/cli/cache` and commands should specify `--profile` for the SSO profile.
- Never commit long-lived credentials into git or Terraform variables; use OIDC for CI and short-lived sessions for local dev.

Security & team recommendations

- Configure a remote terraform backend (S3 + DynamoDB) to ensure shared state.
- Use least-privilege IAM roles (IRSA) and avoid embedding secrets in state or git.

If you'd like I can:

- Add S3 remote backend + example DynamoDB lock resource and templating for multiple environments
- Add GitHub Actions jobs to plan and apply (with OIDC) so infrastructure can be deployed in CI
- Perform a dry-run validate in this environment if you give me permission to run Terraform here (this machine needs AWS creds)

## OIDC-based CI for Terraform (recommended)

Using GitHub Actions with OpenID Connect (OIDC) is the recommended way to avoid storing long-lived AWS credentials in GitHub Secrets.

Key steps (high level):

1. Create an AWS IAM role in the target account allowing GitHub's OIDC provider to assume it. Use the repository or organization as a condition.
2. Attach a narrowly-scoped IAM policy to that role with the least privileges needed to run plan/apply for the resources in `infra/`.
3. Add the role's ARN to your GitHub repository secrets as `AWS_ROLE_TO_ASSUME`.
4. The repo includes `.github/workflows/terraform-oidc.yml` — this workflow uses `aws-actions/configure-aws-credentials@v2` to exchange GitHub's OIDC token for short-lived AWS credentials and run terraform in CI.

Example minimal role trust policy (replace <ACCOUNT_ID> and <REPO_FULLNAME>):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<REPO_FULLNAME>:ref:refs/heads/*"
        }
      }
    }
  ]
}
```

Example minimal repo secret to set (no keys):

- `AWS_ROLE_TO_ASSUME` = `arn:aws:iam::<ACCOUNT_ID>:role/<RoleName>`

If you want I can add the Terraform/CloudFormation snippets to create the role and the exact policy for this repo and then update the workflow to automatically use it (if you allow me to provision roles in your account).
If you want an easy-to-use example I've added a small module in `infra/oidc/` which creates an encrypted S3 bucket, a DynamoDB lock table, a KMS key, and an IAM role configured for GitHub OIDC. See `infra/oidc/README.md` for details and a sample backend snippet.


