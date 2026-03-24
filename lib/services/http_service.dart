import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service HTTP pour les appels API externes
class HttpService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;
  static const Duration timeout = Duration(seconds: 30);

  /// Effectue une requête POST
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: body != null ? json.encode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête GET
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Traite la réponse HTTP
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Réponse invalide du serveur: ${response.body}');
      }
    } else {
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(
          errorData['error'] ?? 'Erreur HTTP ${response.statusCode}',
        );
      } catch (e) {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    }
  }

  /// Traite les erreurs
  static Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('Erreur de connexion: $error');
  }
}
