# Audit Technique : API Macroscopix

**Composant :** API d'enrôlement et de journalisation\
**Technologie :** FastAPI (Python 3.x)\
**Rôle :**Distribution de configuration WebDAV et collecte de logs
techniques

------------------------------------------------------------------------

## 1. Objectif de l'API

L'API FastAPI sert à :

\- Enrôler les terminaux Android,

\- Générer et valider des OTP (One-Time Password),

\- Fournir la configuration WebDAV sécurisée pour chaque terminal,

\- Gérer les terminaux (audit, révocation),

\- Enregistrer les logs de transfert des images.

L'API **ne stocke jamais d'images** et **ne traite aucune donnée de
santé**.\
Elle agit uniquement comme **service de configuration,
d'authentification et de journalisation technique**.

------------------------------------------------------------------------

## 2. Stack technique et bibliothèques utilisées

  -----------------------------------------------------------------------------------------
  **Catégorie**   **Librairie**                    **Version indicative** **Utilisation**
  --------------- -------------------------------- ---------------------- -----------------
  Web Framework   fastapi                          0.95+                  API REST,
                                                                          dépendances,
                                                                          sécurité

  Validation      pydantic                         2.x                    Validation des
                                                                          payloads JSON

  Base de données psycopg2                         2.9+                   Connexion
                                                                          PostgreSQL

  Curseurs dict   psycopg2.extras.RealDictCursor   --                     Résultats
                                                                          structurés

  Emails          smtplib, email.mime.\*           --                     Envoi OTP via
                                                                          SMTP TLS

  Temps           datetime, zoneinfo               --                     Expiration OTP,
                                                                          horodatage

  Sécurité        secrets                          --                     Génération
                                                                          secrets terminaux

  OTP             random                           --                     Génération OTP 6
                                                                          chiffres

  Lifespan        contextlib.asynccontextmanager   --                     Migrations DB au
                                                                          démarrage
  -----------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 3. Sécurité et audit 

### 3.1 API Key

- Protection des routes sensibles via **x-api-key**

- Vérification stricte par dépendance FastAPI

- Retour HTTP 403 en cas d'échec

- Journalisation des tentatives non autorisées

### 3.2 OTP (One-Time Password)

- Code à 6 chiffres

- Durée de validité : **15 minutes**

- Stockage temporaire (api_token, token_expiry)

- Usage unique pour récupération de configuration

### 3.3 Terminal Secret

- Secret unique généré via secrets.token_urlsafe(32)

- Utilisé en **Bearer Token**

- Révocable à tout moment

- Aucun secret stocké côté client en clair

### 3.4 Binding des terminaux

- Nom unique par organisation

- Limitation du nombre de terminaux (max_slots)

- Réactivation possible d'un terminal existant

- Rejet explicite en cas de conflit actif

### 3.5 Protection des données

- Aucune donnée de santé

- Aucune image

- Aucune métadonnée clinique

- Lien patient exclusivement géré dans le SIH du CHU

### 3.6 Journalisation

- Logs applicatifs des actions critiques

- Table transfer_logs :

  - terminal_id

  - organization_id

  - nom de fichier technique anonymisé

  - dossier logique anonymisé

  - statut

  - horodatage

- Rollback automatique en cas d'erreur DB

------------------------------------------------------------------------

## 4. Base de données

### 4.1 Tables principales

  --------------------------------------------------------------
  Table                Colonnes clés        Description
  -------------------- -------------------- --------------------
  users                email, api_token     Comptes techniques

  organizations        max_slots,           Paramètres CHU
                       webdav_url           

  terminals            device_uuid,         Terminaux enrôlés
                       terminal_secret      

  transfer_logs        terminal_id, status  Traçabilité
                                            technique
  --------------------------------------------------------------

### 4.2 Bonnes pratiques

- Transactions explicites

- API stateless

- Migrations automatiques sécurisées au démarrage

------------------------------------------------------------------------

## 5. Routes exposées

  ----------------------------------------------------------------------
  Route               Méthode         Authentification   Description
  ------------------- --------------- ------------------ ---------------
  /request-otp        POST            API Key            Génération OTP

  /get-config         POST            OTP                Configuration
                                                         WebDAV

  /check-auth         GET             Bearer             Vérification
                                                         terminal

  /revoke-terminal    POST            Bearer             Révocation

  /terminals/{uuid}   DELETE          API Key            Suppression

  /log-transfer       POST            Bearer             Log transfert
  ----------------------------------------------------------------------

------------------------------------------------------------------------

## 6. Hébergement

  --------------------------------------------------------------
  Composant            Hébergeur            Statut
  -------------------- -------------------- --------------------
  API / Backend        Infomaniak           Non-HDS

  --------------------------------------------------------------
