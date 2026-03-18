#!/bin/bash

DIR="$(dirname "$0")"
. "${DIR}/config.sh"

set -o errexit
set -o pipefail

REPO_OWNER=$1
REPO_NAME=${2:-google-cloud-slsa}

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

if [[ -z "$REPO_OWNER" ]]; then
  echo "Usage $0 <your-github-username>"
  exit 1
fi

# get the key path 
export KEY_NAME=$(gcloud kms keys describe --keyring $KMS_RING_NAME \
  --location $REGION $KMS_KEY_NAME --format=json \
  | jq --raw-output '.name')

export NOTE_LOCATION=$(curl -s "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${VULN_ATTESTOR_ID}-note" \
  --request "GET" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --header "X-Goog-User-Project: ${PROJECT_ID}" \
  | jq --raw-output '.name')


# gcloud beta builds worker-pools create demo-pool \
#   --region $REGION \
#   --project $PROJECT_ID \
#   --worker-machine-type e2-standard-2 \
#   --worker-disk-size 100GB


gcloud beta builds triggers create github \
  --name hello-app-trigger \
  --region $REGION \
  --project $PROJECT_ID \
  --repo-name $REPO_NAME \
  --repo-owner $REPO_OWNER \
  --tag-pattern "ˆv.*" \
  --substitutions "_KMS_DIGEST_ALG=SHA512,_KMS_KEY_NAME=${KEY_NAME}/cryptoKeyVersions/1,_NOTE_NAME=${NOTE_LOCATION},_BIN_AUTHZ_ID=projects/${PROJECT_ID}/attestors/${SBOM_ATTESTOR_ID},_POOL_NAME=demo-pool" \
  --service-account "projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --build-config "app/cloudbuild.yaml"
