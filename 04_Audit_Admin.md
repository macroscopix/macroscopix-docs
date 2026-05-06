#  Audit Technique : Backend d'Administration Macroscopix

**Composant :** Backend d'administration (Console Web)\
**Technologie :** PHP 8.x, PostgreSQL\
**Rôle :** Gestion administrative, enrôlement des terminaux, supervision
et journalisation technique

------------------------------------------------------------------------

## 1. Objectif et périmètre

Le backend d'administration Macroscopix assure exclusivement des
fonctions de gestion technique :

\- administration des terminaux enrôlés,

\- supervision des accès et des configurations,

\- consultation des journaux techniques,

\- paramétrage des accès WebDAV.

Ce backend : ne stocke aucune image, ne traite aucune donnée de santé,
ne contient aucun identifiant patient ou lien patient--fichier.

Il est strictement séparé du serveur WebDAV certifié HDS, qui est le
seul composant manipulant des données de santé.

------------------------------------------------------------------------

## 2. Architecture et positionnement

- Application PHP stateless, accessible uniquement en HTTPS.

- Hébergement hors périmètre HDS (absence de données de santé).

- Accès restreint aux personnels autorisés (administrateurs techniques).

------------------------------------------------------------------------

## 3. Authentification et contrôle d'accès

### 3.1 Authentification forte (2FA)

- Authentification par mot de passe + OTP.

- Mise en œuvre via une librairie compatible Google Authenticator.

- Validation OTP avec fenêtre temporelle restreinte.

### 3.2 Protection contre les abus

- Limitation du nombre de tentatives d'authentification.

- Blocage temporaire après échecs répétés.

- Messages d'erreur non différenciants pour éviter toute fuite
  d'information.

- Journalisation systématique des tentatives échouées.

------------------------------------------------------------------------

## 4. Gestion des sessions

- Sessions PHP stockées côté serveur.

- Cookies de session sécurisés :

  - HttpOnly,

  - Secure,

  - SameSite=Strict.

- Expiration automatique des sessions inactives.

- Destruction explicite de la session lors de la déconnexion.

------------------------------------------------------------------------

## 5. Gestion des secrets et des configurations

- Aucun secret stocké en clair dans le code source.

- Utilisation exclusive de variables d'environnement pour :

  - clés TOTP,

  - clés API internes,

  - paramètres sensibles.

- Séparation des secrets par environnement (développement / production).

- Rotation des secrets possible sans modification du code.

------------------------------------------------------------------------

## 6. Journalisation et traçabilité

### 6.1 Contenu des logs

Les journaux contiennent uniquement des informations techniques : -
horodatage, - type d'événement (connexion, action admin, erreur), -
identifiant technique de l'administrateur ou du terminal, - adresse IP
source.

### 6.2 Données explicitement exclues

- aucune donnée patient,

- aucun identifiant médical,

- aucun contenu image,

- aucun hash de fichier image.

Les logs sont **non ré-identifiants** et conformes aux principes de
minimisation des données (RGPD).

------------------------------------------------------------------------

## 7. Sécurité applicative

### 7.1 En-têtes HTTP de sécurité

Les en-têtes suivants sont activés : - Strict-Transport-Security
(HSTS), - Content-Security-Policy (CSP), - X-Frame-Options: DENY, -
X-Content-Type-Options: nosniff, - Referrer-Policy: no-referrer.

### 7.2 Réduction de la surface d'attaque

- Aucun upload de fichier.

- Aucun endpoint public non authentifié.

- Aucune exécution de code fournie par l'utilisateur.

- Pas de base de données contenant des données sensibles.

------------------------------------------------------------------------

## 8. Séparation des responsabilités (Security by Design)

  --------------------------------------------------------------
  Composant            Rôle                 Données traitées
  -------------------- -------------------- --------------------
  Backend admin        Administration       Métadonnées
                       technique            

  Serveur WebDAV HDS   Transit fichiers     Images

  SI hospitalier       Dossier patient      Données médicales
  --------------------------------------------------------------

Cette séparation empêche toute reconstitution de données de santé depuis
le backend d'administration.

------------------------------------------------------------------------

## 9. Conformité réglementaire et statut HDS

Le backend d'administration est **hors périmètre HDS**, car : - il ne
stocke ni ne traite de données de santé, - il ne permet aucune
identification de patient, - il est limité à des fonctions techniques et
administratives.

Il respecte les principes suivants : - Privacy by Design, - Least
Privilege, - Defense in Depth.
