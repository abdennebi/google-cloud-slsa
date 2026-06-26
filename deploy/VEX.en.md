# Vulnerability Management: VEX & GKE Continuous Validation

This document describes how to manage false positives and document the non-exploitability of a vulnerability (CVE) in container images using the **VEX (Vulnerability Exploitability eXchange)** specification and integrating it with **GKE Continuous Validation**.

---

## 💡 What is VEX?

VEX is a security statement format used to attest to the actual exploitability or non-exploitability of a vulnerability within the specific context of an application or product.

It instructs your scanners (and GKE compliance engines) to ignore a security alert using standardized justifications such as `vulnerable_code_not_in_execute_path`.

Two main formats coexist in the ecosystem:
1. **OpenVEX**: A modern and simplified JSON format for security tools (e.g., Trivy).
2. **CSAF 2.0 (Common Security Advisory Format)**: A broader, standardized security format required by Google Cloud for native integration with Artifact Analysis.

---

## 📁 VEX Files Generated in the Project

For the vulnerability **CVE-2026-0861** on the `hello` application, two variants have been created under the `policy/` directory:

* **OpenVEX Format**: [policy/hello-cve-2026-0861-vex.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/policy/hello-cve-2026-0861-vex.json)
* **CSAF 2.0 Format**: [policy/hello-cve-2026-0861-csaf-vex.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/policy/hello-cve-2026-0861-csaf-vex.json)

---

## 🚀 Step 1: Uploading the VEX Document to Google Cloud

To associate the `known_not_affected` status with your image in **Artifact Analysis**, you must import the CSAF 2.0 VEX file using the `gcloud` CLI.

### VEX Upload Command:

```bash
# 1. Log in if necessary
gcloud auth login

# 2. Load the VEX document for the affected image:
gcloud artifacts vulnerabilities load-vex \
  --source=policy/hello-cve-2026-0861-csaf-vex.json \
  --uri=europe-west1-docker.pkg.dev/lcl-acdc-sbox-e3e1/google-cloud-slsa/hello@sha256:5c5a073c9f4265a6cdbe825404ef0c4cc11ae0f04086e14db03c924c6822123a \
  --project=lcl-acdc-sbox-e3e1 \
  --location=europe-west1
```

### Verification in GCP
* Go to **Artifact Registry** in the Google Cloud Console.
* Click on the target image and digest.
* In the **Vulnerabilities** tab, search for the CVE. It should now appear under the **Exempted (or resolved)** state with the configured summary text.

---

## 🛡️ Step 2: Immediate Configuration in GKE Continuous Validation

Although loading the VEX into Artifact Analysis updates the security assessment eventually (subject to propagation latency), the best practice to prevent GKE Continuous Validation alerts during the propagation window is to exempt the CVE directly in the GKE security rule.

### 1. Add the CVE to the GKE Continuous Validation policy
Edit the [doc/continuous-validation-policy.json](file:///Volumes/Develop/Repos-Jaseran/slsa/google-cloud-slsa/doc/continuous-validation-policy.json) file and add the CVE to the `allowedCves` list under the `vulnerabilityCheck` section:

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

### 2. Apply the update using Terraform
Deploy the updated GKE platform policy:

```bash
cd terraform/
terraform apply -target=restapi_object.continuous_validation_policy -auto-approve
```

---

## 🔍 Exemption Validation

Once the policy is updated and the VEX document is uploaded, you can execute the project's local security scan script to validate the environment status:

```bash
./deploy/check_cve.sh lcl-acdc-sbox-e3e1 europe-west1 CVE-2026-0861
```
