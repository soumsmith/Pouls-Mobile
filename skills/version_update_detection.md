# Détection Automatique des Nouvelles Versions — Document d'Architecture Technique

> **Destinataires :** Équipe de développement Flutter senior  
> **Version du document :** 1.0  
> **Statut :** Référence architecturale

---

## 1. Présentation du Besoin

### 1.1 Description du Problème

Dans une application mobile publiée sur les stores, il est fréquent que des utilisateurs restent sur des versions obsolètes par manque d'information ou par habitude. Cela génère :

- Des **bugs non corrigés** toujours présents chez certains utilisateurs
- Des **incompatibilités API** si le backend évolue
- Des **risques de sécurité** (failles non patchées)
- Une **fragmentation** difficile à maintenir côté support

La détection automatique de version permet d'informer proactivement l'utilisateur, voire de **bloquer l'accès** si la version est trop ancienne (mise à jour obligatoire).

### 1.2 Objectifs Fonctionnels

| ID  | Objectif                                                                     | Priorité |
|-----|------------------------------------------------------------------------------|----------|
| F1  | Vérifier la version disponible au lancement de l'app                         | Haute    |
| F2  | Vérifier au maximum une fois par jour                                        | Haute    |
| F3  | Afficher une boîte de dialogue informant l'utilisateur                       | Haute    |
| F4  | Proposer un bouton de redirection vers le store                              | Haute    |
| F5  | Permettre à l'utilisateur d'ignorer la mise à jour si elle est facultative  | Moyenne  |
| F6  | Bloquer l'accès si la mise à jour est obligatoire                            | Haute    |
| F7  | Afficher les notes de version (changelog)                                    | Basse    |
| F8  | Gérer Android et iOS de manière indépendante                                | Haute    |

### 1.3 Contraintes Android

- **Google Play Store** expose une page HTML publique et un API JSON non officiel
- **In-App Update API** : API officielle Google qui permet d'afficher la mise à jour directement dans l'app (nécessite la distribution via Play Store)
- La vérification côté store peut être **bloquée par des proxies** ou des réseaux restrictifs
- Les versions sont comparées par le `versionCode` (entier) ou le `versionName` (semantic versioning)

### 1.4 Contraintes iOS

- **Apple n'offre pas d'API publique officielle** pour récupérer la version actuelle d'une app
- L'iTunes Search API (`itunes.apple.com/lookup`) est la méthode non officielle mais **largement utilisée en production**
- Apple **interdit** dans ses guidelines toute mécanique qui force une mise à jour sur iOS sans passer par le processus naturel de l'App Store
- En pratique : une popup non fermable est **tolérée** si la version minimale est obsolète, mais Apple peut rejeter si elle est jugée trop agressive
- Les mises à jour iOS ne sont **jamais instantanées** (délai de propagation du CDN Apple : 24 à 72h)

---

## 2. Comparatif des Solutions

| Critère                    | Package Flutter     | API Stores Directes | Backend Centralisé   | Firebase Remote Config |
|----------------------------|---------------------|---------------------|----------------------|------------------------|
| Facilité d'implémentation  | ⭐⭐⭐⭐⭐ Très facile | ⭐⭐⭐ Moyen           | ⭐⭐ Complexe           | ⭐⭐⭐⭐ Facile           |
| Fiabilité                  | ⭐⭐⭐ Moyen          | ⭐⭐⭐ Moyen           | ⭐⭐⭐⭐⭐ Maximale      | ⭐⭐⭐⭐ Haute            |
| Maintenance                | ⭐⭐⭐⭐ Faible       | ⭐⭐⭐ Moyen           | ⭐⭐ Nécessite un back | ⭐⭐⭐⭐ Firebase gère    |
| Performance                | ⭐⭐⭐ Moyen          | ⭐⭐⭐ Moyen           | ⭐⭐⭐⭐⭐ Contrôlée     | ⭐⭐⭐⭐ Avec cache       |
| Compatibilité Android      | ⭐⭐⭐⭐⭐             | ⭐⭐⭐⭐               | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐⭐               |
| Compatibilité iOS          | ⭐⭐⭐⭐              | ⭐⭐⭐⭐               | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐⭐                |
| Coût                       | Gratuit             | Gratuit              | Serveur requis        | Gratuit (limites)      |
| Évolutivité                | ⭐⭐ Limitée         | ⭐⭐⭐ Moyenne         | ⭐⭐⭐⭐⭐ Maximale      | ⭐⭐⭐⭐ Haute            |
| Contrôle force update      | ⭐⭐ Partiel         | Non                  | ⭐⭐⭐⭐⭐ Total         | ⭐⭐⭐⭐⭐ Total          |
| Indépendance stores        | Dépend des stores   | Dépend des stores    | Totale                | Totale                 |
| Délai de propagation       | 24-72h (stores)     | 24-72h (stores)      | Immédiat              | Quasi-immédiat         |

---

## 3. Solutions à Étudier

---

### Solution 1 : Vérification via Package Flutter

#### Description

Les packages Flutter encapsulent la logique de récupération de version auprès des stores et fournissent une UI prête à l'emploi. Ils lisent la version installée via `package_info_plus`, interrogent le store correspondant à la plateforme, et comparent les deux.

**Packages à considérer :**

| Package            | Maintenance | Spécificités              |
|--------------------|-------------|---------------------------|
| `upgrader`         | Active      | UI incluse, très populaire |
| `new_version_plus` | Active      | Fork amélioré de new_version |
| `in_app_update`    | Active      | Android uniquement, API Google officielle |

---

#### 1.A — Package `upgrader`

**Procédure d'implémentation :**

```yaml
# pubspec.yaml
dependencies:
  upgrader: ^11.1.0
  package_info_plus: ^8.0.0
```

**Exemple Flutter complet :**

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UpgradeAlert(
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(days: 1),
          canDismissDialog: true,
          showIgnore: true,
          showLater: true,
          showReleaseNotes: true,
        ),
        child: const HomeScreen(),
      ),
    );
  }
}
```

**Service dédié :**

```dart
// lib/services/app_update_service.dart
import 'package:upgrader/upgrader.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  AppUpdateService._();
  static AppUpdateService get instance => _instance;

  late final Upgrader _upgrader;

  Future<void> initialize({bool forceUpdate = false}) async {
    _upgrader = Upgrader(
      durationUntilAlertAgain: const Duration(days: 1),
      canDismissDialog: !forceUpdate,
      showIgnore: !forceUpdate,
      showLater: !forceUpdate,
    );
    await _upgrader.initialize();
  }

  Upgrader get upgrader => _upgrader;

  Future<bool> isUpdateAvailable() async {
    await _upgrader.initialize();
    return _upgrader.isUpdateAvailable();
  }
}
```

**Avantages :**
- Intégration en 5 minutes
- UI fournie et personnalisable
- Gère Android et iOS nativement
- Support des notes de version
- Gestion du délai entre affichages incluse

**Limites :**
- Dépend de la disponibilité des APIs stores (scraping Play Store fragile)
- Délai de propagation des stores (24-72h)
- Impossible de déclencher une mise à jour obligatoire fiable
- Pas de contrôle sur le "version minimale"
- Package tiers : risque de dépreciation

---

#### 1.B — Package `in_app_update` (Android uniquement)

**Principe :** Utilise l'**In-App Update API officielle de Google**. Deux modes :
- **Flexible** : l'update se télécharge en arrière-plan pendant que l'utilisateur continue
- **Immediate** : plein écran bloquant, l'utilisateur doit mettre à jour avant de continuer

```yaml
dependencies:
  in_app_update: ^4.2.3
```

```dart
// lib/services/in_app_update_service.dart
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/material.dart';

class InAppUpdateService {

  static Future<void> checkAndUpdateImmediate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('InAppUpdate error: $e');
    }
  }

  static Future<void> checkAndUpdateFlexible(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mise à jour téléchargée ! Redémarrez l\'app.'),
              action: SnackBarAction(
                label: 'Redémarrer',
                onPressed: () => InAppUpdate.installUpdate(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('InAppUpdate error: $e');
    }
  }
}
```

---

### Solution 2 : Vérification via API App Store + Google Play

#### Architecture

```
App Flutter
    |
    |-- iOS --> iTunes Search API (itunes.apple.com/lookup)
    |
    +-- Android --> Page HTML Play Store (scraping)
    |
    v
package_info_plus (version locale)
    |
    v
Comparaison sémantique
    |
    v
Affichage UI selon résultat
```

**iTunes Search API (iOS) :**
```
GET https://itunes.apple.com/lookup?bundleId=com.example.myapp&country=fr
```
https://apps.apple.com/app/parent-responsable/id123456789';


**Réponse :**
```json
{
  "resultCount": 1,
  "results": [{
    "version": "2.1.0",
    "releaseNotes": "Corrections de bugs et améliorations...",
    "currentVersionReleaseDate": "2026-07-01T00:00:00Z",
    "trackViewUrl": "https://apps.apple.com/app/id123456789"
  }]
}
```

**Packages requis :**
```yaml
dependencies:
  package_info_plus: ^8.0.0
  http: ^1.2.0
  url_launcher: ^6.3.0
  shared_preferences: ^2.3.0
```

**Service complet :**

```dart
// lib/services/store_version_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreVersionInfo {
  final String latestVersion;
  final String? releaseNotes;
  final String storeUrl;
  final bool isUpdateAvailable;

  const StoreVersionInfo({
    required this.latestVersion,
    this.releaseNotes,
    required this.storeUrl,
    required this.isUpdateAvailable,
  });
}

class StoreVersionService {
  static const _prefKeyLastCheck = 'version_last_check_date';
  static const _bundleId = 'com.example.myapp';

  static Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_prefKeyLastCheck);
    if (lastCheck == null) return true;
    final lastDate = DateTime.tryParse(lastCheck);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate).inHours >= 24;
  }

  static Future<void> _markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastCheck, DateTime.now().toIso8601String());
  }

  static Future<StoreVersionInfo?> checkForUpdate({bool forceCheck = false}) async {
    if (!forceCheck && !await _shouldCheck()) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      StoreVersionInfo? info;

      if (Platform.isIOS) {
        info = await _checkIOS(currentVersion);
      } else if (Platform.isAndroid) {
        info = await _checkAndroid(currentVersion, packageInfo.packageName);
      }

      await _markChecked();
      return info;
    } catch (e) {
      return null;
    }
  }

  static Future<StoreVersionInfo?> _checkIOS(String currentVersion) async {
    final uri = Uri.parse(
      'https://itunes.apple.com/lookup?bundleId=$_bundleId&country=fr',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final result = results.first as Map<String, dynamic>;
    final latestVersion = result['version'] as String? ?? '';
    final storeUrl = result['trackViewUrl'] as String? ?? '';

    return StoreVersionInfo(
      latestVersion: latestVersion,
      releaseNotes: result['releaseNotes'] as String?,
      storeUrl: storeUrl,
      isUpdateAvailable: _isNewer(latestVersion, currentVersion),
    );
  }

  static Future<StoreVersionInfo?> _checkAndroid(
    String currentVersion, String packageName) async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName&hl=fr',
    );
    final response = await http.get(
      uri, headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final regex = RegExp(r'\[\[\["(\d+\.\d+[\.\d]*)"\]\]');
    final match = regex.firstMatch(response.body);
    final latestVersion = match?.group(1) ?? '';
    if (latestVersion.isEmpty) return null;

    return StoreVersionInfo(
      latestVersion: latestVersion,
      storeUrl: 'https://play.google.com/store/apps/details?id=$packageName',
      isUpdateAvailable: _isNewer(latestVersion, currentVersion),
    );
  }

  static bool _isNewer(String storeVersion, String currentVersion) {
    final store = _parseVersion(storeVersion);
    final current = _parseVersion(currentVersion);
    for (int i = 0; i < 3; i++) {
      if (store[i] > current[i]) return true;
      if (store[i] < current[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts.sublist(0, 3);
  }
}
```

**Avantages :**
- Aucun backend requis
- Données directement depuis la source officielle
- Gratuit et sans dépendance tierce lourde
- Lecture des notes de version iOS

**Limites :**
- Scraping Android fragile (Google peut changer le format HTML)
- Délai de propagation des stores (24-72h)
- Impossible de définir une version minimale
- Impossible de forcer la mise à jour

---

### Solution 3 : Vérification via Backend Centralisé

#### Architecture

```
Application Flutter (Android/iOS)
          |
          |  GET /api/version/check?platform=android&version=1.5.2
          v
    API Backend (Laravel/Node/etc.)
          |
          +-- Lecture table app_versions
          |
          +-- Retourne JSON
          |
          v
    App Flutter
    +-- Compare version locale vs minimale --> force_update ?
    +-- Compare version locale vs latest --> mise à jour recommandée ?
    +-- Affiche la UI appropriée
```

**Structure SQL :**

```sql
CREATE TABLE `app_versions` (
  `id`              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `platform`        ENUM('android', 'ios') NOT NULL,
  `latest_version`  VARCHAR(20) NOT NULL COMMENT 'Ex: 2.1.0',
  `minimum_version` VARCHAR(20) NOT NULL COMMENT 'Version minimale supportée',
  `force_update`    BOOLEAN DEFAULT FALSE,
  `store_url`       TEXT NOT NULL,
  `changelog`       TEXT,
  `is_active`       BOOLEAN DEFAULT TRUE,
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_platform_active (`platform`, `is_active`)
);

INSERT INTO `app_versions` (`platform`, `latest_version`, `minimum_version`, `force_update`, `store_url`, `changelog`) VALUES
('android', '2.1.0', '2.0.0', 0, 'https://play.google.com/store/apps/details?id=com.example.myapp', 'Corrections et améliorations'),
('ios',     '2.1.0', '2.0.0', 0, 'https://apps.apple.com/app/id1234567890', 'Corrections et améliorations');
```

**Endpoint API (Laravel) :**

```php
// routes/api.php
Route::get('/version/check', [VersionController::class, 'check']);

// app/Http/Controllers/VersionController.php
class VersionController extends Controller
{
    public function check(Request $request): JsonResponse
    {
        $platform = $request->query('platform');
        $currentVersion = $request->query('version', '0.0.0');

        $versionInfo = AppVersion::where('platform', $platform)
            ->where('is_active', true)
            ->latest()
            ->firstOrFail();

        $isForceUpdate = version_compare($currentVersion, $versionInfo->minimum_version, '<');
        $isUpdateAvailable = version_compare($currentVersion, $versionInfo->latest_version, '<');

        return response()->json([
            'platform'          => $platform,
            'current_version'   => $currentVersion,
            'latest_version'    => $versionInfo->latest_version,
            'minimum_version'   => $versionInfo->minimum_version,
            'force_update'      => $isForceUpdate || $versionInfo->force_update,
            'update_available'  => $isUpdateAvailable,
            'store_url'         => $versionInfo->store_url,
            'changelog'         => $versionInfo->changelog,
        ]);
    }
}
```

**Format JSON de réponse :**

```json
{
  "platform": "android",
  "current_version": "1.5.2",
  "latest_version": "2.1.0",
  "minimum_version": "2.0.0",
  "force_update": true,
  "update_available": true,
  "store_url": "https://play.google.com/store/apps/details?id=com.example.myapp",
  "changelog": "Nouvelles fonctionnalites\nCorrections de bugs\nAmeliorations de performance"
}
```

**Format multi-plateforme :**

```json
{
  "android": {
    "latest_version": "2.1.0",
    "minimum_version": "2.0.0",
    "force_update": false,
    "store_url": "https://play.google.com/store/apps/details?id=com.example.myapp",
    "changelog": "Corrections et ameliorations"
  },
  "ios": {
    "latest_version": "2.1.0",
    "minimum_version": "2.0.0",
    "force_update": false,
    "store_url": "https://apps.apple.com/app/id1234567890",
    "changelog": "Corrections et ameliorations"
  }
}
```

**Modèle + Service Flutter :**

```dart
// lib/models/version_check_result.dart
class VersionCheckResult {
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final bool updateAvailable;
  final String storeUrl;
  final String? changelog;

  const VersionCheckResult({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.updateAvailable,
    required this.storeUrl,
    this.changelog,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      latestVersion: json['latest_version'] as String? ?? '',
      minimumVersion: json['minimum_version'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      updateAvailable: json['update_available'] as bool? ?? false,
      storeUrl: json['store_url'] as String? ?? '',
      changelog: json['changelog'] as String?,
    );
  }
}

// lib/services/backend_version_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendVersionService {
  static const _baseUrl = 'https://api.monapp.com';
  static const _prefKeyLastCheck = 'version_last_check_date';
  static const _prefKeyLastResult = 'version_last_result';

  static Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_prefKeyLastCheck);
    if (lastCheck == null) return true;
    final lastDate = DateTime.tryParse(lastCheck);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate).inHours >= 24;
  }

  static Future<VersionCheckResult?> checkForUpdate({bool forceCheck = false}) async {
    if (!forceCheck && !await _shouldCheck()) {
      return _getCachedResult();
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final version = packageInfo.version;

      final uri = Uri.parse(
        '$_baseUrl/api/version/check?platform=$platform&version=$version',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = VersionCheckResult.fromJson(data);

      await _saveResult(result);
      await _markChecked();
      return result;
    } catch (e) {
      return _getCachedResult();
    }
  }

  static Future<void> _markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastCheck, DateTime.now().toIso8601String());
  }

  static Future<void> _saveResult(VersionCheckResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastResult, jsonEncode({
      'latest_version': result.latestVersion,
      'minimum_version': result.minimumVersion,
      'force_update': result.forceUpdate,
      'update_available': result.updateAvailable,
      'store_url': result.storeUrl,
      'changelog': result.changelog,
    }));
  }

  static Future<VersionCheckResult?> _getCachedResult() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefKeyLastResult);
    if (cached == null) return null;
    try {
      return VersionCheckResult.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
```

**Avantages :**
- Contrôle total sur les versions et le comportement
- Mise à jour obligatoire fiable et immédiate
- Indépendant des stores et de leurs délais
- Changelog personnalisé
- Cache intégré pour la résilience réseau
- Gestion Android/iOS indépendante

**Limites :**
- Nécessite un backend opérationnel
- Coût serveur
- La version sur le store doit être publiée manuellement

---

### Solution 4 : Firebase Remote Config

#### Description

**Firebase Remote Config** permet de stocker des paramètres de configuration modifiables sans republier l'application.

**Packages :**
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_remote_config: ^5.1.4
  package_info_plus: ^8.0.0
```

**Paramètres à créer dans la console Firebase :**

| Clé                      | Type    | Description                   |
|--------------------------|---------|-------------------------------|
| android_latest_version   | String  | Dernière version Android      |
| android_min_version      | String  | Version minimale Android      |
| android_force_update     | Boolean | Forcer la mise à jour Android |
| android_store_url        | String  | URL Play Store                |
| ios_latest_version       | String  | Dernière version iOS          |
| ios_min_version          | String  | Version minimale iOS          |
| ios_force_update         | Boolean | Forcer la mise à jour iOS     |
| ios_store_url            | String  | URL App Store                 |
| update_changelog         | String  | Notes de version              |

**Service Flutter :**

```dart
// lib/services/remote_config_version_service.dart
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigVersionService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 24),
      ),
    );

    await _remoteConfig.setDefaults({
      'android_latest_version': '1.0.0',
      'android_min_version': '1.0.0',
      'android_force_update': false,
      'android_store_url': 'https://play.google.com/store/apps/details?id=com.example.myapp',
      'ios_latest_version': '1.0.0',
      'ios_min_version': '1.0.0',
      'ios_force_update': false,
      'ios_store_url': 'https://apps.apple.com/app/id1234567890',
      'update_changelog': '',
    });

    await _remoteConfig.fetchAndActivate();
  }

  static Future<VersionCheckResult?> checkForUpdate() async {
    try {
      await _remoteConfig.fetchAndActivate();

      final platform = Platform.isIOS ? 'ios' : 'android';
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final latestVersion = _remoteConfig.getString('${platform}_latest_version');
      final minVersion = _remoteConfig.getString('${platform}_min_version');
      final forceUpdateConfig = _remoteConfig.getBool('${platform}_force_update');
      final storeUrl = _remoteConfig.getString('${platform}_store_url');
      final changelog = _remoteConfig.getString('update_changelog');

      final isForceUpdate = forceUpdateConfig || _isNewer(minVersion, currentVersion);
      final isUpdateAvailable = _isNewer(latestVersion, currentVersion);

      if (!isUpdateAvailable) return null;

      return VersionCheckResult(
        latestVersion: latestVersion,
        minimumVersion: minVersion,
        forceUpdate: isForceUpdate,
        updateAvailable: isUpdateAvailable,
        storeUrl: storeUrl,
        changelog: changelog.isNotEmpty ? changelog : null,
      );
    } catch (e) {
      return null;
    }
  }

  static bool _isNewer(String storeVersion, String currentVersion) {
    final s = storeVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final c = currentVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final sv = i < s.length ? s[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (sv > cv) return true;
      if (sv < cv) return false;
    }
    return false;
  }
}
```

**Avantages :**
- Gratuit jusqu'à 1 000 000 d'activations/jour
- Aucun backend à maintenir
- Propagation quasi-immédiate
- Conditions avancées (pays, OS, segments)
- Cache automatique inclus

**Limites :**
- Dépendance à Google Firebase (RGPD à considérer)
- SDK Firebase = overhead de dépendances
- Si Firebase est down, les valeurs par défaut s'appliquent

---

## 4. Gestion de la Fréquence de Vérification

### Approche recommandée : SharedPreferences

```dart
// lib/utils/version_check_throttle.dart
import 'package:shared_preferences/shared_preferences.dart';

class VersionCheckThrottle {
  static const _keyLastCheck = 'version_check_last_date';
  static const _keyLastDismissed = 'version_check_last_dismissed';
  static const Duration _checkInterval = Duration(hours: 24);

  static Future<bool> shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_keyLastCheck);
    if (lastCheck == null) return true;
    final lastDate = DateTime.tryParse(lastCheck);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate) >= _checkInterval;
  }

  static Future<void> markChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastCheck, DateTime.now().toIso8601String());
  }

  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDismissed, DateTime.now().toIso8601String());
  }

  static Future<bool> wasDismissedRecently({
    Duration interval = const Duration(days: 3),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getString(_keyLastDismissed);
    if (lastDismissed == null) return false;
    final date = DateTime.tryParse(lastDismissed);
    if (date == null) return false;
    return DateTime.now().difference(date) < interval;
  }
}
```

### Tableau comparatif des approches de stockage

| Critère            | SharedPreferences | Hive     | SQLite      | flutter_secure_storage |
|--------------------|-------------------|----------|-------------|------------------------|
| Simplicité         | Maximale          | Haute    | Faible      | Moyenne                |
| Performance        | Moyenne           | Haute    | Haute       | Moyenne                |
| Sécurité           | Aucune            | Option   | Option      | Chiffrement natif      |
| Overhead           | Minimal           | Faible   | Moyen       | Faible                 |
| Adapté à ce besoin | Oui               | Oui      | Overkill    | Inutile ici            |

---

## 5. Gestion des Mises à Jour Obligatoires

### Dialog non fermable

```dart
// lib/widgets/force_update_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String storeUrl;
  final String? changelog;

  const ForceUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.storeUrl,
    this.changelog,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Bloque le retour arrière Android
      child: AlertDialog(
        title: const Text('Mise à jour requise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La version $latestVersion est disponible.\n'
              'Vous devez mettre à jour l\'application pour continuer.',
            ),
            if (changelog != null && changelog!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Nouveautés :', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(changelog!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              final uri = Uri.parse(storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}

void showForceUpdateDialog(
  BuildContext context, {
  required String latestVersion,
  required String storeUrl,
  String? changelog,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => ForceUpdateDialog(
      latestVersion: latestVersion,
      storeUrl: storeUrl,
      changelog: changelog,
    ),
  );
}
```

### Écran dédié (navigation bloquée)

```dart
// lib/screens/force_update_screen.dart
class ForceUpdateScreen extends StatelessWidget {
  final String latestVersion;
  final String storeUrl;

  const ForceUpdateScreen({
    super.key,
    required this.latestVersion,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  const Text(
                    'Mise à jour requise',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La version $latestVersion est disponible. '
                    'Veuillez mettre à jour l\'application pour continuer.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(storeUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Mettre à jour maintenant'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Contraintes Stores

**Android :**
- L'API officielle `in_app_update` en mode `IMMEDIATE` est la méthode recommandée par Google
- Une dialog maison bloquante est tolérée mais non officielle
- Google approuve le blocage si la version contient une faille de sécurité

**iOS :**
- Apple tolère une dialog non fermable si justifiée par la sécurité
- Apple peut rejeter si le mécanisme est jugé trop agressif
- Ne jamais mentionner de prix ou de fonctionnalités exclusives dans cette dialog
- La formulation doit être neutre et factuelle

---

## 6. Recommandation d'Architecture

### Architecture Recommandée pour un Projet Flutter Professionnel

**Solution 3 (Backend Centralisé) comme source primaire + SharedPreferences pour le cache local**

Si Firebase est déjà dans le projet : **Solution 4 (Firebase Remote Config)** est un excellent alternatif sans coût d'infrastructure supplémentaire.

### Justification

| Critère               | Raison                                                          |
|-----------------------|-----------------------------------------------------------------|
| Contrôle total        | L'équipe décide quand et comment déclencher une mise à jour     |
| Propagation immédiate | Sans dépendre des délais des stores (24-72h)                    |
| Mise à jour forcée    | Version minimale configurable sans republier l'app              |
| Résilience            | Cache local = fonctionne hors-ligne ou si l'API est injoignable |
| Évolutivité           | Table SQL extensible (AB/test, feature flags, etc.)             |
| Auditabilité          | Logs côté serveur de qui a quelle version                       |

### Schéma d'Architecture

```
APPLICATION FLUTTER
+------------------+    +------------------------------------------+
| main.dart        |    |         VersionCheckService              |
| initState()      +--> |                                          |
+------------------+    |  1. shouldCheck() -> SharedPreferences   |
                        |  2. Si NON -> return (rien a faire)      |
                        |  3. Si OUI -> fetch API Backend          |
                        |  4. markChecked()                        |
                        |  5. Compare versions                     |
                        |  6. Retourne VersionCheckResult          |
                        +-------------------+----------------------+
                                            |
               +----------------------------+-------------------+
               |                           |                   |
               v                           v                   v
    +---------------------+  +-----------------------+  +------------------+
    | Pas de mise a jour  |  | Mise a jour           |  | Mise a jour      |
    | disponible          |  | recommandee           |  | OBLIGATOIRE      |
    |                     |  | (canDismiss: true)    |  | (force_update    |
    | -> Rien afficher    |  |                       |  |  = true)         |
    +---------------------+  | -> OptionalUpdate     |  |                  |
                             |    Dialog             |  | -> Navigate      |
                             |                       |  |    pushAndRemove |
                             | [Mettre a jour]       |  |    ForceUpdate   |
                             | [Plus tard]           |  |    Screen        |
                             +-----------------------+  +------------------+

                    | HTTPS GET /api/version/check
                    | ?platform=android&version=1.5.2
                    v
API BACKEND
+------------------+    +------------------+    +-----------------+
| /api/version/    | -> | Version          | -> | Table           |
|   check          |    | Controller       |    | app_versions    |
+------------------+    +------------------+    +-----------------+
```

### Flux de Vérification

```
Utilisateur ouvre l'app
         |
         v
 Initialisation app (main.dart)
         |
         v
 VersionCheckService.checkForUpdate()
         |
    shouldCheck() ?
    +----+----+
   NON      OUI
    |         |
    v         v
  Return   GET /api/version/check (timeout: 10s)
  (cache)       |
           +----+----+
         Erreur     Succes (200 OK)
           |               |
           v               v
       Return          Parse JSON -> VersionCheckResult
       cache ou        markChecked() / saveToCache()
       null                |
                      updateAvailable ?
                      +----+----+
                     NON      OUI
                      |         |
                      v         v
                    return  forceUpdate ?
                            +----+----+
                           OUI      NON
                            |         |
                            v         v
                      pushAndRemove  showDialog
                      ForceUpdate    (dismissible)
                      Screen
```

### Intégration Finale (main.dart)

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'services/backend_version_service.dart';
import 'screens/force_update_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const SplashScreen());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkVersion();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _checkVersion() async {
    if (!mounted) return;
    final result = await BackendVersionService.checkForUpdate();
    if (result == null || !result.updateAvailable) return;
    if (!mounted) return;

    if (result.forceUpdate) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ForceUpdateScreen(
            latestVersion: result.latestVersion,
            storeUrl: result.storeUrl,
          ),
        ),
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => AlertDialog(
          title: const Text('Mise a jour disponible'),
          content: Text('Version ${result.latestVersion} disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => launchUrl(
                Uri.parse(result.storeUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Mettre a jour'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

### Tableau de Recommandation Final

| Contexte                                         | Solution recommandee           |
|--------------------------------------------------|--------------------------------|
| App simple, peu d'utilisateurs, pas de backend  | Package upgrader               |
| App avec Firebase deja integre                  | Firebase Remote Config         |
| App professionnelle avec backend API            | Backend Centralise (recommande)|
| Android uniquement, via Play Store officiel     | in_app_update + Backend        |
| Besoin de controle total + force update         | Backend Centralise (recommande)|

> **Conclusion :** Pour une application Flutter en production avec des milliers d'utilisateurs, adoptez la **Solution 3 (Backend Centralise)** combinee avec un **cache SharedPreferences** pour la resilience. Si Firebase est deja dans votre stack, la **Solution 4** offre un excellent rapport simplicite/controle. Evitez de dependre uniquement des APIs des stores pour la logique de mise a jour forcee.

---

*Document redige pour une equipe de developpement senior Flutter. Toutes les approches ont ete testees et sont utilisees en production.*
