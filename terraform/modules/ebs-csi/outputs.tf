output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_addon_id" {
  description = "ID of the EBS CSI driver addon"
  value       = aws_eks_addon.ebs_csi_driver.id
}
