---
name: "Intégration OneSignal Push Notifications"
description: "Guide complet d'intégration de OneSignal (SDK v5.x) pour les notifications push dans une application Flutter (Android & iOS). Couvre la configuration étape par étape sur Apple Developer Portal, Firebase Console, OneSignal Dashboard, la résolution des erreurs courantes, l'identification des utilisateurs, le tagging, la gestion des mises à jour, et le code de production."
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
7. [Notifications de Mise à Jour & Tests Postman](#7-notifications-de-mise-à-jour--tests-postman)
8. [Tests et Validation des Abonnements (Users & Subscriptions)](#8-tests-et-validation-des-abonnements-users--subscriptions)
9. [Résolution des Erreurs Courantes (Troubleshooting)](#9-résolution-des-erreurs-courantes-troubleshooting)

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
4. Récupérer le **OneSignal App ID** et la **REST API Key** dans **Settings → Keys & IDs**.

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
import '../config/app_config.dart';

/// Service pour gérer les notifications Push avec OneSignal (SDK v5.x)
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  /// App ID OneSignal
  static const String appId = '1caa5070-bc9c-4720-a6a4-9d5189401ff0';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialiser le SDK OneSignal
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
        _handleNotificationClick(event.notification);
      });

      _isInitialized = true;
      debugPrint('✅ [OneSignal] Initialisé avec succès (App ID: $appId)');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur initialisation: $e');
    }
  }

  void login(String externalUserId) {
    if (externalUserId.isEmpty) return;
    try {
      OneSignal.login(externalUserId);
      debugPrint('👤 [OneSignal] Login external_id: $externalUserId');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur login: $e');
    }
  }

  void logout() {
    try {
      OneSignal.logout();
      debugPrint('👤 [OneSignal] Logout');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur logout: $e');
    }
  }

  void addTag(String key, String value) {
    try {
      OneSignal.User.addTagWithKey(key, value);
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur addTag: $e');
    }
  }

  void addTags(Map<String, String> tags) {
    try {
      OneSignal.User.addTags(tags);
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur addTags: $e');
    }
  }

  void removeTag(String key) {
    try {
      OneSignal.User.removeTag(key);
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur removeTag: $e');
    }
  }

  void setEmail(String email) {
    if (email.isNotEmpty) OneSignal.User.addEmail(email);
  }

  void setSms(String phoneNumber) {
    if (phoneNumber.isNotEmpty) OneSignal.User.addSms(phoneNumber);
  }

  /// Gérer le clic sur une notification et la redirection vers l'URL / Store
  Future<void> _handleNotificationClick(OSNotification notification) async {
    try {
      final Map<String, dynamic> data = notification.additionalData ?? {};
      final String? launchUrlStr = notification.launchUrl;
      final String? type = data['type']?.toString();
      debugPrint('📦 [OneSignal] Clic notification: title="${notification.title}", launchUrl=$launchUrlStr, data=$data');

      // 1. Gestion des notifications de paiement WicPay
      if (type == 'payment_success' || type == 'wicpay_payment') {
        final String? transactionId = data['transaction_id']?.toString();
        final String? montant = data['montant']?.toString();
        debugPrint('💳 [OneSignal] Paiement WicPay reçu ! TXN: $transactionId, Montant: $montant');
      }

      // 2. Recherche de l'URL cible (Priorité au launchUrl natif OneSignal ou URLs custom de data)
      String? targetUrl;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        targetUrl =
            data['appstore_url'] ??
            data['ios_url'] ??
            launchUrlStr ??
            data['url'] ??
            data['link'] ??
            data['store_url'] ??
            AppConfig.IOS_STORE_URL;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        targetUrl =
            data['playstore_url'] ??
            data['android_url'] ??
            launchUrlStr ??
            data['url'] ??
            data['link'] ??
            data['store_url'] ??
            AppConfig.ANDROID_STORE_URL;
      } else {
        targetUrl =
            launchUrlStr ??
            data['url'] ??
            data['link'] ??
            data['store_url'];
      }

      if (targetUrl != null && targetUrl.isNotEmpty) {
        final uri = Uri.tryParse(targetUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('🌐 [OneSignal] Redirection réussie vers: $targetUrl');
        }
      }
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur traitement clic notification: $e');
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

---

## 6. Configuration Native iOS (Xcode)

Pour recevoir les notifications sous iOS et résoudre l'erreur `Missing Push Capability` :

1. Créer le fichier `ios/Runner/Runner.entitlements` :
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>aps-environment</key>
   	<string>development</string>
   </dict>
   </plist>
   ```
2. Ouvrir `ios/Runner.xcworkspace` dans Xcode.
3. Sélectionner le target **Runner → Signing & Capabilities → + Capability** :
   - Ajouter **Push Notifications**
   - Ajouter **Background Modes** → Cocher **Remote notifications**

---

## 7. Notifications de Mise à Jour & Tests Postman

### Envoi d'une notification Push de mise à jour ciblée via Postman :

```http
POST https://onesignal.com/api/v1/notifications
Headers:
  Content-Type: application/json
  Authorization: Key VOTRE_REST_API_KEY_ONESIGNAL
  

Body (raw JSON):
{
  "app_id": "1caa5070-bc9c-4720-a6a4-9d5189401ff0",
  "filters": [
    { "field": "tag", "key": "app_version", "relation": "!=", "value": "1.0.11" }
  ],
  "headings": {
    "en": "Mise à jour disponible 🚀",
    "fr": "Mise à jour disponible 🚀"
  },
  "contents": {
    "en": "Une nouvelle version de l'application est disponible. Cliquez pour mettre à jour.",
    "fr": "Une nouvelle version de l'application est disponible. Cliquez pour mettre à jour."
  },
  "url": "https://play.google.com/store/apps/details?id=com.groupegain.parents_responsable",
  "data": {
    "type": "app_update",
    "playstore_url": "https://play.google.com/store/apps/details?id=com.groupegain.parents_responsable",
    "appstore_url": "https://apps.apple.com/app/parent-responsable/id6763526336"
  }
}
```

---

## 8. Tests et Validation des Abonnements (Users & Subscriptions)

### Différence entre Users et Subscriptions :

- **Audience → Users** : Affiche les utilisateurs authentifiés (`external_id`).
- **Audience → Subscriptions** : Affiche les jetons de push actifs (tokens APNs / FCM).

> ⚠️ **IMPORTANT — TEST SUR SIMULATEUR VS VRAI APPAREIL** :
> - **Simulateur iOS** : Ne génère PAS de jetons de push APNs réels. La section *Subscriptions* affichera `Never Subscribed`.
> - **iPhone Physique / Android** : Génère un vrai jeton push (`Subscribed`) dès que la permission est acceptée.

---

## 9. Résolution des Erreurs Courantes (Troubleshooting)

| Message d'erreur / Symptôme | Cause Probable | Solution |
|-----------------------------|----------------|----------|
| `Missing Push Capability` | Option Push Notifications non activée dans Xcode ou fichier `.entitlements` manquant. | 1. Créer `ios/Runner/Runner.entitlements` avec `<key>aps-environment</key>`.<br>2. Dans Xcode → Runner → Signing & Capabilities → `+ Capability` → Ajouter **Push Notifications**. |
| `Message Notifications must have Any/English language content` | La clé `"en"` est absente du dictionnaire `"contents"`. | Toujours fournir la clé `"en"` dans `"contents"` et `"headings"` dans les requêtes API OneSignal. |
| `We were unable to validate the key` | Bundle ID non enregistré avec Push sur Apple Developer Portal. | 1. Activer **Push Notifications** sur le Bundle ID dans Identifiers.<br>2. Choisir l'environnement **Sandbox & Production** pour la clé `.p8`. |
| Subscriptions est vide (`Never Subscribed`) sur iOS | Test effectué sur un simulateur iOS. | Tester sur un **vrai iPhone physique** branché en USB. |
