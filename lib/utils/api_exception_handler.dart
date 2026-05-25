import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'notification_helper.dart';

/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException($type): $message';
}

/// Types d'erreurs API
enum ApiErrorType {
  timeout,
  noConnection,
  serverError,
  clientError,
  parseError,
  unknown,
}

/// Gestionnaire centralisé des exceptions API.
///
/// Cette classe fournit une méthode unique [handle] pour traiter toutes
/// les erreurs qui peuvent survenir lors d'appels API :
/// - Timeout (TimeoutException)
/// - Pas de connexion (SocketException)
/// - Erreurs DNS (ClientException avec 'failed host lookup')
/// - Erreurs serveur (status >= 500)
/// - Erreurs client (status 4xx)
/// - Erreurs de parsing JSON
///
/// Elle affiche automatiquement une notification à l'utilisateur
/// via [NotificationHelper].
class ApiExceptionHandler {
  ApiExceptionHandler._();

  static String? _cleanContext(String? context) {
    if (context == null) return null;
    
    // Si c'est un endpoint brut (ex: "GET /vie-ecoles/reservation/eleve/...")
    if (context.startsWith('GET ') || context.startsWith('POST ') || context.startsWith('DELETE ') || context.startsWith('PUT ')) {
      final parts = context.split(' ');
      if (parts.length < 2) return context;
      final String endpoint = parts[1];
      
      if (endpoint.contains('/reservation/eleve/')) {
        return "la récupération de vos réservations";
      }
      if (endpoint.contains('/emploi-du-temps-eleve/')) {
        return "la récupération de l'emploi du temps";
      }
      if (endpoint.contains('/scolarite-eleve/')) {
        return "la récupération de la scolarité";
      }
      if (endpoint.contains('/messages/')) {
        return "la récupération de vos messages";
      }
      if (endpoint.contains('/ecoles/detail-ecole/')) {
        return "la récupération des détails de l'école";
      }
      if (endpoint.contains('/statistiques-presence-eleve/')) {
        return "la récupération de l'état des présences";
      }
      if (endpoint.contains('/service/abonnement/')) {
        return "la récupération de vos abonnements";
      }
      if (endpoint.contains('/paiements-scolarite-eleve/')) {
        return "la récupération de l'historique des paiements";
      }
      if (endpoint.contains('/commandes/') || endpoint.contains('/orders/')) {
        return "le chargement de vos commandes";
      }
      if (endpoint.contains('/eleve/detail/')) {
        return "la récupération du profil élève";
      }
      return "la communication avec le serveur";
    }
    
    return context;
  }

  /// Traite une erreur API et affiche une notification appropriée.
  ///
  /// [error] L'erreur capturée dans le catch
  /// [context] Description du contexte (ex: "récupération des écoles")
  /// [showNotification] Si true, affiche une notification à l'utilisateur (défaut: true)
  ///
  /// Retourne une [ApiException] typée pour un traitement ultérieur si nécessaire.
  static ApiException handle(
    dynamic error, {
    String? context,
    bool showNotification = true,
  }) {
    final cleanCtx = _cleanContext(context);
    final ApiException apiException;
 
    if (error is TimeoutException) {
      apiException = ApiException(
        message: cleanCtx != null
            ? 'Délai dépassé lors de $cleanCtx'
            : 'Le serveur met trop de temps à répondre',
        type: ApiErrorType.timeout,
        originalError: error,
      );
 
      if (showNotification) {
        NotificationHelper.showTimeout(
          customMessage: 'Le serveur met trop de temps à répondre. '
              'Vérifiez votre connexion et réessayez.',
        );
      }
    } else if (error is SocketException) {
      apiException = ApiException(
        message: cleanCtx != null
            ? 'Pas de connexion lors de $cleanCtx'
            : 'Impossible de se connecter au serveur',
        type: ApiErrorType.noConnection,
        originalError: error,
      );
 
      if (showNotification) {
        NotificationHelper.showNoConnection();
      }
    } else if (error is http.ClientException) {
      final errorMsg = error.message.toLowerCase();
 
      if (errorMsg.contains('failed host lookup') ||
          errorMsg.contains('no address associated') ||
          errorMsg.contains('connection refused') ||
          errorMsg.contains('network is unreachable')) {
        apiException = ApiException(
          message: cleanCtx != null
              ? 'Connexion impossible lors de $cleanCtx'
              : 'Impossible de résoudre le serveur',
          type: ApiErrorType.noConnection,
          originalError: error,
        );
 
        if (showNotification) {
          NotificationHelper.showNoConnection(
            customMessage: 'Impossible de joindre le serveur. '
                'Vérifiez votre connexion internet.',
          );
        }
      } else {
        apiException = ApiException(
          message: cleanCtx != null
              ? 'Erreur réseau lors de $cleanCtx'
              : 'Erreur réseau',
          type: ApiErrorType.unknown,
          originalError: error,
        );
 
        if (showNotification) {
          NotificationHelper.showError(
            'Erreur réseau. Veuillez réessayer.',
          );
        }
      }
    } else if (error is FormatException) {
      apiException = ApiException(
        message: cleanCtx != null
            ? 'Réponse invalide lors de $cleanCtx'
            : 'Réponse du serveur invalide',
        type: ApiErrorType.parseError,
        originalError: error,
      );
 
      if (showNotification) {
        NotificationHelper.showError(
          'Le serveur a renvoyé une réponse inattendue.',
        );
      }
    } else if (error is ApiException) {
      // Déjà une ApiException, la retourner telle quelle
      apiException = error;
 
      if (showNotification) {
        switch (error.type) {
          case ApiErrorType.timeout:
            NotificationHelper.showTimeout();
            break;
          case ApiErrorType.noConnection:
            NotificationHelper.showNoConnection();
            break;
          case ApiErrorType.serverError:
            NotificationHelper.showServerError(statusCode: error.statusCode);
            break;
          case ApiErrorType.clientError:
            NotificationHelper.showError(error.message);
            break;
          case ApiErrorType.parseError:
            NotificationHelper.showError(
              'Le serveur a renvoyé une réponse inattendue.',
            );
            break;
          case ApiErrorType.unknown:
            NotificationHelper.showError(error.message);
            break;
        }
      }
    } else {
      // Vérifier si le message contient des indices sur le type d'erreur
      final errorString = error.toString().toLowerCase();
 
      if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        apiException = ApiException(
          message: cleanCtx != null
              ? 'Délai dépassé lors de $cleanCtx'
              : 'Délai de connexion dépassé',
          type: ApiErrorType.timeout,
          originalError: error,
        );
 
        if (showNotification) {
          NotificationHelper.showTimeout();
        }
      } else if (errorString.contains('connection') ||
          errorString.contains('socket') ||
          errorString.contains('network') ||
          errorString.contains('host lookup') ||
          errorString.contains('no route') ||
          errorString.contains('connexion')) {
        apiException = ApiException(
          message: cleanCtx != null
              ? 'Pas de connexion lors de $cleanCtx'
              : 'Problème de connexion',
          type: ApiErrorType.noConnection,
          originalError: error,
        );
 
        if (showNotification) {
          NotificationHelper.showNoConnection();
        }
      } else {
        apiException = ApiException(
          message: cleanCtx != null
              ? 'Erreur lors de $cleanCtx'
              : 'Une erreur est survenue',
          type: ApiErrorType.unknown,
          originalError: error,
        );
 
        if (showNotification) {
          NotificationHelper.showError(
            cleanCtx != null
                ? 'Erreur lors de $cleanCtx. Veuillez réessayer.'
                : 'Une erreur inattendue est survenue.',
          );
        }
      }
    }
 
    // Log pour le debug
    print('');
    print('⚠️ ═══════════════════════════════════════════════════════════');
    print('⚠️ API ERROR HANDLED');
    print('⚠️ ═══════════════════════════════════════════════════════════');
    print('⚠️ Type: ${apiException.type}');
    print('⚠️ Message: ${apiException.message}');
    if (cleanCtx != null) print('⚠️ Context: $cleanCtx');
    print('⚠️ Original error: $error');
    print('⚠️ Notification shown: $showNotification');
    print('⚠️ ═══════════════════════════════════════════════════════════');
    print('');
 
    return apiException;
  }

  /// Traite un code de statut HTTP et affiche une notification si nécessaire.
  ///
  /// Retourne une [ApiException] si le statut est une erreur, null sinon.
  static ApiException? handleHttpStatus(
    int statusCode, {
    String? responseBody,
    String? context,
    bool showNotification = true,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      return null; // Pas d'erreur
    }
 
    final cleanCtx = _cleanContext(context);
    final ApiException exception;
 
    if (statusCode >= 500) {
      exception = ApiException(
        message: cleanCtx != null
            ? 'Erreur serveur lors de $cleanCtx'
            : 'Erreur interne du serveur',
        type: ApiErrorType.serverError,
        statusCode: statusCode,
      );
 
      if (showNotification) {
        NotificationHelper.showServerError(statusCode: statusCode);
      }
    } else if (statusCode == 408) {
      // Request Timeout
      exception = ApiException(
        message: cleanCtx != null
            ? 'Délai dépassé lors de $cleanCtx'
            : 'La requête a expiré',
        type: ApiErrorType.timeout,
        statusCode: statusCode,
      );
 
      if (showNotification) {
        NotificationHelper.showTimeout();
      }
    } else if (statusCode == 429) {
      // Too Many Requests
      exception = ApiException(
        message: 'Trop de requêtes envoyées. Veuillez patienter.',
        type: ApiErrorType.clientError,
        statusCode: statusCode,
      );
 
      if (showNotification) {
        NotificationHelper.showWarning(
          'Trop de requêtes. Veuillez patienter un moment.',
        );
      }
    } else if (statusCode >= 400) {
      exception = ApiException(
        message: cleanCtx != null
            ? 'Erreur lors de $cleanCtx (code $statusCode)'
            : 'Erreur client (code $statusCode)',
        type: ApiErrorType.clientError,
        statusCode: statusCode,
      );
 
      if (showNotification && statusCode != 404) {
        // On ne notifie pas les 404 (souvent attendus)
        NotificationHelper.showError(
          cleanCtx != null 
              ? 'Erreur lors de $cleanCtx (code $statusCode).'
              : 'Erreur lors de la requête (code $statusCode).',
        );
      }
    } else {
      exception = ApiException(
        message: 'Erreur HTTP inattendue: $statusCode',
        type: ApiErrorType.unknown,
        statusCode: statusCode,
      );
 
      if (showNotification) {
        NotificationHelper.showError(
          'Erreur inattendue du serveur.',
        );
      }
    }
 
    return exception;
  }

  /// Wrapper pratique pour exécuter un appel API avec gestion d'erreur automatique.
  ///
  /// Exemple :
  /// ```dart
  /// final result = await ApiExceptionHandler.execute(
  ///   () => http.get(uri).timeout(timeout),
  ///   context: 'la récupération des écoles',
  /// );
  /// ```
  static Future<T?> execute<T>(
    Future<T> Function() apiCall, {
    String? context,
    bool showNotification = true,
    T? defaultValue,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      handle(e, context: context, showNotification: showNotification);
      return defaultValue;
    }
  }
}
