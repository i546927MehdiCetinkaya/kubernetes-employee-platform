# Random suffix for Cloud SQL instance name (required for uniqueness)
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL PostgreSQL Instance with HA and Private Networking
resource "google_sql_database_instance" "postgres" {
  name             = "innovatech-postgres-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  # Deletion protection for production safety
  deletion_protection = false # Set to true in production

  settings {
    tier                  = var.database_tier
    availability_type     = var.database_availability_type # REGIONAL for HA (Multi-AZ)
    disk_type             = var.database_disk_type
    disk_size             = var.database_disk_size_gb
    disk_autoresize       = true
    disk_autoresize_limit = 100 # Max 100 GB

    # IP configuration - private IP only (no public IP for security)
    ip_configuration {
      ipv4_enabled    = false # No public IP
      private_network = google_compute_network.innovatech_vpc.id
      require_ssl     = true # Enforce SSL connections (GDPR compliance)
    }

    # Backup configuration with PITR
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00" # 3 AM UTC backup window
      point_in_time_recovery_enabled = var.enable_pitr
      transaction_log_retention_days = var.database_backup_retention_days

      backup_retention_settings {
        retained_backups = var.database_backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window (Sunday 4-5 AM UTC)
    maintenance_window {
      day          = 7 # Sunday
      hour         = 4
      update_track = "stable"
    }

    # Database flags for security and performance
    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    # Enable query insights for monitoring
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }

    # User labels for resource management
    user_labels = merge(
      var.labels,
      {
        component = "database"
        database  = "postgresql"
      }
    )
  }

  # Wait for private VPC connection to be established
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# HR Database for employee lifecycle data
resource "google_sql_database" "hr_database" {
  name     = "hr_database"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# Database user for application access
resource "google_sql_user" "hr_app_user" {
  name     = "hr_app_user"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id

  # Password should be managed via Secret Manager in production
  # For now, using a randomly generated password
  password = random_password.hr_app_password.result
}

# Random password for database user (stored in Terraform state)
resource "random_password" "hr_app_password" {
  length  = 32
  special = true
}

# Database user for admin operations
resource "google_sql_user" "postgres_admin" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id

  # Admin password
  password = random_password.postgres_admin_password.result
}

# Random password for admin user
resource "random_password" "postgres_admin_password" {
  length  = 32
  special = true
}
