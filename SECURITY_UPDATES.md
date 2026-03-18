# Guide de mise à jour des dépendances et de sécurité

Ce document détaille la procédure pour corriger les vulnérabilités (CVE) en mettant à jour les dépendances Go et les images Docker de base.

## 1. Mise à jour des dépendances Go

Pour corriger les vulnérabilités au niveau du code applicatif, suivez ces étapes dans le répertoire de l'application (ex: `app/`) :

### Étapes :
1. **Mise à jour automatique** :
   ```bash
   go get -u ./...
   ```
2. **Nettoyage du fichier `go.mod`** (supprime les dépendances inutilisées et met à jour la version de Go si nécessaire) :
   ```bash
   go mod tidy
   ```
3. **Mise à jour du dossier `vendor`** (si votre projet l'utilise, comme c'est le cas ici) :
   ```bash
   go mod vendor
   ```
4. **Validation par les tests** :
   ```bash
   go test ./...
   ```

---

## 2. Mise à jour des images Docker

L'utilisation d'images de base obsolètes est la source principale de CVE. Il est recommandé d'utiliser des images "Distroless" pour l'image finale afin de réduire la surface d'attaque.

### Étapes :
1. **Identifier les nouvelles versions** : Recherchez les dernières versions stables (ex: `golang:1.24`, `debian12`).
2. **Récupérer les Hash SHA256** (pour garantir l'immuabilité et la sécurité) :
   ```bash
   docker pull golang:1.24
   docker inspect --format='{{index .RepoDigests 0}}' golang:1.24
   ```
3. **Mettre à jour le `Dockerfile`** :
   Remplacez les anciennes valeurs par les nouveaux SHAs :
   ```dockerfile
   ARG BUILD_BASE=golang@sha256:<nouveau_hash>
   ARG FINAL_BASE=gcr.io/distroless/static-debian12@sha256:<nouveau_hash>
   ```

---

## 3. Mise à jour de la CI/CD (Cloud Build)

Assurez-vous que vos outils de build et de test utilisent les mêmes versions que votre environnement de développement.

*   Modifiez le fichier `cloudbuild.yaml` pour que l'étape `test` utilise la nouvelle image `golang` épinglée par son SHA.

---

## 4. Gestion de la Politique de Sécurité (Kritis)

Une fois les mises à jour effectuées, vous devez réévaluer les exceptions de sécurité :

1. **Lancer un scan** : Exécutez votre pipeline de build.
2. **Nettoyer l'allowlist** : Si des CVE étaient listées dans `policy/vulnz-signing-policy.yaml`, vérifiez si elles sont toujours présentes.
3. **Supprimer les CVE corrigées** : Retirez les identifiants CVE de l'allowlist pour garantir qu'elles ne soient pas réintroduites à l'avenir.

---

## Résumé des bonnes pratiques
*   **Épinglage (Pinning)** : Toujours utiliser le hash SHA256 des images Docker plutôt que des tags mobiles (comme `latest` ou `1.24`).
*   **Fréquence** : Effectuez ces mises à jour au moins une fois par mois ou dès qu'une CVE critique est annoncée.
*   **Automatisation** : Utilisez des outils comme Dependabot ou Renovate si possible pour automatiser ces découvertes.
