# 📊 Audit Complet et Nettoyage de l'Architecture du Projet

Ce document fournit un audit technique exhaustif de **tous les fichiers** présents dans le code source de l'application. Il détaille le rôle de chaque fichier et fournit des recommandations claires sous forme de voyants pour vous aider à **nettoyer le projet en toute sécurité** en éliminant les doublons, les fichiers de test temporaires et le code obsolète.

---

## 🎨 Légende des Voyants de Nettoyage

* 🟢 **ACTIF & INDISPENSABLE** : Fichier crucial, activement utilisé en production. **Ne pas toucher.**
* 🟡 **DOUBLON / À FUSIONNER** : Fichier fonctionnel mais redondant, dont le code devrait être fusionné avec un autre fichier pour simplifier la maintenance.
* 🔴 **INUTILE / À SUPPRIMER** : Fichier temporaire, brouillon de test, exemple ou relique d'ancien écran. **Peut être supprimé immédiatement sans aucun risque.**

---

## 📑 1. Dossier de Configuration (`lib/config/`)

Tous les fichiers de ce dossier sont indispensables au fonctionnement global de l'application et constituent le cœur du Design System et de l'infrastructure.

| Fichier | Statut | Rôle dans l'application | Action recommandée |
| :--- | :---: | :--- | :--- |
| `app_colors.dart` | 🟢 | Centralise la palette de couleurs unifiée (thèmes clair/sombre, couleur de focus des inputs, etc.). | **Garder** |
| `app_config.dart` | 🟢 | Définit les configurations globales (URL des serveurs d'API de production, clés secrètes). | **Garder** |
| `app_dimensions.dart` | 🟢 | Cœur du design adaptatif : gère les marges, arrondis et l'épaisseur unifiée des bordures de focus (`0.5`). | **Garder** |
| `app_typography.dart` | 🟢 | Configure les polices d'écriture Google Fonts (`Outfit` et `Roboto`) de manière globale. | **Garder** |

---

## 📂 2. Dossier des Exemples (`lib/examples/`)

Ce dossier a servi au prototypage local d'éléments visuels mais n'a aucun lien avec la production.

| Fichier | Statut | Rôle dans l'application | Action recommandée |
| :--- | :---: | :--- | :--- |
| `subtle_retry_button_examples.dart` | 🔴 | Démonstrations et cas d'usage visuels du bouton de reconnexion et d'essai. | **Supprimer** |

---

## 🏗️ 3. Fichiers et Fichiers Temporaires du Dossier Services (`lib/services/`)

C'est ici qu'on trouve le plus grand nombre de fichiers de test obsolètes et de doublons de fichiers d'API.

### 🔴 Fichiers de Test, Brouillons et Sauvegardes (À Supprimer Immédiatement)

| Fichier | Statut | Rôle dans l'application | Action recommandée |
| :--- | :---: | :--- | :--- |
| `auth_service copy.dart` | 🔴 | Copie de sauvegarde obsolète d'une ancienne version de l'authentification. | **Supprimer** |
| `mock_api_service.dart` | 🔴 | Contient des réponses d'API simulées et codées en dur, utilisées pendant la phase de maquettage initial. | **Supprimer** |
| `pouls_scolaire_example.dart` | 🔴 | Code d'exemple d'implémentation de requêtes API obsolète. | **Supprimer** |
| `jsonOptimise.json` | 🔴 | Fichier de données JSON temporaire resté dans le dossier de code. | **Supprimer** |
| `testObjet.json` | 🔴 | Exemple de réponse brute JSON restée dans le dossier de code. | **Supprimer** |
| `testObjet.optimized.json` | 🔴 | Fichier JSON de test optimisé volumineux. | **Supprimer** |
| `testObjet.optimized copy.json` | 🔴 | Doublon du fichier JSON de test. | **Supprimer** |

### 🟡 Doublons et Fichiers à Regrouper (À Fusionner)

| Fichier | Statut | Rôle dans l'application | Action de Fusion |
| :--- | :---: | :--- | :--- |
| `ecoles_api_service.dart` | 🟡 | Gère la liste générale des écoles. | **À fusionner** dans `ecole_api_service.dart` pour regrouper toute la logique d'établissement dans un fichier unique. |
| `message_api_service.dart` | 🟡 | Gère les requêtes d'envoi de messages individuels d'élèves. | **À fusionner** avec `message_service.dart` pour regrouper la messagerie instantanée. |
| `student_message_service.dart` | 🟡 | Gère les notifications de tchat de l'élève. | **À fusionner** également dans `message_service.dart`. |
| `video_api_service.dart` | 🟡 | Gère l'API d'interactions sur vidéos (likes/commentaires). | **À fusionner** avec `video_service.dart` pour tout centraliser au même endroit. |

### 🟢 Services d'API Actifs et Indispensables (À Conserver)

| Fichier | Statut | Rôle dans l'application | Action recommandée |
| :--- | :---: | :--- | :--- |
| `pouls_scolaire_api_service.dart`| 🟢 | **Service d'API majeur.** Regroupe l'immense majorité des endpoints de l'application. | **Garder absolument** |
| `database_service.dart` | 🟢 | Gère la base de données SQLite locale pour mémoriser les enfants, sessions et préférences. | **Garder** |
| `auth_service.dart` | 🟢 | Cœur de l'authentification et du maintien des sessions utilisateur. | **Garder** |
| `access_control_service.dart` | 🟢 | Service gérant le contrôle d'accès RFID aux barrières de l'école. | **Garder** |
| `access_log_service.dart` | 🟢 | Gère l'affichage des historiques des entrées et sorties des enfants. | **Garder** |
| `avis_service.dart` | 🟢 | Service gérant la soumission d'avis de l'école. | **Garder** |
| `blog_service.dart` | 🟢 | Service de récupération des actualités de l'école. | **Garder** |
| `bulletin_api_service.dart` | 🟢 | Gère l'historique académique des notes de l'élève. | **Garder** |
| `cart_service.dart` | 🟢 | Gère les ajouts, suppressions et calculs du panier Libouli en local. | **Garder** |
| `category_api_service.dart` | 🟢 | Gère les catégories de produits de la boutique. | **Garder** |
| `coulisse_excellence_service.dart`| 🟢 | Gère la récupération des coulisses de l'excellence (vidéos de l'école). | **Garder** |
| `echeance_service.dart` | 🟢 | Interroge les alertes de factures ou de retards scolaires. | **Garder** |
| `ecole_api_service.dart` | 🟢 | Récupère le profil détaillé d'une école sélectionnée. | **Garder** |
| `ecole_eleve_service.dart` | 🟢 | Lait le pont technique entre les écoles et les profils d'élèves. | **Garder** |
| `event_rating_service.dart` | 🟢 | Permet de noter les événements organisés par l'école. | **Garder** |
| `event_service.dart` | 🟢 | Gère l'affichage du calendrier des événements de l'école. | **Garder** |
| `extra_scolaire_service.dart` | 🟢 | Gère la souscription de services (cantine, transport) par élève. | **Garder** |
| `gallery_service.dart` | 🟢 | Gère le catalogue visuel d'images de l'école. | **Garder** |
| `gestion_presence_eleve_service.dart`| 🟢 | Assure le suivi de présence d'un élève. | **Garder** |
| `group_message_service.dart` | 🟢 | Gère le chargement des circulaires de l'établissement. | **Garder** |
| `http_service.dart` | 🟢 | Gestionnaire d'appels HTTP client de base. | **Garder** |
| `inscription_api_service.dart` | 🟢 | Gère les demandes d'inscription ou réinscription financière complète. | **Garder** |
| `integration_request_service.dart`| 🟢 | Gère le suivi et résultat de dossier d'intégration. | **Garder** |
| `integration_service.dart` | 🟢 | Cœur logique des demandes de transfert d'élèves. | **Garder** |
| `interaction_api_service.dart` | 🟢 | Cœur de synchronisation réseau des interactions vidéos (like/unlike). | **Garder** |
| `library_service.dart` | 🟢 | Gère les livres empruntés ou disponibles à la bibliothèque. | **Garder** |
| `lieu_livraison_service.dart` | 🟢 | Renvoie les communes et tarifs de livraison pour la boutique. | **Garder** |
| `message_service.dart` | 🟢 | Gère le tchat privé bilatéral parent-enseignant. | **Garder** |
| `niveau_service.dart` | 🟢 | Récupère les classes scolaires supportées par l'école. | **Garder** |
| `notes_api_service.dart` | 🟢 | Gère l'affichage des notes des devoirs scolaires. | **Garder** |
| `notification_service.dart` | 🟢 | Service système d'enregistrement et d'affichage des badges et notifications. | **Garder** |
| `order_service.dart` | 🟢 | Validation et suivi de traitement des paniers Libouli. | **Garder** |
| `paiement_historique_service.dart`| 🟢 | Gère le chargement des factures et quittances déjà réglées. | **Garder** |
| `paiement_service.dart` | 🟢 | Gère l'initialisation de transactions Mobile Money sécurisées. | **Garder** |
| `parent_suggestion_service.dart` | 🟢 | Service gérant la recommandation d'écoles non-partenaires. | **Garder** |
| `parrainage_service.dart` | 🟢 | Gère la récupération des filleuls et des gains générés par le parent. | **Garder** |
| `place_reservation_service.dart` | 🟢 | Gère les pré-réservations de classes par acomptes. | **Garder** |
| `produit_service.dart` | 🟢 | Charge la liste des articles e-commerce (uniformes, sacs, etc.). | **Garder** |
| `recommendation_service.dart` | 🟢 | Service suggérant des établissements pertinents aux parents. | **Garder** |
| `remote_api_service.dart` | 🟢 | Gestionnaire technique générique des requêtes serveurs. | **Garder** |
| `school_service.dart` | 🟢 | Fournit des outils généraux de gestion de l'école. | **Garder** |
| `school_supply_service.dart` | 🟢 | Fournit la liste officielle des fournitures requises par classe. | **Garder** |
| `scolarite_service.dart` | 🟢 | Calculatrice financière globale de scolarité par élève. | **Garder** |
| `sms_service.dart` | 🟢 | Authentification et envoi de codes de sécurité temporaires OTP par SMS. | **Garder** |
| `statistiques_presence_service.dart`| 🟢 | Calculateur des taux de présences et absences annuelles. | **Garder** |
| `student_detail_service.dart` | 🟢 | Renvoie les fiches d'élèves lors de leur liaison par le parent. | **Garder** |
| `student_scolarite_service.dart` | 🟢 | Gère le récapitulatif financier et les versements d'un élève. | **Garder** |
| `student_timetable_service.dart` | 🟢 | Service d'extraction de l'emploi du temps de l'étudiant. | **Garder** |
| `system_ui_service.dart` | 🟢 | Permet de changer la couleur de la barre de statut de l'OS. | **Garder** |
| `testimonial_service.dart` | 🟢 | Gère les retours et évaluations rédigés par les parents. | **Garder** |
| `text_size_service.dart` | 🟢 | **Service d'accessibilité central.** Distribue la taille de police personnalisée à toute l'app. | **Garder absolument** |
| `theme_service.dart` | 🟢 | Centralise le choix du mode sombre/clair persistant. | **Garder** |
| `ticket_service.dart` | 🟢 | Réservation et validation de QR Codes pour la billetterie scolaire. | **Garder** |
| `video_service.dart` | 🟢 | Gère la lecture des liens Youtube pour les coulisses de l'excellence. | **Garder** |
| `visite_guidee_service.dart` | 🟢 | Gère le fil de vidéos de visite virtuelle d'écoles. | **Garder** |

---

## 📱 4. Dossier des Écrans (`lib/screens/`)

Ce dossier contient les vues et pages. Un vieil écran inutile et un écran au nom trompeur y figurent.

| Écran | Statut | Rôle dans l'application | Recommandation |
| :--- | :---: | :--- | :--- |
| `fees_screen.dart` | 🔴 | Ancien écran de tarifs scolaires statiques. | **À supprimer**. Remplacé avantageusement par `student_scolarite_screen.dart` qui charge les données financières dynamiquement ! |
| `notes_screen_json.dart` | 🟢 | **Écran principal des notes scolaires (Bulletins).** | **Garder précieusement**. Malgré la présence de `_json` dans son nom, c'est l'écran actif qui est importé pour afficher les notes ! |
| `child_list_screen.dart` | 🟢 | **Cœur de l'application (470 Ko+).** Gère le tableau de bord complet avec les onglets de détails des enfants (Absences, Emploi du temps, Scolarité). | **Garder absolument** |
| `new_settings_screen.dart`| 🟢 | Nouvel écran de paramètres complet (préférences, taille texte, dark mode). | **Garder** |
| *Tous les autres écrans* | 🟢 | Écrans standards opérationnels (Boutique, Tchat, Événements, Panier, Connexion, Profil, etc.). | **Garder** |

---

## 🛠️ 5. Dossiers de Base (`lib/utils/` et `lib/widgets/`)

Ces deux répertoires contiennent vos outils partagés et vos composants d'interface. Ils sont tous **100 % actifs et propres** (les doublons y ont déjà été nettoyés dans les étapes antérieures).

* **`lib/utils/`** : `api_exception_handler.dart` (🟢), `image_helper.dart` (🟢), `notification_helper.dart` (🟢), `responsive_helper.dart` (🟢) sont **actifs**.
* **`lib/widgets/`** : Tous les composants partagés comme `SearchableDropdown` (🟢), `CustomTextField` (🟢), `BottomSheetHeader` (🟢), `PaymentBottomSheet` (🟢), et les sous-dossiers comme `lib/widgets/bottom_sheets/` (🟢) et `lib/widgets/components/` (🟢) sont **activement utilisés**.

---

## 🚀 Plan d'action recommandé pour le Nettoyage

Pour faire un nettoyage propre de votre projet, vous pouvez ouvrir votre terminal et exécuter ces étapes simples de suppression :

```bash
# 1. Suppression des fichiers d'exemples et d'écrans obsolètes
rm lib/examples/subtle_retry_button_examples.dart
rm lib/screens/fees_screen.dart

# 2. Suppression des copies de sauvegarde et fichiers de mock temporaires
rm lib/services/auth_service\ copy.dart
rm lib/services/mock_api_service.dart
rm lib/services/pouls_scolaire_example.dart

# 3. Suppression des fichiers de test JSON volumineux
rm lib/services/jsonOptimise.json
rm lib/services/testObjet.json
rm lib/services/testObjet.optimized.json
rm lib/services/testObjet.optimized\ copy.json
```

Ce nettoyage vous permettra de libérer de l'espace, d'accélérer la compilation et de conserver un projet Flutter 100 % propre et structuré !
