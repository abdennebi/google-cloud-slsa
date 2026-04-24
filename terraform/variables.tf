variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "europe-west1"
}

# Cluster variables
variable "cluster_name" {
  description = "Base name for GKE clusters"
  type        = string
  default     = "hello"
}

variable "cluster_node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "cluster_release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "RAPID"
}

variable "cluster_size" {
  description = "Number of nodes per cluster"
  type        = number
  default     = 3
}

# Pipeline variables
variable "registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "google-cloud-slsa"
}

# KMS variables
variable "kms_ring_name" {
  description = "KMS key ring name"
  type        = string
  default     = "binauthz"
}

variable "kms_key_name" {
  description = "KMS key name"
  type        = string
  default     = "binauthz-signer"
}

# Binary Authorization attestor IDs
variable "gcb_attestor_id" {
  description = "Attestor ID for Cloud Build"
  type        = string
  default     = "built-by-cloud-build"
}

variable "vuln_attestor_id" {
  description = "Attestor ID for vulnerability scanning"
  type        = string
  default     = "vulnz-attestor"
}

variable "sbom_attestor_id" {
  description = "Attestor ID for SBOM"
  type        = string
  default     = "sbom-attestor"
}

# Cloud Build trigger variables
variable "github_repo_owner" {
  description = "GitHub repository owner (username or org)"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "google-cloud-slsa"
}
