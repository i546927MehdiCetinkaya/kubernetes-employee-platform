terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# GCP Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# GCP Beta Provider for features in beta
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
