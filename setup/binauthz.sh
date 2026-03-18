#!/bin/bash

DIR="$(dirname "$0")"
. "${DIR}/config.sh"

set -o errexit
set -o pipefail

# setup vulnerability and builder attestors
setup/attestor.sh $GCB_ATTESTOR_ID
setup/attestor.sh $SBOM_ATTESTOR_ID
setup/attestor.sh $VULN_ATTESTOR_ID

# setup policy 
gcloud container binauthz policy import policy/attestor-policy.yaml

# list attestors
gcloud container binauthz attestors list

# list attestation 
gcloud container binauthz attestations list \
    --attestor=$VULN_ATTESTOR_ID \
    --attestor-project=$PROJECT_ID