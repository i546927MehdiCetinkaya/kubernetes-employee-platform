# VPC Network for Employee Lifecycle Automation
resource "google_compute_network" "innovatech_vpc" {
  name                    = "innovatech-vpc"
  auto_create_subnetworks = false
  description             = "VPC for Case Study 3 - Employee Lifecycle Automation"
  project                 = var.project_id
  routing_mode            = "REGIONAL"

  # Delete default routes on destroy to enable clean deletion
  delete_default_routes_on_create = false
}

# Database subnet for Cloud SQL PostgreSQL (private networking)
resource "google_compute_subnetwork" "database_subnet" {
  name          = "database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.innovatech_vpc.id
  description   = "Private subnet for Cloud SQL PostgreSQL instances"

  # Private Google Access enables private connectivity to Google APIs
  private_ip_google_access = true

  # Enable VPC Flow Logs for security monitoring (GDPR audit trail)
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE subnet for Kubernetes workloads (Phase 3)
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = google_compute_network.innovatech_vpc.id
  description   = "Private subnet for GKE Autopilot cluster (Phase 3)"

  # Private Google Access for accessing Google APIs
  private_ip_google_access = true

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.101.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.102.0.0/20"
  }

  # Enable VPC Flow Logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.innovatech_vpc.id
}

# Private service connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.innovatech_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud Router for NAT Gateway (if needed for internet access from private subnets)
resource "google_compute_router" "router" {
  name    = "innovatech-router"
  region  = var.region
  network = google_compute_network.innovatech_vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for outbound internet access from private subnets
resource "google_compute_router_nat" "nat" {
  name                               = "innovatech-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
