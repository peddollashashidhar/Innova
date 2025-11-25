GitHub Actions → AWS (OIDC) setup

This document shows how to configure GitHub Actions to authenticate to AWS using OIDC (no long-lived secrets), create the required IAM roles, and grant permissions for CI to push images to ECR and deploy to EKS.

Overview
- Create an IAM role that trusts GitHub's OIDC provider and allows the repository `srpeddolla/Innova` to assume it.
- Attach a policy to that role that grants the CI the permissions it needs (ECR push, EKS describe, STS assume, etc.).
- Store the role ARN in the repository secret `AWS_ROLE_TO_ASSUME` and `AWS_REGION` in `AWS_REGION`.

1) Create the IAM OIDC provider (if not already present)

Use the AWS Console or AWS CLI. The following CLI examples assume AWS CLI is already configured for an admin user.

Get GitHub's OIDC provider thumbprint and issuer URL (standard):
- Issuer URL: https://token.actions.githubusercontent.com

Create the provider (example):
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list <THUMBPRINT> \
  --client-id-list sts.amazonaws.com
```

(You can also create this manually in the AWS Console under IAM > Identity providers.)

2) Create the CI role (example) and trust policy

Save the following trust policy as `github-oidc-trust.json`. Replace `OWNER` and `REPO` and `ENV` as needed. This example allows only workflows from the repository `srpeddolla/Innova` to assume the role.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:sub": "repo:srpeddolla/Innova:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Notes:
- The condition above restricts to workflow runs on the `main` branch. Remove `:ref:refs/heads/main` or modify it to allow PRs or other branches as desired. For more granular control, use `repo` and `ref` conditions.

Create the role with the trust policy:
```bash
aws iam create-role --role-name GitHubActions-Innova-Role --assume-role-policy-document file://github-oidc-trust.json
```

3) Attach a permissions policy for CI (example)

Below is a recommended minimal policy that allows pushing images to ECR and describing EKS clusters (needed for `aws eks update-kubeconfig`). Save as `ci-policy.json`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:CreateRepository"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

This policy intentionally uses `*` for resources for brevity; you can replace with more specific ARNs (ECR repo ARNs, EKS cluster ARN) for least privilege.

Attach the policy to the role:
```bash
aws iam put-role-policy --role-name GitHubActions-Innova-Role --policy-name GitHubActionsCI-Policy --policy-document file://ci-policy.json
```

4) Add the role ARN to GitHub Secrets

In your repository settings, add a secret named `AWS_ROLE_TO_ASSUME` with the role ARN returned by `aws iam create-role` (e.g. `arn:aws:iam::123456789012:role/GitHubActions-Innova-Role`). Also add `AWS_REGION` (e.g., `us-east-1`).

5) Cluster RBAC: allow the IAM role to access the cluster

After Terraform creates the EKS cluster, you must map the GitHub Actions role to a Kubernetes RBAC role (e.g., `system:masters`) to allow `kubectl`/`helm` to act. Terraform's EKS module can add this mapping using `map_roles` or you can manually edit the `aws-auth` ConfigMap.

Example (kubectl patch after cluster creation)
```bash
kubectl create configmap aws-auth --from-literal=mapRoles='[{"rolearn":"arn:aws:iam::123456789012:role/GitHubActions-Innova-Role","username":"github-actions","groups":["system:masters"]}]' -n kube-system
```

Alternatively, have Terraform add the mapping when creating the cluster.

6) Update GitHub Actions workflow

Set the `Configure AWS Credentials` step to use the role ARN (I updated the workflow to read `AWS_ROLE_TO_ASSUME` and use `aws-actions/configure-aws-credentials@v2`).

7) Optional: separate roles for Terraform and Deploy

For safety, create two roles:
- `Terraform-Role` with broader privileges (AdministratorAccess or a well-scoped policy) used only by collaborators to run `terraform apply` from CI or manually.
- `GitHubActions-Innova-Role` (described above) for build/push/deploy operations.

If you want, I can generate a Terraform template to create these IAM roles and attach the policies automatically.

---
If you'd like I can now:
- (A) Update the workflow to use OIDC (done) and add a small helper file with the exact AWS CLI commands to create roles (I already added `infra/docs/github-oidc.md`).
- (B) Add Terraform resources to create the GitHub OIDC provider and the two IAM roles/policies automatically in `infra/` (I can implement this next - recommended for reproducible infra).

Which next step do you want? If (B), I'll implement Terraform resources to create the IAM provider and roles with configurable policy ARNs and outputs for the role ARNs to copy into GitHub secrets.
