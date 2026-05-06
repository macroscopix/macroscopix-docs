## Dossier d'Architecture Technique et de Sécurité (DATS)

**Projet :** MacroscopiX**\
Date :** 22 janvier 2026\
**Confidentialité :** Interne / Diffusion restreinte -- DSI / RSSI CHU

------------------------------------------------------------------------

## 1. Présentation de la solution

MacroscopiX est une solution mobile sécurisée permettant la capture et
le transfert d'images médicales depuis un smartphone vers le Système
d'Information Hospitalier (SIH), sans persistance des données sur le
terminal (02_Mobile_App.docx).

La solution s'inscrit dans un cadre institutionnel maîtrisé, conforme
aux exigences HDS et RGPD, et vise à encadrer des usages terrain
existants en les sécurisant.

### 1.1 Enrôlement et identification des terminaux

Avant toute utilisation, l'application MacroscopiX, signée et distribuée
via le Google Play Store, fait l'objet d'un processus d'enrôlement
contrôlé permettant d'identifier, d'autoriser et de tracer les terminaux
habilités à capturer des images médicales.

- L'établissement désigne **un ou plusieurs référents d'enrôlement**
  (ex. cadre de santé, responsable de secteur, référent informatique).

- Pour chaque référent, une **adresse email institutionnelle
  nominative** est communiquée lors de la mise en service.

- Les référents sont habilités à :

  - initier l'enrôlement d'un terminal mobile,

  - valider l'association entre un terminal et l'établissement,

Le processus d'enrôlement repose sur une authentification forte (OTP) et
permet de générer un identifiant technique unique pour chaque terminal,
associé à un jeton d'authentification délivré via l'API dédiée
(03_API_server.docx, 04_Admin_Console.docx).

Cet identifiant est utilisé pour :

- l'authentification de l'application,

- le contrôle d'accès aux flux de données de santé,

La révocation d'un terminal entraîne l'invalidation immédiate de son
jeton d'accès.

### 1.2 BYOD 

L'application MacroscopiX a été pensée pour un accès BYOD (Bring Your
Own Device) lorsque cela est compatible avec la politique du Système
d'Information de l'établissement via 4G/5G. Les conditions sont les
suivantes :

- Le terminal doit être préalablement enrôlé et validé par un référent
  désigné de l'établissement.

- Les données de santé doivent transiter via l'infrastructure HDS
  MacroscopiX (05_Webdav_Server_S3_Storage.docx) et utiliser le service
  MacroscopiXSync (06_Sync_Service.docx).

Cette approche permet aux praticiens d'utiliser leurs propres
smartphones tout en assurant la sécurité, la traçabilité et la
conformité HDS des données de santé.

### 1.3 Contexte clinique et flux de travail

L'application est destinée à être utilisée en **laboratoire d'Anatomie
et Cytologie Pathologiques (ACP)**, environnement technique contraint
(manipulation de formol, port de gants, risques chimiques) nécessitant
des outils rapides, robustes et ergonomiques, compatibles avec un usage
« sans contact ».

Workflow sécurisé type :

1.  **Identification (entrée)**\
    Le praticien scanne le code-barres ou le DataMatrix du dossier
    (numéro d'examen) directement sur la demande d'examen. L'absence de
    saisie manuelle réduit les risques d'erreurs d'identitovigilance.

2.  **Capture**\
    Prise de photographies macroscopiques des prélèvements afin de
    documenter le dossier.

3.  **Transfert (sortie)**\
    Envoi immédiat et automatique des images vers le serveur sécurisé.

4.  **Purge**\
    Suppression automatique des données de la mémoire du terminal après
    acquittement du serveur.

5.  **Intégration au SI hospitalier**\
    Transfert des images vers le système d'information intra-hospitalier
    et intégration automatique dans le Système de Gestion de Laboratoire
    (SGL), reposant sur un nommage normalisé des fichiers basé sur le
    code-barres de la demande.

#### Objectifs de sécurité

- **Zéro persistance :** aucune donnée de santé n'est conservée sur le
  terminal mobile après le transfert.

- **Cloisonnement strict :** séparation physique et logique entre les
  flux d'administration et les flux de données de santé.

- **Intégrité et confidentialité :** chiffrement des flux réseau de bout
  en bout (TLS ≥ 1.2).

### 

### 1.4 Enjeux et bénéfices institutionnels

Le déploiement de MacroscopiX répond à plusieurs objectifs stratégiques
pour l'établissement :

- **Besoin terrain identifié :** réponse à un besoin opérationnel réel
  d'acquisition rapide et standardisée d'images au poste de travail
  (paillasse).

- **Mobilité et efficacité :** réalisation de clichés de qualité sans
  infrastructure lourde ni poste fixe dédié (gain de temps et de
  fluidité des processus).

- **Rationalisation économique :** alternative agile aux systèmes de
  caméras sur bras articulés, coûteux et peu flexibles.

- **Encadrement des pratiques (Shadow IT) :** sécurisation et
  formalisation d'usages existants (photos via téléphones personnels)
  dans un cadre validé par la DSI.

- **Innovation pragmatique :** démarche d'amélioration continue de la
  qualité des soins et de l'organisation du travail.

------------------------------------------------------------------------

## 2. Architecture Globale et Ségrégation des Flux

L'architecture de MacroscopiX repose sur une **ségrégation stricte**
(logique et physique) des composants, garantissant une étanchéité totale
entre la gestion administrative et le traitement des données de santé.

### 2.1 Structuration en Zones Distinctes

La solution s\'articule autour de deux environnements isolés :

- **Zone d'Administration (Non-HDS) :** Ce périmètre gère exclusivement
  les métadonnées techniques (enrôlement des terminaux, licences, logs
  de transfert). Il ne voit jamais passer de données de santé ou
  d\'images. L\'accès est protégé par une authentification forte
  (2FA/TOTP).

- **Zone de Transit HDS :** Cet environnement est dédié au transit et au
  stockage temporaire des images médicales sur des infrastructures
  certifiées **HDS (Hébergeur de Données de Santé)**. L\'architecture
  est dite **stateless** : les données sont purgées dès que le transfert
  vers le SIH est acquitté.

![](media/image1.png){width="6.497222222222222in"
height="3.6534722222222222in"}

### 2.2 Flexibilité d\'Hébergement et Responsabilités

La solution offre deux modes de déploiement pour s\'adapter aux
politiques de sécurité de l\'établissement :

1.  **Modèle Standard (Cloud HDS) :** Le transit est assuré par les
    serveurs certifiés MacroscopiX. Le service **MacroscopixSync**
    assure la passerelle descendante vers le stockage local via un flux
    HTTPS sortant.

2.  **Modèle Délégué (On-Premise) :** L'environnement de transit est
    hébergé directement par le CHU (via une URL WebDAV interne en
    HTTPS). Dans cette configuration :

    - Le service **MacroscopixSync** devient optionnel.

    - La sécurité périmétrique (WAF, reverse proxy, filtrage IP,
      limitation de débit) et la conformité HDS incombent alors
      entièrement à la DSI du CHU.

### 2.3 Connectivité et Politique d\'Usage (BYOD vs Flotte Institutionnelle)

La solution est conçue pour offrir une agilité maximale tout en
respectant les contraintes de sécurité périmétrique :

- **Scénario BYOD (Privilégié pour l\'agilité) :** L\'utilisation de
  terminaux personnels en 4G/5G ou via un Wi-Fi \"Invité\" est
  parfaitement supportée. La sécurité est assurée par l\'absence de
  persistance des données sur le téléphone et le chiffrement TLS 1.2+
  des flux. Cela permet un déploiement rapide sans investissement
  matériel pour l\'établissement.

- **Contrainte Wi-Fi CHU :** Si l\'établissement impose l\'usage du
  Wi-Fi interne de production, l\'accès sera restreint aux terminaux
  gérés par la DSI (flotte institutionnelle avec certificats). Dans ce
  cas, l\'usage du BYOD sur le réseau Wi-Fi métier est proscrit pour
  garantir l\'étanchéité du réseau local.

- **Récupération de flux :** Dans tous les cas, la purge automatique
  après transfert garantit qu\'aucune donnée de santé ne \"sort\" de
  l\'établissement sur le terminal, qu\'il soit personnel ou
  institutionnel.

------------------------------------------------------------------------

## 3. Matrice des flux et des ports

  -----------------------------------------------------------------------------------
  Source             Destination    Protocole   Port   Description          Données
                                                                            de santé
  ------------------ -------------- ----------- ------ -------------------- ---------
  Application        API            HTTPS       443    Récupération de      Non
  Android            d'enrôlement                      configuration, OTP,  
                                                       journaux d'erreurs   

  Application        Serveur WebDAV HTTPS       443    Téléversement (PUT)  Oui
  Android                                              des images médicales 

  Service            Serveur WebDAV HTTPS       443    Téléchargement (GET) Oui
  MacroscopixSync                                      et suppression       
                                                       (DELETE)             

  Console            API            HTTPS       443    Gestion des licences Non
  d'administration   d'enrôlement                      et des terminaux     
  -----------------------------------------------------------------------------------

**Note importante :** aucun flux entrant n'est requis sur le pare-feu du
CHU. L'ensemble des connexions est initié en sortie (HTTPS standard).

## 4. Mesures de sécurité mises en œuvre

### 4.1 Sécurité sur le terminal mobile

- **Traitement en mémoire vive :** les images sont traitées
  exclusivement en RAM.

- **Suppression immédiate :** effacement automatique après acquittement
  du serveur.

- **Absence de stockage local :** aucune utilisation de la galerie
  publique Android.

- **Protection des secrets :** stockage des identifiants et jetons dans
  le Keystore Android (support matériel).

- **Obfuscation du code :** utilisation de ProGuard / R8 pour limiter
  l'ingénierie inverse.

### 4.2 Sécurité des communications

- **Chiffrement TLS 1.3** (TLS 1.2 minimum avec suites cryptographiques
  robustes).

- **Authentification forte :** jeton unique par terminal avec liaison à
  l'identifiant du périphérique.

### 4.3 Hébergement et stockage

- Zone HDS multi-fournisseurs :

  - **Serveur WebDAV (compute)** : hébergé chez Scalingo (certifications
    HDS et ISO 27001).

  - **Stockage objet (S3)** : hébergé chez Hosteur (certifications HDS
    et ISO 27001).

- **Chiffrement au repos :** chiffrement natif des buckets S3 (SSE-S3 ou
  SSE-KMS).

- Isolation logique forte :

  - un dossier racine dédié,

  - un jeton WebDAV unique par dossier.

### 4.4 Supervision et détection d'anomalies

- **Supervision des ressources :** surveillance de la charge système et
  régulation automatique des tâches en cas de pic d'activité.

- **Contrôles d'intégrité :** analyse en temps réel des journaux de
  transfert pour détecter incohérences et fichiers suspects.

- **Alertes de sécurité :** notifications automatiques des
  administrateurs en cas d'événement anormal.

------------------------------------------------------------------------

## 5. Conformité RGPD et HDS

  -----------------------------------------------------------------------
  Exigence       Mise en œuvre
  -------------- --------------------------------------------------------
  Droit à        Suppression automatique après intégration dans le SIH
  l'effacement   

  Minimisation   Conservation exclusive de journaux techniques
  des données    (succès/échec, volumétrie). Aucune donnée patient

  Souveraineté   Les données de santé sont hébergées 100 % en France dans
                 un environnement HDS certifié (Scalingo / Hosteur). Les
                 données techniques (enrôlement, licences, logs) sont
                 hébergées en Suisse (Infomaniak).

  Traçabilité    Conservation des Logs technique pendant 12 mois
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 6. Prérequis côté CHU

1.  **Poste ou VM de synchronisation** disposant d'un accès Internet
    sortant (HTTPS) et d'un accès en écriture vers la cible locale.

2.  **Proxy de sortie** : autorisation (whitelist) des domaines
    \*.macroscopix.fr.
