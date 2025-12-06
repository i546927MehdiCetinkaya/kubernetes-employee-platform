# Main Terraform Configuration for Employee Lifecycle Automation on AWS EKS
# Case Study 3 - Innovatech Solutions
# ZERO TRUST ARCHITECTURE with Virtual Workspaces
# - All services are private (internal ALBs only)
# - Authentication via AWS Cognito
# - NAT Instance instead of NAT Gateway
# - VPC Endpoints for AWS service access (no public internet)

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend configuration moved to backend.tf
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project      = "InnovatechEmployeeLifecycle"
      Environment  = var.environment
      ManagedBy    = "Terraform"
      CostCenter   = "IT-Infrastructure"
      Owner        = "DevOps-Team"
      Architecture = "ZeroTrust"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for EKS authentication
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# =============================================================================
# VPC MODULE - With NAT Instance (Zero Trust)
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  environment        = var.environment
  use_nat_instance   = var.use_nat_instance
  nat_instance_type  = var.nat_instance_type
}

# =============================================================================
# EKS MODULE
# =============================================================================
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment

  depends_on = [module.vpc]
}

# =============================================================================
# DYNAMODB MODULE
# =============================================================================
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name  = var.dynamodb_table_name
  environment = var.environment
}

# =============================================================================
# VPC ENDPOINTS MODULE - For private AWS service access (Zero Trust)
# =============================================================================
module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids
  environment        = var.environment

  depends_on = [module.vpc]
}

# =============================================================================
# COGNITO MODULE - For Zero Trust Authentication
# =============================================================================
module "cognito" {
  source = "./modules/cognito"

  cluster_name            = var.cluster_name
  environment             = var.environment
  domain_name             = var.domain_name
  hr_portal_callback_urls = var.hr_portal_callback_urls
  hr_portal_logout_urls   = var.hr_portal_logout_urls
  workspace_callback_urls = var.workspace_callback_urls
  workspace_logout_urls   = var.workspace_logout_urls
}

# =============================================================================
# SYSTEMS MANAGER MODULE (SSM Parameter Store, Session Manager)
# =============================================================================
module "systems_manager" {
  source = "./modules/systems-manager"

  cluster_name           = var.cluster_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  workspace_domain       = "workspaces.innovatech.example.com"
  enable_session_manager = true
  enable_patch_manager   = false
  enable_state_manager   = false

  tags = {
    Environment = var.environment
    Project     = "InnovatechEmployeeLifecycle"
  }

  depends_on = [module.vpc]
}

# =============================================================================
# IAM MODULE
# =============================================================================
module "iam" {
  source = "./modules/iam"

  cluster_name                  = var.cluster_name
  eks_oidc_issuer               = module.eks.oidc_issuer
  eks_oidc_arn                  = module.eks.oidc_provider_arn
  dynamodb_table_arn            = module.dynamodb.table_arn
  dynamodb_workspaces_table_arn = module.dynamodb.workspaces_table_arn
  ssm_policy_arn                = module.systems_manager.hr_portal_ssm_policy_arn
  enable_directory_service      = var.enable_directory_service
  directory_id                  = var.enable_directory_service ? module.directory_service[0].directory_id : ""
  route53_zone_arn              = "arn:aws:route53:::hostedzone/Z0206991D2VAV0U5DTHR"
  environment                   = var.environment

  depends_on = [module.eks, module.dynamodb, module.systems_manager]
}

# =============================================================================
# DIRECTORY SERVICE MODULE (AWS Managed Microsoft AD)
# =============================================================================
module "directory_service" {
  source = "./modules/directory-service"
  count  = var.enable_directory_service ? 1 : 0

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = slice(module.vpc.private_subnet_ids, 0, 2) # AD requires exactly 2 subnets
  admin_password     = var.directory_admin_password
  environment        = var.environment

  depends_on = [module.vpc]
}

# =============================================================================
# EBS CSI DRIVER MODULE
# =============================================================================
module "ebs_csi" {
  source = "./modules/ebs-csi"

  cluster_name    = var.cluster_name
  eks_oidc_issuer = module.eks.oidc_issuer
  eks_oidc_arn    = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

# =============================================================================
# SECURITY GROUPS MODULE - Zero Trust
# =============================================================================
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id                = module.vpc.vpc_id
  cluster_name          = var.cluster_name
  environment           = var.environment
  vpc_cidr_blocks       = [var.vpc_cidr]
  corporate_cidr_blocks = var.corporate_cidr_blocks

  depends_on = [module.vpc]
}

# =============================================================================
# ECR MODULE
# =============================================================================
module "ecr" {
  source = "./modules/ecr"

  repositories = [
    "hr-portal-backend",
    "hr-portal-frontend",
    "employee-workspace"
  ]
  environment = var.environment
}

# =============================================================================
# CLOUDWATCH MONITORING MODULE
# =============================================================================
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks]
}

# =============================================================================
# ROUTE53 MODULE - Internal DNS
# =============================================================================
module "route53" {
  source = "./modules/route53"

  vpc_id       = module.vpc.vpc_id
  domain_name  = var.domain_name
  cluster_name = var.cluster_name
  environment  = var.environment
}

# =============================================================================
# OPENVPN MODULE - Cost-effective VPN for Zero Trust Access
# =============================================================================
module "openvpn" {
  source = "./modules/openvpn"
  count  = var.enable_openvpn ? 1 : 0

  project_name     = var.cluster_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  public_subnet_id = module.vpc.public_subnet_ids[0]
  key_name         = var.openvpn_key_name
  instance_type    = var.openvpn_instance_type
  admin_password   = var.openvpn_admin_password
  domain_name      = var.domain_name
  # Use VPC DNS - actual service IPs will be resolved via Route53 private zone
  hr_portal_ip = cidrhost(var.vpc_cidr, 100) # Placeholder, will use Route53
  api_ip       = cidrhost(var.vpc_cidr, 101) # Placeholder, will use Route53

  depends_on = [module.vpc]
}
