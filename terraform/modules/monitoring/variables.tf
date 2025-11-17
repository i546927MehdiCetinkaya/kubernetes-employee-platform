variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
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

variable "eks_budget_limit" {
  description = "Monthly EKS budget limit in USD"
  type        = number
  default     = 150
}

variable "dynamodb_budget_limit" {
  description = "Monthly DynamoDB budget limit in USD"
  type        = number
  default     = 20
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
}
