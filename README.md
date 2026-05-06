# Synthèse Technique - Dossier de Validation CHU
**Projet : MacroscopiX**  
**Version : 2.5 (Production - Mars 2026)**  
**Statut : Validé pour exploitation hospitalière**

---

## 📂 Accès aux Documents du Pack (Lecture directe sur GitHub)

- **DATS** ([Version MD](./01_DATS.md) | [Version Word](./01_DATS.docx))
- **Audit Mobile** ([Version MD](./02_Audit_Mobile.md) | [Version Word](./02_Audit_Mobile.docx))
- **Audit API** ([Version MD](./03_Audit_API.md) | [Version Word](./03_Audit_API.docx))
- **Audit Admin** ([Version MD](./04_Audit_Admin.md) | [Version Word](./04_Audit_Admin.docx))
- **Audit WebDAV HDS** ([Version MD](./05_Audit_Webdav_HDS.md) | [Version Word](./05_Audit_Webdav_HDS.docx))
- **Audit Sync Service** ([Version MD](./06_Audit_Sync_Service.md) | [Version Word](./06_Audit_Sync_Service.docx))
- **Schémas d'Architecture** ([Archi.png](./Archi.png))

---

## 1. Présentation du Système
MacroscopiX est une solution de macroscopie mobile permettant l'acquisition sécurisée de clichés photographiques à la paillasse via des terminaux Android standards. La solution vise à supprimer le "Shadow IT" (utilisation de téléphones personnels sans cadre sécurisé) et à automatiser l'intégration des photos dans le Système de Gestion de Laboratoire (SGL).

## 2. Architecture Technique
L'écosystème repose sur quatre piliers isolés :
1. **Terminal Mobile (Android)** : Application native gérant l'acquisition et le chiffrement en RAM.
2. **API Dispatcher (FastAPI)** : Orchestrateur central gérant l'authentification et la configuration des terminaux.
3. **Serveur de Stockage (WebDAV/S3)** : Réceptacle final des images (HDS ou On-Premise).
4. **Agent de Synchronisation (Windows)** : Service local assurant le transfert transparent des images vers le SGL.

## 3. Sécurité & Confidentialité des Données
La sécurité est au cœur de la conception "Security by Design" de MacroscopiX :
- **Zéro Persistance Mobile** : Aucune donnée de santé (image ou identité) n'est stockée de façon permanente sur le téléphone. Le traitement se fait exclusivement en mémoire vive (RAM).
- **Chiffrement des Flux** : Tous les transferts sont chiffrés via TLS 1.3 (HTTPS/WebDAVS).
- **Authentification Forte** : Double validation via code OTP (One-Time Password) et liaison matérielle unique (Device UUID).
- **Identitovigilance** : L'acquisition commence obligatoirement par le scan du code-barre du dossier patient, garantissant un nommage automatique sans erreur de saisie.

## 4. Modalités d'Hébergement
La solution offre une flexibilité totale pour s'adapter aux exigences des DSI :
- **Option On-Premise** : Installation sur les serveurs internes du CHU (contrôle total des données).
- **Option Cloud HDS** : Hébergement sur une infrastructure certifiée "Hébergeur de Données de Santé" (externalisation sécurisée).

## 5. État des Fonctionnalités (Production vs R&D)
*Note importante pour la validation :*
- **Fonctionnalités Activées** : Capture sécurisée, Scan Code-barre, Nommage dynamique, Transfert SGL, Journalisation des accès.
- **Fonctionnalités en cours de déploiement (R&D)** : Les modules d'Intelligence Artificielle (**YOLO v8**) pour la détection d'organes et les mires de calibration (**ArUco**) pour la mesure automatique ne sont **pas encore activés en production**. Ils feront l'objet d'une validation ultérieure.

---
**Document établi pour servir de base à l'audit technique et à la validation DSI / RGPD.**
