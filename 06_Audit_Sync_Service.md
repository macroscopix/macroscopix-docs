# Audit Technique : Client de Synchronisation (MacroscopixSync)

**Composant :** Agent Windows (Service / Tâche utilisateur Per-User)  
**Version :** 2.5 (Production)  
**Technologie :** .NET 8.0 LTS (C#)  
**Rôle :** Passerelle sécurisée descendante entre le Cloud HDS et le SIH local (LIS / NAS / SGL).

------------------------------------------------------------------------

## 1. Fonctionnement Technique

Le module **MacroscopixSync** est un agent d'intégration Windows natif (`Macroscopix.Sync.Service.exe`). Il automatise le rapatriement des données médicales acquises sur le terrain (photographies, dictées audio, fiches documentaires PDF) et leur routage sécurisé vers les serveurs de stockage et logiciels métier de l'établissement sans intervention humaine.

### 1.1 Cycle de Vie et Automatisme

1. **Boucle de démarrage résiliente (Anti-crash au boot) :**  
   Au lancement de la machine ou de la session, l'agent teste la joignabilité réseau et la résolution DNS. Si le réseau hospitalier (DHCP/Wi-Fi) est temporairement indisponible, il effectue une attente non bloquante avec réessais toutes les 5 secondes (`[RÉSEAU] Connecté.`), évitant tout plantage prématuré du processus.

2. **Polling Sécurisé (Mécanisme Pull sortant) :**  
   L'agent interroge périodiquement le serveur WebDAV HDS via une connexion sortante HTTPS sécurisée (intervalle configurable via `PollIntervalInSeconds`).

3. **Filtrage et Exclusion Stricte de Quarantaine :**  
   L'agent analyse l'arborescence distante et applique un filtre de sécurité catégorique : tout dossier ou fichier dont le nom contient `quarantine` ou `_quarantine` est **strictement ignoré**. Ces éléments ne sont jamais téléchargés vers le CHU et ne sont jamais supprimés sur le serveur cloud, préservant l'intégrité de l'infrastructure locale.

4. **Transfert Atomique et Intégrité Octet par Octet :**  
   Chaque fichier est d'abord écrit localement sous une extension temporaire `.tmp` avec verrouillage exclusif (`FileShare.None`). L'agent vérifie ensuite que la taille du fichier écrit sur disque correspond **exactement** à l'en-tête `Content-Length` émis par le serveur WebDAV. En cas d'incohérence, le fichier `.tmp` est immédiatement supprimé et aucun acquittement de purge n'est envoyé.

5. **Aiguillage Multi-Dépôts (Multi-Target Routing) :**  
   Une fois le téléchargement validé, le fichier est déplacé de façon atomique vers son répertoire cible selon sa nature :
   - **Photographies (`.jpg`, `.jpeg`, `.png`)** $\rightarrow$ Dépôt images principal (`LocalPath`).
   - **Documents numérisés (`.pdf`)** $\rightarrow$ Dépôt documentaire (`PdfLocalPath`, ou repli sur `LocalPath` si non configuré).
   - **Enregistrements vocaux (`.wav`)** $\rightarrow$ Dépôt dictaphone (`AudioLocalPath`, ou repli sur `LocalPath`).  
     *Normalisation Audio :* Pour assurer une compatibilité immédiate avec les logiciels de transcription vocale et de secrétariat médical qui interdisent les caractères de soulignement dans les chemins de dossiers, les underscores sont automatiquement supprimés des répertoires de prélèvements audio (ex. `Dossier_Prelevement` devient `DossierPrelevement`).

6. **Acquittement et Purge Cloud HDS :**  
   La requête HTTP `DELETE` n'est émise vers le serveur WebDAV HDS **qu'après** confirmation absolue de la persistance locale du fichier sur le stockage de l'établissement.

------------------------------------------------------------------------

## 2. Analyse de Sécurité et Étanchéité

### 2.1 Flux Réseau et Périmètre

- **Architecture "Zero Inbound" :** L'agent initie exclusivement des connexions sortantes (TCP Outbound port 443). Aucun port entrant n'est ouvert sur le pare-feu du CHU.
- **Absence d'exposition DMZ :** Pas de redirection NAT/PAT, le poste de synchronisation reste totalement invisible depuis l'Internet public.
- **Standard de Chiffrement :** Utilisation du composant `HttpClient` .NET avec négociation forcée en **TLS 1.2 / TLS 1.3**.

### 2.2 Gestion des Identifiants et Droits Système

- **Authentification Sécurisée :** Couple User / Token unique transmis par en-tête `Authorization` chiffré sur canal HTTPS.
- **Support Double Mode (Service SYSTEM ou Tâche Per-User) :**
  - **Mode Service Managé :** Exécution sous compte de service Windows standard ou gMSA avec droits restreints.
  - **Mode Per-User (Sans privilège admin) :** Exécution au sein de la session utilisateur locale, sans nécessiter d'élévation `runas Administrator` au quotidien, répondant aux politiques de postes de travail verrouillés.
- **Protection des Fichiers de Configuration (`appsettings.json`) :**
  - Droits NTFS restreints à l'administrateur et au compte exécutant.
  - Chiffrement possible des chaînes de connexion via l'API **DPAPI Windows** (Data Protection API).
- **Sécurité des Dépôts Cibles (SMB v3) :**
  - Le transfert vers les serveurs de fichiers hospitaliers / NAS supporte nativement le chiffrement **SMB v3**, protégeant les données de santé contre l'écoute interne sur le LAN.

------------------------------------------------------------------------

## 3. Déploiement et Exploitation DSI

### 3.1 Industrialisation et Déploiement

- **Packaging :** Installateur exécutable Windows standard (Inno Setup) avec création de raccourcis, options de démarrage automatique au login, et outil de configuration visuel (`MacroscopixConfigurator.exe`).
- **Déploiement Télédistribué :** Support complet des commutateurs d'installation silencieuse (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`) pour intégration via SCCM, Microsoft Intune, ou scripts GPO.
- **Contrôle d'Intégrité du Binaire :** Empreinte de hachage SHA-256 fournie pour validation préalable au déploiement en production.

### 3.2 Observabilité et Console Temps Réel

- **Console Temps Réel Typée :** Interface visuelle d'exploitation indiquant immédiatement l'état du réseau (`[RÉSEAU] Connecté.`) et le typage explicite des flux reçus :
  - `📸 Image reçue : <nom_fichier>`
  - `📄 Document reçu : <nom_fichier>`
  - `🎵 Audio reçu : <nom_fichier>`
- **Journalisation DSI :** Fichiers journaux rotatifs horodatés conservés localement et possibilité de journalisation dans l'Observateur d'événements Windows (`Event Viewer`).
- **Supervision :** Traçabilité claire des codes retour HTTP et des incidents disques (espace insuffisant, droits SMB manquants), facilitant l'alerte proactive par Zabbix, Nagios ou PRTG.

------------------------------------------------------------------------

## 4. Conclusion

L'agent MacroscopixSync fonctionne comme une soupape de sécurité unidirectionnelle (Pull exclusif). En assurant le routage multi-dépôts (images, audio normalisé, documents PDF), en garantissant l'intégrité octet par octet avant toute purge cloud, et en isolant catégoriquement les fichiers en quarantaine, il répond aux standards les plus stricts de sécurité hospitalière et de continuité d'exploitation DSI.

