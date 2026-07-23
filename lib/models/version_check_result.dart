import 'dart:io';
import '../config/app_config.dart';

class VersionCheckResult {
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final bool updateAvailable;
  final String storeUrl;
  final String? changelog;

  const VersionCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.updateAvailable,
    required this.storeUrl,
    this.changelog,
  });

  factory VersionCheckResult.fromJson(
      Map<String, dynamic> json, String currentVersion) {
    print("--- DEBUT DE LA COMPARAISON DES VERSIONS ---");
    print("Version actuelle de l'app: $currentVersion");
    
    final latestVersion = json['latest_version'] as String? ?? '';
    final minimumVersion = json['minimum_version'] as String? ?? '';
    
    print("Dernière version (latest_version): $latestVersion");
    print("Version minimale (minimum_version): $minimumVersion");
    
    // Parsing de force_update robuste
    bool forceUpdate = false;
    final rawForce = json['force_update'];
    if (rawForce is bool) {
      forceUpdate = rawForce;
    } else if (rawForce != null) {
      forceUpdate = rawForce.toString() == 'true' || rawForce.toString() == '1';
    }
    print("force_update (from JSON): $forceUpdate");
    
    if (!forceUpdate && minimumVersion.isNotEmpty) {
      forceUpdate = _isVersionLower(currentVersion, minimumVersion);
      print("Calcul force_update (current < minimum): $forceUpdate");
    }

    // Parsing de update_available robuste
    bool updateAvailable = false;
    final rawUpdate = json['update_available'];
    if (rawUpdate is bool) {
      updateAvailable = rawUpdate;
    } else if (rawUpdate != null) {
      updateAvailable = rawUpdate.toString() == 'true' || rawUpdate.toString() == '1';
    }
    print("update_available (from JSON): $updateAvailable");
    
    if (!updateAvailable && latestVersion.isNotEmpty) {
      updateAvailable = _isVersionLower(currentVersion, latestVersion);
      print("Calcul update_available (current < latest): $updateAvailable");
    }

    // Si une mise à jour forcée est requise, une mise à jour est nécessairement disponible
    if (forceUpdate) {
      updateAvailable = true;
      print("forceUpdate est vrai -> updateAvailable forcé à true");
    }

    // Détermination dynamique de l'URL du Store selon l'OS (Android vs iOS)
    final rawStoreUrl = json['store_url'] as String? ?? '';
    String effectiveStoreUrl = rawStoreUrl;

    if (Platform.isAndroid) {
      if (rawStoreUrl.isEmpty || !rawStoreUrl.contains('play.google.com')) {
        effectiveStoreUrl = AppConfig.ANDROID_STORE_URL;
      }
    } else if (Platform.isIOS) {
      if (rawStoreUrl.isEmpty || !rawStoreUrl.contains('apple.com')) {
        effectiveStoreUrl = AppConfig.IOS_STORE_URL;
      }
    }

    print("--- FIN DE LA COMPARAISON DES VERSIONS (Store URL: $effectiveStoreUrl) ---");

    return VersionCheckResult(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      forceUpdate: forceUpdate,
      updateAvailable: updateAvailable,
      storeUrl: effectiveStoreUrl,
      changelog: json['changelog'] as String?,
    );
  }

  static bool _isVersionLower(String current, String target) {
    if (current.isEmpty || target.isEmpty) return false;
    try {
      final currentParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final targetParts = target.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      
      print("  -> Comparaison détaillée: $currentParts (actuel) vs $targetParts (cible)");
      
      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final t = i < targetParts.length ? targetParts[i] : 0;
        
        if (c < t) {
          print("    -> $c < $t à l'index $i. La version actuelle est inférieure.");
          return true;
        }
        if (c > t) {
          print("    -> $c > $t à l'index $i. La version actuelle est supérieure ou égale.");
          return false;
        }
      }
      print("    -> Les versions sont identiques.");
    } catch (e) {
      print("  -> Erreur lors du parsing des versions: $e");
    }
    return false;
  }
}
