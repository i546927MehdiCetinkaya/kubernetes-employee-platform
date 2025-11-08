# Main Terraform Configuration for Employee Lifecycle Automation on AWS EKS
# Case Study 3 - Innovatech Solutions
# Zero Trust Architecture with Virtual Workspaces

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
      Project     = "InnovatechEmployeeLifecycle"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = "IT-Infrastructure"
      Owner       = "DevOps-Team"
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

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  environment        = var.environment
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment

  depends_on = [module.vpc]
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name  = var.dynamodb_table_name
  environment = var.environment
}

# VPC Endpoints Module
module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids
  environment        = var.environment

  depends_on = [module.vpc]
}

# Systems Manager Module (SSM Parameter Store, Session Manager)
module "systems_manager" {
  source = "./modules/systems-manager"

  cluster_name               = var.cluster_name
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  workspace_domain           = "workspaces.innovatech.example.com"
  enable_session_manager     = true
  enable_patch_manager       = false
  enable_state_manager       = false
  
  tags = {
    Environment = var.environment
    Project     = "InnovatechEmployeeLifecycle"
  }

  depends_on = [module.vpc]
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  cluster_name                   = var.cluster_name
  eks_oidc_issuer                = module.eks.oidc_issuer
  eks_oidc_arn                   = module.eks.oidc_provider_arn
  dynamodb_table_arn             = module.dynamodb.table_arn
  dynamodb_workspaces_table_arn  = module.dynamodb.workspaces_table_arn
  ssm_policy_arn                 = module.systems_manager.hr_portal_ssm_policy_arn
  environment                    = var.environment

  depends_on = [module.eks, module.dynamodb, module.systems_manager]
}

# EBS CSI Driver Module
module "ebs_csi" {
  source = "./modules/ebs-csi"

  cluster_name    = var.cluster_name
  eks_oidc_issuer = module.eks.oidc_issuer
  eks_oidc_arn    = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id       = module.vpc.vpc_id
  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.vpc]
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  repositories = [
    "hr-portal-backend",
    "hr-portal-frontend",
    "employee-workspace"
  ]
  environment = var.environment
}

# CloudWatch Module
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks]
}
