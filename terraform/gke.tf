# ---------------------------------------------------------------------------
# GKE clusters – hello-test and hello-prod (Autopilot)
# Autopilot gère les nœuds automatiquement : pas de node pool à définir.
# Les clusters Autopilot sont régionaux (pas zonaux).
# ---------------------------------------------------------------------------

locals {
  clusters = {
    test = "${var.cluster_name}-test"
    prod = "${var.cluster_name}-prod"
  }
}

resource "google_container_cluster" "clusters" {
  provider = google-beta
  for_each = local.clusters

  project  = var.project_id
  name     = each.value
  location = var.region  # régional (requis pour Autopilot)

  # Autopilot
  enable_autopilot = true

  # Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Networking
  network    = google_compute_network.default.id
  subnetwork = google_compute_subnetwork.default.id

  ip_allocation_policy {}

  release_channel {
    channel = upper(var.cluster_release_channel)
  }

  resource_labels = {
    demo  = "build"
    group = each.value
  }

  deletion_protection = false

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
  ]
}
