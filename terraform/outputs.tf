output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP project number"
  value       = local.project_number
}

output "region" {
  description = "Deployment region"
  value       = var.region
}

output "artifact_registry_url" {
  description = "Artifact Registry Docker repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.registry_name}"
}

output "kms_key_id" {
  description = "Full KMS crypto key resource ID"
  value       = google_kms_crypto_key.binauthz_signer.id
}

output "kms_key_version" {
  description = "Full KMS crypto key version resource name (used in substitutions)"
  value       = "${google_kms_crypto_key.binauthz_signer.id}/cryptoKeyVersions/1"
}

output "gke_cluster_names" {
  description = "Names of the created GKE clusters"
  value       = { for k, c in google_container_cluster.clusters : k => c.name }
}

output "attestor_names" {
  description = "Binary Authorization attestor names"
  value       = { for k, a in google_binary_authorization_attestor.attestors : k => a.name }
}

output "cloudbuild_trigger_id" {
  description = "Cloud Build trigger ID"
  value       = google_cloudbuild_trigger.hello_app.trigger_id
}
