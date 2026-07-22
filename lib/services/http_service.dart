import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

/// Service HTTP pour les appels API externes
class HttpService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;
  static const Duration timeout = Duration(seconds: 30);

  static bool _hasConnection = true;
  static DateTime _lastConnectionCheck = DateTime.now().subtract(const Duration(minutes: 1));

  /// Vérifie la connexion internet avec un cache de 5 secondes
  static Future<void> _ensureConnection() async {
    final now = DateTime.now();
    if (now.difference(_lastConnectionCheck).inSeconds > 5) {
      try {
        final result = await InternetAddress.lookup('google.com');
        _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        _hasConnection = false;
      }
      _lastConnectionCheck = now;
    }

    if (!_hasConnection) {
      throw const SocketException('Pas de connexion internet détectée');
    }
  }

  /// Effectue une requête POST
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool showNotification = true,
  }) async {
    try {
      await _ensureConnection();
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🌐 HttpService POST URL: $uri');

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
      await _ensureConnection();
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
      await _ensureConnection();
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
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Erreur HTTP ${response.statusCode}';
        throw ApiException(
          message: errorMessage.toString(),
          type: ApiErrorType.clientError,
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          message: 'Erreur HTTP ${response.statusCode}',
          type: ApiErrorType.serverError,
          statusCode: response.statusCode,
        );
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
