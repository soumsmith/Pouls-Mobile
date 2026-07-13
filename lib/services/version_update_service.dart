import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';
import '../models/version_check_result.dart';

class VersionUpdateService {
  // 1. Définir le booléen pour activer ou désactiver la vérification
  static const bool enableUpdateCheck = true;

  static Future<VersionCheckResult?> checkForUpdate() async {
    if (!enableUpdateCheck) return null;

    try {
      // Appel API vers le script PHP
      final response = await http.get(
        Uri.parse(
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/app-versions',
        ),
      );

      if (response.statusCode != 200) {
        print(
          'Erreur réseau lors de la vérification de la version : ${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);

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
