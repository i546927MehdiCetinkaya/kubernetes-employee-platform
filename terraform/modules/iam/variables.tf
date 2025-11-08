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

variable "environment" {
  description = "Environment name"
  type        = string
}
