# Outputs for Systems Manager Module

output "workspace_role_arn" {
  description = "ARN of the IAM role for workspace instances"
  value       = aws_iam_role.workspace_role.arn
}

output "workspace_instance_profile_name" {
  description = "Name of the instance profile for workspace instances"
  value       = aws_iam_instance_profile.workspace.name
}

output "workspace_instance_profile_arn" {
  description = "ARN of the instance profile for workspace instances"
  value       = aws_iam_instance_profile.workspace.arn
}

output "session_logs_bucket" {
  description = "S3 bucket for Session Manager logs"
  value       = var.enable_session_manager ? aws_s3_bucket.session_logs[0].id : null
}

output "session_logs_log_group" {
  description = "CloudWatch log group for Session Manager"
  value       = var.enable_session_manager ? aws_cloudwatch_log_group.session_logs[0].name : null
}

output "ssm_endpoints" {
  description = "VPC endpoints for Systems Manager"
  value = var.enable_session_manager ? {
    ssm         = aws_vpc_endpoint.ssm[0].id
    ssmmessages = aws_vpc_endpoint.ssmmessages[0].id
    ec2messages = aws_vpc_endpoint.ec2messages[0].id
  } : null
}

output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = var.enable_patch_manager ? aws_ssm_patch_baseline.workspace_baseline[0].id : null
}

output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = var.enable_patch_manager ? aws_ssm_maintenance_window.patch_window[0].id : null
}

output "parameter_store_paths" {
  description = "Parameter Store paths for configuration"
  value = {
    workspace_config = aws_ssm_parameter.workspace_config.name
    jwt_secret       = aws_ssm_parameter.jwt_secret.name
    db_credentials   = aws_ssm_parameter.db_credentials.name
    email_config     = aws_ssm_parameter.email_config.name
    workspace_domain = aws_ssm_parameter.workspace_domain.name
  }
}

output "hr_portal_ssm_policy_arn" {
  description = "ARN of IAM policy for HR Portal SSM access"
  value       = aws_iam_policy.hr_portal_ssm_access.arn
}

output "ssm_document_session_prefs" {
  description = "SSM Document for Session Manager preferences"
  value       = var.enable_session_manager ? aws_ssm_document.session_manager_prefs[0].name : null
}
