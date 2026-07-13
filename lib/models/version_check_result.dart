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
    
    // Si force_update n'est pas fourni, on calcule localement
    bool forceUpdate = json['force_update'] as bool? ?? false;
    print("force_update (from JSON): $forceUpdate");
    
    if (!forceUpdate && minimumVersion.isNotEmpty) {
      forceUpdate = _isVersionLower(currentVersion, minimumVersion);
      print("Calcul force_update (current < minimum): $forceUpdate");
    }

    // Si updateAvailable n'est pas fourni, on calcule localement
    bool updateAvailable = json['update_available'] as bool? ?? false;
    print("update_available (from JSON): $updateAvailable");
    
    if (!updateAvailable && latestVersion.isNotEmpty) {
      updateAvailable = _isVersionLower(currentVersion, latestVersion);
      print("Calcul update_available (current < latest): $updateAvailable");
    }

    print("--- FIN DE LA COMPARAISON DES VERSIONS ---");

    return VersionCheckResult(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      forceUpdate: forceUpdate,
      updateAvailable: updateAvailable,
      storeUrl: json['store_url'] as String? ?? '',
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
