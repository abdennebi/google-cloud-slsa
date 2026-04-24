# ---------------------------------------------------------------------------
# IAM – Cloud Build service account
# Mirrors the `cloudbuild_roles` loop in init.sh
# ---------------------------------------------------------------------------
locals {
  cloudbuild_roles = [
    "roles/containeranalysis.notes.editor",
    "roles/containeranalysis.notes.occurrences.viewer",
    "roles/containeranalysis.occurrences.editor",
    "roles/binaryauthorization.attestorsViewer",
    "roles/cloudkms.cryptoKeyDecrypter",
    "roles/cloudkms.signerVerifier",
    "roles/containeranalysis.notes.attacher",
    "roles/clouddeploy.operator",
    "roles/cloudkms.admin",
  ]

  clouddeploy_roles = [
    "roles/clouddeploy.releaser",
    "roles/iam.serviceAccountUser",
    "roles/clouddeploy.jobRunner",
    "roles/container.developer",
  ]

  # Rôles nécessaires pour exécuter les steps Cloud Build via le trigger
  # (le trigger utilise clouddeploy-runner comme SA)
  cloudbuild_trigger_roles = [
    "roles/containeranalysis.notes.editor",
    "roles/containeranalysis.notes.occurrences.viewer",
    "roles/containeranalysis.occurrences.editor",
    "roles/binaryauthorization.attestorsViewer",
    "roles/cloudkms.cryptoKeyDecrypter",
    "roles/cloudkms.signerVerifier",
    "roles/cloudkms.viewer",
    "roles/containeranalysis.notes.attacher",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
    "roles/ondemandscanning.admin",
    "roles/clouddeploy.operator",
    "roles/storage.admin",
  ]
}

resource "google_project_iam_member" "cloudbuild_sa" {
  for_each = toset(local.cloudbuild_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.cloud_build_sa_email}"

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------------------------------------
# IAM – Dedicated Cloud Deploy runner service account
# Mirrors the `clouddeploy_roles` loop in init.sh
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "clouddeploy_sa" {
  for_each = toset(local.clouddeploy_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.clouddeploy_sa_email}"

  depends_on = [google_service_account.clouddeploy_runner]
}

resource "google_project_iam_member" "clouddeploy_sa_build" {
  for_each = toset(local.cloudbuild_trigger_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.clouddeploy_sa_email}"

  depends_on = [google_service_account.clouddeploy_runner]
}

# ---------------------------------------------------------------------------
# IAM – Cloud Build SA reads from Artifact Registry
# Mirrors clusters.sh: gcloud projects add-iam-policy-binding … roles/artifactregistry.reader
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "cloudbuild_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.cloud_build_sa_email}"

  depends_on = [google_project_service.apis]
}
