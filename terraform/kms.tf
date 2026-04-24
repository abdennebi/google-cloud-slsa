# ---------------------------------------------------------------------------
# KMS – Key ring + asymmetric signing key
# Mirrors the KMS section in init.sh and the key binding in attestor.sh
# ---------------------------------------------------------------------------
resource "google_kms_key_ring" "binauthz" {
  project  = var.project_id
  name     = var.kms_ring_name
  location = var.region

  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "binauthz_signer" {
  name     = var.kms_key_name
  key_ring = google_kms_key_ring.binauthz.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = "RSA_SIGN_PKCS1_4096_SHA512"
    protection_level = "SOFTWARE"
  }

  # Prevent accidental key destruction
  lifecycle {
    prevent_destroy = false
  }
}

# ---------------------------------------------------------------------------
# KMS IAM – Cloud Build SA: signerVerifier + viewer
# Mirrors init.sh: gcloud kms keys add-iam-policy-binding (×2)
# ---------------------------------------------------------------------------
resource "google_kms_crypto_key_iam_member" "cloudbuild_signer_verifier" {
  crypto_key_id = google_kms_crypto_key.binauthz_signer.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${local.cloud_build_sa_email}"
}

resource "google_kms_crypto_key_iam_member" "cloudbuild_viewer" {
  crypto_key_id = google_kms_crypto_key.binauthz_signer.id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${local.cloud_build_sa_email}"
}
