# AWS Directory Service Module - Managed Microsoft AD
# Provides centralized identity management for employees

# AWS Managed Microsoft AD
resource "aws_directory_service_directory" "main" {
  name       = "innovatech.local"
  short_name = "INNOVATECH"
  password   = var.admin_password
  edition    = "Standard"
  type       = "MicrosoftAD"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.private_subnet_ids
  }

  tags = {
    Name        = "${var.cluster_name}-directory"
    Environment = var.environment
    Purpose     = "Employee Identity Management"
  }
}

# IAM Identity Center (AWS SSO) - Optional integration
# This allows employees to sign in via Directory Service and assume roles

# Security Group for Directory Service
resource "aws_security_group" "directory" {
  name_prefix = "${var.cluster_name}-directory-"
  description = "Security group for AWS Directory Service"
  vpc_id      = var.vpc_id

  # Allow LDAP from VPC
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "LDAP"
  }

  # Allow LDAPS from VPC
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "LDAPS"
  }

  # Allow Kerberos from VPC
  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kerberos TCP"
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kerberos UDP"
  }

  # Allow DNS from VPC
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS TCP"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS UDP"
  }

  # Allow SMB from VPC
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SMB"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "${var.cluster_name}-directory-sg"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for Directory Service
resource "aws_cloudwatch_log_group" "directory" {
  name              = "/aws/directoryservice/${aws_directory_service_directory.main.id}"
  retention_in_days = 30

  tags = {
    Name        = "${var.cluster_name}-directory-logs"
    Environment = var.environment
  }
}

# Resource Policy to allow Directory Service to write logs
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_resource_policy" "directory" {
  policy_name = "${var.cluster_name}-directory-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DSLogSubscriptionWrite"
        Effect = "Allow"
        Principal = {
          Service = "ds.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.directory.arn}:*"
      }
    ]
  })
}

# Enable logging for Directory Service
resource "aws_directory_service_log_subscription" "main" {
  directory_id   = aws_directory_service_directory.main.id
  log_group_name = aws_cloudwatch_log_group.directory.name

  depends_on = [aws_cloudwatch_log_resource_policy.directory]
}

# SSM Parameters for Directory Configuration
resource "aws_ssm_parameter" "directory_id" {
  name        = "/${var.cluster_name}/directory/id"
  description = "AWS Directory Service ID"
  type        = "String"
  value       = aws_directory_service_directory.main.id

  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "directory_dns" {
  name        = "/${var.cluster_name}/directory/dns-ips"
  description = "AWS Directory Service DNS IPs"
  type        = "StringList"
  value       = join(",", aws_directory_service_directory.main.dns_ip_addresses)

  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "directory_domain" {
  name        = "/${var.cluster_name}/directory/domain"
  description = "AWS Directory Service Domain Name"
  type        = "String"
  value       = aws_directory_service_directory.main.name

  tags = {
    Environment = var.environment
  }
}
