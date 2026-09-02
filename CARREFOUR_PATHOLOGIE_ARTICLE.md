# 🔬 Communication Carrefour Pathologie

**Titre :** *De la paillasse au SGL : Numérisation et traçabilité de l'imagerie macroscopique par smartphone sécurisé et agent de synchronisation autonome.*

**Auteurs :**  
Dr Franck Monnien (PhD)¹*, Pr Frédéric Bibeau²  
¹ *Ingénieur de recherche, Service d’Anatomie Pathologique, CHU de Besançon*  
² *Chef de service d’Anatomie Pathologique, CHU de Besançon*  
*\* Auteur correspondant : contact@macroscopix.fr*

---

## 📝 Résumé (Abstract)

La documentation photographique macroscopique est devenue une étape incontournable du diagnostic anapath et de la recherche en anatomie pathologique. Cependant, la chaîne d'acquisition traditionnelle (appareil photo compact, transfert par carte SD ou câble, renommage manuel et import SGL) reste une source majeure de perte de temps et de risque d'erreur d'identification. 

Nous présentons **MacroscopiX**, une solution logicielle développée au CHU de Besançon combinant une application mobile d'acquisition sécurisée et un agent de synchronisation Windows autonome (`MacroscopiX Sync`). MacroscopiX permet le scan instantané du code-barres examen, la prise de vue haute définition et l'intégration automatique des clichés dans le dossier patient du SGL, sans aucun stockage local sur le smartphone et sans nécessiter de droits administrateur système.

---

## 1. 🏥 Introduction & Problématique Terrain

Dans le quotidien d'un laboratoire d'Anatomie et Cytologie Pathologiques (ACP), la prise de vue macroscopique répond à une triple exigence : **médico-légale, diagnostique et pédagogique**.

Pourtant, le workflow conventionnel souffre de multiples ruptures de charge :
- **Manipulation lourde :** Prise en main d'appareils photo dédiés volumineux ou mal adaptés au milieu propre/sale de la paillasse.
- **Saisie manuelle fastidieuse :** Recopie manuelle du numéro d'anapath, renommage des fichiers image (`IMG_0042.jpg` -> `A26-12345_01.jpg`).
- **Risque d'erreur d'identitovigilance :** Inversion d'images entre deux pièces d'exérèse lors des transferts par cartes mémoire.
- **Contraintes informatiques (DSI) :** Difficulté d'intégrer des équipements mobiles dans le réseau hospitalier sans alourdir la maintenance.

---

## 2. 💡 Matériel & Méthodes : La Solution MacroscopiX

MacroscopiX a été conçu directement sur la paillasse du CHU de Besançon pour répondre à ces défis sans altérer les habitudes des équipes.

```
[ Paillasse / Smartphone ]            [ Transfert Sécurisé ]           [ PC Poste de Travail ]
+-------------------------+            +--------------------+           +----------------------+
| 1. Scan Code-Barre      |  HTTPS/TLS | Cloud HDS /        | WebDAV    | MacroscopiX Sync     |
| 2. Prise de vue HD      | ---------> | Serveur On-Premise | --------> | (Agent Utilisateur)  |
| 3. Traitement en RAM    |            +--------------------+           | -> Dossier SGL / NAS |
+-------------------------+                                             +----------------------+
```

### A. Application Mobile (iOS / Android)
- **Scan intelligent :** Lecture optique du code-barres sur le bulletin de demande ou le cassette/pot de prélèvement.
- **Nommage dynamique :** Génération automatique du nom de fichier selon la nomenclature exacte du laboratoire.
- **Sécurité & RGPD (Zero Trust Mobile) :** Aucun fichier n'est conservé dans la mémoire ou la galerie du smartphone. L'image est traitée en mémoire vive (RAM) et immédiatement transmise sous flux chiffré (TLS 1.2+).

### B. Agent de Synchronisation PC (`MacroscopiX Sync v2.0`)
- **Déploiement en 3 clics ("Juste pour vous") :** L'agent s'installe directement dans la session de l'utilisateur sans aucun privilège ni mot de passe administrateur Windows.
- **Raccordement natif au réseau (`Z:\...`) :** S'exécutant sous le contexte utilisateur, l'agent accède directement aux lecteurs réseau partagés et au dossier de réception du SGL.
- **Console d'activité Live :** Validation visuelle en temps réel (`✅ Image reçue : A26-12345_01.jpg`) assurant une réassurance immédiate pour le pathologiste et le technicien.

---

## 3. 📊 Résultats & Retour d'Expérience

Déployée en conditions réelles d'exploitation au CHU de Besançon, la solution MacroscopiX démontre :

1. **Un gain de temps significatif :** Réduction du temps consacré à la gestion documentaire macroscopique de **plus de 70%** par examen.
2. **Une identitovigilance irréprochable :** Élimination totale des erreurs de couplage "Image / Patient" grâce au nommage à la source par scan.
3. **Une adoption immédiate :** Prise en main en moins de 2 minutes par les pathologistes et techniciens, sans formation complexe.
4. **Une empreinte DSI nulle :** Zéro ticket support grâce à l'installation en mode utilisateur sans privilèges administrateur.

> *"Macroscopix permet de réaliser des clichés de qualité de façon très réactive, tout en sécurisant des pratiques existantes. Un gain de temps réel pour les équipes."*  
> — **Pr Frédéric Bibeau**, Chef de service d'Anatomie Pathologique, CHU de Besançon.

---

## 4. 🎯 Conclusion & Perspectives

MacroscopiX prouve qu'il est possible de concilier la souplesse d'un outil mobile moderne avec les exigences de sécurité et de traçabilité des données de santé. Née du terrain, la solution s'adapte aussi bien aux structures hospitalières universitaires qu'aux cabinets privés d'anatomie pathologique.

---

**Consultez la démonstration et la documentation :**  
🌐 Site officiel : [https://www.macroscopix.fr](https://www.macroscopix.fr)  
✉️ Contact : [contact@macroscopix.fr](mailto:contact@macroscopix.fr)  
🧪 Profil scientifique : [ResearchGate — Dr Franck Monnien](https://www.researchgate.net/profile/Franck-Monnien)
