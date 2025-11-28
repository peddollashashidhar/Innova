# GitHub OIDC + Terraform backend (example)

This folder contains a small example Terraform module that provisions a secure backend for Terraform (S3 + DynamoDB + KMS) and an IAM role configured for GitHub Actions OIDC.

It is intended as a safe, copy-pasteable starting point — please review and tighten IAM permissions to meet your security posture before applying in production.

What it creates

- An S3 bucket for Terraform state (versioned and encrypted with KMS)
- A DynamoDB table used for Terraform state locking
- A KMS key and alias used to encrypt state
- An IAM OIDC provider entry for token.actions.githubusercontent.com
- An IAM role with a trust policy limited to the repo (and references/branches) you specify
- Two example inline policies attached to the role:
  - `tf-state-access`: allows the role to read/write state, use the DynamoDB lock and use the KMS key
  - `terraform-manage-scoped`: a scoped example policy attached to the OIDC role that grants the minimal common actions required to manage EKS and the supporting VPC/network resources in this repo. Review and tighten further for production.

How to use (example)

1. Edit `variables.tf` to choose a globally-unique S3 `bucket_name` and confirm `github_repo` value.
2. From `infra/oidc` run `terraform init` and `terraform apply` to create the resources.

After apply, the role ARN is output. Add that value as `AWS_ROLE_TO_ASSUME` in your GitHub repository secrets and your workflow can assume that role via OIDC.

Example GitHub Actions workflow (backend config snippet for remote state)

--- copy into your root `infra/main.tf` or a top-level `backend.tf` and update names ---

terraform {
  backend "s3" {
    bucket         = "YOUR_BUCKET_NAME"
    key            = "infra/terraform.tfstate"
    region         = "REGION"
    dynamodb_table = "LOCK_TABLE_NAME"
    kms_key_id     = "KMS_KEY_ARN"
  }
}

Security notes

- The module includes a `terraform-manage-scoped` inline policy. It grants a focused set of EKS, EC2/VPC, AutoScaling, ELB, IAM (tag-scoped) and CloudWatch Logs permissions needed to bootstrap the cluster and nodegroups. For production lock-down, further scope ARNs and add more precise conditions.
- Optionally add conditions to the role assume policy for `token.actions.githubusercontent.com:aud` and other checks.
- Keep the S3 bucket name unique and protected — enable bucket policies if you want to restrict access by account or principal.

CI Verification workflow

This repository includes a small, safe verification workflow that validates OIDC role assumption without changing any resources.

Steps:

1. Add the created role's ARN to your repository secrets with the name `AWS_ROLE_TO_ASSUME` (only the role ARN, no keys).
1. Trigger the workflow from the Actions tab: "Verify GitHub OIDC role (safe)" -> Run workflow.
    - Optionally pass `region` to the run inputs. Default region is `ap-south-1`.
1. The job will assume the role via OIDC and run `aws sts get-caller-identity`.

If the run succeeds you'll see the identity JSON printed in the logs. If it fails, verify the role trust policy and that the `github_repo` value in this module matches the repo that runs the workflow.

Next: least-privilege

The role created by this module now includes an example `terraform-manage-scoped` policy which narrows the permissions Terraform needs to create the EKS cluster, the node group and the VPC/subnet resources used by that cluster. This is intentionally conservative but still practical — for production environments I recommend auditing the actions actually used by your Terraform runs and further restricting actions and resources accordingly.

