import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../models/configuration_ecole.dart';
import '../utils/api_exception_handler.dart';

/// Service pour récupérer les options de configuration école depuis l'API
class ConfigurationEcoleService {
  static const Duration _timeout = Duration(seconds: 30);
  static ConfigurationEcoleData? _cachedData;

  /// Options par défaut issues de la configuration de l'école
  static const List<String> defaultStatuts = ['Tous', 'Public', 'Privé'];
  static const List<String> defaultProgrammes = ['Tous', 'Français', 'Anglais', 'Arabe'];
  static const List<String> defaultOrdres = [
    'Tous',
    'Laïc',
    'Catholique',
    'Évangélique',
    'Méthodiste',
    'Islamique',
  ];
  static const List<String> defaultTypes = [
    'Tous',
    'Général',
    'Technique',
    'Professionnel',
    'Supérieur',
  ];

  /// Récupère la configuration complète depuis l'API https://api2.vie-ecoles.com/api/options/configuration-ecole
  static Future<ConfigurationEcoleData?> getConfiguration({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedData != null) {
      return _cachedData;
    }

    try {
      final url =
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/options/configuration-ecole';
      developer.log('[ConfigurationEcoleService] GET Request URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['data'] != null && body['data'] is Map<String, dynamic>) {
          final data = ConfigurationEcoleData.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          _cachedData = data;
          developer.log(
            '[ConfigurationEcoleService] Options de configuration récupérées avec succès',
          );
          return data;
        }
      }
    } catch (e) {
      developer.log(
        '❌ [ConfigurationEcoleService] Erreur lors de la récupération des options: $e',
      );
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération des options de configuration',
      );
    }
    return _cachedData;
  }

  /// Retourne la liste des intitulés de statuts (avec 'Tous' au début)
  static Future<List<String>> getStatutsOptions({
    bool forceRefresh = false,
  }) async {
    final config = await getConfiguration(forceRefresh: forceRefresh);
    if (config != null && config.statuts.isNotEmpty) {
      return ['Tous', ...config.statuts.map((e) => e.libelle)];
    }
    return defaultStatuts;
  }

  /// Retourne la liste des intitulés de programmes d'enseignement (avec 'Tous' au début)
  static Future<List<String>> getProgrammesOptions({
    bool forceRefresh = false,
  }) async {
    final config = await getConfiguration(forceRefresh: forceRefresh);
    if (config != null && config.programmesEnseignement.isNotEmpty) {
      return ['Tous', ...config.programmesEnseignement.map((e) => e.libelle)];
    }
    return defaultProgrammes;
  }

  /// Retourne la liste des intitulés d'ordres d'enseignement (avec 'Tous' au début)
  static Future<List<String>> getOrdresOptions({
    bool forceRefresh = false,
  }) async {
    final config = await getConfiguration(forceRefresh: forceRefresh);
    if (config != null && config.ordresEnseignement.isNotEmpty) {
      return ['Tous', ...config.ordresEnseignement.map((e) => e.libelle)];
    }
    return defaultOrdres;
  }

  /// Retourne la liste des intitulés de types d'enseignement (avec 'Tous' au début)
  static Future<List<String>> getTypesOptions({
    bool forceRefresh = false,
  }) async {
    final config = await getConfiguration(forceRefresh: forceRefresh);
    if (config != null && config.typesEnseignement.isNotEmpty) {
      return ['Tous', ...config.typesEnseignement.map((e) => e.libelle)];
    }
    return defaultTypes;
  }
}
