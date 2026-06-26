# Attestation Retrieval: GKE SLSA Demo

This document details the methods for querying and retrieving security attestations (vulnerabilities, SLSA provenance, SBOM) associated with container images deployed in the Google Cloud infrastructure.

In this secure architecture, every image accepted on the GKE clusters must have three distinct cryptographically signed attestations using a Cloud KMS key.

---

## 🔍 Method 1: Global Querying (Container Analysis REST API)

All attestations, regardless of the attestor, are stored as occurrences of type `ATTESTATION` linked to the project. This is the recommended method to retrieve all attestations in a single query.

### 1. List all attestations for an image
To retrieve all signatures and metadata associated with an exact image URI (identified by its SHA256 digest):

```bash
IMAGE_URI="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"

curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-urlencode "filter=kind=\"ATTESTATION\" AND resourceUrl=\"${IMAGE_URI}\"" \
  "https://containeranalysis.googleapis.com/v1/projects/lcl-acdc-sbox-e3e1/occurrences" \
  | jq .
```

### 2. Extract and decode the Attestation Payload
The attestation statement payload (`serializedPayload`) is Base64 encoded. To decode it on the fly to read the statements in cleartext (JSON in-toto format):

```bash
curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-urlencode "filter=kind=\"ATTESTATION\" AND resourceUrl=\"${IMAGE_URI}\"" \
  "https://containeranalysis.googleapis.com/v1/projects/lcl-acdc-sbox-e3e1/occurrences" \
  | jq -r '.occurrences[].attestation.serializedPayload' | base64 -d
```

---

## 💻 Method 2: Querying via CLI `gcloud` (Per Attestor)

The `gcloud` SDK allows querying Binary Authorization directly. This method requires executing a specific request for each configured attestor.

### 1. Vulnerability Attestation (`vulnz-attestor`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/vulnz-attestor" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

### 2. GCB Provenance Attestation (`built-by-cloud-build`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/built-by-cloud-build" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

### 3. SBOM Presence Attestation (`sbom-attestor`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/sbom-attestor" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

---

## 🔐 Method 3: Cosign SBOM Verification (External Integration)

The image also generates attestations compatible with the industry-standard signing tool, **Cosign**, backed by Cloud KMS:

```bash
cosign verify-attestation --type spdxjson \
  --key gcpkms://projects/lcl-acdc-sbox-e3e1/locations/europe-west1/keyRings/binauthz/cryptoKeys/binauthz-signer/cryptoKeyVersions/1 \
  "europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```
*(This allows validating the SPDX SBOM file attached to the container image stored in the registry).*
