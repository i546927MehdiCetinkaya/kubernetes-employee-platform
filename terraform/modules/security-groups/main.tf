# =============================================================================
# SECURITY GROUPS MODULE - ZERO TRUST ARCHITECTURE
# Principle: Deny by default, allow only what's explicitly needed
# =============================================================================

# NOTE: Public ALB is NOT used in Zero Trust architecture
# All access is through internal ALBs with Cognito authentication

# INTERNAL ALB Security Group for HR Portal - ONLY accessible from corporate network
resource "aws_security_group" "hr_portal_internal_alb" {
  name        = "hr-portal-internal-alb-sg"
  description = "Security group for HR Portal Internal ALB - Only accessible from corporate network"
  vpc_id      = var.vpc_id

  # Only allow HTTPS from VPC CIDR (internal traffic)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow HTTPS from VPC only"
  }

  # Allow from VPN/DirectConnect CIDR ranges (corporate network)
  dynamic "ingress" {
    for_each = var.corporate_cidr_blocks
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Allow HTTPS from corporate network"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow outbound to VPC only"
  }

  tags = {
    Name        = "hr-portal-internal-alb-sg"
    Environment = var.environment
    Purpose     = "HR Portal Internal Access Only"
  }
}

# INTERNAL ALB Security Group for Workspaces - ONLY accessible from corporate network
resource "aws_security_group" "workspace_internal_alb" {
  name        = "workspace-internal-alb-sg"
  description = "Security group for Workspace Internal ALB - Only accessible from corporate network"
  vpc_id      = var.vpc_id

  # Only allow HTTPS from VPC CIDR (internal traffic)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow HTTPS from VPC only"
  }

  # Allow from VPN/DirectConnect CIDR ranges (corporate network)
  dynamic "ingress" {
    for_each = var.corporate_cidr_blocks
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Allow HTTPS from corporate network"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow outbound to VPC only"
  }

  tags = {
    Name        = "workspace-internal-alb-sg"
    Environment = var.environment
    Purpose     = "Workspace Internal Access Only"
  }
}

# EKS Node Security Group additions for Zero Trust
resource "aws_security_group" "eks_nodes_zero_trust" {
  name        = "${var.cluster_name}-eks-nodes-zero-trust"
  description = "Additional security rules for EKS nodes - Zero Trust"
  vpc_id      = var.vpc_id

  # Allow inbound from internal ALBs only
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    security_groups = [
      aws_security_group.hr_portal_internal_alb.id,
      aws_security_group.workspace_internal_alb.id
    ]
    description = "Allow traffic from internal ALBs"
  }

  # Allow inbound from VPC Endpoints
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow HTTPS from VPC (VPC Endpoints)"
  }

  # Allow node-to-node communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow node-to-node communication"
  }

  # Egress to VPC only (VPC Endpoints handle AWS service access)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow HTTPS to VPC (VPC Endpoints)"
  }

  # Egress for NAT Instance (limited internet access if needed)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound via NAT (limited use)"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.vpc_cidr_blocks
    description = "Allow DNS"
  }

  tags = {
    Name        = "${var.cluster_name}-eks-nodes-zero-trust"
    Environment = var.environment
  }
}
