import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/version_check_result.dart';

class VersionUpdateService {
  // 1. Définir le booléen pour activer ou désactiver la vérification
  static const bool enableUpdateCheck = true;

  // 2. Le JSON mocké (à remplacer par un appel API plus tard)
  static const String _mockApiResponse = '''
  {
    "android": {
      "latest_version": "2.1.0",
      "minimum_version": "1.0.10",
      "force_update": false,
      "store_url": "https://play.google.com/store/apps/details?id=com.groupegain.parents_responsable&hl=fr",
      "changelog": "Corrections et améliorations"
    },
    "ios": {
      "latest_version": "2.1.0",
      "minimum_version": "1.0.10",
      "force_update": false,
      "store_url": "https://apps.apple.com/app/parent-responsable/id6763526336",
      "changelog": "Corrections et améliorations"
    }
  }
  ''';

  static Future<VersionCheckResult?> checkForUpdate() async {
    if (!enableUpdateCheck) return null;

    try {
      // Pour une vraie API :
      // final response = await http.get(Uri.parse('https://api.votre-site.com/version'));
      // final Map<String, dynamic> data = json.decode(response.body);

      // Pour l'instant, on utilise le mock
      final Map<String, dynamic> data = json.decode(_mockApiResponse);

      // On détermine la plateforme
      final platform = Platform.isIOS ? 'ios' : 'android';
      print('Plateforme détectée : $platform');

      // On s'assure que la clé de la plateforme existe dans le JSON
      if (!data.containsKey(platform)) {
        print('Aucune configuration de mise à jour trouvée pour $platform');
        return null;
      }

      final platformData = data[platform] as Map<String, dynamic>;

      // On récupère la version actuelle de l'application installée
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('Lancement de l\'analyse de la version...');

      // On parse les données dans notre Model
      final result = VersionCheckResult.fromJson(platformData, currentVersion);

      // On ne retourne le résultat que s'il y a une mise à jour disponible
      if (result.updateAvailable) {
        return result;
      }

      return null;
    } catch (e) {
      print('Erreur lors de la vérification de version: $e');
      return null;
    }
  }
}
