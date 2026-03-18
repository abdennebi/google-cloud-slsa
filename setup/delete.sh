#!/bin/bash

DIR="$(dirname "$0")"
. "${DIR}/config.sh"

set -o errexit
set -o pipefail


# clusters
gcloud beta container clusters delete "${CLUSTER_NAME}-test" \
    --project $PROJECT_ID \
    --zone $CLUSTER_ZONE \
    --async

gcloud beta container clusters delete "${CLUSTER_NAME}-prod" \
    --project $PROJECT_ID \
    --zone $CLUSTER_ZONE \
    --async
