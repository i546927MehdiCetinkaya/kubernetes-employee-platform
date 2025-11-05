variable "project_id" {
  description = "GCP Project ID for Case Study 3"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "region" {
  description = "GCP region for resources (europe-west4 - Netherlands)"
  type        = string
  default     = "europe-west4"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "database_subnet_cidr" {
  description = "CIDR block for database subnet"
  type        = string
  default     = "10.100.2.0/24"
}

variable "gke_subnet_cidr" {
  description = "CIDR block for GKE subnet"
  type        = string
  default     = "10.100.1.0/24"
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_version" {
  description = "PostgreSQL database version"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_availability_type" {
  description = "Cloud SQL availability type (REGIONAL for HA, ZONAL for single-zone)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.database_availability_type)
    error_message = "Availability type must be REGIONAL or ZONAL."
  }
}

variable "database_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
  validation {
    condition     = var.database_backup_retention_days >= 1 && var.database_backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

variable "database_disk_size_gb" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.database_disk_size_gb >= 10 && var.database_disk_size_gb <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "database_disk_type" {
  description = "Cloud SQL disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.database_disk_type)
    error_message = "Disk type must be PD_SSD or PD_HDD."
  }
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery for Cloud SQL"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project    = "casestudy3"
    managed_by = "terraform"
    student    = "mehdi-cetinkaya"
    course     = "nca"
  }
}
