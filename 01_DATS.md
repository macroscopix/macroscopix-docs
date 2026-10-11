## Dossier d'Architecture Technique et de Sécurité (DATS)

**Projet :** MacroscopiX\
**Version :** 2.5 (Production)\
**Date :** 11 octobre 2026\
**Confidentialité :** Interne / Diffusion restreinte -- DSI / RSSI CHU

------------------------------------------------------------------------

## 1. Présentation de la solution

MacroscopiX est une solution mobile sécurisée permettant l'acquisition et
le transfert de données médicales macroscopiques (photographies haute résolution,
dictées vocales / comptes-rendus audio, et numérisations de documents / fiches de demande PDF)
depuis un smartphone vers le Système d'Information Hospitalier (SIH),
sans persistance des données sur le terminal (02_Audit_Mobile.md).

La solution s'inscrit dans un cadre institutionnel maîtrisé, conforme
aux exigences HDS et RGPD, et vise à encadrer des usages terrain
existants en les sécurisant.

### 1.1 Enrôlement et identification des terminaux

Avant toute utilisation, l'application MacroscopiX, signée et distribuée
via le Google Play Store, fait l'objet d'un processus d'enrôlement
contrôlé permettant d'identifier, d'autoriser et de tracer les terminaux
habilités à capturer des données médicales.

- L'établissement désigne **un ou plusieurs référents d'enrôlement**
  (ex. cadre de santé, responsable de secteur, référent informatique).

- Pour chaque référent, une **adresse email institutionnelle
  nominative** est communiquée lors de la mise en service.

- Les référents sont habilités à :
  - initier l'enrôlement d'un terminal mobile,
  - valider l'association entre un terminal et l'établissement.

Le processus d'enrôlement repose sur une authentification forte (OTP à 6 chiffres
valable 15 minutes) et permet de générer un identifiant technique unique pour chaque terminal,
associé à un jeton d'authentification délivré via l'API dédiée
(03_Audit_API.md, 04_Audit_Admin.md).

Cet identifiant est utilisé pour :
- l'authentification de l'application,
- le contrôle d'accès aux flux de données de santé (liaison matérielle stricte Device UUID / Organisation).

### 1.2 Cycle de vie et Procédure de Révocation des Terminaux

La maîtrise de la flotte mobile et du parc BYOD impose des mécanismes de révocation instantanés et déterministes. MacroscopiX prend en compte tous les scénarios de rupture d'habilitation :

#### Scénarios de Révocation et Réponses du Système

1. **Perte, Vol ou Compromission du Terminal :**
   - **Action Référent / Administrateur :** Depuis la console d'administration (`admin.macroscopix.fr`) ou via l'API sécurisée (`DELETE /terminals/{uuid}`), l'administrateur technique révoque le terminal en un clic.
   - **Effet Serveur Immédiat :** Le `terminal_secret` (Bearer Token) est purgé de la table des terminaux autorisés et son statut bascule à inactif.
   - **Blocage des Flux :** Toute tentative d'authentification (`/check-auth`) ou de journalisation (`/log-transfer`) est immédiatement rejetée avec une erreur **HTTP 401 Unauthorized**.
   - **Dissociation Matérielle :** L'association entre le `device_uuid` matériel et l'établissement est rompue, libérant instantanément le slot de licence de l'organisation (`max_slots`).
   - **Protection des Données :** En vertu du principe de **Zéro Persistance**, aucun cliché, dictée ou document médical ne réside sur le stockage interne ou dans la galerie du téléphone égaré.

2. **Désinstallation ou Réinitialisation par l'Utilisateur :**
   - **Côté Terminal Mobile :** La désinstallation de l'application détruit définitivement les clés privées et secrets d'accès logés dans le **Keystore Android** sécurisé.
   - **Révocation Volontaire (Déconnexion de l'App) :** L'application dispose d'un bouton de déconnexion / désenrôlement explicite appelant la route `/revoke-terminal` (avec en-tête `Authorization: Bearer <secret>`). Le secret de session est instantanément invalidé en base centrale et le cache sandbox local est intégralement purgé.

3. **Renouvellement d'Appareil / Ré-enrôlement :**
   - Si un utilisateur change de smartphone ou le réinitialise (générant un nouvel UUID), un nouvel OTP envoyé à l'adresse institutionnelle nominative du référent est requis pour valider le nouveau couple matériel.
   - L'ancien terminal peut être soit écrasé proprement via le même nom d'équipement (`friendly_name`), soit révoqué préalablement pour libérer le quota de licences.

### 1.3 BYOD et Mobilité Sécurisée

L'application MacroscopiX a été conçue pour un accès BYOD (Bring Your
Own Device) lorsque cela est compatible avec la politique du Système
d'Information de l'établissement via 4G/5G ou réseau Wi-Fi dédié. Les conditions sont les
suivantes :

- Le terminal doit être préalablement enrôlé et validé par un référent
  désigné de l'établissement.

- Les données de santé transitent exclusivement via l'infrastructure HDS
  MacroscopiX (05_Audit_Webdav_HDS.md) et utilisent le service
  MacroscopixSync (06_Audit_Sync_Service.md).

Cette approche permet aux praticiens d'utiliser leurs smartphones
tout en assurant la sécurité, la traçabilité et la
conformité HDS des données de santé.

### 1.4 Contexte clinique et flux de travail multi-modal

L'application est destinée à être utilisée en **laboratoire d'Anatomie
et Cytologie Pathologiques (ACP)**, environnement technique contraint
(manipulation de formol, port de gants, risques chimiques) nécessitant
des outils rapides, robustes et ergonomiques, compatibles avec un usage
« sans contact ».

Workflow sécurisé type :

1.  **Identification (entrée)**\
    Le praticien scanne le code-barres ou le DataMatrix du dossier
    (numéro d'examen) directement sur la demande d'examen. L'absence de
    saisie manuelle élimine les risques d'erreurs d'identitovigilance.

2.  **Acquisition multi-modale** :
    - **Photographies macroscopiques** : Clichés haute résolution des pièces opératoires
      et prélèvements avec recadrage et balance des blancs optimisée.
    - **Dictaphone intégré** : Enregistrement vocal des descriptions macroscopiques
      (format WAV audio haute fidélité) rattaché au numéro de prélèvement.
    - **Scanner documentaire** : Numérisation des ordonnances, comptes-rendus extérieurs
      ou feuilles de transmission au format PDF multi-pages.

3.  **Transfert (sortie)**\
    Envoi immédiat et automatique des fichiers vers le serveur sécurisé WebDAV HDS
    (timeouts réseau configurés à 120s pour résister aux liaisons hospitalières instables).

4.  **Purge immédiate**\
    Suppression automatique et irréversible des fichiers de la mémoire vive et du cache
    chiffré du terminal dès réception de l'acquittement HTTP 201/204 du serveur.

5.  **Aiguillage et intégration au SI hospitalier**\
    L'agent local MacroscopixSync rapatrie les fichiers et les achemine vers les répertoires
    cibles appropriés du Système de Gestion de Laboratoire (SGL) / NAS :
    - Dossier Images : Répertoire racine configuré (`LocalPath`).
    - Dossier Documents PDF : Répertoire dédié (`PdfLocalPath`).
    - Dossier Audio : Répertoire de dictée (`AudioLocalPath`), avec normalisation automatique
      des sous-dossiers (suppression des underscores type `DossierPrelevement` pour compatibilité
      avec les logiciels de transcription médicale).

#### Objectifs de sécurité majeurs

- **Zéro persistance :** aucune donnée de santé n'est conservée sur le
  terminal mobile après le transfert.
- **Cloisonnement strict :** séparation physique et logique entre les
  flux d'administration (FastAPI / PHP) et les flux de données de santé (WebDAV HDS / S3).
- **Intégrité et confidentialité :** chiffrement des flux réseau de bout
  en bout (TLS ≥ 1.2, TLS 1.3 privilégié).
- **Contrôle d'intégrité strict avant purge cloud :** comparaison octet par octet
  (`Content-Length`) avant toute suppression sur le serveur HDS.
- **Isolation de sécurité et quarantaine :** exclusion absolue des répertoires
  de quarantaine (`_quarantine`) côté client local, interdisant le rapatriement ou
  l'effacement de fichiers mis à l'isolement sur le cloud.

### 1.5 Enjeux et bénéfices institutionnels

Le déploiement de MacroscopiX répond à plusieurs objectifs stratégiques
pour l'établissement :

- **Besoin terrain identifié :** réponse à un besoin opérationnel réel
  d'acquisition rapide et standardisée d'images, dictées et documents au poste de travail (paillasse).
- **Mobilité et efficacité :** centralisation des flux iconographiques et audio
  sans infrastructure matérielle lourde ni poste fixe dédié.
- **Rationalisation économique :** alternative agile aux caméras sur potence et dictaphones
  dédiés propriétaires.
- **Encadrement des pratiques (Shadow IT) :** sécurisation et
  formalisation d'usages existants dans un cadre validé par la DSI et le RSSI.
- **Innovation pragmatique :** démarche d'amélioration continue de la
  qualité des soins et de traçabilité médico-légale des prélèvements.

------------------------------------------------------------------------

## 2. Architecture Globale et Ségrégation des Flux

L'architecture de MacroscopiX repose sur une **ségrégation stricte**
(logique et physique) des composants, garantissant une étanchéité totale
entre la gestion administrative et le traitement des données de santé.

### 2.1 Structuration en Zones Distinctes

La solution s'articule autour de deux environnements isolés :

- **Zone d'Administration (Non-HDS) :** Ce périmètre gère exclusivement
  les métadonnées techniques (enrôlement des terminaux, licences, logs
  techniques anonymisés). Il ne voit jamais passer de données de santé,
  d'images ou d'enregistrements audio. L'accès administrateur est protégé par une
  authentification forte (2FA / TOTP).

- **Zone de Transit HDS :** Cet environnement est dédié au transit et au
  stockage temporaire des données médicales sur des infrastructures
  certifiées **HDS (Hébergeur de Données de Santé)**. L'architecture
  est dite **stateless** : les données sont purgées dès que le transfert
  vers le SIH est validé octet par octet.

![](media/image1.png){width="6.497222222222222in"
height="3.6534722222222222in"}

### 2.2 Flexibilité d'Hébergement et Responsabilités

La solution offre deux modes de déploiement pour s'adapter aux
politiques de sécurité de l'établissement :

1.  **Modèle Standard (Cloud HDS) :** Le transit est assuré par les
    serveurs certifiés MacroscopiX (Scalingo compute HDS + Hosteur S3 HDS). Le service
    **MacroscopixSync** assure la passerelle descendante vers le stockage local via un flux
    HTTPS sortant exclusif.

2.  **Modèle Délégué (On-Premise) :** L'environnement de transit est
    hébergé directement par le CHU (via une URL WebDAV interne en
    HTTPS). Dans cette configuration :
    - Le service **MacroscopixSync** peut être utilisé en réseau local ou remplacé par
      les scripts de transfert internes du CHU.
    - La sécurité périmétrique (WAF, reverse proxy, filtrage IP,
      limitation de débit) et la conformité HDS incombent alors
      entièrement à la DSI du CHU.

### 2.3 Connectivité et Politique d'Usage (BYOD vs Flotte Institutionnelle)

- **Scénario BYOD (4G/5G / Wi-Fi Invité) :**
  L'utilisation de terminaux mobiles professionnels ou personnels est sécurisée par le fait
  qu'aucun fichier ne persiste en mémoire flash locale (purge mémoire immédiate après téléversement),
  les identifiants sont protégés par le Keystore matériel, et tous les flux sont chiffrés en TLS 1.2/1.3.

- **Réseau Wi-Fi CHU :**
  Si le terminal est raccordé au réseau Wi-Fi hospitalier, les flux sortants vers les sous-domaines
  `*.macroscopix.fr` sur le port 443 doivent être autorisés sur le filtrage réseau / proxy de l'établissement.
  L'application intègre des délais de garde réseau étendus (120 secondes) évitant les échecs lors des
  transitions de bornes Wi-Fi.

------------------------------------------------------------------------

## 3. Matrice des flux et des ports

| Source | Destination | Protocole | Port | Description | Données de santé |
|---|---|---|---|---|---|
| Application Android | API d'enrôlement (`api.macroscopix.fr`) | HTTPS | 443 | Configuration, OTP, vérification token, logs techniques anonymisés | Non |
| Application Android | Serveur WebDAV (`hds.macroscopix.fr`) | HTTPS | 443 | Téléversement (PUT) des photos, fichiers audio WAV et documents PDF | Oui |
| Agent MacroscopixSync (Windows) | Serveur WebDAV (`hds.macroscopix.fr`) | HTTPS | 443 | Téléchargement séquentiel (GET), vérification de taille, et suppression (DELETE) | Oui |
| Agent MacroscopixSync (Windows) | Stockage Local CHU (NAS / SGL) | SMB v3 / NTFS | 445 / Local | Dépôt ventilé des fichiers (Images, PDF, Audio) | Oui (Intra-CHU) |
| Console d'administration | API d'enrôlement | HTTPS | 443 | Gestion des licences et des terminaux | Non |

**Note importante :** aucun flux entrant n'est requis sur le pare-feu du
CHU. L'ensemble des connexions est initié en sortie (HTTPS standard sortant port 443).

------------------------------------------------------------------------

## 4. Mesures de sécurité mises en œuvre

### 4.1 Sécurité sur le terminal mobile

- **Traitement en mémoire vive et cache éphémère :** Les clichés, enregistrements audio
  et scans PDF sont manipulés en RAM ou dans le sandbox applicatif privé isolé.
- **Suppression immédiate :** Effacement automatique dès confirmation du transfert WebDAV.
- **Absence de stockage local :** Aucune inscription dans la galerie publique Android
  ni dans les répertoires partagés du système.
- **Protection des secrets :** Stockage des identifiants et jetons dans
  le Android Keystore avec protection matérielle (TEE / StrongBox).
- **Obfuscation du code :** Minification et obfuscation complètes via R8 / ProGuard.
- **Résilience réseau :** Timeouts HTTP calibrés à 120s pour sécuriser les téléversements
  de fichiers volumineux (PDF multi-pages, audio WAV) sans corruption.

### 4.2 Sécurité des communications

- **Chiffrement TLS 1.3** (TLS 1.2 minimum avec suites cryptographiques robustes).
- **Authentification forte :** Jeton unique par terminal avec liaison matérielle au `device_uuid`.
- **Validation SSL stricte :** Vérification systématique de la chaîne de certification.

### 4.3 Hébergement et stockage HDS

- **Zone HDS multi-fournisseurs français :**
  - **Serveur WebDAV (compute)** : hébergé chez Scalingo (certifié HDS et ISO 27001).
  - **Stockage objet (S3)** : hébergé chez Hosteur (certifié HDS et ISO 27001).
- **Chiffrement au repos :** Chiffrement natif AES-256 (SSE-S3).
- **Isolation logique forte :**
  - Un dossier racine dédié et étanche par établissement.
  - Un jeton WebDAV unique par dossier racine.
  - Rejet des accès croisés.

### 4.4 Dispositif de Quarantaine et Intégrité

- **Gestion des fichiers suspects (Quarantaine serveur) :** Les fichiers identifiés comme
  anormaux par les contrôles d'intégrité cloud sont déplacés dans un dossier isolé `_quarantine`.
- **Exclusion stricte côté agent local :** L'agent Windows `MacroscopixSync` filtre et ignore
  rigoureusement tout dossier ou fichier contenant `quarantine` ou `_quarantine`. Ces fichiers ne sont
  jamais rapatriés sur le réseau du CHU et ne sont jamais supprimés par l'agent de synchronisation.
- **Contrôle d'intégrité de transfert :** L'agent compare la taille exacte du fichier téléchargé
  avec l'en-tête `Content-Length` émis par le serveur WebDAV. En cas d'écart (téléchargement partiel),
  le fichier local temporaire `.tmp` est détruit et le fichier distant est conservé intact pour un
  nouvel essai.

### 4.5 Supervision et Résilience de l'Agent Local

- **Démarrage résilient :** Au démarrage de la session ou du système Windows, l'agent exécute
  une boucle d'attente réseau non bloquante (contrôle toutes les 5 secondes) jusqu'à ce que la passerelle
  et le DNS hospitalier soient opérationnels, évitant les crashs au boot.
- **Déploiement Per-User / Service :** L'agent peut s'exécuter sous session utilisateur sans
  nécessiter d'élévation permanente des privilèges administrateur.
- **Supervision en temps réel :** Console d'état visuelle avec typage clair des flux reçus
  (images, documents, audio) et journalisation conforme aux standards d'exploitation DSI.

------------------------------------------------------------------------

## 5. Conformité RGPD et HDS

| Exigence | Mise en œuvre |
|---|---|
| **Droit à l'effacement** | Suppression automatique du Cloud HDS immédiatement après rapatriement et vérification par le CHU. Purge de sécurité programmée (24h) via Lifecycle Policy S3. |
| **Minimisation des données** | Conservation exclusive de journaux techniques anonymisés (horodatage, volumétrie, UUID terminal). Aucune donnée d'identification patient dans les bases centrales. |
| **Souveraineté** | Données de santé (photos, audio, PDF) traitées et hébergées 100 % en France sur des datacenters certifiés HDS (Scalingo / Hosteur). Les métadonnées administratives sont hébergées chez Infomaniak (Suisse). |
| **Traçabilité** | Conservation des journaux techniques de transfert pendant 12 mois. |

## 6. Prérequis côté CHU

1. **Poste ou VM de synchronisation** (Windows 10/11 ou Windows Server) disposant d'un accès
   Internet sortant HTTPS (port 443) et d'un accès en écriture sur le partage cible (SMB/NTFS).
2. **Autorisations pare-feu / proxy** : Autorisation en sortie des domaines `*.macroscopix.fr`.
3. **Répertoire(s) de destination** : Droits d'écriture accordés pour les dossiers cibles
   (Photos, Documents PDF, Fichiers Audio).

