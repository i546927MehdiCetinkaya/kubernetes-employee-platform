# VPC Outputs
output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.innovatech_vpc.name
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.innovatech_vpc.id
}

output "vpc_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.innovatech_vpc.self_link
}

# Subnet Outputs
output "database_subnet_name" {
  description = "Name of the database subnet"
  value       = google_compute_subnetwork.database_subnet.name
}

output "database_subnet_cidr" {
  description = "CIDR range of the database subnet"
  value       = google_compute_subnetwork.database_subnet.ip_cidr_range
}

output "gke_subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_cidr" {
  description = "CIDR range of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

# Cloud SQL Outputs
output "cloudsql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "cloudsql_instance_connection_name" {
  description = "Connection name for Cloud SQL instance (used for Cloud SQL Proxy)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "cloudsql_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
  sensitive   = true
}

output "cloudsql_database_name" {
  description = "Name of the HR database"
  value       = google_sql_database.hr_database.name
}

output "cloudsql_database_version" {
  description = "PostgreSQL version of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.database_version
}

# Database User Outputs
output "database_user_name" {
  description = "Database user name for application"
  value       = google_sql_user.hr_app_user.name
}

output "database_user_password" {
  description = "Database user password (sensitive)"
  value       = google_sql_user.hr_app_user.password
  sensitive   = true
}

output "database_admin_password" {
  description = "Database admin password (sensitive)"
  value       = google_sql_user.postgres_admin.password
  sensitive   = true
}

# Service Account Outputs
output "github_actions_service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "cloud_sql_admin_service_account_email" {
  description = "Email of the Cloud SQL admin service account"
  value       = google_service_account.cloud_sql_admin.email
}

output "gke_workload_service_account_email" {
  description = "Email of the GKE workload service account"
  value       = google_service_account.gke_workload.email
}

# Workload Identity Federation Outputs
output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions OIDC"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "workload_identity_provider_full_name" {
  description = "Full resource name of the Workload Identity Provider"
  value       = "projects/${var.project_id}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github_provider.workload_identity_pool_provider_id}"
}

# Monitoring Dashboard Output
output "monitoring_dashboard_url" {
  description = "URL to access the Cloud Monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.infrastructure_health.id}?project=${var.project_id}"
}

# Connection Instructions
output "cloudsql_connection_command" {
  description = "Command to connect to Cloud SQL via Cloud SQL Proxy"
  value       = "cloud-sql-proxy ${google_sql_database_instance.postgres.connection_name} --port 5432"
}

output "psql_connection_command" {
  description = "Command to connect to PostgreSQL database via psql"
  value       = "PGPASSWORD='<password>' psql -h 127.0.0.1 -U ${google_sql_user.hr_app_user.name} -d ${google_sql_database.hr_database.name}"
  sensitive   = true
}
