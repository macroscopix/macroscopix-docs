# Audit Technique : Serveur WebDAV & Flux HDS (MacroscopiX)

**Composant :** Passerelle de transit Stateless  
**Technologie :** Python 3.x (WsgiDAV / Boto3 / Cheroot)  
**Rôle :** Interface sécurisée entre les terminaux (mobiles / synchronisation) et le stockage objet S3.

## 1. Conformité de l'Hébergement HDS

L'infrastructure repose sur une chaîne de confiance certifiée **HDS (Hébergeur de Données de Santé)** et **ISO 27001**, garantissant la souveraineté et la sécurité des données traitées :
- **Serveur de Transit (Logique métier) :** Scalingo (PaaS certifié HDS).
- **Stockage Objet (Persistance temporaire) :** Hosteur (S3 certifié HDS).

---

## 2. Architecture "Security by Design"

### 2.1 Modèle Stateless et Atomicité des Flux
L'architecture est strictement **sans état (stateless)** et repose sur un principe de **transaction atomique** :

- **Buffering et Isolation Mémoire :** Les fichiers sont accumulés intégralement dans un buffer `BytesIO` (mémoire vive) avant toute interaction avec le stockage S3. 
- **Zéro Persistance Locale :** Aucun fichier n'est écrit sur le disque local. En cas de compromission, aucune donnée de santé n'est récupérable car rien n'est stocké physiquement sur l'instance de calcul.
- **Résilience aux Interruptions (Anti-Corruption) :** Contrairement aux passerelles standards, ce serveur n'ouvre aucune session d'écriture sur S3 avant d'avoir reçu 100% du fichier en mémoire. Cela garantit l'absence de fichiers orphelins ou corrompus (ex: résidus de 36 octets) en cas de redémarrage de container ou de coupure réseau.

### 2.2 Ségrégation des Privilèges (Plan de Contrôle vs Plan de Données)
- **Accès Administrateur (Plan de Contrôle) :** Accès restreint via authentification forte (MFA : Mot de passe + OTP TOTP).
- **Accès Terminaux (Plan de Données) :** Authentification par **Token unique** par terminal.
- **Étanchéité Logique (Chroot) :** Chaque jeton est verrouillé sur un répertoire racine spécifique. Un terminal ne peut techniquement ni lister, ni accéder aux données d'un autre terminal.

### 2.3 Sécurisation des Flux
- **Chiffrement en Transit :** Utilisation impérative du protocole **TLS 1.2/1.3**.
- **Hardening HTTP :** Middleware forçant le HTTPS et injection d'en-têtes de sécurité (HSTS, X-Content-Type-Options).

---

## 3. Contrôle des Opérations et Filtrage

### 3.1 Intégrité et Validation Applicative
- **Validation de Seuil de Données :** Le logiciel rejette systématiquement tout flux inférieur à 100 octets, éliminant les bruits réseau et les paquets HTTP malformés.
- **Filtrage par Liste Blanche :** Seules les extensions d'images médicales sont autorisées. Les fichiers exécutables sont rejetés.
- **Vérification MIME "Deep Inspection" :** Utilisation de `libmagic` pour analyser la signature réelle (MIME type) et confirmer qu'il s'agit bien d'une image médicale avant le dépôt sur S3.
- **Contrôle de Volumétrie :** Limitation stricte de la taille des fichiers (`client_max_body_size`) pour prévenir les attaques par déni de service (DoS).

### 3.2 Sécurité du Stockage S3
- **Encryption at Rest :** Chiffrement natif AES-256 activé sur le bucket (SSE).
- **Politique de Rétention :** Outre la suppression commandée par le client local, une règle de cycle de vie (**Lifecycle Policy**) assure la purge automatique des données résiduelles après 24h.

---

## 4. Traçabilité et Défense Périmétrique

### 4.1 Journalisation et Auditabilité (HDS)
Le système maintient des logs de traçabilité pendant 12 mois :
- **Anonymisation :** Logs limités aux métadonnées techniques (ID terminal, horodatage). Aucune donnée patient nominative n'est enregistrée.
- **Non-répudiation :** Le calcul du Hash lors du transfert garantit l'intégrité de l'image de la capture jusqu'au dépôt local dans le SIH.

### 4.2 Protection Active
- **Limitation de débit (Rate Limiting) :** Protection contre le brute-force.
- **Bannissement Automatique :** Identification et blocage des IP présentant un comportement suspect (erreurs répétées, scans).

---

## 5. Conclusion
Le serveur de transit MacroscopiX agit comme une barrière de sécurité active. Son architecture **atomique et stateless** garantit qu'aucune donnée de santé ne peut être corrompue ou fuiter lors du transit entre le terminal et le SI Hospitalier.
