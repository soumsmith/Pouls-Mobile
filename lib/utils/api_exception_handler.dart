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
    final ApiException apiException;

    if (error is TimeoutException) {
      apiException = ApiException(
        message: context != null
            ? 'Délai dépassé lors de $context'
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
        message: context != null
            ? 'Pas de connexion lors de $context'
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
          message: context != null
              ? 'Connexion impossible lors de $context'
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
          message: context != null
              ? 'Erreur réseau lors de $context'
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
        message: context != null
            ? 'Réponse invalide lors de $context'
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
          message: context != null
              ? 'Délai dépassé lors de $context'
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
          message: context != null
              ? 'Pas de connexion lors de $context'
              : 'Problème de connexion',
          type: ApiErrorType.noConnection,
          originalError: error,
        );

        if (showNotification) {
          NotificationHelper.showNoConnection();
        }
      } else {
        apiException = ApiException(
          message: context != null
              ? 'Erreur lors de $context'
              : 'Une erreur est survenue',
          type: ApiErrorType.unknown,
          originalError: error,
        );

        if (showNotification) {
          NotificationHelper.showError(
            context != null
                ? 'Erreur lors de $context. Veuillez réessayer.'
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
    if (context != null) print('⚠️ Context: $context');
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

    final ApiException exception;

    if (statusCode >= 500) {
      exception = ApiException(
        message: context != null
            ? 'Erreur serveur lors de $context'
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
        message: context != null
            ? 'Délai dépassé lors de $context'
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
        message: context != null
            ? 'Erreur lors de $context (code $statusCode)'
            : 'Erreur client (code $statusCode)',
        type: ApiErrorType.clientError,
        statusCode: statusCode,
      );

      if (showNotification && statusCode != 404) {
        // On ne notifie pas les 404 (souvent attendus)
        NotificationHelper.showError(
          'Erreur lors de la requête (code $statusCode).',
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
