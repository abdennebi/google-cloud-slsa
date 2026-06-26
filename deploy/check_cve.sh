#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Parameters
PROJECT_ID="${1:-lcl-acdc-sbox-e3e1}"
REGION="${2:-europe-west1}"
CVE_ID="${3:-CVE-2026-0861}"

echo "======================================================================"
echo "Checking CVE: $CVE_ID in project: $PROJECT_ID (Region: $REGION)"
echo "======================================================================"

echo "1. Querying Artifact Analysis for vulnerable images..."
# Get all occurrences of the vulnerability
OCCURRENCES_JSON=$(curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-urlencode "filter=kind=\"VULNERABILITY\" AND noteId=\"${CVE_ID}\"" \
  "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/occurrences")

# Parse resourceUri using jq and strip "https://" prefix to match GKE format
VULNERABLE_IMAGES=$(echo "$OCCURRENCES_JSON" | jq -r '.occurrences[].resourceUri' 2>/dev/null | sed 's|^https://||' | sort -u || true)

if [ -z "$VULNERABLE_IMAGES" ]; then
  echo "No vulnerable images for $CVE_ID found in Artifact Registry."
  echo "All quiet in the registry."
else
  echo "Found vulnerable images in registry:"
  echo "$VULNERABLE_IMAGES"
fi
echo ""

echo "2. Scanning running GKE workloads..."
CLUSTERS=$(gcloud container clusters list --region="$REGION" --project="$PROJECT_ID" --format="value(name)")

if [ -z "$CLUSTERS" ]; then
  echo "No GKE clusters found in region $REGION."
  exit 0
fi

for cluster in $CLUSTERS; do
  echo "=> Fetching credentials for GKE cluster: $cluster"
  gcloud container clusters get-credentials "$cluster" --region="$REGION" --project="$PROJECT_ID" --quiet
  
  echo "=> Analyzing workloads in GKE cluster: $cluster"
  # Fetch namespace, pod name, and container images
  # Format output as: namespace pod-name container-image
  kubectl get pods -A -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.image}{"\n"}{end}{end}' | \
  while read -r namespace pod image; do
    if [ -z "$image" ]; then
      continue
    fi
    
    # Check if the running image is in our vulnerable list.
    if [ -n "$VULNERABLE_IMAGES" ] && echo "$VULNERABLE_IMAGES" | grep -Fq "$image"; then
      echo "   ⚠️  ALERT: Pod [$pod] in namespace [$namespace] is running vulnerable image: $image"
    else
      # Option to show clean images for debugging
      # echo "   Clean: Pod [$pod] -> $image"
      true
    fi
  done
done

echo "======================================================================"
echo "Scan complete."
echo "======================================================================"
