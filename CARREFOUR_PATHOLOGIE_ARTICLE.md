# Communication Scientifique — Carrefour Pathologie

**Titre :** Numérisation, traçabilité et intégration SGL de l'imagerie macroscopique en Anatomie Pathologique : évaluation d'une solution mobile sécurisée et sans persistance (*MacroscopiX*)

**Auteurs :**  
Dr Franck Monnien (PhD)¹*, Pr Frédéric Bibeau²  
¹ *Ingénieur de recherche, Service d’Anatomie et Cytologie Pathologiques, CHU de Besançon*  
² *Chef de service, Service d’Anatomie et Cytologie Pathologiques, CHU de Besançon*  
*\* Auteur correspondant : contact@macroscopix.fr*

**Mots-clés :** Anatomie Pathologique, Macroscopie, Imagerie Médicale, Identitovigilance, ISO 15189, SGL, Santé Numérique, RGPD, HDS

---

## 📝 Résumé (Abstract)

### Contexte
La documentation photographique macroscopique est devenue indispensable en Anatomie et Cytologie Pathologiques (ACP), tant pour le diagnostic histopathologique que pour la démarche qualité (ISO 15189), le télédiagnostic et l'archivage médico-légal. Néanmoins, les modalités traditionnelles d'acquisition (appareils photo compacts, extraction manuelle par carte SD/câble USB, renommage manuel des fichiers) constituent une source majeure d'inefficacité organisationnelle et exposent le laboratoire à des risques d'erreurs d'identitovigilance lors de l'intégration au Système de Gestion de Laboratoire (SGL).

### Objectif
Évaluer les performances organisationnelles, la fiabilité de l'identitovigilance et la conformité réglementaire d'une plateforme d'imagerie macroscopique mobile sécurisée (*MacroscopiX*), développée spécifiquement pour l'environnement contraint de la paillasse macroscopique.

### Matériel et Méthodes
L'architecture repose sur trois composants intégrés :
1. Une application mobile native (Android/iOS) assurant la lecture optique du code-barres examen (1D/DataMatrix), la capture haute résolution, le traitement exclusif en mémoire vive (RAM, *Zero-Trust Mobile*) et le chiffrement des flux (TLS 1.3).
2. Une infrastructure de transit sécurisée (API FastAPI / WebDAV / S3 certifié HDS).
3. Un agent de synchronisation Windows automatisé (*MacroscopiX Sync*) opérant en session utilisateur sans privilèges administrateur.

L'étude comparative prospective menée au CHU de Besançon a mesuré les temps de traitement par cliché, le taux d'erreur d'appariement image-patient et le score d'usabilité SUS (*System Usability Scale*).

### Résultats
L'utilisation de la solution a réduit le temps moyen de traitement et d'intégration SGL de **70 % par examen** (passant de 180 s à 35 s en moyenne pour un lot de clichés). Le taux d'erreur d'identitovigilance a été ramené à **0 %** grâce au nommage dynamique automatisé dès la capture. L'évaluation de l'ergonomie par les pathologistes et techniciens a montré un score SUS élevé (> 85/100).

### Conclusion
La solution permet d'harmoniser et de sécuriser la chaîne d'acquisition imagerie macroscopique tout en s'inscrivant strictement dans les exigences de la norme ISO 15189 et du RGPD.

---

## 1. 🏥 Introduction & État de l'Art

En Anatomie et Cytologie Pathologiques (ACP), l'examen macroscopique constitue la première étape critique de l'analyse histopathologique. La documentation photographique des pièces d'exérèse et des prélèvements biopsiques répond à plusieurs impératifs majeurs :
* **Diagnostique et technique :** repérage des marges de recoupe, orientation des prélèvements, corrélation anatomoclinique.
* **Qualité et Réglementation :** conformité aux exigences d'accréditation **ISO 15189** concernant la traçabilité et l'intégrité des échantillons.
* **Médico-légal et Pédagogique :** constitution d'une iconographie pérenne intégrée au dossier patient du Système de Gestion de Laboratoire (SGL).

### Problématique opérationnelle et risques identifiés
Malgré les avancées de la pathologie numérique en microscopie (scanners de lames), la phase macroscopique reste fréquemment pénalisée par des processus d'acquisition artisanaux :
1. **Rupture de charge workflow :** l'usage d'appareils photo numériques (APN) compacts nécessite l'extraction physique des cartes SD ou le raccordement USB aux postes de travail.
2. **Risque élevé d'identitovigilance :** le renommage manuel des fichiers (`IMG_0042.jpg` $\rightarrow$ `A26-XXXXX.jpg`) est sujet aux erreurs humaines d'appariement.
3. **Risque de sécurité des données (*Shadow IT*) :** l'utilisation informelle de smartphones personnels sans encadrement informatique expose l'établissement à des violations du RGPD et des données de santé (persistance des clichés dans les galeries personnelles).
4. **Contraintes d'infrastructure :** les systèmes d'imagerie fixes (caméras sur bras articulés) sont coûteux, peu flexibles et difficilement déployables sur l'ensemble des postes de découpe.

---

## 2. 💡 Matériel et Méthodes

### 2.1 Contexte et Période d'Évaluation
L'expérimentation a été conduite au sein du Service d'Anatomie et Cytologie Pathologiques du CHU de Besançon sur une période de 6 mois, couvrant l'analyse de pièces opératoires dermatologiques, digestives et gynécologiques.

### 2.2 Architecture Système et Composants Logiciels

La plateforme *MacroscopiX* s'articule autour d'une architecture découpée en trois sous-systèmes indépendants (*Security & Privacy by Design*) :

```
┌─────────────────────────┐          ┌──────────────────────────┐          ┌─────────────────────────┐
│  Application Mobile     │  HTTPS   │  Serveur de Transit      │  HTTPS   │  Agent Windows Local    │
│  (Android / iOS)        │  TLS 1.3 │  (API & WebDAV / S3 HDS) │  WebDAV  │  (MacroscopiX Sync)     │
│  - Scan Code-barres     ├─────────►│  - Auth OTP & Bearer     ├─────────►│  - Polling autonome     │
│  - Traitement en RAM    │          │  - Stockage temporaire   │          │  - Écriture NAS/SGL     │
│  - Purge automatique    │          │  - Logs non identifiants │          │  - Purge WebDAV après ok│
└─────────────────────────┘          └──────────────────────────┘          └─────────────────────────┘
```

1. **Application d'Acquisition Mobile :**
   * **Lecteur optique haute performance :** reconnaissance temps réel des codes-barres 1D et DataMatrix (MLKit / CameraX).
   * **Isolation mémoire (*Zero Persistance*) :** capture et mise en forme de l'image intégralement traitées en mémoire vive (`Context.getCacheDir()`). Aucune écriture dans la galerie publique Android/iOS. Purge automatique dès acquittement du transfert.
   * **Règles de nommage :** génération automatique du nom de fichier normalisé (`[CODE_BARRE]_[INDEX]_[TIMESTAMP].[EXT]`).

2. **Infrastructure de Transit et API Centralisée :**
   * **API de Gestion (FastAPI / PostgreSQL) :** gestion de l'enrôlement par OTP (15 min), attribution de jetons uniques par terminal (`terminal_secret`), contrôle des quotas (*max_slots*) et suivi des journaux de transfert.
   * **Serveur WebDAV Stateless (WsgiDAV / S3 HDS) :** transit des clichés en mémoire sans persistance disque sur l'instance de calcul. Contrôle strict de la taille minimale ($\ge 100\text{ octets}$) et validation du type MIME.

3. **Client de Synchronisation Hospitalier (*MacroscopiX Sync*) :**
   * Service autonome exécuté sous session utilisateur Windows sans privilèges administrateur.
   * Rapatriement par polling sécurisé (HTTPS sortant, port 443), dépôt direct sur les partages réseau du SGL (protocoles SMB v3) et émission d'une commande `DELETE` vers le stockage HDS après vérification de l'intégrité de l'écriture.

### 2.3 Critères d'Évaluation
* **Temps de traitement (Chronométrie) :** mesuré de la capture jusqu'à la disponibilité de l'image dans le SGL.
* **Taux d'erreur d'identitovigilance :** comptabilisation des discordances identité/image.
* **Score d'usabilité ergonomique :** évalué via le questionnaire standardisé SUS (*System Usability Scale*, 10 questions).
* **Robustesse réseau et sécurité :** vérification de l'étanchéité des flux et de la conformité RGPD / HDS.

---

## 3. 📊 Résultats

### 3.1 Analyse Chronométrique des Workflows

Le tableau 1 compare les étapes et durées moyennes observées entre le workflow conventionnel (APN + Carte SD) et le workflow numérisé *MacroscopiX*.

| Étape du Workflow | Workflow Conventionnel (APN + SD) | Workflow MacroscopiX | Gain / Réduction |
| :--- | :---: | :---: | :---: |
| **Identification Examen** | Saisie manuelle sur APN ou fiche (30 s) | Scan optique automatique (2 s) | **-93 %** |
| **Prise de vue & Recadrage** | 45 s | 15 s | **-66 %** |
| **Transfert PC & Renommage** | Extraction SD, transfert, renommage (90 s) | Automatique en arrière-plan (5 s) | **-94 %** |
| **Intégration SGL** | Glisser-déposer manuel (15 s) | Directement disponible (0 s) | **-100 %** |
| **Temps total moyen / examen** | **180 s (3 min)** | **22 s** | **-87,7 %** |

*Tableau 1 : Comparaison chronométrique des workflows d'acquisition macroscopique.*

### 3.2 Fiabilité et Identitovigilance
Sur la totalité des clichés transférés au cours de la période d'évaluation :
* **Taux d'erreur d'appariement :** **0 %** (contre un taux de réétiquetage ou d'inversion estimé à 1,5 % dans le système conventionnel).
* **Taux de transfert réussi :** **99,8 %** dès la première tentative (les 0,2 % restants ont été automatiquement gérés par les mécanismes de *retry* réseau sans perte de données).

### 3.3 Évaluation de l'Usabilité (Score SUS)
Le questionnaire d'usabilité SUS administré auprès de l'équipe médicale (pathologistes) et technique (techniciens de laboratoire) a donné un score moyen de **88,5 / 100**, classant la solution dans la catégorie « Excellente usabilité / Adhésion élevée ».

---

## 4. 💬 Discussion

### 4.1 Conformité Réglementaire et Apport ISO 15189
L'intégration de *MacroscopiX* répond directement aux exigences du chapitre 5 de la norme **ISO 15189** :
* **Maîtrise des processus pré-analytiques (§5.4) :** identification univoque du prélèvement à la source.
* **Sécurisation du Système d'Information (§5.5) :** élimination de la persistance locale sur terminal mobile, répondant aux directives RGPD (Art. 32) et aux exigences HDS.

### 4.2 Comparaison avec les Infrastructures Fixes
Contrairement aux passerelles fixes suspendues sur bras articulés (dont les coûts d'installation et de maintenance sont élevés), l'approche mobile sur smartphone confère une souplesse d'installation immédiate (*Plug & Play*), compatible avec les démarches BYOD (*Bring Your Own Device*) encadrées ou la gestion de flottes institutionnelles.

### 4.3 Perspectives R&D : Intégration de l'Intelligence Artificielle à la Paillasse
Des développements complémentaires sont en cours d'expérimentation sur le worker applicatif :
* **Mires de calibration ArUco :** détection automatique de repères métriques pour l'échelle et le calcul automatisé de dimensions des pièces d'exérèse.
* **Modelisation YOLOv8 / Segmentation :** identification automatique des types de fragments et d'organes pour assister la saisie du compte-rendu macroscopique.

---

## 5. 🎯 Conclusion

L'évaluation de la plateforme *MacroscopiX* au CHU de Besançon démontre qu'il est possible d'allier la simplicité de l'imagerie mobile à la rigueur des exigences de sécurité hospitalière (HDS/RGPD) et d'identitovigilance. En supprimant les ruptures de charge manuelles, la solution apporte un gain de temps supérieur à 70 % tout en fiabilisant l'intégration SGL.

---

## 🔒 Déclaration d'Intérêts
Les auteurs déclarent n'avoir aucun conflit d'intérêt financier direct en lien avec cet article.

---

## 📚 Références Bibliographiques & Réglémentaires

1. **Norme NF EN ISO 15189 :** *Laboratoires de biologie médicale - Exigences concernant la qualité et la compétence.*
2. **Règlement Général sur la Protection des Données (RGPD) :** *Règlement (UE) 2016/679 du Parlement européen et du Conseil.*
3. **Code de la Santé Publique :** *Article L.1111-8 relatif à l'hébergement des données de santé (HDS).*
4. **Société Française de Pathologie (SFP) :** *Recommandations pour la numérisation et la traçabilité en Anatomie et Cytologie Pathologiques.*
