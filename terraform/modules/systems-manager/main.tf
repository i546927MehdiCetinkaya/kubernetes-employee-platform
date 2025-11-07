# AWS Systems Manager Main Configuration
# This module provides Intune-like capabilities for workspace management

# ============================================================================
# Session Manager Configuration (Remote Access)
# ============================================================================

# VPC Endpoints for Systems Manager (required for private subnets)
resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.enable_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  count = var.enable_session_manager ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ec2messages-endpoint"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "ssm_endpoints" {
  count = var.enable_session_manager ? 1 : 0

  name_prefix = "${var.cluster_name}-ssm-endpoints-"
  description = "Security group for Systems Manager VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ssm-endpoints-sg"
  })
}

# Session Manager Preferences
resource "aws_ssm_document" "session_manager_prefs" {
  count = var.enable_session_manager ? 1 : 0

  name            = "${var.cluster_name}-session-manager-prefs"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences for ${var.cluster_name}"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.session_logs[0].id
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.session_logs[0].name
      cloudWatchEncryptionEnabled = true
      idleSessionTimeout          = var.session_timeout_minutes
      maxSessionDuration          = ""
      runAsEnabled                = false
      runAsDefaultUser            = ""
    }
  })

  tags = var.tags
}

# S3 Bucket for Session Logs
resource "aws_s3_bucket" "session_logs" {
  count = var.enable_session_manager ? 1 : 0

  bucket_prefix = "${var.cluster_name}-session-logs-"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-session-logs"
  })
}

resource "aws_s3_bucket_encryption" "session_logs" {
  count = var.enable_session_manager ? 1 : 0

  bucket = aws_s3_bucket.session_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "session_logs" {
  count = var.enable_session_manager ? 1 : 0

  bucket = aws_s3_bucket.session_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for Session Logs
resource "aws_cloudwatch_log_group" "session_logs" {
  count = var.enable_session_manager ? 1 : 0

  name              = "/aws/ssm/${var.cluster_name}/sessions"
  retention_in_days = 30

  tags = var.tags
}

# ============================================================================
# Parameter Store (Secrets Management)
# ============================================================================

# Workspace default configuration
resource "aws_ssm_parameter" "workspace_config" {
  name        = "/${var.cluster_name}/workspace/config"
  description = "Default workspace configuration"
  type        = "String"
  value = jsonencode({
    cpu_limit    = "2000m"
    memory_limit = "4Gi"
    storage      = "10Gi"
    image        = "workspace-image:latest"
  })

  tags = merge(var.tags, {
    Category = "Configuration"
  })
}

# JWT Secret (example)
resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.cluster_name}/hr-portal/jwt-secret"
  description = "JWT secret for HR Portal authentication"
  type        = "SecureString"
  value       = "REPLACE_WITH_ACTUAL_SECRET" # Should be replaced in production

  tags = merge(var.tags, {
    Category = "Security"
  })

  lifecycle {
    ignore_changes = [value]
  }
}

# Database credentials (placeholder)
resource "aws_ssm_parameter" "db_credentials" {
  name        = "/${var.cluster_name}/database/credentials"
  description = "Database connection credentials"
  type        = "SecureString"
  value = jsonencode({
    host   = "dynamodb.${data.aws_region.current.name}.amazonaws.com"
    region = data.aws_region.current.name
    table  = "${var.cluster_name}-employees"
  })

  tags = merge(var.tags, {
    Category = "Configuration"
  })
}

# ============================================================================
# Patch Manager Configuration (Automated Updates)
# ============================================================================

# Patch Baseline for Amazon Linux 2
resource "aws_ssm_patch_baseline" "workspace_baseline" {
  count = var.enable_patch_manager ? 1 : 0

  name             = "${var.cluster_name}-workspace-baseline"
  description      = "Patch baseline for workspace instances"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days = 7
    compliance_level   = "CRITICAL"

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix", "Enhancement"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  tags = var.tags
}

# Maintenance Window for Patching
resource "aws_ssm_maintenance_window" "patch_window" {
  count = var.enable_patch_manager ? 1 : 0

  name                       = "${var.cluster_name}-patch-window"
  description                = "Maintenance window for applying patches"
  schedule                   = var.patch_schedule
  duration                   = 3
  cutoff                     = 1
  allow_unassociated_targets = false

  tags = var.tags
}

# Maintenance Window Target (all managed instances)
resource "aws_ssm_maintenance_window_target" "patch_targets" {
  count = var.enable_patch_manager ? 1 : 0

  window_id     = aws_ssm_maintenance_window.patch_window[0].id
  name          = "${var.cluster_name}-all-workspaces"
  description   = "All workspace instances"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Environment"
    values = [var.cluster_name]
  }
}

# Maintenance Window Task (patch)
resource "aws_ssm_maintenance_window_task" "patch_task" {
  count = var.enable_patch_manager ? 1 : 0

  window_id        = aws_ssm_maintenance_window.patch_window[0].id
  name             = "${var.cluster_name}-patch-task"
  description      = "Apply patches to workspace instances"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.maintenance_window[0].arn
  max_concurrency  = "50%"
  max_errors       = "25%"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_targets[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

# ============================================================================
# State Manager Configuration (Configuration Compliance)
# ============================================================================

# Association to ensure SSM Agent is running
resource "aws_ssm_association" "ensure_ssm_agent" {
  count = var.enable_state_manager ? 1 : 0

  name             = "AWS-UpdateSSMAgent"
  association_name = "${var.cluster_name}-update-ssm-agent"

  targets {
    key    = "tag:Environment"
    values = [var.cluster_name]
  }

  schedule_expression = "rate(14 days)"
}

# Association to collect inventory
resource "aws_ssm_association" "inventory_collection" {
  count = var.enable_state_manager ? 1 : 0

  name             = "AWS-GatherSoftwareInventory"
  association_name = "${var.cluster_name}-inventory"

  targets {
    key    = "tag:Environment"
    values = [var.cluster_name]
  }

  schedule_expression = "rate(1 day)"

  parameters = {
    applications                = "Enabled"
    awsComponents               = "Enabled"
    networkConfig               = "Enabled"
    instanceDetailedInformation = "Enabled"
  }
}

# ============================================================================
# IAM Roles and Policies
# ============================================================================

# IAM Role for Workspace Instances
resource "aws_iam_role" "workspace_role" {
  name_prefix = "${var.cluster_name}-workspace-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Attach AWS managed SSM policy
resource "aws_iam_role_policy_attachment" "workspace_ssm" {
  role       = aws_iam_role.workspace_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for Parameter Store access
resource "aws_iam_role_policy" "workspace_parameter_store" {
  name_prefix = "parameter-store-"
  role        = aws_iam_role.workspace_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.cluster_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "workspace" {
  name_prefix = "${var.cluster_name}-workspace-"
  role        = aws_iam_role.workspace_role.name

  tags = var.tags
}

# IAM Role for Maintenance Window
resource "aws_iam_role" "maintenance_window" {
  count = var.enable_patch_manager ? 1 : 0

  name_prefix = "${var.cluster_name}-mw-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ssm.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "maintenance_window" {
  count = var.enable_patch_manager ? 1 : 0

  role       = aws_iam_role.maintenance_window[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}
