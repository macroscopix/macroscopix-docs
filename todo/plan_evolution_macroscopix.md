# Feuille de Route Technologique : Évolution du Pipeline MacroscopiX

Ce document définit les étapes de restructuration du système de détection des fragments tissulaires. L'objectif est de passer d'un simple script d'analyse d'image (Proof of Concept) à un véritable outil métier interactif, performant et intégrant une étape de validation humaine essentielle dans le milieu médical ("Human-in-the-Loop").

---

## Phase 1 : Séparation des Responsabilités (Backend)
**Problématique actuelle :** Le script *worker* (IA) génère l'image et incruste les annotations de taille et le compteur directement dans les pixels de l'image ("brûlage"). Cela rend la modification a posteriori impossible.

**Objectifs de la phase :**
1. **Déléguer le rendu à l'interface client.** Le worker (actuellement sous Flask avec Ultralytics/OpenCV) ne doit renvoyer que la donnée brute structurée (via l'API centrale).
2. **Implémenter une logique de tri.** Les fragments détectés doivent être numérotés de façon logique (ex: lecture de haut en bas, puis de gauche à droite).

**Spécification de l'API (Output JSON attendu du Worker) :**
Le format de réponse du pipeline IA doit devenir un standard JSON :
```json
{
  "status": "success",
  "metadata": {
    "processing_time_ms": 1450,
    "pixel_size_mm": 0.082
  },
  "results": {
    "total_fragments": 6,
    "fragments": [
      {
        "id": 1,
        "bounding_box": {"x": 120, "y": 300, "w": 45, "h": 20},
        "size_mm": {"length": 6.9, "width": 5.5},
        "confidence": 0.94
      }
    ]
  }
}
```

---

## Phase 2 : Validation Technicien "Human in the Loop" (Frontend)
**Problématique actuelle :** Le système est une "boîte noire" non interactive. En cas de faux positif (ex: un bout de fil ou de gaze reconnu comme fragment), le technicien ne peut pas corriger l'erreur avant la sauvegarde au dossier patient.

**Objectifs de la phase :**
1. **Affichage Dynamique :** 
   - L'application web (Vanilla JS) ou mobile (Kotlin) reçoit l'image d'origine vierge et le JSON depuis l'API FastAPI.
   - Utilisation de `HTML5 Canvas` (sur le web) pour dessiner dynamiquement les boîtes (bounding boxes) et les identifiants (Fragment 1, 2...) en superposition de l'image.
2. **Correction Interactive (Outils d'édition) :**
   - **Suppression :** Clic droit (ou bouton dédié) sur une boîte pour supprimer un faux positif.
   - **Ajout :** Outil "Dessiner" permettant au technicien de tracer une boîte manuellement s'il manque un fragment. La taille (longueur/largeur) est calculée instantanément par l'interface grâce au ratio `pixel_size_mm` fourni dans le JSON.
   - **Ajustement :** (Optionnel) Possibilité d'étirer/réduire une boîte existante.
3. **Soumission (Validation) :** Un bouton "Valider les mesures" enregistre le JSON corrigé et validé par l'humain dans la base de données.

---

## Phase 3 : Optimisation des Performances (Temps de réponse)
**Problématique actuelle :** Le temps de traitement entre la prise de la photo et l'affichage des résultats est trop long, ce qui casse le flux de travail naturel du technicien.

**Pistes d'optimisation :**
1. **Compression en amont :** 
   - Avant l'envoi de la photo au serveur (worker), redimensionner l'image (ex: limiter à 1920x1080) directement côté client/application. La détection YOLO n'a généralement pas besoin d'une résolution 4K.
2. **Allègement des Modèles :**
   - Vérifier le modèle YOLO utilisé (utiliser une version `YOLO-nano` ou `YOLO-small` si la précision reste satisfaisante).
3. **Expérience Utilisateur (UX) pendant l'attente :**
   - Intégrer un feedback visuel robuste (Skeleton loading, barre de progression asynchrone, messages de statut "Détection ArUco...", "Analyse IA...") pour réduire la perception de lenteur.

---

## Phase 4 : Génération Automatisée du Compte Rendu (Intégration DictAI)
**Problématique actuelle :** Après l'étape de macroscopie, le technicien ou médecin doit dicter ou rédiger manuellement un compte-rendu (CR) reprenant exactement le nombre et la taille de tous les fragments mesurés, ce qui est fastidieux et source d'erreurs de saisie.

**Objectifs de la phase :**
1. **Passerelle JSON -> DictAI :** Utiliser le module DictAI pour ingérer le JSON validé par le technicien à l'issue de la Phase 2.
2. **Présentation et Validation Unifiée :** Utiliser l'interface de DictAI comme point central pour afficher l'image macro, superposer les boîtes dynamiquement (JSON), et permettre la validation humaine.
3. **Génération de Trame (Drafting) :** Dès que le technicien clique sur "Valider", DictAI extrait les informations (nombre de fragments, dimensions) et génère automatiquement la base textuelle du compte-rendu macroscopique.
   - *Exemple généré :* "Réception à l'état frais d'un prélèvement constitué de 6 fragments tissulaires. Leurs dimensions respectives sont : 17.1 x 11.6 mm, 16.2 x 9.5 mm, 14.3 x 15.4 mm, 12.7 x 9.4 mm, 12.7 x 8.1 mm et 6.9 x 5.5 mm."
4. **Gain de temps :** L'utilisateur n'a plus qu'à compléter cette trame pré-remplie (par dictée vocale ou au clavier) avec d'autres détails macroscopiques (couleur, aspect, etc.).

---

## Vision à Long Terme : Évolutions Futures
Pour fluidifier au maximum le travail du technicien et améliorer la qualité biométrique :
- **Intégration Flux Vidéo (Live Camera) :** Remplacer la "prise de photo" par une caméra montée en potence. L'écran tactile affiche la vidéo en direct. Un bouton "Capturer et Analyser" fige l'image, l'envoie au modèle et affiche instantanément les boîtes correctibles sur l'écran tactile.
- **Interopérabilité HL7 :** Ajout d'un bouton "Envoyer" à la fin du flux DictAI pour transmettre automatiquement le compte-rendu macroscopique finalisé vers le Système de Gestion de Laboratoire (SGL / LIS) tiers.
- **Évolution IA vers la Segmentation :** Passer de YOLO "Détection" (bounding boxes) à YOLO "Segmentation" (polygones). Cela permettra de mesurer précisément les fragments courbes ou positionnés en biais grâce au calcul du rectangle orienté minimum (minAreaRect) et de la squelettisation.

---

## Phase 5 : Feuille de Route Architecture & Simplification Système (v3.0)

Cette section planifie la simplification technique et la rationalisation de l'infrastructure globale MacroscopiX en vue du passage à l'échelle industrielle ou d'une cession/partenariat de licence (ex. CliniSys).

### 1. Simplification du Transit Données : Suppression de WebDAV et Passage aux Presigned URLs S3

* **Architecture actuelle :**  
  Mobile $\rightarrow$ Passerelle WebDAV (Python WsgiDAV Scalingo) $\rightarrow$ Buffer RAM $\rightarrow$ Boto3 vers S3 Scaleway $\rightarrow$ Agent local Windows via requêtes WebDAV.
* **Problématique :**  
  Nécessite un dyno/serveur de calcul dédié permanent, point de contention potentiel lors de téléversements simultanés volumineux (PDF, audio WAV, images HD).
* **Cible v3.0 (Cloud Native S3 Direct) :**
  1. L'application mobile contacte l'API FastAPI : `POST /media/upload-url` avec les métadonnées (nom de fichier, type MIME, taille).
  2. L'API génère une **URL pré-signée S3 Scaleway temporaire (Presigned PUT URL)** avec signature cryptographique HMAC valide 5 à 10 minutes.
  3. Le terminal téléverse directement le flux chiffré vers le bucket Scaleway S3 HDS en HTTPS standard.
  4. L'agent Windows `MacroscopixSync` récupère la liste des objets via l'API et télécharge directement les fichiers depuis S3 (via URL GET pré-signée ou compte de service restreint).
* **Bénéfices :**
  - **Suppression intégrale du serveur WebDAV intermédiaire** (zéro maintenance WsgiDAV/Cheroot).
  - Économie directe de coûts de calcul (PaaS).
  - Bande passante et scalabilité maximales adossées à l'infrastructure réseau de Scaleway.

### 2. Unification de la Stack Backend & Administration (Full Python)

* **Architecture actuelle :**  
  - API Dispatcher : FastAPI (Python 3.x).
  - Console d'administration Web : PHP 8.x + templates classiques.
  - Deux codebases distincts interagissant avec la même base de données PostgreSQL.
* **Cible v3.0 :**
  - Rapatriement de la console d'administration au sein du projet FastAPI (soit via une interface d'administration intégrée type SQLAdmin/FastAPI-Admin, soit via un dashboard léger Vue.js/React consommant l'API).
* **Bénéfices :**
  - **Unicité technologique :** 100 % Python (FastAPI / SQLAlchemy / Pydantic).
  - Fin de la duplication des modèles de données et requêtes SQL entre PHP et Python.
  - Déploiement et conteneurisation simplifiés en une seule image Docker.

### 3. Consolidation d'Hébergement Souverain : 100 % Scaleway HDS (France)

* **Architecture actuelle :**  
  - Infomaniak (Suisse) : API, Admin, PostgreSQL (Non-HDS).
  - Scalingo (France) : Passerelle WebDAV (HDS v2.0).
  - Scaleway (France) : S3 Object Storage (HDS v2.0).
* **Cible v3.0 :**
  - Rapatriement de l'ensemble de la stack chez **Scaleway France** (région Paris `fr-par`) :
    - API FastAPI + Admin : Conteneur Serverless / Kapsule (Kubernetes) certifié HDS.
    - Base de données PostgreSQL : Managed Database Scaleway.
    - Stockage fichiers : Scaleway S3 Object Storage HDS.
* **Bénéfices :**
  - **Un seul fournisseur, une seule facture, une seule console Cloud.**
  - **Blindage juridique face aux DSI/RSSI :** Élimine toute discussion sur la Suisse ou les serveurs non-HDS. L'argumentaire institutionnel tient en une phrase : *"Solution 100 % hébergée en France sur infrastructure souveraine Scaleway certifiée HDS v2.0 (BSI Group)."*

### 4. Anonymisation Renforcée des Logs Techniques (Hashage SHA-256)

* **Objectif :** Rendre la table `transfer_logs` totalement inattaquable sur le plan du RGPD et du secret médical.
* **Mise en œuvre :** Le numéro d'examen/dossier patient (`folder_name`) n'est plus enregistré en clair, mais sous forme d'empreinte hachée salée (`SHA256(folder_name + salt_organisation)`).
* **Bénéfice :** Garantit la traçabilité technique (vérification qu'un prélèvement a bien été transféré) sans aucune possibilité pour un tiers ou un auditeur externe de corréler le log sans accès interne au SGL du CHU.
