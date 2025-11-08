# IAM Roles for Service Accounts (IRSA)

# HR Portal Backend Role
resource "aws_iam_role" "hr_portal" {
  name = "${var.cluster_name}-hr-portal-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:hr-portal:hr-portal-backend"
            "${replace(var.eks_oidc_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-hr-portal-role"
  }
}

resource "aws_iam_role_policy" "hr_portal_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.hr_portal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*",
          var.dynamodb_workspaces_table_arn,
          "${var.dynamodb_workspaces_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Attach SSM Parameter Store policy to HR Portal role
resource "aws_iam_role_policy_attachment" "hr_portal_ssm" {
  role       = aws_iam_role.hr_portal.name
  policy_arn = var.ssm_policy_arn
}

# Workspace Provisioner Role
resource "aws_iam_role" "workspace" {
  name = "${var.cluster_name}-workspace-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:workspaces:workspace-provisioner"
            "${replace(var.eks_oidc_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-workspace-role"
  }
}

resource "aws_iam_role_policy" "workspace_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.workspace.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
