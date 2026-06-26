# ---------------------------------------------------------------------------
# VPC – default network + subnet europe-west1
# ---------------------------------------------------------------------------
resource "google_compute_network" "default" {
  project                 = var.project_id
  name                    = "default"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "default" {
  project                  = var.project_id
  name                     = "default"
  region                   = var.region
  network                  = google_compute_network.default.id
  ip_cidr_range            = "10.132.0.0/20"
  private_ip_google_access = true
}
