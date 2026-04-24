# ---------------------------------------------------------------------------
# Binary Authorization – Container Analysis notes + attestors
# Mirrors setup/attestor.sh (called 3× from binauthz.sh)
#
# NOTE: The `google_binary_authorization_attestor` resource manages the
# BinAuthz attestor and its PKIX key binding natively. The Container Analysis
# note must be created separately via `google_container_analysis_note`.
# ---------------------------------------------------------------------------

locals {
  attestor_ids = {
    gcb  = var.gcb_attestor_id
    vuln = var.vuln_attestor_id
    sbom = var.sbom_attestor_id
  }
}

# ---------------------------------------------------------------------------
# Container Analysis notes (one per attestor)
# Mirrors the curl POST to containeranalysis.googleapis.com in attestor.sh
# ---------------------------------------------------------------------------
resource "google_container_analysis_note" "attestor_notes" {
  for_each = local.attestor_ids

  project = var.project_id
  name    = "${each.value}-note"

  attestation_authority {
    hint {
      human_readable_name = "${each.value} note"
    }
  }

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------------------------------------
# IAM on each note – Cloud Build SA: occurrences.viewer + notes.attacher
# Mirrors the curl setIamPolicy call in attestor.sh
# ---------------------------------------------------------------------------
resource "google_container_analysis_note_iam_binding" "note_occurrences_viewer" {
  for_each = local.attestor_ids

  project = var.project_id
  note    = google_container_analysis_note.attestor_notes[each.key].name
  role    = "roles/containeranalysis.notes.occurrences.viewer"
  members = ["serviceAccount:${local.cloud_build_sa_email}"]
}

resource "google_container_analysis_note_iam_binding" "note_attacher" {
  for_each = local.attestor_ids

  project = var.project_id
  note    = google_container_analysis_note.attestor_notes[each.key].name
  role    = "roles/containeranalysis.notes.attacher"
  members = ["serviceAccount:${local.cloud_build_sa_email}"]
}

# ---------------------------------------------------------------------------
# Binary Authorization attestors
# Mirrors: gcloud container binauthz attestors create
#          gcloud beta container binauthz attestors public-keys add
# ---------------------------------------------------------------------------
resource "google_binary_authorization_attestor" "attestors" {
  for_each = local.attestor_ids

  project = var.project_id
  name    = each.value

  attestation_authority_note {
    note_reference = google_container_analysis_note.attestor_notes[each.key].name

    # Bind the shared KMS key (version 1) as the PKIX signing key
    # Mirrors: gcloud beta container binauthz attestors public-keys add --keyversion 1
    public_keys {
      id = data.google_kms_crypto_key_version.binauthz_v1.id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.binauthz_v1.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.binauthz_v1.public_key[0].algorithm
      }
    }
  }

  depends_on = [google_container_analysis_note.attestor_notes]
}

# Retrieve the public key for KMS key version 1
data "google_kms_crypto_key_version" "binauthz_v1" {
  crypto_key = google_kms_crypto_key.binauthz_signer.id
}

# ---------------------------------------------------------------------------
# Attestor IAM – Cloud Build SA: attestorsViewer
# Mirrors: gcloud container binauthz attestors add-iam-policy-binding in attestor.sh
# Note: Uses local-exec via gcloud to avoid ADC quota-project issue with
# the google_binary_authorization_attestor_iam_member resource.
# ---------------------------------------------------------------------------
resource "terraform_data" "cb_viewer_binauthz" {
  for_each = local.attestor_ids

  input = "${var.project_id}/${each.value}/${local.cloud_build_sa_email}"

  provisioner "local-exec" {
    command = <<-EOT
      gcloud container binauthz attestors add-iam-policy-binding ${each.value} \
        --project ${var.project_id} \
        --member "serviceAccount:${local.cloud_build_sa_email}" \
        --role "roles/binaryauthorization.attestorsViewer"
    EOT
  }

  depends_on = [google_binary_authorization_attestor.attestors]
}

# ---------------------------------------------------------------------------
# Binary Authorization policy
# Mirrors: gcloud container binauthz policy import policy/attestor-policy.yaml
# (template.attestor-policy.yaml)
# ---------------------------------------------------------------------------
resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  default_admission_rule {
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    evaluation_mode  = "ALWAYS_ALLOW"
  }

  # prod cluster
  cluster_admission_rules {
    cluster                 = "${local.cluster_zone}.${var.cluster_name}-prod"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    require_attestations_by = [for k, v in local.attestor_ids : google_binary_authorization_attestor.attestors[k].name]
  }

  # test cluster
  cluster_admission_rules {
    cluster                 = "${local.cluster_zone}.${var.cluster_name}-test"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    require_attestations_by = [for k, v in local.attestor_ids : google_binary_authorization_attestor.attestors[k].name]
  }

  # Global image allowlist (mirrors admissionWhitelistPatterns in template)
  admission_whitelist_patterns { name_pattern = "us.gcr.io/google-containers/**" }
  admission_whitelist_patterns { name_pattern = "gcr.io/google_containers/**" }
  admission_whitelist_patterns { name_pattern = "gcr.io/stackdriver-agents/**" }
  admission_whitelist_patterns { name_pattern = "gke.gcr.io/**" }

  depends_on = [google_binary_authorization_attestor.attestors]
}
