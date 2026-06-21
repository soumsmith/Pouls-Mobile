---
name: flutter-local-notifications
description: Guide d'intégration et d'utilisation de flutter_local_notifications (v22.0.1)
tags: [flutter, notifications, local, push, setup]
---

# Flutter Local Notifications Skill

Ce "skill" vous guide pas à pas dans l'intégration du package `flutter_local_notifications` (version 22.0.1) pour envoyer des notifications locales sur Android et iOS.

## 1. Installation

Ajoutez la dépendance dans votre `pubspec.yaml` :
```yaml
dependencies:
  flutter_local_notifications: ^22.0.1
```

## 2. Configuration Native (Très Important)

Les notifications exigent une configuration stricte côté Android et iOS.

### Android

**1. Icône par défaut :**
Placez une icône transparente/blanche (ex: `app_icon.png`) dans le dossier `android/app/src/main/res/drawable/`.

**2. Permissions (`android/app/src/main/AndroidManifest.xml`) :**
Ajoutez les permissions suivantes avant la balise `<application>` :
```xml
<!-- Permission pour Android 13 (API 33) et supérieur -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<!-- Permission pour les notifications planifiées (Optionnel) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

### iOS

**1. Autorisations (`ios/Runner/AppDelegate.swift`) :**
Vérifiez que le code suivant est présent pour permettre l'affichage si l'application est au premier plan :
```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Si vous utilisez les notifications locales
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 3. Le Service de Notification (Code Flutter)

Il est fortement conseillé de centraliser la logique dans un Singleton (`NotificationService`).

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Android : l'icône doit correspondre à celle dans le dossier drawable
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/app_icon'); // ou '@mipmap/ic_launcher'

    // iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le clic sur la notification
        debugPrint('Notification cliquée ! Payload: ${response.payload}');
      },
    );
  }

  // Demander les permissions (Essentiel pour Android 13+ et iOS)
  Future<void> requestPermissions() async {
    // Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Afficher une notification simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'main_channel_id', // ID unique du canal
      'Notifications Générales', // Nom visible par l'utilisateur
      channelDescription: 'Ce canal est utilisé pour les notifications basiques.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFFE65100), // Ex: AppColors.screenOrange
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}
```

## 4. Comment l'utiliser dans l'application

1. **Initialisation** (Dans votre `main.dart`) :
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service
  await NotificationService().init();
  
  runApp(const MyApp());
}
```

2. **Demander la permission** (Sur l'écran d'accueil ou à l'inscription) :
```dart
@override
void initState() {
  super.initState();
  NotificationService().requestPermissions();
}
```

3. **Déclencher la notification** (Au clic sur un bouton) :
```dart
ElevatedButton(
  onPressed: () {
    NotificationService().showNotification(
      id: 1,
      title: 'Inscription réussie ! 🎉',
      body: 'Bienvenue dans notre application. Votre profil est prêt.',
      payload: 'SCREEN_PROFIL', // Utile pour la redirection au clic
    );
  },
  child: const Text('Tester la notification'),
)
```

## 5. Pièges Fréquents
- **Android Icon Error** : Si l'application crashe au lancement de la notification sur Android, c'est que l'image renseignée dans `AndroidInitializationSettings` n'existe pas ou est mal formatée. Utilisez `@mipmap/ic_launcher` en attendant d'avoir votre icône dédiée.
- **Canaux Android** : Une fois qu'un canal (Channel ID) est créé sur un téléphone, modifier son importance dans le code ne fera rien. Il faut réinstaller l'application ou changer le nom du Channel ID.
- **Payload vide** : Si vous fermez complètement l'application (kill), l'interception du clic se fera via la fonction d'initialisation, assurez-vous de bien avoir défini `onDidReceiveNotificationResponse`.
