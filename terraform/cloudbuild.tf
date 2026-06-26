# ---------------------------------------------------------------------------
# Cloud Build trigger
#
# IMPORTANT LIMITATION: The trigger uses `github` source type which requires
# a pre-existing GitHub App connection set up manually in the GCP Console.
# The `_POOL_NAME` substitution references a private worker pool ("demo-pool")
# that is commented-out in the original script – it is kept here as a variable
# defaulting to empty so the build falls back to the default public pool.
# ---------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "hello_app" {
  project  = var.project_id
  name     = "hello-app-trigger"
  location = var.region

  description = "Trigger on git tags matching ^v.* for ${var.github_repo_name}"

  # Tag pattern filter – mirrors --tag-pattern "^v.*"
  github {
    owner = var.github_repo_owner
    name  = var.github_repo_name

    push {
      tag = "^v.*"
    }
  }

  # Build config file in the repository
  filename = "app/cloudbuild.yaml"

  # Service account – mirrors --service-account flag
  service_account = "projects/${var.project_id}/serviceAccounts/${local.clouddeploy_sa_email}"

  # Substitutions wired by trigger.sh
  # _KMS_KEY_NAME  = full resource name of KMS key version 1
  # _NOTE_NAME     = full resource name of the vulnz Container Analysis note
  # _BIN_AUTHZ_ID  = SBOM attestor resource name
  # _POOL_NAME     = private worker pool name (set to empty → default pool)
  substitutions = {
    _KMS_DIGEST_ALG = "SHA512"
    _KMS_KEY_NAME   = "${google_kms_crypto_key.binauthz_signer.id}/cryptoKeyVersions/1"
    _NOTE_NAME      = google_container_analysis_note.attestor_notes["vuln"].name
    _BIN_AUTHZ_ID   = "projects/${var.project_id}/attestors/${var.sbom_attestor_id}"
    _POOL_NAME      = ""
  }

  depends_on = [
    google_project_service.apis,
    google_kms_crypto_key.binauthz_signer,
    google_container_analysis_note.attestor_notes,
    google_binary_authorization_attestor.attestors,
    google_service_account.clouddeploy_runner,
  ]
}
