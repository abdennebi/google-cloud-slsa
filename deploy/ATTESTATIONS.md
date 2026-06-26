# Récupération des Attestations : GKE SLSA Demo

Ce document détaille les méthodes pour interroger et récupérer les attestations de sécurité (vulnérabilités, provenance SLSA, SBOM) associées aux images conteneurs déployées dans l'infrastructure Google Cloud.

Dans cette architecture sécurisée, chaque image acceptée sur les clusters GKE doit posséder trois attestations distinctes signées cryptographiquement par une clé Cloud KMS.

---

## 🔍 Méthode 1 : Interrogation Globale (API REST Container Analysis)

Toutes les attestations, quel que soit l'attesteur, sont stockées sous forme d'**occurrences** de type `ATTESTATION` liées au projet. C'est la méthode recommandée pour récupérer l'ensemble des attestations en une seule requête.

### 1. Lister toutes les attestations d'une image
Pour récupérer toutes les signatures et métadonnées associées à une URI d'image exacte (identifiée par son digest SHA256) :

```bash
IMAGE_URI="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"

curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-urlencode "filter=kind=\"ATTESTATION\" AND resourceUrl=\"${IMAGE_URI}\"" \
  "https://containeranalysis.googleapis.com/v1/projects/lcl-acdc-sbox-e3e1/occurrences" \
  | jq .
```

### 2. Extraire et décoder le Payload des attestations
Le contenu décrivant l'attestation (`serializedPayload`) est encodé en Base64. Pour le décoder à la volée afin de lire les déclarations au format clair (JSON in-toto) :

```bash
curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-urlencode "filter=kind=\"ATTESTATION\" AND resourceUrl=\"${IMAGE_URI}\"" \
  "https://containeranalysis.googleapis.com/v1/projects/lcl-acdc-sbox-e3e1/occurrences" \
  | jq -r '.occurrences[].attestation.serializedPayload' | base64 -d
```

---

## 💻 Méthode 2 : Interrogation via CLI `gcloud` (Par Attesteur)

Le SDK `gcloud` permet d'interroger directement Binary Authorization. Cette méthode nécessite d'effectuer une requête spécifique pour chaque attesteur configuré.

### 1. Attestation de Posture de Vulnérabilités (`vulnz-attestor`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/vulnz-attestor" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

### 2. Attestation de Provenance GCB (`built-by-cloud-build`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/built-by-cloud-build" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

### 3. Attestation de présence de SBOM (`sbom-attestor`)
```bash
gcloud container binauthz attestations list \
  --attestor="projects/lcl-acdc-sbox-e3e1/attestors/sbom-attestor" \
  --artifact-url="europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```

---

## 🔐 Méthode 3 : Vérification SBOM Cosign (Intégration externe)

L'image génère également des attestations compatibles avec l'outil de signature standard du marché, **Cosign**, en s'adossant sur Cloud KMS :

```bash
cosign verify-attestation --type spdxjson \
  --key gcpkms://projects/lcl-acdc-sbox-e3e1/locations/europe-west1/keyRings/binauthz/cryptoKeys/binauthz-signer/cryptoKeyVersions/1 \
  "europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a"
```
*(Cela permet de valider le fichier SBOM SPDX attaché à l'image stockée dans le registre).*
