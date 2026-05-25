import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

/// Service HTTP pour les appels API externes
class HttpService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;
  static const Duration timeout = Duration(seconds: 30);

  /// Effectue une requête POST
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool showNotification = true,
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
      throw _handleError(e, context: 'POST $endpoint', showNotification: showNotification);
    }
  }

  /// Effectue une requête GET
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    bool showNotification = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🌐 HttpService GET URL: $uri');

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

      print('🌐 HttpService Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('🌐 HttpService Response body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      print('🌐 HttpService Error: $e');
      throw _handleError(e, context: 'GET $endpoint', showNotification: showNotification);
    }
  }

  /// Effectue une requête DELETE
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool showNotification = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🌐 HttpService DELETE URL: $uri');

      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout);

      print('🌐 HttpService Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        print('🌐 HttpService Response body: ${response.body}');
      }

      // 204 No Content est une réponse valide pour un DELETE réussi
      if (response.statusCode == 204) {
        return {'status': 'success'};
      }

      return _handleResponse(response);
    } catch (e) {
      print('🌐 HttpService Error: $e');
      throw _handleError(e, context: 'DELETE $endpoint', showNotification: showNotification);
    }
  }

  /// Traite la réponse HTTP
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Cas spécial : L'API retourne parfois un code 500 avec {"somme_reservation":0,"status":false}
    // au lieu d'un 200 OK quand il n'y a pas de réservation. On traite cela comme un succès.
    final bool isSpecialReservationNoContent = response.statusCode == 500 &&
        response.body.contains('"somme_reservation":0') &&
        response.body.contains('"status":false');

    // Vérifier les erreurs HTTP et notifier l'utilisateur
    ApiExceptionHandler.handleHttpStatus(
      response.statusCode,
      responseBody: response.body,
      context: 'la requête API',
      showNotification: response.statusCode >= 500 && !isSpecialReservationNoContent, // Notifier seulement pour les erreurs réelles du serveur
    );

    if ((response.statusCode >= 200 && response.statusCode < 300) || isSpecialReservationNoContent) {
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

  /// Traite les erreurs et affiche les notifications appropriées
  static Exception _handleError(dynamic error, {String? context, bool showNotification = true}) {
    // Utiliser le handler centralisé pour détecter et notifier
    ApiExceptionHandler.handle(
      error,
      context: context,
      showNotification: showNotification,
    );

    // Retourner l'exception originale pour ne pas casser le flow existant
    if (error is Exception) {
      return error;
    }
    return Exception('Erreur de connexion: $error');
  }
}
