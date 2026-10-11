# Audit Technique : Serveur WebDAV & Flux HDS (MacroscopiX)

**Composant :** Passerelle de transit Stateless  
**Technologie :** Python 3.x (WsgiDAV / Boto3 / Cheroot)  
**Rôle :** Interface sécurisée entre les terminaux (mobiles / synchronisation) et le stockage objet S3.

## 1. Conformité de l'Hébergement HDS

L'infrastructure repose sur une chaîne de confiance certifiée **HDS (Hébergeur de Données de Santé)** et **ISO 27001**, garantissant la souveraineté et la sécurité des données traitées :
- **Serveur de Transit (Logique métier) :** Scalingo (PaaS certifié HDS, hébergé en France).
- **Stockage Objet (Persistance temporaire) :** Scaleway (S3 Object Storage certifié HDS, région Paris `fr-par`, datacenters souverains en France).

---

## 2. Architecture "Security by Design"

### 2.1 Modèle Stateless et Atomicité des Flux
L'architecture est strictement **sans état (stateless)** et repose sur un principe de **transaction atomique** :

- **Buffering et Isolation Mémoire :** Les fichiers (images JPEG, enregistrements audio WAV, documents PDF) sont accumulés intégralement dans un buffer `BytesIO` (mémoire vive) avant toute interaction avec le stockage S3. 
- **Zéro Persistance Locale :** Aucun fichier n'est écrit sur le disque local de l'instance WebDAV. En cas de redémarrage ou d'arrêt inopiné de l'instance, aucune donnée de santé résiduelle n'est présente sur le conteneur.
- **Résilience aux Interruptions (Anti-Corruption) :** Aucune session d'écriture S3 n'est initiée avant la réception complète du fichier en mémoire vive. Cela élimine tout risque de fichiers orphelins ou corrompus (fichiers tronqués) en cas de coupure réseau mobile.

### 2.2 Ségrégation des Privilèges (Plan de Contrôle vs Plan de Données)
- **Accès Administrateur (Plan de Contrôle) :** Accès restreint via authentification forte (MFA : Mot de passe + OTP TOTP).
- **Accès Terminaux (Plan de Données) :** Authentification par **Token unique** par terminal ou organisation.
- **Étanchéité Logique (Chroot) :** Chaque jeton est strictement circonscrit à son répertoire racine organisationnel. Un terminal ne peut techniquement ni lister, ni accéder aux données d'un autre établissement.

### 2.3 Sécurisation des Flux
- **Chiffrement en Transit :** Utilisation impérative du protocole **TLS 1.2 / TLS 1.3**.
- **Hardening HTTP :** Forçage systématique du HTTPS et injection d'en-têtes de sécurité (HSTS, X-Content-Type-Options).

---

## 3. Contrôle des Opérations et Filtrage

### 3.1 Intégrité et Validation Applicative
- **Validation de Seuil de Données :** Rejet systématique de tout flux inférieur à 100 octets pour éliminer les paquets HTTP fantômes.
- **Filtrage par Liste Blanche d'Extensions :** Seules les extensions médicales reconnues sont acceptées :
  - Images macroscopiques : `.jpg`, `.jpeg`, `.png`
  - Dictées vocales : `.wav`
  - Numérisations documentaires : `.pdf`
  - Les extensions exécutables (`.exe`, `.bat`, `.sh`, `.py`, `.dll`) ou suspectes sont immédiatement rejetées avec un code HTTP 403 / 415.
- **Vérification MIME "Deep Inspection" :** Utilisation de `libmagic` pour analyser les octets d'en-tête (Magic Numbers) et valider la signature binaire réelle avant tout dépôt sur S3.
- **Contrôle de Volumétrie :** Limitation stricte de la taille des requêtes pour prévenir les saturations mémoires.

### 3.2 Mécanisme de Quarantaine Cloud et Sécurité Sanitaire
- **Mise à l'écart (`_quarantine`) :** En cas d'incohérence détectée (signature binaire non conforme, fichier malformé ou paquet suspect), le système déplace le fichier dans un dossier isolé de quarantaine (`_quarantine`) sur le stockage cloud.
- **Non-exposition locale :** Ce dossier est explicitement exclu des requêtes de l'agent de synchronisation `MacroscopixSync`, empêchant tout risque de contamination du SIH ou d'erreur de traitement en laboratoire.

### 3.3 Sécurité du Stockage S3
- **Encryption at Rest :** Chiffrement matériel côté serveur activé sur l'intégralité du bucket S3 (SSE-S3 AES-256).
- **Politique de Rétention et Purge Automatique :** Outre la suppression immédiate déclenchée par l'agent local après vérification octet par octet, une règle de cycle de vie (**Lifecycle Policy S3**) garantit la suppression irréversible de toute donnée non purgée après 24 heures.

---

## 4. Traçabilité et Défense Périmétrique

### 4.1 Journalisation et Auditabilité (HDS)
Le système maintient des journaux de traçabilité pendant 12 mois :
- **Anonymisation :** Logs limités aux métadonnées techniques (UUID terminal, volumétrie en octets, horodatage, statut HTTP). Aucune donnée d'identification patient nominative n'est enregistrée.
- **Vérification d'intégrité :** Émission de l'en-tête `Content-Length` exact permettant à l'agent local de valider l'intégrité binaire avant toute suppression du cloud.

### 4.2 Protection Active
- **Limitation de débit (Rate Limiting) :** Protection contre les attaques en force brute.
- **Bannissement Automatique :** Blocage des adresses IP présentant un comportement anormal (tentatives d'accès répétées sur des routes non autorisées).

---

## 5. Conclusion
Le serveur de transit MacroscopiX forme une barrière de protection active et étanche. Son architecture **stateless en mémoire vive, son filtrage MIME strict et son mécanisme de quarantaine** garantissent qu'aucune donnée de santé ne peut être altérée ou corrompue entre le smartphone et le SI Hospitalier.

