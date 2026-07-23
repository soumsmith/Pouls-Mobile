---
name: firebase-flutter-integration
description: Guide complet étape par étape pour configurer et intégrer Firebase (Android & iOS) dans une application Flutter via FlutterFire CLI et traiter tous les cas de dépannage (xcodeproj, reauthentification CLI 401, etc.).
---

# Guide d'Intégration Firebase pour Flutter (FlutterFire CLI)

## Vue d'Ensemble

Lors de la configuration d'un projet Firebase, plusieurs types d'applications sont proposés dans la console Firebase :
- **iOS+** : Pour les applications natives Apple (`GoogleService-Info.plist`).
- **Android** : Pour les applications natives Android (`google-services.json`).
- **Web** : Pour les applications Web (JavaScript / `firebaseConfig`).
- **Unity** : Pour les jeux vidéo Unity.
- **Flutter** : La méthode recommandée pour les projets Flutter. Elle utilise l'outil **FlutterFire CLI** (`flutterfire configure`) pour lier automatiquement et simultanément Android, iOS, Web et Desktop tout en générant le fichier central `lib/firebase_options.dart`.

---

## Guide d'Intégration Étape par Étape

### 1. Prérequis & Installation des Outils CLI

Avant de lancer la configuration, assurez-vous d'avoir les outils nécessaires sur votre machine :

```bash
# 1. Installer Firebase CLI globalement via npm
npm install -g firebase-tools

# 2. Se connecter à votre compte Google/Firebase
firebase login

# 3. Activer FlutterFire CLI
dart pub global activate flutterfire_cli

# 4. (Sur macOS) Installer la gem Ruby xcodeproj nécessaire pour l'intégration iOS
gem install xcodeproj --user-install
# Ou si vous avez les droits d'administration : sudo gem install xcodeproj
```

---

### 2. Ajout des Dépendances Flutter (`pubspec.yaml`)

Assurez-vous que le package `firebase_core` (et les autres services Firebase souhaités) est ajouté dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.0
  # Services optionnels :
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
  firebase_storage: ^12.4.4
  firebase_messaging: ^15.2.4
```

Puis exécutez :
```bash
flutter pub get
```

---

### 3. Exécution de `flutterfire configure`

À la racine de votre projet Flutter, lancez la commande interactive :

```bash
flutterfire configure
```

#### Déroulement interactif :
1. **Sélection du projet Firebase** : Choisissez votre projet existant (ex: `parent-responsable-8fc40`) ou sélectionnez `<create a new project>`.
2. **Sélection des plateformes** :
   - Utilisez les **Flèches Haut/Bas** ($\uparrow$ / $\downarrow$) pour vous déplacer.
   - Appuyez sur la **Barre d'Espace** pour cocher/décocher les plateformes (sélectionnez idéalement `android` et `ios`).
   - Appuyez sur **Entrée** pour valider.

---

### 4. Fichiers Générés et Vérification

Une fois l'exécution terminée, FlutterFire a automatiquement généré ou mis à jour :

| Fichier | Emplacement | Rôle |
| :--- | :--- | :--- |
| **`firebase_options.dart`** | `lib/firebase_options.dart` | Contient la configuration Dart multi-plateformes |
| **`google-services.json`** | `android/app/google-services.json` | Fichier de configuration natif Android |
| **`GoogleService-Info.plist`** | `ios/Runner/GoogleService-Info.plist` | Fichier de configuration natif iOS |

*Note : Si vous aviez d'anciens fichiers de configuration d'un autre compte/projet Firebase, `flutterfire` les écrase et les remplace automatiquement.*

---

### 5. Initialisation dans `lib/main.dart`

Ouvrez `lib/main.dart` et initialisez Firebase avant le lancement de l'application :

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Fichier généré par FlutterFire

void main() async {
  // 1. Assurer l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialiser Firebase avec les options de la plateforme courante
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation de Firebase: $e');
  }

  runApp(const MyApp());
}
```

---

## Guide de Dépannage & Erreurs Courantes

### ❌ Erreur 1 : `HTTP Error: 401, Request had invalid authentication credentials`
* **Cause** : Votre jeton de connexion Firebase CLI est expiré ou invalide.
* **Solution** : Reconnectez-vous avec :
  ```bash
  firebase login --reauth
  ```

---

### ❌ Erreur 2 : `cannot load such file -- xcodeproj (LoadError)`
* **Cause** : La gem Ruby `xcodeproj` est manquante sur macOS pour modifier la cible iOS dans Xcode.
* **Solution** : Installez la gem avec l'une des commandes suivantes :
  ```bash
  gem install xcodeproj --user-install
  # Ou avec sudo si nécessaire :
  sudo gem install xcodeproj
  ```
  Puis relancez `flutterfire configure`.

---

### ❌ Erreur 3 : `Failed to create project` lors de la création d'un projet CLI
* **Cause** : Nom de projet contenant des majuscules ou caractères invalides.
* **Solution** : Les ID de projet Firebase doivent être exclusivement en minuscules et sans espaces (ex: `parent-responsable-app`).

---

### ❌ Conflit avec d'anciens fichiers Firebase
* **Question** : Faut-il supprimer manuellement les anciens `google-services.json` ou `GoogleService-Info.plist` ?
* **Réponse** : Non, `flutterfire configure` télécharge et réécrit directement ces fichiers avec les clés et identifiants du nouveau projet sélectionné.
