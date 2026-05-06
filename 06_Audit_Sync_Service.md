# Audit Technique : Client de Synchronisation (MacroscopixSync)

**Composant :** Agent Windows (Service)

**Technologie :** .NET 8.0 LTS (C#)

**Rôle :** Passerelle sécurisée descendante entre le Cloud HDS et le SIH
local (LIS / NAS)

------------------------------------------------------------------------

## 1. Fonctionnement Technique

Le module **MacroscopixSync** est un service Windows natif
(Macroscopix.Sync.Service.exe). Il est conçu pour automatiser la
récupération des images médicales et leur intégration dans le flux de
travail hospitalier sans intervention humaine.

### 1.1 Cycle de Vie et Automatisme

1.  **Polling (Mécanisme Pull) :** Le service interroge le serveur
    WebDAV HDS via une connexion sécurisée à intervalles réguliers
    (configurable via PollIntervalInMinutes).

2.  **Transfert Séquentiel :** Les nouveaux fichiers sont téléchargés un
    par un via HTTPS pour garantir l\'intégrité de chaque transfert et
    ne pas saturer la bande passante.

3.  **Dépôt Local (SMB Push) :** Une fois téléchargé, le service dépose
    le fichier sur le stockage cible du CHU (partage réseau UNC ou
    disque local) via le protocole **SMB v3** (chiffré).

4.  **Acquittement et Purge HDS :** Immédiatement après confirmation de
    l\'écriture locale (vérification du checksum), le service émet une
    commande DELETE vers le Cloud HDS. Le fichier n\'est supprimé du
    Cloud **qu\'après** validation de sa persistance sur
    l\'infrastructure du CHU.

------------------------------------------------------------------------

## 2. Analyse de Sécurité et Étanchéité

### 2.1 Flux Réseau et Périmètre

- **Architecture \"Zero Inbound\" :** Le service initie exclusivement
  des connexions sortantes (TCP Outbound port 443).

- **Absence de DMZ :** Aucun port entrant n\'est ouvert sur le pare-feu
  de l\'établissement. Il n\'y a pas d\'exposition du réseau local vers
  l\'Internet (pas de NAT/PAT).

- **Standard de chiffrement :** Utilisation de HttpClient .NET avec
  négociation forcée **TLS 1.2/1.3**.

### 2.2 Gestion des Secrets et Authentification

- **Double Authentification Technique :** L\'accès au Cloud HDS repose
  sur un couple User/Token unique, transmis via Basic Auth sur canal
  HTTPS.

- **Protection des configurations :** Le fichier appsettings.json
  contient les paramètres de connexion.

  - *Sécurisation préconisée :* Les secrets peuvent être chiffrés via la
    **DPAPI Windows** (Data Protection API), rendant les identifiants
    illisibles même en cas d\'accès physique au fichier par un tiers.

  - *ACL NTFS :* Les droits d\'accès au répertoire d\'installation sont
    limités au compte SYSTEM et aux administrateurs locaux.

### 2.3 Privilèges Système et SMB

- **Compte de Service Dédié :** Bien qu\'exécutable en LocalSystem, il
  est recommandé d\'exécuter le service sous un **Compte de Service AD
  managé (gMSA)** ou un compte de service standard.

- **Moindre Privilège :** Ce compte nécessite uniquement les droits de
  \"Lecture/Écriture\" sur le répertoire cible. Aucun droit
  d\'administration sur le domaine ou la machine n\'est requis.

- **Sécurité SMB :** Le service supporte nativement le chiffrement **SMB
  v3**, garantissant que le flux entre le service de synchro et le
  stockage final reste protégé contre l\'interception interne.

------------------------------------------------------------------------

## 3. Déploiement et Exploitation

### 3.1 Industrialisation

- **Packaging :** Installateur .exe (Inno Setup).

- **Signature numérique :** Non signée en phase pilote (signature
  commerciale avec certificat de *Code Signing* prévue pour
  l\'industrialisation). L\'intégrité du binaire est garantie par la
  fourniture de son **empreinte SHA-256** pour vérification avant
  déploiement.

- **Déploiement Centralisé :** Compatible avec les outils de
  télédistribution (SCCM, GPO, Intune) via le mode silencieux
  (/VERYSILENT).

### 3.2 Supervision (Observabilité)

- **Logs Applicatifs :** Intégration complète à l\'Observateur
  d\'événements Windows (Source : MacroscopixSync).

- **Alerting DSI :** Les codes erreurs standards (Échec de connexion,
  Quota disque plein, Erreur d\'écriture) sont exploitables par les
  outils de supervision (Zabbix, Nagios, SCOM).

------------------------------------------------------------------------

## 4. Conclusion

Le module MacroscopixSync agit comme une \"valve de sécurité\"
unidirectionnelle. En rapatriant les données via un mécanisme de Pull
sécurisé, il garantit la souveraineté des données de santé qui ne
transitent que temporairement par la zone HDS/WebDav. Sa conception
robuste en .NET 8 assure une compatibilité à long terme avec les
politiques de durcissement.
