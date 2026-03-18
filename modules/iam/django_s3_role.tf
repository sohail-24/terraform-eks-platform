############################################
# Get AWS account ID
############################################

data "aws_caller_identity" "current" {}

############################################
# Get EKS cluster info
############################################

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

############################################
# Extract OIDC issuer URL
############################################

locals {
  oidc_issuer = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider = replace(local.oidc_issuer, "https://", "")
}

############################################
# Get TLS certificate for OIDC
############################################

data "tls_certificate" "oidc" {
  url = local.oidc_issuer
}

############################################
# Create OIDC provider if not exists
############################################

data "aws_iam_openid_connect_provider" "oidc" {
  url = local.oidc_issuer
}

############################################
# IAM Role for Django ServiceAccount
############################################

resource "aws_iam_role" "django_s3_role" {

  name = "django-s3-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:ecommerce:django-sa"
          }
        }
      }
    ]
  })
}

############################################
# S3 Policy for Django media files
############################################

resource "aws_iam_policy" "django_s3_policy" {

  name = "django-s3-policy"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::${var.bucket_name}"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

############################################
# Attach policy to role
############################################

resource "aws_iam_role_policy_attachment" "django_s3_attach" {

  role       = aws_iam_role.django_s3_role.name
  policy_arn = aws_iam_policy.django_s3_policy.arn
}

