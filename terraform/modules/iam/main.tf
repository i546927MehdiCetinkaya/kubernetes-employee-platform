# IAM Roles Module - Role-Based Access Control
# Uses IAM Roles per department/category instead of IAM Users
# Integrates with AWS Directory Service for identity management

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# SERVICE ROLES (for Kubernetes Service Accounts via IRSA)
# ==============================================================================

# HR Portal Backend Service Role
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
    Name        = "${var.cluster_name}-hr-portal-role"
    Type        = "ServiceRole"
    Environment = var.environment
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

# HR Portal can manage Directory Service users
resource "aws_iam_role_policy" "hr_portal_directory" {
  count = var.enable_directory_service ? 1 : 0
  name  = "directory-service-access"
  role  = aws_iam_role.hr_portal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DirectoryUserManagement"
        Effect = "Allow"
        Action = [
          "ds:CreateUser",
          "ds:DeleteUser",
          "ds:ResetUserPassword",
          "ds:DescribeDirectories",
          "ds:DescribeUsers",
          "ds:AddUserToGroup",
          "ds:RemoveUserFromGroup",
          "ds:DescribeGroups",
          "ds:ListGroupsForUser"
        ]
        Resource = var.directory_id != "" ? "arn:aws:ds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:directory/${var.directory_id}" : "*"
      }
    ]
  })
}

# Attach SSM Parameter Store policy to HR Portal role
resource "aws_iam_role_policy_attachment" "hr_portal_ssm" {
  role       = aws_iam_role.hr_portal.name
  policy_arn = var.ssm_policy_arn
}

# HR Portal Route53 Policy for personal workspace DNS
resource "aws_iam_role_policy" "hr_portal_route53" {
  name = "route53-workspace-dns"
  role = aws_iam_role.hr_portal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Route53WorkspaceDNS"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = var.route53_zone_arn != "" ? var.route53_zone_arn : "arn:aws:route53:::hostedzone/*"
      },
      {
        Sid    = "Route53ListZones"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetHostedZone"
        ]
        Resource = "*"
      }
    ]
  })
}

# Workspace Provisioner Service Role
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
    Name        = "${var.cluster_name}-workspace-role"
    Type        = "ServiceRole"
    Environment = var.environment
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

# ==============================================================================
# DEPARTMENT/CATEGORY ROLES (for Employee Access via Directory Service)
# ==============================================================================

# Infrastructure Team Role
resource "aws_iam_role" "infra_role" {
  name = "${var.cluster_name}-infra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDirectoryServiceAssume"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSAMLAssume"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/ADFS"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  max_session_duration = 43200 # 12 hours

  tags = {
    Name        = "${var.cluster_name}-infra-role"
    Type        = "DepartmentRole"
    Department  = "Infrastructure"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "infra_permissions" {
  name = "infrastructure-permissions"
  role = aws_iam_role.infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2ReadAccess"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:GetConsoleOutput"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMReadAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.cluster_name}/*"
      }
    ]
  })
}

# Developer Role
resource "aws_iam_role" "developer_role" {
  name = "${var.cluster_name}-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDirectoryServiceAssume"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSAMLAssume"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/ADFS"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  max_session_duration = 43200 # 12 hours

  tags = {
    Name        = "${var.cluster_name}-developer-role"
    Type        = "DepartmentRole"
    Department  = "Development"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "developer_permissions" {
  name = "developer-permissions"
  role = aws_iam_role.developer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"
      },
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:ListBuildsForProject"
        ]
        Resource = "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.cluster_name}-*"
      },
      {
        Sid    = "CloudWatchLogsRead"
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ArtifactAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.cluster_name}-artifacts",
          "arn:aws:s3:::${var.cluster_name}-artifacts/*"
        ]
      }
    ]
  })
}

# HR Role (for HR staff to manage employees)
resource "aws_iam_role" "hr_role" {
  name = "${var.cluster_name}-hr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDirectoryServiceAssume"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSAMLAssume"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/ADFS"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  max_session_duration = 28800 # 8 hours

  tags = {
    Name        = "${var.cluster_name}-hr-role"
    Type        = "DepartmentRole"
    Department  = "HR"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "hr_permissions" {
  name = "hr-permissions"
  role = aws_iam_role.hr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBEmployeeAccess"
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
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Sid    = "DynamoDBWorkspacesRead"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_workspaces_table_arn,
          "${var.dynamodb_workspaces_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Manager Role (read-only access to team data)
resource "aws_iam_role" "manager_role" {
  name = "${var.cluster_name}-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDirectoryServiceAssume"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSAMLAssume"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/ADFS"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  max_session_duration = 28800 # 8 hours

  tags = {
    Name        = "${var.cluster_name}-manager-role"
    Type        = "DepartmentRole"
    Department  = "Management"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "manager_permissions" {
  name = "manager-permissions"
  role = aws_iam_role.manager_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBReadOnly"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*",
          var.dynamodb_workspaces_table_arn,
          "${var.dynamodb_workspaces_table_arn}/index/*"
        ]
      },
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Admin Role (full access for system administrators)
resource "aws_iam_role" "admin_role" {
  name = "${var.cluster_name}-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDirectoryServiceAssume"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSAMLAssume"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/ADFS"
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  max_session_duration = 14400 # 4 hours (shorter for admin)

  tags = {
    Name        = "${var.cluster_name}-admin-role"
    Type        = "DepartmentRole"
    Department  = "Admin"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "admin_permissions" {
  name = "admin-permissions"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FullDynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*",
          var.dynamodb_workspaces_table_arn,
          "${var.dynamodb_workspaces_table_arn}/index/*"
        ]
      },
      {
        Sid    = "EKSFullAccess"
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMFullAccess"
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.cluster_name}/*"
      },
      {
        Sid    = "CloudWatchFullAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DirectoryServiceAccess"
        Effect = "Allow"
        Action = [
          "ds:*"
        ]
        Resource = var.directory_id != "" ? "arn:aws:ds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:directory/${var.directory_id}" : "*"
      }
    ]
  })
}

# ==============================================================================
# ROLE MAPPINGS TO DIRECTORY SERVICE GROUPS
# ==============================================================================

# Store role ARNs in SSM for the backend to use when assigning roles
resource "aws_ssm_parameter" "role_mappings" {
  name        = "/${var.cluster_name}/iam/role-mappings"
  description = "Mapping of department groups to IAM Role ARNs"
  type        = "String"
  value = jsonencode({
    "Infra-Team" = aws_iam_role.infra_role.arn
    "Developers" = aws_iam_role.developer_role.arn
    "HR-Team"    = aws_iam_role.hr_role.arn
    "Managers"   = aws_iam_role.manager_role.arn
    "Admins"     = aws_iam_role.admin_role.arn
    # Service roles (not for direct user assumption)
    "hr-portal" = aws_iam_role.hr_portal.arn
    "workspace" = aws_iam_role.workspace.arn
  })

  tags = {
    Environment = var.environment
  }
}
