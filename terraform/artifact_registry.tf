resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
  description   = "Docker images for ${var.registry_name}"

  depends_on = [google_project_service.apis]
}
