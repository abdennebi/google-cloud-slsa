# Gestion des Vulnérabilités : VEX & GKE Continuous Validation

Ce document décrit comment gérer les faux positifs et documenter la non-exploitabilité d'une vulnérabilité (CVE) dans les images de conteneurs en utilisant la spécification **VEX (Vulnerability Exploitability eXchange)** et en l'intégrant dans **GKE Continuous Validation**.

---

## 💡 Qu'est-ce que le VEX ?

Le VEX est un format de déclaration de sécurité permettant d'attester de la exploitabilité ou de la non-exploitabilité réelle d'une vulnérabilité dans le contexte spécifique d'une application ou d'un produit. 

Il permet d'indiquer à vos scanners (et aux moteurs de conformité de GKE) d'ignorer une alerte de sécurité avec des justifications standardisées comme `vulnerable_code_not_in_execute_path`.

Deux formats principaux coexistent dans l'écosystème :
1. **OpenVEX** : Format JSON moderne et simplifié pour les outils de sécurité (ex: Trivy).
2. **CSAF 2.0 (Common Security Advisory Format)** : Format de sécurité plus large et normalisé requis par Google Cloud pour l'intégration native avec Artifact Analysis.

---

## 📁 Fichiers VEX générés dans le Projet

Pour la vulnérabilité **CVE-2026-0861** sur l'application `hello`, deux variantes ont été créées sous le dossier `policy/` :

* **Format OpenVEX** : [policy/hello-cve-2026-0861-vex.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/policy/hello-cve-2026-0861-vex.json)
* **Format CSAF 2.0** : [policy/hello-cve-2026-0861-csaf-vex.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/policy/hello-cve-2026-0861-csaf-vex.json)

---

## 🚀 Étape 1 : Pousser le document VEX vers Google Cloud

Pour associer le statut `known_not_affected` à votre image dans **Artifact Analysis**, vous devez importer le fichier CSAF 2.0 VEX via la CLI `gcloud`.

### Commande de Chargement VEX :

```bash
# 1. Connectez-vous si nécessaire
gcloud auth login

# 2. Chargez le document VEX pour l'image concernée :
gcloud artifacts vulnerabilities load-vex \
  --source=policy/hello-cve-2026-0861-csaf-vex.json \
  --uri=europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a \
  --project=lcl-acdc-sbox-e3e1 \
  --location=europe-west1
```

### Vérification dans GCP
* Allez dans **Artifact Registry** dans la Console Google Cloud.
* Cliquez sur l'image et le digest ciblé.
* Dans l'onglet **Vulnérabilités**, recherchez la CVE. Elle doit maintenant apparaître sous l'état **Exempté (ou résolu)** avec le résumé textuel configuré.

---

## 🛡️ Étape 2 : Configuration Immédiate dans GKE Continuous Validation

Bien que le chargement du VEX dans Artifact Analysis mette à jour l'évaluation de sécurité à terme (quelques minutes/heures de latence de propagation), la bonne pratique pour éviter toute alerte intempestive de **GKE Continuous Validation** consiste à l'exclure directement au niveau de la règle de sécurité GKE.

### 1. Ajouter la CVE dans la politique de validation continue
Éditez le fichier [doc/continuous-validation-policy.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/doc/continuous-validation-policy.json) et complétez la liste `allowedCves` sous la section `vulnerabilityCheck` :

```json
          {
            "displayName": "Vulnerability check",
            "vulnerabilityCheck": {
              "maximumFixableSeverity": "LOW",
              "maximumUnfixableSeverity": "MEDIUM",
              "allowedCves": [
                "CVE-2020-29511",
                "CVE-2020-29509",
                "CVE-2026-0861"
              ],
              "containerAnalysisVulnerabilityProjects": [
                "projects/goog-vulnz"
              ]
            }
          }
```

### 2. Appliquer la mise à jour via Terraform
Déployez la mise à jour de la politique restapi sur Google Cloud :

```bash
cd terraform/
terraform apply -target=restapi_object.continuous_validation_policy -auto-approve
```

---

## 🔍 Validation de l'Exemption

Une fois la politique mise à jour et le document VEX poussé, vous pouvez exécuter le script de scan de sécurité local du projet pour valider que le système est sain :

```bash
./deploy/check_cve.sh lcl-acdc-sbox-e3e1 europe-west1 CVE-2026-0861
```
