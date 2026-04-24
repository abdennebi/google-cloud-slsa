# ---------------------------------------------------------------------------
# Cloud Deploy – Delivery pipeline + targets
# Mirrors app/clouddeploy.yaml
# ---------------------------------------------------------------------------

resource "google_clouddeploy_delivery_pipeline" "demo" {
  project  = var.project_id
  location = var.region
  name     = "deploy-demo-pipeline"

  description = "Security-focused CI/CD pipeline on GCP"

  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.hello["test"].name
    }
    stages {
      target_id = google_clouddeploy_target.hello["prod"].name
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_clouddeploy_target" "hello" {
  for_each = local.clusters

  project  = var.project_id
  location = var.region
  name     = "hello-${each.key}"

  description      = "${each.key} cluster"
  require_approval = each.key == "prod"

  gke {
    cluster = "projects/${var.project_id}/locations/${local.cluster_zone}/clusters/${each.value}"
  }

  depends_on = [google_container_cluster.clusters]
}
