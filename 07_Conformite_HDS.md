# Audit Technique : Conformité & Hébergement HDS (MacroscopiX)

**Document :** Fiche de Conformité Réglementaire Hébergement de Données de Santé (HDS)  
**Version :** 2.5 (Production - Octobre 2026)  
**Destinataires :** RSSI, DPO, DSI des Établissements de Santé (CHU, CH, ESPIC)

------------------------------------------------------------------------

## 1. Cadre Légal et Réglementaire

Conformément à l'**article L. 1111-8 du Code de la Santé Publique** et au **décret n° 2018-137 du 26 février 2018**, tout hébergement de données de santé à caractère personnel recueillies lors d'activités de prévention, de diagnostic, de soins ou de suivi médico-social doit obligatoirement être confié à un organisme certifié **HDS (Hébergeur de Données de Santé)**.

L'architecture Cloud de transit de MacroscopiX repose **exclusivement sur des sous-traitants d'infrastructure titulaires d'un certificat HDS v2.0 en cours de validité**, vérifiables sur le registre national officiel de l'**Agence du Numérique en Santé (ANS)**.

------------------------------------------------------------------------

## 2. Registre des Prestataires d'Infrastructure et Certifications

Toutes les données de santé transitant par MacroscopiX sont traitées et stockées **100 % sur le territoire français**, sous souveraineté juridique européenne (RGPD), sans transfert vers des juridictions tierces.

| Fournisseur | Rôle dans l'Architecture | Datacenters | Certifications Détenues | Référencement Officiel ANS |
|---|---|---|---|---|
| **SCALINGO** (Scalingo SAS) | **Serveur de Calcul WebDAV** (Compute, traitement en mémoire vive RAM) | Paris / Roubaix (France) | • **HDS v2.0** (Activités 1 à 6)<br>• **ISO 27001:2022**<br>• Hébergeur d'Infrastructures & Infogéreur | [Consulter sur esante.gouv.fr](https://esante.gouv.fr/offres-services/hds/liste-des-hebergeurs-certifies) |
| **SCALEWAY** (Scaleway SAS - Groupe iliad) | **Stockage Objet S3 HDS** (Chiffrement AES-256 natif au repos, rétention tampon) | Région Paris `fr-par` / DC2-DC3-DC5 (France) | • **HDS v2.0** (Activités 1 à 6)<br>• **ISO 27001:2022**<br>• **ISO 50001** / Souveraineté UE | [Consulter sur esante.gouv.fr](https://esante.gouv.fr/offres-services/hds/liste-des-hebergeurs-certifies) |
| **INFOMANIAK** (Infomaniak Network SA) | **Serveur d'Enrôlement / Gestion Admin** *(Hors périmètre HDS : 0 donnée de santé)* | Genève (Suisse, adéquation RGPD) | • **ISO 27001**<br>• **ISO 9001**<br>• Tier III+ souverain | *N/A (Uniquement métadonnées techniques)* |

> **Lien officiel de vérification de l'État :**  
> La liste exhaustive des hébergeurs certifiés HDS délivrée par les organismes accrédités (AFNOR, Bureau Veritas, BSI, LSTI) est librement consultable en ligne sur le portail ministériel de l'ANS :  
> 👉 [https://esante.gouv.fr/offres-services/hds/liste-des-hebergeurs-certifies](https://esante.gouv.fr/offres-services/hds/liste-des-hebergeurs-certifies)

------------------------------------------------------------------------

## 3. Matrice des 6 Activités du Référentiel HDS

Le référentiel HDS de l'ANS définit 6 activités réglementaires. La chaîne de confiance MacroscopiX couvre l'ensemble de ce périmètre :

| Activité HDS | Libellé Réglementaire | Prestataire Couvrant |
|---|---|---|
| **Activité 1** | Mise à disposition et maintien en condition opérationnelle (MCO) des sites physiques | Scalingo / Scaleway |
| **Activité 2** | Mise à disposition et MCO des infrastructures matérielles | Scalingo / Scaleway |
| **Activité 3** | Mise à disposition et MCO de la plateforme d'hébergement applicative | Scalingo |
| **Activité 4** | Mise à disposition et MCO de l'infrastructure virtuelle | Scalingo / Scaleway |
| **Activité 5** | Administration et exploitation du système d'information | Scalingo / Scaleway |
| **Activité 6** | Sauvegarde et réplication externalisée | Scaleway (Object Storage Multi-AZ) |

------------------------------------------------------------------------

## 4. Garanties de Sécurité & Non-Persistance HDS

1. **Architecture Éphémère (Sas de Transit Stateless) :**  
   L'infrastructure cloud MacroscopiX n'est en aucun cas un lieu d'archivage pérenne des dossiers patients. Elle agit comme une passerelle sécurisée de relais. Les données sont purgées dès téléchargement validé par l'établissement local.
2. **Double Filet de Sécurité de Purge :**  
   - Commande `DELETE` émise par l'agent local dès vérification d'intégrité de transfert (`Content-Length`).
   - Règle matérielle S3 **Lifecycle Policy de 24 heures** détruisant tout fichier n'ayant pas été purgé (ex. coupure d'infrastructure du CHU).
3. **Chiffrement de Bout en Bout :**  
   - En transit : TLS 1.2 / TLS 1.3 avec suites cryptographiques fortes (PFS).
   - Au repos : Chiffrement natif AES-256 (SSE-S3) sur les disques physiques des datacenters.
4. **Cloisonnement Hermétique Multi-Établissements :**  
   Chaque CHU possède son jeton technique dédié et une racine de stockage verrouillée (`chroot`). Aucune visibilité transversale n'est possible entre les données de différents hôpitaux.

------------------------------------------------------------------------

## 5. Synthèse pour le DPO et le RSSI

- **Localisation des Données Médicales :** 100 % France (Datacenters certifiés).
- **Conformité Réglementaire :** Conforme Art. L. 1111-8 CSP et RGPD (Art. 28, 32).
- **Statut HDS :** Porté par des acteurs certifiés HDS de plein droit inscrits sur la liste ANS.
- **Réversibilité / Restitution :** Les données étant immédiatement rapatriées dans le SIH de l'établissement, le CHU conserve 100 % de la propriété et de la maîtrise souveraine de ses clichés et enregistrements.
