# Outputs for Directory Service Module

output "directory_id" {
  description = "ID of the AWS Directory Service"
  value       = aws_directory_service_directory.main.id
}

output "directory_name" {
  description = "Name (domain) of the directory"
  value       = aws_directory_service_directory.main.name
}

output "directory_dns_ip_addresses" {
  description = "DNS IP addresses of the directory"
  value       = aws_directory_service_directory.main.dns_ip_addresses
}

output "directory_access_url" {
  description = "Access URL for the directory"
  value       = aws_directory_service_directory.main.access_url
}

output "security_group_id" {
  description = "Security group ID for Directory Service"
  value       = aws_security_group.directory.id
}

output "directory_short_name" {
  description = "Short name of the directory (NetBIOS name)"
  value       = aws_directory_service_directory.main.short_name
}
