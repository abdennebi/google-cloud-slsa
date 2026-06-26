terraform {
  required_version = ">= 1.3.0"

  backend "gcs" {
    bucket = "lcl-acdc-sbox-e3e1-tfstate"
    prefix = "google-cloud-slsa"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.29.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.29.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Provider alias requis pour binaryauthorization.googleapis.com :
# cette API exige le header X-Goog-User-Project avec les ADC utilisateur,
# indépendamment du champ `project` dans la ressource.
provider "google" {
  alias                 = "with_quota"
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# ---------------------------------------------------------------------------
# Derived locals (mirrors config.sh)
# ---------------------------------------------------------------------------
locals {
  cluster_zone         = "${var.region}-b"
  project_number       = data.google_project.project.number
  cloud_build_sa_email = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  # Dedicated SA used for Cloud Deploy / Cloud Build trigger (replaces deleted default Compute SA)
  clouddeploy_sa_email = "clouddeploy-runner@${var.project_id}.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

# ---------------------------------------------------------------------------
# Enable APIs (mirrors the `gcloud services enable` block in init.sh)
# ---------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "containerscanning.googleapis.com",
    "containersecurity.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "ondemandscanning.googleapis.com",
  ])

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

# ---------------------------------------------------------------------------
# Dedicated service account for Cloud Deploy / Cloud Build trigger
# (the default Compute SA is deleted in this project and cannot be recovered)
# ---------------------------------------------------------------------------
resource "google_service_account" "clouddeploy_runner" {
  project      = var.project_id
  account_id   = "clouddeploy-runner"
  display_name = "Cloud Deploy Runner"
  description  = "Used by Cloud Deploy jobs and Cloud Build trigger (replaces deleted default Compute SA)"

  depends_on = [google_project_service.apis]
}
