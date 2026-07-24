---
name: Système de Partage et Deep Linking
description: Instructions et architecture pour intégrer le système de partage de contenu et les deep links natifs (Universal Links iOS et App Links Android).
---

# 🔗 Guide d'intégration : Partage & Deep Linking

Ce skill décrit l'architecture et les étapes exactes pour mettre en place un système de partage de contenu (comme des vidéos) qui ouvre directement l'application via les standards natifs : **Universal Links** (iOS) et **App Links** (Android).

## 🏛️ Architecture du système

Le système repose sur une solution sans backend propriétaire, utilisant uniquement les configurations natives et des pages web statiques de fallback.

1.  **Fichiers d'association (Hébergement Web)** : `.well-known/apple-app-site-association` (iOS) et `.well-known/assetlinks.json` (Android) hébergés sur le domaine cible (ex: `pouls-scolaire.net`).
2.  **Configuration Native** : `AndroidManifest.xml` (intent-filters) et `Runner.entitlements` (associated domains) configurés pour intercepter le domaine.
3.  **`DeepLinkService` (Service Flutter)** : Écoute les liens entrants (via le package `app_links`), que l'app soit fermée (cold start) ou en arrière-plan (warm start), parse l'URL et notifie l'application.
4.  **`VideoShareService` (Service Flutter)** : Génère les URLs (ex: `https://pouls-scolaire.net/video/coulisse/123`) à partager via les applications de messagerie.
5.  **Écran de réception** : Un écran (ex: `DeepLinkVideoScreen`) qui s'affiche lors de l'ouverture du lien, récupère la donnée de l'API via l'ID de l'URL, et redirige l'utilisateur vers le contenu exact.

---

## 🛠️ Étapes d'intégration pas à pas

### 1. Dépendances (pubspec.yaml)

Utiliser le package `app_links` qui est la solution moderne recommandée.

```yaml
dependencies:
  app_links: ^6.3.2
  share_plus: ^7.2.2 # Pour l'interface de partage
```

### 2. Hébergement Web (Domaine cible)

Sur le domaine qui servira pour les liens (ex: `pouls-scolaire.net`), héberger ces fichiers à la racine :

**A. `/.well-known/assetlinks.json` (Android)**
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.votre.package",
      "sha256_cert_fingerprints": ["VOTRE_SHA256_KEYSTORE"]
    }
  }
]
```

**B. `/.well-known/apple-app-site-association` (iOS)**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TEAM_ID.com.votre.package"],
        "paths": ["/video/*"]
      }
    ]
  }
}
```

**C. `/deep-link-hosting/video/index.html` (Fallback)**
Une page web simple pour intercepter les utilisateurs n'ayant pas l'application, utilisant les paramètres d'URL (ex: `?type=coulisse&id=123`) pour éviter les erreurs 404 sur les serveurs statiques.

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ouverture dans l'application...</title>
</head>
<body>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        const type = urlParams.get('type');
        const id = urlParams.get('id');
        
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
        
        if (type && id) {
            // Tenter d'ouvrir l'application si l'OS ne l'a pas fait automatiquement via un Custom Scheme (ex: pouls://)
            window.location.href = `pouls://video/${type}/${id}`;
        }
        
        setTimeout(function () {
            if (isIOS) {
                window.location.href = 'https://apps.apple.com/app/...'; // URL App Store
            } else {
                window.location.href = 'https://play.google.com/store/apps/...'; // URL Play Store
            }
        }, 2500);
    </script>
</body>
</html>
```

### 3. Configuration Native App

**Android (`android/app/src/main/AndroidManifest.xml`) :**
Dans la balise `<activity>` principale :
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="pouls-scolaire.net" android:pathPrefix="/video" />
</intent-filter>
```

**iOS (`ios/Runner/Runner.entitlements`) :**
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:pouls-scolaire.net</string>
</array>
```

### 4. Le Service DeepLinkService

Créer un service singleton pour écouter les liens au démarrage ou en arrière-plan.

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final _deepLinkController = StreamController<Uri>.broadcast();

  Stream<Uri> get onLinkReceived => _deepLinkController.stream;

  Future<void> init() async {
    _appLinks = AppLinks();

    // 1. Cold start
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _deepLinkController.add(initialUri);
    } catch (e) { print('Erreur initial link: $e'); }

    // 2. Warm start
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _deepLinkController.add(uri);
      });
    } catch (e) { print('Erreur stream deep link (hot reload ?): $e'); }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
```

### 5. Initialisation et Écoute Globale

Dans `main.dart`, initialiser le service et l'écouter.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeepLinkService().init();
  runApp(const MyApp());
}

// Dans le State de MyApp
@override
void initState() {
  super.initState();
  DeepLinkService().onLinkReceived.listen((uri) {
    // Parser l'URI (ex: extraire l'ID depuis /video/coulisse/123)
    // Rediriger via un navigatorKey global
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (context) => DeepLinkVideoScreen(uri: uri),
    ));
  });
}
```

### 6. Le Service de Partage

Créer un service pour centraliser la génération des URLs. **Important :** Utilisez des `query parameters` pour pointer vers le fichier `index.html` afin d'éviter les erreurs 404 sur un hébergement statique simple.

```dart
class VideoShareService {
  static String buildLink(String type, int id) {
    // Redirection vers index.html pour éviter les 404
    return 'https://pouls-scolaire.net/deep-link-hosting/video/index.html?type=$type&id=$id';
  }

  static String buildShareText(String title, String link) {
    return 'Regarde cette vidéo : $title\n👉 $link';
  }
}
```

### 7. Mise à jour du parsing (DeepLinkService)

Votre parseur de Deep Link doit extraire les informations des paramètres d'URL :

```dart
  static DeepLinkData? parseUri(Uri uri) {
    if (!uri.path.contains('video')) return null;

    final typeStr = uri.queryParameters['type'];
    final id = uri.queryParameters['id'];

    if (typeStr == null || id == null || id.isEmpty) return null;

    // Retourner votre objet DeepLinkData
    return DeepLinkData(type: typeStr, id: id);
  }
```

## 🎨 Bonnes Pratiques

- **Écran Intermédiaire (`DeepLinkVideoScreen`)** : Toujours utiliser un écran de chargement (avec un "loader" ou logo) lors de la réception d'un Deep Link, le temps de requêter l'API pour récupérer les infos de la vidéo via l'ID avant d'afficher le contenu.
- **Fail-Safe** : Ajouter un try-catch autour de l'écoute du stream `app_links` pour éviter le crash `MissingPluginException` lors d'un "hot reload" (le code natif n'étant chargé qu'au cold restart).
- **Navigation Globale** : Utiliser un `navigatorKey` défini globalement pour permettre la navigation depuis le `main.dart` sans avoir besoin d'un `BuildContext` local.

---

## 🧠 Explication Détaillée du Flux (Deep Dive)

Comprendre exactement ce qui se passe quand un utilisateur partage et clique sur un lien est essentiel pour déboguer le système. Voici le cycle de vie complet :

### 1. La génération du lien (Émetteur)
Quand l'utilisateur A clique sur "Partager" :
- L'application Flutter génère un lien statique pointant vers le fallback avec paramètres, par exemple : `https://pouls-scolaire.net/deep-link-hosting/video/index.html?type=coulisse&id=123`.
- Ce lien est envoyé via WhatsApp, SMS, etc.
- **Note** : L'utilisation de `index.html?type=...` garantit que le serveur web ne renverra pas d'erreur 404 (contrairement aux faux chemins virtuels type `/coulisse/123`).

### 2. Le clic et l'interception (OS - iOS/Android)
Quand l'utilisateur B clique sur le lien WhatsApp :
- L'OS (iOS ou Android) intercepte le clic *avant* même d'ouvrir le navigateur web.
- L'OS vérifie sa base de registre interne : "Est-ce qu'une application installée a déclaré être propriétaire du domaine `pouls-scolaire.net` ?"
- Pour prouver cette propriété, l'OS a préalablement (lors de l'installation de l'app) téléchargé en silence les fichiers `.well-known/apple-app-site-association` ou `.well-known/assetlinks.json` depuis le serveur.
- Si la vérification cryptographique (Team ID / SHA256) réussit : **L'OS bloque l'ouverture du navigateur et ouvre directement l'application Flutter**.

### 3. Le traitement par Flutter (Récepteur)
Si l'app s'ouvre :
- Le plugin natif `app_links` récupère l'URL ayant déclenché l'ouverture.
- Le service `DeepLinkService` parse cette URL en lisant `uri.queryParameters['type']` et `uri.queryParameters['id']`.
- Un événement est émis dans un `Stream` (écouté par `main.dart`).
- `main.dart` déclenche une navigation vers `DeepLinkVideoScreen`, en passant l'ID.
- `DeepLinkVideoScreen` affiche un loader animé, appelle l'API pour charger les données de la vidéo, puis redirige vers le vrai lecteur vidéo.

### 4. Le Fallback (Si l'app n'est pas installée)
Si l'utilisateur B n'a pas l'application :
- L'OS ne trouve aucune app liée au domaine. Il ouvre donc le lien normalement dans **Safari / Chrome**.
- Le navigateur atterrit sur `https://pouls-scolaire.net/deep-link-hosting/video/index.html?type=coulisse&id=123`.
- Le serveur web sert le fichier statique `index.html` (pas de 404).
- Ce fichier HTML contient un script JavaScript très simple qui :
  1. Parse le paramètre d'URL pour tenter une dernière fois un custom URL Scheme (ex: `pouls://`).
  2. Détecte si le visiteur est sur un iPhone ou un Android.
  3. Lance un compte à rebours de 2.5 secondes.
  4. Redirige automatiquement le navigateur vers la fiche App Store ou Play Store de l'application.

### 💡 Pourquoi cette approche au lieu de Firebase Dynamic Links ?
Firebase Dynamic Links (FDL) faisait exactement cela, mais avec un serveur propriétaire Google au milieu (qui raccourcissait les liens en `page.link`). FDL étant obsolète, cette approche "vanilla" (Universal Links / App Links) est la méthode standard de l'industrie utilisée par tous les grands réseaux sociaux (Instagram, TikTok, Twitter). Elle est plus rapide (pas de redirection serveur intermédiaire) et totalement gratuite.
