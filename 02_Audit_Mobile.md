# Audit Technique : Application Mobile Android

**Application :** MacroscopiX Mobile\
**Version :** 2.5 (Production)\
**OS Cible :** Android 7.0+ (Min SDK 24) -> Android 15 (Target SDK 36)\
**Langage :** Kotlin / Jetpack Compose

------------------------------------------------------------------------

## 1. Analyse Statique du Code

### 1.1 Stack Technique

L'application est développée en **Kotlin** natif, utilisant les
standards modernes recommandés par Google (Modern Android Development) :

- **UI** : Jetpack Compose (Déclaratif, réactif, élimine les fuites de vues et réduit les failles d'interface).
- **Réseau** : Retrofit + OkHttp 4.x (Standard industriel robuste avec gestion fine des timeouts à 120s et du pool de connexions TLS 1.3).
- **Capture & Traitement d'Images** : MLKit Barcode Scanning (Scan instantané des identifiants d'examen) + CameraX (Gestion caméra matérielle unifiée et optimisée).
- **Enregistrement Audio (Dictaphone)** : AudioRecord / AudioTrack natif avec conversion directe en flux WAV non compressé (16-bit PCM, qualité médicale).
- **Scanner Documentaire (PDF)** : Module de numérisation haute lisibilité avec génération dynamique de documents PDF multi-pages.
- **R&D Embarquée (IA & Métrologie)** : Modules OpenCV / ArUco (détection de mires millimétrées) et YOLO v8 (détection d'organes/prélèvements), isolés et désactivables.
- **Architecture** : MVVM (Model-View-ViewModel) avec StateFlow / Coroutines assurant un découplage strict entre couche logique et couche de présentation.

### 1.2 Permissions Demandées et Principe du Moindre Privilège

L'application applique strictement le principe du moindre privilège :

- `android.permission.CAMERA` : Indispensable pour l'acquisition photographique macroscopique, le scan de code-barres et la numérisation de documents.
- `android.permission.RECORD_AUDIO` : Requis exclusivement pour le module dictaphone médical (enregistrement des comptes-rendus vocaux de macroscopie).
- `android.permission.INTERNET` : Indispensable pour le transfert chiffré vers les serveurs HDS et l'enrôlement OTP.
- **Aucune permission de stockage externe** (`READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`) n'est requise ni sollicitée sur Android 10+ (API 29+), garantissant l'impossibilité technique pour l'application d'accéder aux photos, documents ou fichiers personnels du terminal.

### 1.3 Configuration de Build (build.gradle.kts)

- **Minification et R8** : `isMinifyEnabled = true` et `isShrinkResources = true` en Release. Le bytecode est offusqué et optimisé via **R8/ProGuard**, rendant l'ingénierie inverse et la décompilation extrêmement difficiles.
- **Target SDK 36** : L'application bénéficie de l'ensemble des mécanismes de sécurité récents du système Android (Sandboxing renforcé, restrictions strictes sur l'accès aux identifiants matériels globaux, gestion granulaire de la mémoire).

------------------------------------------------------------------------

## 2. Analyse de Sécurité Mobile

### 2.1 Gestion des Données en Local (Zéro Persistance)

- **Photos & Images Médicales** : Traitées en mémoire vive (RAM) et temporairement stockées dans le cache privé de l'application (`Context.getCacheDir()`), inaccessible aux autres applications du système (Sandbox Linux Android). Elles sont effacées de manière irréversible dès réception du code de succès HTTP (201/204) du serveur WebDAV HDS.
- **Enregistrements Vocaux (Audio WAV)** : Les flux audio sont capturés et assemblés dans un buffer mémoire / cache applicatif privé. Aucun fichier audio n'est copié dans le dossier `Music/` ou `Recordings/` public. Suppression immédiate après confirmation d'envoi.
- **Numérisations de Documents (PDF)** : Assemblage du PDF directement dans le cache sandbox privé, puis purge immédiate après acquittement.
- **Absence de Galerie Publique** : À aucun moment les médias acquis ne sont insérés dans le `MediaStore` ou visibles dans l'application Google Photos / Galerie du smartphone.
- **Absence de Logs Médicaux** : Aucun log persistant ne contient de données de santé, de noms de patients ou d'identifiants cliniques en clair.

### 2.2 Authentification et Protection des Secrets

- **Stockage Sécurisé des Clés** : Les tokens d'enrôlement, secrets de terminaux et credentials WebDAV sont stockés via le composant **Android Keystore**, bénéficiant de la protection matérielle de l'enclave sécurisée du processeur (TEE / StrongBox).
- **Chiffrement des Flux Réseau** :
  - `networkSecurityConfig` configuré pour interdire formellement tout trafic HTTP en clair (`cleartextTrafficPermitted="false"`).
  - Négociation forcée en **TLS 1.2 / TLS 1.3** avec validation stricte de la chaîne d'autorité de certification.
  - Timeouts étendus (120 secondes sur OkHttp) évitant les abandons de requêtes lors des commutations d'antennes ou de bornes Wi-Fi hospitalières.

### 2.3 Dépendances et Tiers

- Librairies tierces sélectionnées selon les standards de l'ANSSI / OWASP Mobile Security :
  - `com.squareup.okhttp3` / `retrofit2` : Communications HTTP sécurisées sans dépendances superflues.
  - `com.google.mlkit:barcode-scanning` : Traitement local on-device (aucun appel réseau vers Google Cloud pour le décodage des codes-barres).
- Absence totale de SDK publicitaires, de trackers analytics tiers (Google Analytics, Firebase Crashlytics commercial) ou de frameworks de monétisation.

