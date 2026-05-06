# Audit Technique : Application Mobile Android

**Application :** MacroscopiX Mobile\
**OS Cible :** Android 7.0+ (Min SDK 24) -\> Android 15 (Target SDK 36)\
**Langage :** Kotlin / Jetpack Compose

------------------------------------------------------------------------

## 1. Analyse Statique du Code

### 1.1 Stack Technique

L'application est développée en **Kotlin** natif, utilisant les
standards modernes recommandés par Google (Modern Android Development) :

- **UI** : Jetpack Compose (Déclaratif, réduit les risques de bugs
  d'interface).

- **Réseau** : Retrofit + OkHttp (Standard industriel robuste).

- **Image Processing** : MLKit (Scan code-barres) + CameraX (Gestion
  caméra unifiée).

- **Architecture** : MVVM (Model-View-ViewModel) assurant une séparation
  des responsabilités.

### 1.2 Permissions Demandées

L'application respecte le principe de moindre privilège. -
android.permission.CAMERA : Indispensable pour la capture. -
android.permission.INTERNET : Indispensable pour le transfert. - **Pas
de permission de stockage** (READ/WRITE_EXTERNAL_STORAGE) demandée sur
Android 10+, garantissant que l'appli ne peut pas lire les autres
fichiers du téléphone.

### 1.3 Configuration de Build (build.gradle.kts)

- **Minification** : isMinifyEnabled = true en Release. Le code est
  offusqué via **R8/ProGuard**, rendant le reverse engineering
  difficile.

- **Target SDK 36** : L'application cible la toute dernière version
  d'Android, intégrant les dernières protections système (Sandbox
  renforcée).

------------------------------------------------------------------------

## 2. Analyse de Sécurité Mobile

### 2.1 Gestion des Données en Local

- **Photos** : Les images capturées sont stockées dans le répertoire
  "Cache" ou "Files" privé de l'application (Context.getCacheDir()),
  inaccessible aux autres applications (sandbox). Elles sont supprimées
  dès le succès de l'upload.

- **Logs** : L'application n'écrit pas de logs applicatifs persistants
  contenant des données sensibles.

### 2.2 Authentification et Secrets

- **Stockage** : Les tokens d'authentification et mots de passe WebDAV
  ne sont pas stockés en clair dans les SharedPreferences mais chiffrés
  ou isolés.

- **Communication** :

  - networkSecurityConfig est présent, permettant de forcer le HTTPS et
    de gérer les certificats de confiance.

  - Utilisation stricte de TLS pour toute communication réseau.

### 2.3 Dépendances

Les librairies tierces sont maintenues et standard :

- com.squareup.okhttp3 : Client HTTP sécurisé.

- io.ktor : Client HTTP alternatif.

- Pas de librairies publicitaires ou de traçage commercial intrusif.
