# Feuille de Route Stratégique & Plan d'Évolution MacroscopiX

Ce document définit la trajectoire d'évolution technologique, architecturale et métier de la solution MacroscopiX. Les priorités sont classées de l'urgence industrielle immédiate jusqu'à la vision à long terme.

---

## 🧭 Matrice des Priorités

| Priorité | Horizon | Périmètre | Objectif Principal |
|---|---|---|---|
| **P0 - Critique** | Immédiat (Q4 2026) | **Sécurité & Conformité DSI** | Blindage RGPD des logs (Hash SHA-256) & Préparation Démo Partenaire |
| **P1 - Majeure** | Court terme (Q1 2027) | **Architecture Système v3.0** | Remplacement WebDAV par Presigned URLs S3 & Rationalisation Cloud |
| **P2 - Métier** | Court terme (Q1-Q2 2027) | **Pipeline IA & "Human in the Loop"** | Découplage JSON du worker et interface d'édition interactive (Canvas) |
| **P3 - Intégration** | Moyen terme (Q2-Q3 2027) | **Valorisation Clinique (DictAI)** | Génération automatique de compte-rendu textuel & Optimisation perfs |
| **P4 - Vision** | Long terme (2027+) | **R&D & Segmentation Avancée** | Caméra potence Live, interopérabilité HL7/FHIR et masques polygones |

---

## 🔴 PRIORITÉ 0 : Sécurité, Conformité DSI & Préparation Démo (Immédiat)

*L'objectif est d'éliminer toute objection juridique lors des audits CHU ou des présentations à des partenaires industriels (ex. CliniSys).*

### 1. Anonymisation Cryptographique des Logs Techniques (Hashage SHA-256)
* **Problématique :** La présence du numéro d'examen en clair dans la table `transfer_logs` (hébergée chez Infomaniak) peut être requalifiée par un DPO pointilleux en donnée indirectement nominative.
* **Action :** Remplacer le stockage en clair du numéro de dossier par son empreinte hachée salée : `SHA256(folder_name + salt_organisation)`.
* **Bénéfice :** Traçabilité technique absolue (preuve de bon transfert) sans aucune possibilité pour un tiers ou un auditeur de remonter au patient sans les clés internes du CHU.

### 2. Kit de Démonstration Industrielle "Zero-Risk"
* Configuration d'un profil de démonstration autonome (hotspot 4G dédié, simulateur de partage local SGL) pour garantir des présentations en congrès infaillibles, y compris en cas de réseau saturé.

---

## 🟠 PRIORITÉ 1 : Simplification Architecturale v3.0 (Court Terme)

*L'objectif est de diviser par deux la complexité d'infrastructure, de supprimer les serveurs intermédiaires et de réduire les coûts opérationnels.*

### 1. Élimination de WebDAV au profit des Presigned URLs S3 Directes
* **Architecture actuelle :**  
  Mobile $\rightarrow$ Passerelle WebDAV (WsgiDAV Scalingo HDS) $\rightarrow$ Buffer RAM $\rightarrow$ Boto3 $\rightarrow$ S3 Scaleway $\rightarrow$ Agent Windows via WebDAV.
* **Cible v3.0 (Cloud Native S3 Direct) :**
  1. Le terminal mobile sollicite l'API : `POST /media/upload-url` (métadonnées, type MIME, taille).
  2. L'API retourne une **URL S3 Scaleway pré-signée temporaire (Presigned PUT URL)** signée HMAC (validité 5 min).
  3. Le terminal téléverse directement le flux chiffré vers le bucket Scaleway S3 HDS en HTTPS.
  4. L'agent Windows télécharge directement depuis S3 (via URL GET pré-signée ou compte de service restreint).
* **Gains :**
  - **Suppression intégrale du serveur WebDAV Scalingo** (zéro maintenance de conteneur de calcul).
  - Élimination de tout goulot d'étranglement lors des pics de transfert simultanés.
  - Vitesse et scalabilité natives adossées à l'infrastructure Scaleway.

### 2. Consolidation 100 % Scaleway HDS (Souveraineté France Unique)
* **Architecture actuelle :** Infomaniak (Suisse, non-HDS) + Scalingo (France, HDS) + Scaleway (France, HDS).
* **Cible v3.0 :** Rapatriement de l'API FastAPI, de la base PostgreSQL gérée et du stockage S3 chez **Scaleway France** (région Paris `fr-par`).
* **Gains :** Un seul fournisseur, une seule facture, zéro débat juridique sur l'hébergement en Suisse. Argumentaire DSI : *"100 % hébergé en France sur infrastructure souveraine Scaleway certifiée HDS v2.0 (BSI Group)."*

### 3. Unification de la Stack en Full Python
* Rapatriement de la console d'administration (actuellement en PHP) au sein du projet FastAPI (dashboard admin léger Vue.js ou SQLAdmin).
* **Gains :** Un seul langage (Python), un seul modèle de données SQLAlchemy/Pydantic, un seul conteneur Docker.

---

## 🟡 PRIORITÉ 2 : Pipeline IA & "Human in the Loop" (Court Terme)

*L'objectif est de transformer le prototype de mesure d'organes/fragments en un outil métier validé scientifiquement et ergonomique.*

### 1. Découplage Métier / Rendu (Output JSON Structuré)
* **Problématique :** Le worker IA actuel "brûle" les annotations et les cotes directement dans les pixels de l'image, empêchant toute correction ultérieure.
* **Action :** Le worker renvoie l'image d'origine intacte accompagnée d'un JSON standardisé avec tri ordonné (lecture de haut en bas, gauche à droite) :
```json
{
  "status": "success",
  "metadata": { "processing_time_ms": 1450, "pixel_size_mm": 0.082 },
  "results": {
    "total_fragments": 6,
    "fragments": [
      {
        "id": 1,
        "bounding_box": { "x": 120, "y": 300, "w": 45, "h": 20 },
        "size_mm": { "length": 6.9, "width": 5.5 },
        "confidence": 0.94
      }
    ]
  }
}
```

### 2. Interface de Validation Technicien (Canvas Interactif)
* **Affichage Dynamique :** Superposition dynamique des boîtes englobantes et des cotes millimétrées via Canvas HTML5 (web) ou composant natif (mobile).
* **Outils d'Édition Manuelle :**
  - *Suppression :* Clic sur une boîte pour écarter un faux positif (ex. débris de gaze ou fil).
  - *Ajout manuel :* Outil permettant de tracer un fragment manqué, avec calcul automatique immédiat des millimètres via le ratio de calibration ArUco.
  - *Ajustement :* Redimensionnement des limites si besoin.
* **Validation Finale :** Bouton "Valider les mesures" figeant le JSON corrigé au dossier.

---

## 🟢 PRIORITÉ 3 : Valorisation Clinique & Optimisations (Moyen Terme)

*L'objectif est d'accélérer le flux de travail et d'automatiser la rédaction médicale.*

### 1. Passerelle DictAI (Génération Automatisée de Compte-Rendu)
* **Objectif :** Supprimer la ressaisie fastidieuse des dimensions de fragments dans le compte-rendu macroscopique.
* **Fonctionnement :** Dès validation du JSON par le technicien, DictAI génère automatiquement la trame textuelle exacte :
  > *"Réception à l'état frais d'un prélèvement constitué de 6 fragments tissulaires. Leurs dimensions respectives sont : 17.1 x 11.6 mm, 16.2 x 9.5 mm, 14.3 x 15.4 mm, 12.7 x 9.4 mm, 12.7 x 8.1 mm et 6.9 x 5.5 mm."*
* Le praticien n'a plus qu'à dicter les aspects qualitatifs (lésion, consistance, couleur).

### 2. Optimisation des Temps de Réponse (Latence IA)
* **Compression Client :** Redimensionnement adaptatif sur le smartphone avant téléversement (les modèles n'exigent pas de résolution 4K brute).
* **Allègement Modèle :** Évaluation des variantes légères `YOLO-nano` / `YOLO-small` pour un inférence sous les 500 ms.
* **UX Réactive :** Affichage de squelettes de chargement et d'états d'avancement pour fluidifier la perception utilisateur.

---

## 🔵 PRIORITÉ 4 : Vision & R&D Avancée (Long Terme)

*L'objectif est d'anticiper les futurs usages de laboratoire de pointe.*

1. **Intégration Vidéo Potence (Live Camera) :** Flux vidéo continu sur écran tactile de paillasse avec bouton "Figer & Mesurer" sans contact.
2. **Interopérabilité HL7 / FHIR :** Connecteurs directs pour injection des résultats structurés et comptes-rendus dans les SGL leaders du marché sans intermédiaire de fichiers.
3. **IA par Segmentation Polygonale (Masks) :** Transition de YOLO Détection (rectangles) à YOLO Segmentation (polygones) pour épouser fidèlement les fragments courbés et calculer les surfaces réelles et axes de squelettisation.
