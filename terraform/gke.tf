# ---------------------------------------------------------------------------
# GKE clusters – hello-test and hello-prod
# Mirrors setup/cluster.sh called twice from setup/clusters.sh
# ---------------------------------------------------------------------------

# Shared node-pool config extracted as locals for DRY code
locals {
  node_scopes = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append",
  ]

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
  location = local.cluster_zone

  release_channel {
    channel = upper(var.cluster_release_channel)
  }

  # Binary Authorization – PROJECT_SINGLETON_POLICY_ENFORCE
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Disable basic auth
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Networking
  network    = google_compute_network.default.id
  subnetwork = google_compute_subnetwork.default.id

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  # Logging & monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  # Addons
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Default node pool is removed; we manage our own below
  remove_default_node_pool = true
  initial_node_count       = 1

  # Shielded nodes
  enable_shielded_nodes = true

  resource_labels = {
    demo  = "build"
    group = each.value
  }

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
    google_service_account.gke_node,
  ]
}

resource "google_container_node_pool" "primary" {
  provider = google-beta
  for_each = local.clusters

  project    = var.project_id
  name       = "primary"
  location   = local.cluster_zone
  cluster    = google_container_cluster.clusters[each.key].name
  node_count         = var.cluster_size
  max_pods_per_node  = 110

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  node_config {
    machine_type = var.cluster_node_machine_type
    image_type   = "COS_CONTAINERD"
    disk_type    = "pd-standard"
    disk_size_gb = 100

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = local.node_scopes

    service_account = "gke-node@${var.project_id}.iam.gserviceaccount.com"

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
