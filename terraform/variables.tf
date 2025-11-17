# Variables for Employee Lifecycle Automation Infrastructure

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "innovatech-employee-lifecycle"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for employee data"
  type        = string
  default     = "innovatech-employees"
}

variable "enable_vpn" {
  description = "Enable VPN for administrative access"
  type        = bool
  default     = false
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 6
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 300
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
}
