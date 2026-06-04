import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

/// Modèle représentant un pays retourné par l'API
class Pays {
  final String nom;
  final String lien;
  final String photo;

  const Pays({
    required this.nom,
    required this.lien,
    required this.photo,
  });

  factory Pays.fromJson(Map<String, dynamic> json) {
    return Pays(
      nom: json['nom'] as String? ?? '',
      lien: json['lien'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
    );
  }
}

/// Service pour récupérer la liste des pays depuis l'API
class PaysService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Cache en mémoire pour éviter les appels répétés
  static List<Pays>? _cachedPays;

  /// Récupère la liste des pays depuis l'API
  /// Utilise un cache mémoire pour éviter les appels réseau inutiles.
  static Future<List<Pays>> getPays({bool forceRefresh = false}) async {
    // Retourner le cache si disponible et pas de refresh forcé
    if (!forceRefresh && _cachedPays != null) {
      return _cachedPays!;
    }

    try {
      final url = '${AppConfig.API_AFRICA_URL}/ecoles/pays';
      developer.log('[PaysService] GET Request URL: $url');

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
        final List<dynamic> data = json.decode(response.body);
        final pays = data.map((item) => Pays.fromJson(item as Map<String, dynamic>)).toList();
        
        // Mettre en cache
        _cachedPays = pays;
        
        developer.log('[PaysService] ${pays.length} pays récupérés avec succès');
        return pays;
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [PaysService] Erreur lors de la récupération des pays: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des pays');
      throw Exception('Erreur lors de la récupération des pays: $e');
    }
  }

  /// Retourne la liste des noms de pays avec "Tous" en premier
  static Future<List<String>> getPaysNames({bool forceRefresh = false}) async {
    final pays = await getPays(forceRefresh: forceRefresh);
    return ['Tous', ...pays.map((p) => p.nom)];
  }

  /// Construit le map pays display -> API value dynamiquement
  static Future<Map<String, String>> getPaysMap({bool forceRefresh = false}) async {
    final pays = await getPays(forceRefresh: forceRefresh);
    final map = <String, String>{'Tous': ''};
    for (final p in pays) {
      map[p.nom] = p.nom;
    }
    return map;
  }

  /// Construit le reverse map API value -> display name dynamiquement
  static Future<Map<String, String>> getPaysReverseMap({bool forceRefresh = false}) async {
    final pays = await getPays(forceRefresh: forceRefresh);
    final map = <String, String>{'': 'Tous'};
    for (final p in pays) {
      map[p.nom] = p.nom;
    }
    return map;
  }

  /// Vide le cache
  static void clearCache() {
    _cachedPays = null;
  }
}
