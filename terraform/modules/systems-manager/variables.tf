# AWS Systems Manager Module
# Provides workspace management capabilities similar to Microsoft Intune

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for workspaces"
  type        = string
  default     = "workspaces"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoints"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_session_manager" {
  description = "Enable SSM Session Manager for remote access"
  type        = bool
  default     = true
}

variable "enable_patch_manager" {
  description = "Enable SSM Patch Manager for automated patching"
  type        = bool
  default     = true
}

variable "enable_state_manager" {
  description = "Enable SSM State Manager for configuration management"
  type        = bool
  default     = true
}

variable "session_timeout_minutes" {
  description = "Session timeout in minutes for Session Manager"
  type        = number
  default     = 60
}

variable "patch_schedule" {
  description = "Cron expression for patch schedule (UTC)"
  type        = string
  default     = "cron(0 2 ? * SUN *)" # Every Sunday at 2 AM UTC
}

variable "workspace_domain" {
  description = "Public domain for workspace Ingress URLs"
  type        = string
  default     = "workspaces.innovatech.example.com"
}
