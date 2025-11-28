terraform {
  required_version = ">= 1.3"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tfstate" {
  bucket = var.bucket_name
  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tfstate_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name = "terraform-state-${var.bucket_name}"
    ManagedBy = "Innova/terraform-oidc"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    ManagedBy = "Innova/terraform-oidc"
  }
}

resource "aws_kms_key" "tfstate_key" {
  description             = "KMS key to encrypt Terraform state for Innova infra"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowRootAndAdmins"
        Effect = "Allow"
        Principal = { AWS = "*" }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "tfstate_alias" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.tfstate_key.key_id
}

# -- Create an OIDC provider entry in the account for GitHub Actions token
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Thumbprint used by GitHub's certificate — historically required. Keep updated if GitHub rotates.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for ref in var.allowed_refs : "repo:${var.github_repo}:ref:${ref}"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_policy.json
  description        = "GitHub Actions role to allow CI to run Terraform with an OIDC token (example - scope down further as needed)"
}

resource "aws_iam_role_policy" "tf_state_access" {
  name = "tf-state-access"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3AccessToStateBucket",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ],
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },
      {
        Sid = "DynamoLocks",
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ],
        Resource = [aws_dynamodb_table.tf_locks.arn]
      },
      {
        Sid = "KMSUse",
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = [aws_kms_key.tfstate_key.arn]
      }
    ]
  })
}

########################
# Optional: a starting policy for resource management
# NOTE: Terraform may need many permissions to create EKS, EC2, IAM, AutoScaling etc.
# The policy below is an example that is intentionally broad to allow bootstrapping; tighten this policy before using in production.
resource "aws_iam_role_policy" "terraform_manage_scoped" {
  name = "terraform-manage-scoped"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # EKS management (create/update/delete clusters & nodegroups)
      {
        Sid = "EKSManagement",
        Effect = "Allow",
        Action = [
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:TagResource",
          "eks:UntagResource"
        ],
        Resource = "*"
      },

      # EC2 / VPC networking operations (create subnets, security-groups, ENIs), allow describe broadly
      {
        Sid = "EC2Networking",
        Effect = "Allow",
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:Describe*",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/ManagedBy" = "terraform"
          }
        }
      },

      # AutoScaling and instance-related actions (managed nodegroups)
      {
        Sid = "AutoScaling",
        Effect = "Allow",
        Action = [
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        Resource = "*"
      },

      # ELB (load balancers used by Kubernetes Service type=LoadBalancer)
      {
        Sid = "ELB",
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*"
        ],
        Resource = "*"
      },

      # IAM operations required to create roles for cluster/nodegroups/IRSA; scoped with request tag requirement
      {
        Sid = "IAMScoped",
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:ListRoles"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/ManagedBy" = "terraform"
          }
        }
      },

      # CloudWatch / Logs used by cluster & nodes
      {
        Sid = "CloudWatchLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      },

      # Allow minimal SSM for node management tasks
      {
        Sid = "SSM",
        Effect = "Allow",
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetConnectionStatus"
        ],
        Resource = "*"
      }
    ]
  })
}
