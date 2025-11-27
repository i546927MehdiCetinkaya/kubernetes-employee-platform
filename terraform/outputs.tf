# Outputs for Employee Lifecycle Automation Infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_name" {
  description = "Alias for EKS cluster name (used by CI/CD)"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.eks.node_role_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

output "ecr_repositories" {
  description = "Map of ECR repository names to URLs"
  value       = module.ecr.repository_urls
}

output "hr_portal_service_account_role_arn" {
  description = "ARN of IAM role for HR Portal service account"
  value       = module.iam.hr_portal_role_arn
}

output "workspace_service_account_role_arn" {
  description = "ARN of IAM role for workspace service account"
  value       = module.iam.workspace_role_arn
}

# Department IAM Roles
output "infra_role_arn" {
  description = "ARN of Infrastructure Team IAM role"
  value       = module.iam.infra_role_arn
}

output "developer_role_arn" {
  description = "ARN of Developer IAM role"
  value       = module.iam.developer_role_arn
}

output "hr_role_arn" {
  description = "ARN of HR Team IAM role"
  value       = module.iam.hr_role_arn
}

output "manager_role_arn" {
  description = "ARN of Manager IAM role"
  value       = module.iam.manager_role_arn
}

output "admin_role_arn" {
  description = "ARN of Admin IAM role"
  value       = module.iam.admin_role_arn
}

output "role_mappings" {
  description = "Mapping of department groups to IAM Role ARNs"
  value       = module.iam.role_mappings
}

# Directory Service Outputs
output "directory_id" {
  description = "ID of AWS Directory Service"
  value       = var.enable_directory_service ? module.directory_service[0].directory_id : null
}

output "directory_name" {
  description = "Domain name of AWS Directory Service"
  value       = var.enable_directory_service ? module.directory_service[0].directory_name : null
}

output "directory_dns_ip_addresses" {
  description = "DNS IP addresses of AWS Directory Service"
  value       = var.enable_directory_service ? module.directory_service[0].directory_dns_ip_addresses : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of DynamoDB VPC endpoint"
  value       = module.vpc_endpoints.dynamodb_endpoint_id
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of ECR API VPC endpoint"
  value       = module.vpc_endpoints.ecr_api_endpoint_id
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of ECR DKR VPC endpoint"
  value       = module.vpc_endpoints.ecr_dkr_endpoint_id
}

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
