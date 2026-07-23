import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';
import '../models/version_check_result.dart';
import 'database_service.dart';
import 'onesignal_service.dart';
import 'notification_service.dart';

class VersionUpdateService {
  // 1. Définir le booléen pour activer ou désactiver la vérification
  static const bool enableUpdateCheck = true;

  // Permet de ne pas harceler l'utilisateur avec la notification à chaque retour sur la Home
  static bool hasShownUpdateNotification = false;

  static Future<VersionCheckResult?> checkForUpdate() async {
    if (!enableUpdateCheck) return null;

    final platform = Platform.isIOS ? 'ios' : 'android';
    print('Plateforme détectée : $platform');

    Map<String, dynamic>? platformData;

    try {
      // Appel API vers le script PHP
      final response = await http.get(
        Uri.parse(
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/app-versions',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // On s'assure que la clé de la plateforme existe dans le JSON
        if (data.containsKey(platform)) {
          platformData = data[platform] as Map<String, dynamic>;
          // Sauvegarder dans le cache pour un accès hors ligne futur
          await DatabaseService.instance.saveVersionUpdateCache(platform, platformData);
        } else {
          print('Aucune configuration de mise à jour trouvée pour $platform');
        }
      } else {
        print(
          'Erreur réseau lors de la vérification de la version : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur lors de la vérification de version (API inaccessible): $e');
    }

    // Si on n'a pas pu récupérer les données depuis l'API, on tente depuis le cache local
    if (platformData == null) {
      print('Tentative de récupération de la version depuis le cache local...');
      platformData = await DatabaseService.instance.getVersionUpdateCache(platform);
      
      if (platformData != null) {
        print('Données de version récupérées depuis le cache avec succès.');
      } else {
        print('Aucune donnée de version trouvée dans le cache.');
        return null;
      }
    }

    try {
      // On récupère la version actuelle de l'application installée
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 1. Taguer automatiquement la version de l'utilisateur dans OneSignal
      try {
        OneSignalService().addTag('app_version', currentVersion);
      } catch (e) {
        print('Erreur tag OneSignal app_version: $e');
      }

      print('Lancement de l\'analyse de la version...');

      // On parse les données dans notre Model
      final result = VersionCheckResult.fromJson(platformData, currentVersion);

      // On ne retourne le résultat que s'il y a une mise à jour disponible ou forcée
      if (result.updateAvailable || result.forceUpdate) {
        // Taguer dans OneSignal qu'une mise à jour est requise pour cet utilisateur
        try {
          OneSignalService().addTag('update_required', 'true');
        } catch (_) {}

        // Notification automatique Push/Locale lors de la détection de la mise à jour
        if (!hasShownUpdateNotification) {
          hasShownUpdateNotification = true;
          try {
            await NotificationService().showNotification(
              id: 999,
              title: 'Mise à jour disponible 🚀',
              body: result.latestVersion.isNotEmpty
                  ? 'Une nouvelle version (${result.latestVersion}) de l\'application est disponible. Cliquez pour mettre à jour.'
                  : 'Une nouvelle version de l\'application est disponible. Cliquez pour mettre à jour.',
              payload: result.storeUrl,
            );
          } catch (e) {
            print('Erreur notification automatique de mise à jour: $e');
          }
        }

        return result;
      } else {
        try {
          OneSignalService().addTag('update_required', 'false');
        } catch (_) {}
      }

      return null;
    } catch (e) {
      print('Erreur lors du traitement des données de version: $e');
      return null;
    }
  }
}
