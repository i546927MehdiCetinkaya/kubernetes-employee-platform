variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_issuer" {
  description = "OIDC issuer URL for EKS"
  type        = string
}

variable "eks_oidc_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "dynamodb_workspaces_table_arn" {
  description = "ARN of the DynamoDB workspaces table"
  type        = string
}

variable "ssm_policy_arn" {
  description = "ARN of the SSM Parameter Store policy for HR Portal"
  type        = string
}

variable "directory_id" {
  description = "ID of the AWS Directory Service (optional)"
  type        = string
  default     = ""
}

variable "enable_directory_service" {
  description = "Whether Directory Service is enabled"
  type        = bool
  default     = false
}

variable "route53_zone_arn" {
  description = "ARN of the Route53 hosted zone for workspace DNS records"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
}
