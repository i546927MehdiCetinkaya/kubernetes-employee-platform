# VPC Firewall Rules - Zero Trust Implementation
# Default deny all ingress/egress, then explicitly allow required traffic

# Deny all ingress by default (implicit in GCP, but explicit for documentation)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "deny-all-ingress"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  description = "Default deny all ingress traffic (Zero Trust baseline)"
}

# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]

  description = "Allow all internal VPC traffic for inter-subnet communication"
}

# Allow GKE subnet to access Cloud SQL (port 5432)
resource "google_compute_firewall" "allow_gke_to_cloudsql" {
  name    = "allow-gke-to-cloudsql"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 900
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.gke_subnet_cidr]
  target_tags   = ["cloudsql"]

  description = "Allow GKE workloads to connect to Cloud SQL PostgreSQL (least privilege)"
}

# Allow health checks from Google Cloud (required for load balancers)
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 900
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  description = "Allow Google Cloud health checks for load balancers"
}

# Allow IAP (Identity-Aware Proxy) for SSH access if needed
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 900
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP IP range for SSH tunneling
  source_ranges = ["35.235.240.0/20"]

  description = "Allow SSH access via Identity-Aware Proxy (secure bastion alternative)"
}

# Deny all egress to internet from database subnet (extra security layer)
resource "google_compute_firewall" "deny_database_egress_internet" {
  name    = "deny-database-egress-internet"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 500
  direction = "EGRESS"

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  # Apply only to database subnet
  target_tags = ["cloudsql", "database"]

  description = "Deny internet egress from database subnet (Zero Trust - no data exfiltration)"
}

# Allow egress to Google APIs from all subnets (required for Private Google Access)
resource "google_compute_firewall" "allow_egress_google_apis" {
  name    = "allow-egress-google-apis"
  network = google_compute_network.innovatech_vpc.name
  project = var.project_id

  priority  = 100
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Google Private Access IP ranges
  destination_ranges = [
    "199.36.153.8/30",
    "199.36.153.4/30"
  ]

  description = "Allow egress to Google APIs via Private Google Access"
}
