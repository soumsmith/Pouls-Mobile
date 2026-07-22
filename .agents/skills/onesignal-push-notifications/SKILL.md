---
name: "Intégration OneSignal Push Notifications"
description: "Guide complet d'intégration de OneSignal (SDK v5.x) pour les notifications push dans une application Flutter (Android & iOS). Couvre la configuration étape par étape sur Apple Developer Portal, Firebase Console, OneSignal Dashboard, la résolution des erreurs courantes, l'identification des utilisateurs, le tagging, et le code de production."
---

# Intégration OneSignal Push Notifications — Flutter (Guide Complet Étape par Étape)

Ce skill décrit l'intégration de bout en bout de OneSignal (SDK v5.x) dans une application Flutter pour iOS et Android.

---

## Table des matières

1. [Prérequis et Identifiants du Projet](#1-prérequis-et-identifiants-du-projet)
2. [Créer un projet OneSignal](#2-créer-un-projet-onesignal)
3. [Configuration iOS sur Apple Developer Portal & OneSignal](#3-configuration-ios-sur-apple-developer-portal--onesignal)
4. [Configuration Android (FCM) sur Firebase & OneSignal](#4-configuration-android-fcm-sur-firebase--onesignal)
5. [Installation et Configuration Flutter (Code Production)](#5-installation-et-configuration-flutter-code-production)
6. [Configuration Native iOS (Xcode)](#6-configuration-native-ios-xcode)
7. [Tests et Validation des Abonnements (Users & Subscriptions)](#7-tests-et-validation-des-abonnements-users--subscriptions)
8. [Résolution des Erreurs Courantes (Troubleshooting)](#8-résolution-des-erreurs-courantes-troubleshooting)

---

## 1. Prérequis et Identifiants du Projet

- **Flutter** 3.x+ / **Dart** 3.x+
- Compte **OneSignal** (Gratuit jusqu'à 10 000 abonnés)
- Compte **Apple Developer** (Payant, requis pour iOS Push)
- Compte **Firebase** (Gratuit, requis pour Android FCM)

### Exemple d'identifiants du projet :
- **OneSignal App ID** : `1caa5070-bc9c-4720-a6a4-9d5189401ff0`
- **iOS App Bundle ID** : `com.groupegain.parentsresponsable`
- **Android Package Name** : `com.groupegain.parents_responsable`
- **Apple Team ID** : `BVJ6PT96L8`

---

## 2. Créer un projet OneSignal

1. Se connecter sur [https://onesignal.com](https://onesignal.com)
2. Cliquer sur **"New App/Website"**
3. Nommer l'application (ex: `Parent Responsable`)
4. Récupérer le **OneSignal App ID** dans **Settings → Keys & IDs**.

---

## 3. Configuration iOS sur Apple Developer Portal & OneSignal

La configuration iOS nécessite la création d'une clé d'authentification APNs (`.p8`) chez Apple, puis son importation sur OneSignal.

### Étape A : Activer "Push Notifications" sur le Bundle ID (Apple Developer)

1. Allez sur **[Apple Developer Portal](https://developer.apple.com/account)**.
2. **Certificates, Identifiers & Profiles → Identifiers**.
3. Recherchez votre Bundle ID (ex: `com.groupegain.parentsresponsable`).
   - *S'il n'existe pas* : Cliquez sur **`+`** → **App IDs** → **App** → Entrez la description et le Bundle ID précis.
   - *S'il existe* : Cliquez dessus, faites défiler jusqu'à **Push Notifications** et **cochez la case**.
4. Cliquez sur **Save**.

### Étape B : Générer la Clé APNs (.p8)

1. **Certificates, Identifiers & Profiles → Keys**.
2. Cliquez sur le bouton **`+`** (Register a New Key).
3. **Key Name** : Entrez un nom explicite (ex: `Parent Responsable Push Key`).
4. Cochez la case **Apple Push Notifications service (APNs)**.
5. Cliquez sur le bouton bleu **Configure** situé à droite d'APNs :
   - **Environment** : Sélectionnez **`Sandbox & Production`** *(recommandé pour réutiliser la même clé en test et en store)*.
   - **Key Restriction** : Sélectionnez **`Team Scoped (All Topics)`**.
   - Cliquez sur **Save**.
6. Cliquez sur **Continue**, puis sur **Register**.
7. **Téléchargez le fichier `.p8`** (ex: `AuthKey_FP47LRU2UY.p8`).
   > ⚠️ **ATTENTION** : Apple ne permet de télécharger ce fichier `.p8` **qu'une seule et unique fois** ! Conservez-le en lieu sûr.
8. Notez le **Key ID** (chaîne de 10 caractères, ex: `FP47LRU2UY`).

### Étape C : Configurer OneSignal (Plateforme Apple iOS)

1. Dans le dashboard OneSignal : **Settings → Platforms → Apple iOS (APNs)**.
2. **APNs Authentication Type** : Choisissez `.p8 Auth Key (Recommended)`.
3. **Key (.p8 file)** : Uploadez le fichier `.p8` téléchargé.
4. **Key ID** : Entrez le Key ID à 10 caractères (ex: `FP47LRU2UY`).
5. **Team ID** : Entrez votre Team ID Apple (ex: `BVJ6PT96L8`).
6. **App Bundle ID** : Entrez votre Bundle ID iOS (ex: `com.groupegain.parentsresponsable`).
7. Cliquez sur **Save & Continue**, puis sélectionnez le SDK **Flutter**.

---

## 4. Configuration Android (FCM) sur Firebase & OneSignal

OneSignal utilise Firebase Cloud Messaging (FCM) comme canal de transmission sous Android.

### Étape A : Télécharger la clé de service Firebase JSON

1. Allez sur la **[Console Firebase](https://console.firebase.google.com/)**.
2. Ouvrez votre projet → Cliquez sur l'engrenage ⚙️ **Paramètres du projet** → Onglet **Comptes de service**.
3. Cliquez sur **"Générer une nouvelle clé privée"** → Téléchargez le fichier JSON.

### Étape B : Configurer OneSignal (Plateforme Google Android)

1. Dans le dashboard OneSignal : **Settings → Platforms → Google Android (FCM)**.
2. Choisissez **Firebase Service Account JSON**.
3. Uploadez le fichier JSON téléchargé depuis Firebase.
4. Cliquez sur **Save & Continue**.

---

## 5. Installation et Configuration Flutter (Code Production)

### 5.1. Dépendance pubspec.yaml

```yaml
dependencies:
  onesignal_flutter: ^5.2.9
```
Puis exécuter : `flutter pub get`.

### 5.2. Service OneSignal (`lib/services/onesignal_service.dart`)

```dart
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static const String appId = '1caa5070-bc9c-4720-a6a4-9d5189401ff0';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);

      // Listener au premier plan (Foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('🔔 [OneSignal] Notification reçue au premier plan: ${event.notification.title}');
        event.notification.display();
      });

      // Listener clic notification
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('🔔 [OneSignal] Notification cliquée: ${event.notification.title}');
        final data = event.notification.additionalData;
        if (data != null) {
          _handleNotificationData(data);
        }
      });

      _isInitialized = true;
      debugPrint('✅ [OneSignal] Initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur initialisation: $e');
    }
  }

  void login(String externalUserId) {
    if (externalUserId.isEmpty) return;
    OneSignal.login(externalUserId);
    debugPrint('👤 [OneSignal] Login external_id: $externalUserId');
  }

  void logout() {
    OneSignal.logout();
    debugPrint('👤 [OneSignal] Logout');
  }

  void addTags(Map<String, String> tags) {
    OneSignal.User.addTags(tags);
  }

  void setEmail(String email) {
    if (email.isNotEmpty) OneSignal.User.addEmail(email);
  }

  void setSms(String phoneNumber) {
    if (phoneNumber.isNotEmpty) OneSignal.User.addSms(phoneNumber);
  }

  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final String? urlString = data['url'] ?? data['link'] ?? data['store_url'];
    if (urlString != null && urlString.isNotEmpty) {
      final uri = Uri.tryParse(urlString);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
```

### 5.3. Initialisation dans `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation OneSignal
  await OneSignalService().init();

  runApp(const MyApp());
}
```

### 5.4. Liaison avec l'Authentification (`lib/services/auth_service.dart`)

```dart
// À la connexion réussie de l'utilisateur :
OneSignalService().login(user.id.toString());
if (user.email != null) OneSignalService().setEmail(user.email!);
if (user.phone != null && user.phone.isNotEmpty) OneSignalService().setSms('+225${user.phone}');
OneSignalService().addTags({
  'role': user.role ?? 'parent',
  'parent_uid': user.parentUid ?? '',
});

// À la déconnexion :
OneSignalService().logout();
```

---

## 6. Configuration Native iOS (Xcode)

Pour recevoir les notifications riches (images) et autoriser les notifications en arrière-plan sous iOS :

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
2. Sélectionner le target **Runner → Signing & Capabilities → + Capability** :
   - Ajouter **Push Notifications**
   - Ajouter **Background Modes** → Cocher **Remote notifications**
3. (Optionnel) Ajouter la **Notification Service Extension** pour l'affichage des images.

---

## 7. Tests et Validation des Abonnements (Users & Subscriptions)

### Différence entre Users et Subscriptions :

- **Audience → Users** : Affiche les utilisateurs authentifiés (`external_id`). Un utilisateur peut être enregistré dès le login.
- **Audience → Subscriptions** : Affiche les jetons de push actifs (tokens APNs / FCM).

> ⚠️ **IMPORTANT — TEST SUR SIMULATEUR VS VRAI APPAREIL** :
> - **Simulateur iOS** : Ne génère PAS de jetons de push APNs réels. La section *Subscriptions* restera vide sur un simulateur iOS.
> - **Appareil Physique iOS / Android ou Émulateur Android** : Génère un vrai jeton push dès que la permission est acceptée.

### Envoi d'un test push depuis OneSignal :

1. Allez sur **Messages → New Push**.
2. Titre : `Test Notification`
3. Message : `Message de test OneSignal`
4. Audience : `Send to All Subscribed Users`
5. Cliquez sur **Review & Send**.

---

## 8. Résolution des Erreurs Courantes (Troubleshooting)

| Message d'erreur / Symptôme | Cause Probable | Solution |
|-----------------------------|----------------|----------|
| `We were unable to validate the key` | Bundle ID non enregistré avec Push sur Apple Developer, ou mauvaise association Team ID / Key ID. | 1. Vérifier que le Bundle ID a **Push Notifications** coché dans Identifiers sur Apple Developer.<br>2. Vérifier que l'Environnement de la clé `.p8` est bien réglé sur **`Sandbox & Production`**. |
| Subscriptions est vide sur le dashboard | Test effectué sur un simulateur iOS. | Tester sur un **vrai iPhone** ou un **appareil/émulateur Android**. |
| Pas de notification reçue sur Android | Fichier Firebase Service Account JSON invalide ou manquant. | Réexporter la clé privée JSON depuis la console Firebase et la réuploader sur OneSignal. |
| Permission non demandée sur iOS | Clé `requestPermission` non appelée ou annulée. | Appeler `OneSignal.Notifications.requestPermission(true)` après `initialize()`. |
