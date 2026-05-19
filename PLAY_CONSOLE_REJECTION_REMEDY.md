# 🚀 Résolution du Refus Google Play : Accès aux Applications (Pouls Mobile)

> [!IMPORTANT]
> **Statut actuel du rejet :** Refusé le 19 mai 2026.
> **Motif principal :** *Exigences de Play Console : Violation des exigences de Play Console (Renseignements manquants sur la démo ou le compte d'invité)*.
>
> Les testeurs de Google ont bloqué la validation car l'application s'ouvre sur un écran de connexion par numéro de téléphone, et aucun identifiant de test n'a été fourni dans votre console pour leur permettre de se connecter et d'explorer les fonctionnalités.

---

## 🔍 1. Analyse Technique du Problème

En analysant votre application (notamment `lib/screens/login_screen.dart` et `lib/services/auth_service.dart`), nous constatons le fonctionnement suivant :
1. **Écran de Connexion (`LoginScreen`)** : Il utilise une **connexion directe** via l'API Quarkus (`/vie-ecoles/auth/parent/connexion`). Il n'y a **pas de double facteur (OTP) obligatoire lors de la connexion simple** si le numéro existe dans votre base de données.
2. **Écran d'Inscription (`SignupScreen` & `OtpVerificationScreen`)** : Il utilise un code OTP de test générique en développement/mock (`123456`).

Puisque l'application nécessite obligatoirement un compte ou un numéro de téléphone valide connecté pour accéder au tableau de bord, Google a l'obligation légale et technique de tester chaque recoin de l'application avant sa publication. Sans instructions d'accès, l'application est systématiquement rejetée.

---

## 🛠️ 2. Solution Étape par Étape (Dans la Google Play Console)

Pour valider votre application très rapidement, vous devez déclarer un **Accès à l'application** dans votre console développeur. Suivez précisément ces étapes :

### Étape 1 : Accéder aux Paramètres de Politique
1. Connectez-vous à votre [Google Play Console](https://play.google.com/console/).
2. Sélectionnez votre application **Pouls-Mobile**.
3. Dans le menu de gauche, faites défiler tout en bas jusqu'à la section **Politique et conformité** (ou *Policy and compliance*).
4. Cliquez sur **Contenu de l'application** (ou *App content*).

### Étape 2 : Configurer "Accès aux applications"
1. Sous la rubrique **Accès aux applications** (qui devrait afficher un statut rouge/incomplet), cliquez sur **Gérer** ou **Commencer**.
2. Cochez l'option : 
   👉 **"Toutes les fonctionnalités ou certaines d'entre elles sont restreintes (par exemple, si votre application requiert des identifiants de connexion...)"**
3. Cliquez sur **+ Ajouter des instructions** (ou *Add new credentials*).

### Étape 3 : Renseigner les Identifiants de Test
Remplissez le formulaire avec les informations suivantes :

| Champ dans la Play Console | Valeur à renseigner |
| :--- | :--- |
| **Nom du paramètre / Titre** | Compte de Test Parent |
| **Nom d'utilisateur / Téléphone** | *[Entrez un numéro de téléphone de test valide, ex: +2250700000000 ou +22370000000]* |
| **Mot de passe** | Aucun (Connexion directe par API sans mot de passe) |
| **Numéro de téléphone (si demandé séparément)** | *Même numéro de test* |

> [!TIP]
> **Action Recommandée avant soumission :** Assurez-vous que le numéro de téléphone que vous fournissez existe bien dans votre base de données API active (`https://api2.vie-ecoles.com`). Si ce n'est pas le cas, ajoutez un parent fictif avec ce numéro dans votre base de données afin que l'API renvoie un succès direct (`status: true`).

### Étape 4 : Rédiger des Instructions Claires (À copier-coller)
Dans le champ **Instructions d'accès** (ou *Any other instructions*), copiez et collez le texte ci-dessous :

```text
Bonjour l'équipe de validation Google Play,

Pour tester l'intégralité des fonctionnalités de notre application "Pouls-Mobile", veuillez utiliser les instructions de connexion suivantes :

1. Sur l'écran d'accueil, saisissez le numéro de téléphone de test fourni ci-dessus (ex: +225 XX XX XX XX / +223 XX XX XX XX).
2. Cliquez sur le bouton "Connexion". L'authentification se fera automatiquement via notre API sans avoir besoin de mot de passe ou d'OTP pour ce numéro de test.

Option de création de compte alternatif (si vous souhaitez tester le tunnel d'inscription complet) :
1. Cliquez sur le lien "Créer un compte" en bas de l'écran.
2. Saisissez vos informations (Nom, Prénom, un numéro de téléphone fictif).
3. À l'étape de vérification OTP, saisissez le code de test universel suivant : 123456 pour valider le compte.

Merci d'avance pour votre examen constructif.
Cordialement,
L'équipe Pouls Mobile
```

### Étape 5 : Enregistrer et Renvoyer pour Examen
1. Cliquez sur **Enregistrer** (Save).
2. Retournez dans l'onglet **Aperçu de la publication** (Publishing overview) dans le menu de gauche.
3. Cliquez sur **Envoyer pour examen** (Submit for review) pour soumettre à nouveau votre mise à jour.

---

## 💡 3. Bonnes Pratiques Additionnelles pour éviter d'autres rejets

Pour garantir une validation à 100% sans nouvel accroc, vérifiez ces points dans votre projet mobile :

* **Stabilité des APIs** : Assurez-vous que votre serveur API (`https://api2.vie-ecoles.com`) est parfaitement en ligne et disponible 24h/24 pendant la période d'examen de Google (généralement 1 à 7 jours). Si l'API renvoie une erreur 500 ou un timeout, Google rejettera à nouveau l'application.
* **Données Fictives Réalistes** : Le compte de test fourni doit être associé à un élève ayant des notes, un emploi du temps et des factures fictives afin que les testeurs puissent naviguer dans les écrans d'emploi du temps (`student_timetable_screen.dart`), des notes (`notes_screen.dart`) et de scolarité (`student_scolarite_screen.dart`) sans voir des écrans totalement vides ou en erreur.

---
*Ce document a été généré pour vous guider pas à pas dans la résolution rapide du blocage sur la Play Console.*
