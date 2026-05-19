# 📋 Guide de Test des Fonctionnalités pour la Validation Google Play

> **À destination de :** L'équipe de validation de Google Play (Google Play Console Review Team)
> **Application :** Pouls Mobile (Application Parent d'élèves)
> **Objectif du document :** Fournir les étapes pas-à-pas pour tester chaque module fonctionnel de l'application "Pouls Mobile" afin de faciliter et d'accélérer le processus de validation.

---

## 🔑 1. Identifiants de Test et Accès

Pour commencer l'examen, veuillez vous connecter avec le compte de test configuré ci-dessous.

### 👤 Compte de Test Principal (Parent d'élève)
* **Numéro de téléphone de test :** `+225 07 48 01 12 47` (ou tout autre numéro de test configuré dans votre API active)
* **Mot de passe :** Aucun (connexion directe par API sécurisée sans mot de passe).
* **Code OTP de contournement (si requis lors de l'inscription) :** `123456`

---

## 🧭 2. Scénarios de Test Étape par Étape par Fonctionnalité

Veuillez suivre les étapes ci-dessous pour tester l'intégralité de l'expérience parent dans l'application.

---

### 📂 A. Tableau de Bord et Suivi Scolaire de l'Élève

Ce module permet au parent de suivre en temps réel la vie scolaire de son enfant (Emploi du temps, Notes, Absences, Accès).

#### 1. Consultation de l'Emploi du Temps (`student_timetable_screen.dart`)
* **Étape 1 :** Depuis l'écran d'accueil, sélectionnez la fiche de l'élève (ex: "Koffi Kouassi").
* **Étape 2 :** Cliquez sur le bouton **Emploi du temps**.
* **Étape 3 :** Naviguez entre les jours de la semaine (Lundi à Vendredi) pour visualiser les cours de l'élève, les horaires, les salles de classe et les enseignants correspondants.

#### 2. Suivi des Notes et Bulletins (`notes_screen.dart`)
* **Étape 1 :** Cliquez sur l'onglet ou le bouton **Notes et Bulletins** depuis le menu de l'élève.
* **Étape 2 :** Visualisez les notes des différents trimestres/semestres classées par matière.
* **Étape 3 :** Cliquez sur le bouton de téléchargement du bulletin scolaire officiel au format PDF.

#### 3. Contrôle d'Accès et Registre des Absences (`student_access_control_screen.dart`)
* **Étape 1 :** Cliquez sur **Contrôle d'accès** ou **Registre de Présences**.
* **Étape 2 :** Visualisez le journal des pointages RFID (entrées et sorties physiques de l'établissement avec heures exactes).
* **Étape 3 :** Examinez les statistiques globales d'assiduité (taux de présence annuel, nombre d'absences justifiées ou non).

---

### 💳 B. Suivi Financier et Paiement des Frais Scolaires

Ce module gère le suivi comptable des frais de scolarité et permet le règlement direct par paiement mobile.

#### 4. État Financier de la Scolarité (`student_scolarite_screen.dart`)
* **Étape 1 :** Sur le profil de l'élève, cliquez sur le bouton **Scolarité et Paiements**.
* **Étape 2 :** Visualisez la barre de progression des paiements (Total Dû vs Total Payé vs Reste à Payer).
* **Étape 3 :** Consultez l'échéancier des versements (mensuels ou trimestriels) avec les dates limites de paiement.

#### 5. Paiement de la Scolarité en Ligne (`fees_screen.dart` / API `/scolarite/paiement-en-ligne`)
* **Étape 1 :** Depuis l'écran de scolarité, cliquez sur **Effectuer un paiement**.
* **Étape 2 :** Saisissez un montant fictif à régler et sélectionnez le moyen de paiement (Orange Money, Wave, etc.).
* **Étape 3 :** Validez la transaction fictive pour voir la confirmation de l'enregistrement et la mise à jour immédiate du reste à payer.

---

### 💬 C. Messagerie et Communication Directe

Ce module assure le lien de communication directe entre la direction de l'école, les enseignants et les parents.

#### 6. Notifications et Circulaires de l'École (`messages_screen.dart`)
* **Étape 1 :** Cliquez sur l'icône **Messagerie** ou **Notification** de la barre de navigation inférieure.
* **Étape 2 :** Dans l'onglet **Annonces de l'école**, lisez les communiqués généraux publiés par l'administration.
* **Étape 3 :** Cliquez sur un message pour le marquer comme lu et observez la mise à jour du compteur de notifications.

#### 7. Chat Bidirectionnel avec les Enseignants (`student_messages_screen.dart`)
* **Étape 1 :** Sélectionnez l'onglet **Messages privés** ou cliquez sur un enseignant dans la liste des contacts de la classe.
* **Étape 2 :** Saisissez un message textuel dans la zone de saisie et cliquez sur envoyer.
* **Étape 3 :** Testez l'envoi d'une pièce jointe (document ou photo de justificatif d'absence).

---

### 🛒 D. E-Commerce Libouli & Fournitures Scolaires (`shop_screen.dart`)

Ce module permet aux parents d'acheter les fournitures scolaires, livres et uniformes recommandés directement depuis l'application.

#### 8. Achat de Fournitures Scolaires
* **Étape 1 :** Dans la barre de navigation inférieure, cliquez sur l'onglet **Boutique**.
* **Étape 2 :** Naviguez parmi les catégories de produits (Manuels, Sacs, Uniformes, Papeterie).
* **Étape 3 :** Cliquez sur un produit (ex: "Sac à dos Pouls") pour ouvrir sa fiche détaillée (`product_detail_screen.dart`), choisissez une taille/option et cliquez sur **Ajouter au panier**.
* **Étape 4 :** Accédez au **Panier** (`cart_screen.dart`), sélectionnez le mode de livraison (Livraison à domicile ou Retrait à l'école) et validez la commande fictive pour voir le suivi dans l'historique (`orders_screen.dart`).

---

### 🎟️ E. Événements et Billetterie Scolaire (`all_events_screen.dart`)

Permet de réserver et d'acheter des places pour les événements officiels de l'établissement (fête de fin d'année, kermesse).

#### 9. Réservation et Achat de Tickets
* **Étape 1 :** Depuis le tableau de bord ou l'onglet actualités, sélectionnez un événement dans la liste.
* **Étape 2 :** Cliquez sur **Participer** ou **Réserver des tickets**.
* **Étape 3 :** Sélectionnez le nombre de places pour chaque catégorie (VIP, Standard).
* **Étape 4 :** Une fois la réservation complétée, accédez à l'onglet **Mes Tickets** (`my_tickets_screen.dart`) pour visualiser le QR Code officiel généré pour l'entrée.

---

### 🎥 F. Flux Vidéos et Interactions Sociales

Permet de suivre la vie extrascolaire à travers des vidéos YouTube ou des rapports d'événements.

#### 10. Visionnage et Interactions Vidéos (`coulisse_video_feed_screen.dart`)
* **Étape 1 :** Accédez à la section **Coulisses de l'Excellence** ou **Visites Guidées**.
* **Étape 2 :** Cliquez sur lecture sur l'un des flux vidéo YouTube intégrés.
* **Étape 3 :** Testez les interactions sociales : cliquez sur le bouton **J'aime** (like), notez la vidéo (1 à 5 étoiles) ou ajoutez un commentaire en bas de la vidéo.

---

### 🤝 G. Profil, Parrainage & Recommandations (`profile_screen.dart`)

Espace de gestion du compte utilisateur et de recommandation de la plateforme.

#### 11. Espace Parrainage & Recommandation d'écoles
* **Étape 1 :** Cliquez sur l'onglet **Mon Profil** dans la barre de navigation.
* **Étape 2 :** Cliquez sur **Parrainage** pour visualiser votre code promotionnel unique de partage et vos commissions de parrainage.
* **Étape 3 :** Cliquez sur **Suggérer une école** (`parent_suggestion_screen.dart`) et remplissez le formulaire pour recommander l'intégration d'un nouvel établissement non-partenaire.

---

### 📝 H. Inscription et Réinscription d'un nouvel élève (`inscription_screen.dart`)

Parcours d'adhésion et d'inscription d'un nouvel enfant au sein d'une école partenaire.

#### 12. Parcours Complet d'Inscription
* **Étape 1 :** Depuis l'écran d'accueil, cliquez sur **Inscrire un enfant**.
* **Étape 2 :** Saisissez le matricule ou sélectionnez un établissement et une classe dans le menu déroulant.
* **Étape 3 :** Remplissez les données administratives requises.
* **Étape 4 :** Validez l'échéancier financier et finalisez l'inscription pour soumission à l'administration de l'établissement.

---

## 🛠️ 3. Spécifications Techniques pour l'examen

* **Réseau :** L'application communique activement avec notre serveur principal via l'API REST `https://api2.vie-ecoles.com/api`. Veuillez vous assurer que votre environnement de test autorise le trafic vers ce domaine.
* **Moteur Graphique :** Construit en Flutter (compatible Android 5.0+ et iOS 12.0+), conçu pour s'adapter automatiquement aux smartphones ainsi qu'aux tablettes tactiles.
