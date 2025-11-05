# IAM Service Accounts for Case Study 3

# Service account for GitHub Actions Terraform deployment via OIDC
resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for Terraform deployment via Workload Identity Federation (OIDC)"
  project      = var.project_id
}

# Service account for Cloud SQL administration
resource "google_service_account" "cloud_sql_admin" {
  account_id   = "cloud-sql-admin"
  display_name = "Cloud SQL Admin Service Account"
  description  = "Service account for Cloud SQL database management and migrations"
  project      = var.project_id
}

# Service account for GKE workloads (Phase 3)
resource "google_service_account" "gke_workload" {
  account_id   = "gke-workload"
  display_name = "GKE Workload Service Account"
  description  = "Service account for Kubernetes workloads to access Cloud SQL"
  project      = var.project_id
}

# IAM role bindings for GitHub Actions service account
# Required roles for Terraform deployment with least privilege

resource "google_project_iam_member" "github_actions_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_iam_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_service_networking_admin" {
  project = var.project_id
  role    = "roles/servicenetworking.networksAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_monitoring_admin" {
  project = var.project_id
  role    = "roles/monitoring.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# IAM role bindings for Cloud SQL Admin service account
resource "google_project_iam_member" "cloud_sql_admin_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_admin.email}"
}

resource "google_project_iam_member" "cloud_sql_admin_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.cloud_sql_admin.email}"
}

# IAM role bindings for GKE Workload service account
resource "google_project_iam_member" "gke_workload_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.gke_workload.email}"
}

# Workload Identity Pool for GitHub Actions OIDC
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions OIDC authentication"
  project                   = var.project_id
}

# Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"
  description                        = "OIDC provider for GitHub Actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# IAM binding to allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_member" "github_actions_workload_identity" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/i546927MehdiCetinkaya/casestudy3"
}
