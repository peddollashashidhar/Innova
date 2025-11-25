locals {
  eks_oidc_host = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  external_sa_name = "external-secrets"
  external_sa_namespace = "external-secrets"
  # Build a list of secret ARNs from the map values. Support both string and object forms.
  secret_arns = length(values(var.aws_secrets_to_sync)) > 0 ? [for s in values(var.aws_secrets_to_sync): try(s.arn, s)] : ["*"]
}

# IAM role for External Secrets Operator (IRSA)
resource "aws_iam_role" "external_secrets_irsa" {
  name = "external-secrets-irsa-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_host}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.eks_oidc_host}:sub" = "system:serviceaccount:${local.external_sa_namespace}:${local.external_sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets_policy" {
  name = "ExternalSecrets-ReadSecrets-${var.cluster_name}"
  role = aws_iam_role.external_secrets_irsa.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = local.secret_arns
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create namespace for external-secrets operator
resource "kubernetes_namespace" "external_secrets_ns" {
  metadata {
    name = local.external_sa_namespace
  }
}

# Service account annotated with the IAM role for IRSA
resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name = local.external_sa_name
    namespace = kubernetes_namespace.external_secrets_ns.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets_irsa.arn
    }
  }
}

# Install External Secrets Operator via Helm
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets_ns.metadata[0].name
  create_namespace = false

  values = [yamlencode({
    fullnameOverride = "external-secrets",
    serviceAccount = {
      create = false,
      name = local.external_sa_name
    },
    # Use aws provider via IRSA
    env = {
      AWS_REGION = var.region
    }
  })]
  depends_on = [kubernetes_service_account.external_secrets_sa]
}
