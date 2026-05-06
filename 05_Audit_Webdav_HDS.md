# Audit Technique : Serveur WebDAV & Flux HDS (MacroscopiX)

**Composant :** Passerelle de transit Stateless

**Technologie :** Python 3.x (WsgiDAV / Boto3 / Cheroot)

**Rôle :** Interface sécurisée entre les terminaux (mobiles /
synchronisation) et le stockage objet S3.

## 1. Conformité de l\'Hébergement HDS

L\'infrastructure repose sur une chaîne de confiance certifiée **HDS
(Hébergeur de Données de Santé)** et **ISO 27001**, garantissant la
souveraineté et la sécurité des données traitées :

- **Serveur de Transit (Logique métier) :** Scalingo (PaaS certifié
  HDS).

- **Stockage Objet (Persistance temporaire) :** Hosteur (S3 certifié
  HDS).

------------------------------------------------------------------------

## 2. Architecture \"Security by Design\"

### 2.1 Modèle Stateless et Volatilité

L\'architecture est strictement **sans état (stateless)**.

- **Streaming Mémoire :** Les fichiers sont streamés directement vers le
  stockage S3 via BytesIO (mémoire vive).

- **Zéro Persistance Locale :** Aucun fichier n\'est écrit sur le disque
  local du serveur de transit. En cas de compromission du serveur,
  aucune donnée de santé n\'est récupérable car rien n\'est stocké
  physiquement sur l\'instance de calcul.

### 2.2 Ségrégation des Privilèges (Plan de Contrôle vs Plan de Données)

- **Accès Administrateur (Plan de Contrôle) :** Dédié à la maintenance.
  Accès restreint via une authentification forte (MFA : Mot de passe +
  OTP TOTP).

- **Accès Terminaux (Plan de Données) :** Authentification par **Token
  unique** par terminal.

- **Étanchéité Logique (Chroot) :** Chaque jeton d\'accès est verrouillé
  sur un répertoire racine spécifique. Un terminal ne peut techniquement
  ni lister, ni accéder aux répertoires des autres organisations ou
  terminaux.

### 2.3 Sécurisation des Flux

- **Chiffrement en Transit :** Utilisation impérative du protocole **TLS
  1.2/1.3**.

- **Hardening HTTP :** Utilisation de middleware pour forcer le HTTPS et
  injecter les en-têtes de sécurité (HSTS, X-Content-Type-Options).

------------------------------------------------------------------------

## 3. Contrôle des Opérations et Filtrage

### 3.1 Intégrité et Validation (Logiciel server.py)

- **Filtrage par Liste Blanche :** Seules les extensions d\'images
  médicales sont autorisées. Les fichiers potentiellement exécutables
  (.php, .exe, .sh, etc.) sont systématiquement rejetés.

- **Vérification MIME \"Deep Inspection\" :** La solution ne se fie pas
  à l\'extension du fichier. Elle utilise libmagic pour analyser la
  signature réelle du fichier (MIME type) et confirmer qu\'il s\'agit
  bien d\'une image avant tout traitement.

- **Contrôle de Volumétrie :** Limitation stricte de la taille des
  fichiers (client_max_body_size) pour prévenir les attaques par déni de
  service (DoS).

### 3.2 Sécurité du Stockage S3

- **Encryption at Rest :** Le chiffrement natif AES-256 est activé sur
  le bucket S3 (Server-Side Encryption).

- **Politique de Rétention :** Outre la suppression commandée par le
  client de synchronisation local, une règle de cycle de vie (Lifecycle
  Policy) assure la purge automatique des données résiduelles après 24h.

------------------------------------------------------------------------

## 4. Traçabilité et Défense Périmétrique

### 4.1 Journalisation et Auditabilité (HDS)

Conformément aux exigences RGPD et HDS, le système maintien des logs de
traçabilité pendant 12 mois :

- **Anonymisation :** Les logs enregistrent les métadonnées techniques
  (ID terminal, horodatage, statut) mais aucune donnée patiente
  nominative ou pseudonymisée.

- **Non-répudiation :** Le calcul du Hash SHA-256 lors du transfert
  garantit l\'intégrité de l\'image de la capture jusqu\'au dépôt local
  dans le SIH.

### 4.2 Protection Active

- **Limitation de débit (Rate Limiting) :** Protection contre les
  tentatives de brute-force et les abus de ressources.

- **Bannissement Automatique (Fail2ban) :** Identification et blocage
  des IP présentant un comportement suspect (erreurs 401/403 répétées,
  scans de ports).

------------------------------------------------------------------------

## 5. Conclusion

Le serveur de transit MacroscopiX est conçu comme une passerelle
transparente. En combinant une architecture stateless, un hébergement
certifié HDS et un filtrage applicatif rigoureux, il offre un niveau de
sécurité maximal pour le transfert des données de santé entre le terrain
et le cœur du SI Hospitalier.
