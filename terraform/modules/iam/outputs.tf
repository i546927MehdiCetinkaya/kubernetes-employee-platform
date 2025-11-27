output "hr_portal_role_arn" {
  description = "ARN of HR Portal IAM role"
  value       = aws_iam_role.hr_portal.arn
}

output "workspace_role_arn" {
  description = "ARN of Workspace IAM role"
  value       = aws_iam_role.workspace.arn
}

# Department Role ARNs
output "infra_role_arn" {
  description = "ARN of Infrastructure Team IAM role"
  value       = aws_iam_role.infra_role.arn
}

output "developer_role_arn" {
  description = "ARN of Developer IAM role"
  value       = aws_iam_role.developer_role.arn
}

output "hr_role_arn" {
  description = "ARN of HR Team IAM role"
  value       = aws_iam_role.hr_role.arn
}

output "manager_role_arn" {
  description = "ARN of Manager IAM role"
  value       = aws_iam_role.manager_role.arn
}

output "admin_role_arn" {
  description = "ARN of Admin IAM role"
  value       = aws_iam_role.admin_role.arn
}

output "role_mappings" {
  description = "Mapping of groups to IAM Role ARNs"
  value = {
    "Infra-Team" = aws_iam_role.infra_role.arn
    "Developers" = aws_iam_role.developer_role.arn
    "HR-Team"    = aws_iam_role.hr_role.arn
    "Managers"   = aws_iam_role.manager_role.arn
    "Admins"     = aws_iam_role.admin_role.arn
  }
}
