# Synthèse Technique - Dossier de Validation CHU
**Projet : MacroscopiX**  
**Version : 2.5 (Production - Octobre 2026)**  
**Statut : Validé pour exploitation hospitalière**

---

## 📂 Accès aux Documents du Pack (Lecture directe sur GitHub)

- **DATS** ([Version MD](./01_DATS.md) | [Version Word](./docx/01_DATS.docx))
- **Audit Mobile** ([Version MD](./02_Audit_Mobile.md) | [Version Word](./docx/02_Audit_Mobile.docx))
- **Audit API** ([Version MD](./03_Audit_API.md) | [Version Word](./docx/03_Audit_API.docx))
- **Audit Admin** ([Version MD](./04_Audit_Admin.md) | [Version Word](./docx/04_Audit_Admin.docx))
- **Audit WebDAV HDS** ([Version MD](./05_Audit_Webdav_HDS.md) | [Version Word](./docx/05_Audit_Webdav_HDS.docx))
- **Audit Sync Service** ([Version MD](./06_Audit_Sync_Service.md) | [Version Word](./docx/06_Audit_Sync_Service.docx))
- **Schémas d'Architecture** ([Archi.png](./Archi.png))

---

## 1. Présentation du Système
MacroscopiX est une solution mobile institutionnelle permettant l'acquisition sécurisée de données médicales macroscopiques à la paillasse en laboratoire d'Anatomie et Cytologie Pathologiques (ACP) : photographies haute résolution, dictées vocales (Audio WAV) et numérisations documentaires (PDF multi-pages). La solution élimine le "Shadow IT" (utilisation de téléphones personnels sans cadre sécurisé) et automatise l'intégration et le routage des médias dans le Système de Gestion de Laboratoire (SGL) / NAS hospitalier.

## 2. Architecture Technique
L'écosystème repose sur quatre piliers étanches :
1. **Terminal Mobile (Android)** : Application native (Jetpack Compose / Kotlin) gérant l'acquisition multi-modale (photos, audio, PDF) et le chiffrement en RAM/sandbox sans persistance sur le stockage de masse.
2. **API Dispatcher (FastAPI)** : Orchestrateur central gérant l'authentification forte (OTP 6 chiffres, liaison matérielle UUID), la distribution des accès et les logs techniques anonymisés.
3. **Serveur de Transit (WebDAV HDS / S3)** : Passerelle stateless avec buffering mémoire intégrale, filtrage MIME strict et zone d'isolement de sécurité (`_quarantine`).
4. **Agent d'Intégration Local (Windows .NET 8)** : Agent résilient exécutable en service ou session utilisateur (Per-User), opérant en Pull sortant exclusif, avec contrôle d'intégrité octet par octet (`Content-Length`), exclusion catégorique des fichiers en quarantaine, et aiguillage multi-dépôts (Images, PDF, Audio normalisé).

## 3. Sécurité & Confidentialité des Données
La sécurité est au cœur de la conception "Security by Design" de MacroscopiX :
- **Zéro Persistance Mobile** : Aucune donnée de santé (cliché, voix, document scanné) n'est stockée de façon permanente sur le téléphone ni accessible via la galerie publique. Le traitement se fait exclusivement en mémoire vive et cache applicatif privé, purgé dès acquittement.
- **Chiffrement des Flux de Bout en Bout** : Tous les transferts sont chiffrés via TLS 1.2 / TLS 1.3 (HTTPS / WebDAVS).
- **Authentification Forte & Enrôlement Contrôlé** : Validation par OTP à durée de vie limitée (15 minutes) et liaison stricte à l'identifiant matériel (`Device UUID`).
- **Identitovigilance Native** : L'acquisition commence obligatoirement par le scan du code-barres / DataMatrix de la demande d'examen, assurant un nommage automatisé et infalsifiable.
- **Intégrité Binaire & Cloisonnement Quarantaine** : Vérification stricte de la taille des données avant toute suppression cloud, et confinement automatique des éléments suspects sans risque de téléchargement local.

## 4. Modalités d'Hébergement
La solution offre une flexibilité totale pour s'adapter aux politiques des DSI hospitalières :
- **Option Cloud HDS (Recommandée)** : Transit assuré sur des infrastructures souveraines certifiées Hébergeur de Données de Santé en France (Scalingo PaaS HDS + Hosteur S3 HDS). L'agent local rapatrie les flux par HTTPS sortant sans nécessiter d'ouverture de port pare-feu.
- **Option On-Premise (Déléguée)** : Installation de l'instance de transit directement sur l'infrastructure interne du CHU, sous le contrôle exclusif de la DSI.

## 5. État des Fonctionnalités (Production vs R&D)
- **Fonctionnalités Activées en Production (v2.5)** :
  - Capture macroscopique haute résolution et scan de code-barres.
  - Dictaphone médical intégré (enregistrement vocal WAV rattaché au numéro de dossier).
  - Scanner de documents intégré (numérisation et génération PDF multi-pages).
  - Agent de synchronisation Windows multi-dépôts (Photos, Audio, PDF) avec démarrage résilient, exclusion de quarantaine et vérification d'intégrité octet par octet.
  - Normalisation automatique des sous-dossiers audio (suppression des underscores pour compatibilité avec les logiciels de transcription médicale).
- **Modules R&D Embarqués (Évaluation en cours)** : Les modules d'Intelligence Artificielle (**YOLO v8**) pour la segmentation d'organes et les mires de calibration (**ArUco**) pour la métrologie automatique sont embarqués en mode expérimental et feront l'objet d'une phase de validation clinique ultérieure.

---
**Document établi pour servir de base à l'audit technique et à la validation DSI / RSSI / DPO.**

