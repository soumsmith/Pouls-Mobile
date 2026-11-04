import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http_pkg;
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/code_dren_ecole.dart';
import 'auth_service.dart';
import 'country_service.dart';

/// Service centralisé de journalisation pour l'ensemble de l'application.
/// Enregistre les appels API, les actions de boutons, les ajouts d'enfants
/// et la navigation vers le script PHP distant.
class AppLogService {
  static final AppLogService instance = AppLogService._internal();
  factory AppLogService() => instance;
  AppLogService._internal();

  /// URLs à ne JAMAIS intercepter/logger pour éviter les boucles infinies ou le spam
  static final List<String> _ignoredUrlKeywords = [
    'log_child_add.php',
    'log_action.php',
    'ipwho.is',
    'api.country.is',
    'ipapi.co',
  ];

  /// Enregistre un appel API (utilisé automatiquement par `app_http.dart`).
  static void logApi({
    required String method,
    required String url,
    int? statusCode,
    int? durationMs,
    String? error,
    dynamic requestBody,
  }) {
    // Éviter de logger les requêtes vers le serveur de logs ou la détection d'IP
    for (final keyword in _ignoredUrlKeywords) {
      if (url.contains(keyword)) return;
    }

    final status = (statusCode != null && statusCode >= 200 && statusCode < 300)
        ? 'success'
        : (statusCode != null && statusCode >= 400 ? 'error' : 'info');

    _send(
      category: 'api',
      event: 'api_call',
      status: status,
      data: {
        'method': method.toUpperCase(),
        'url': url,
        if (statusCode != null) 'status_code': statusCode,
        if (durationMs != null) 'duration_ms': durationMs,
        if (error != null) 'error': error,
      },
    );
  }

  /// Enregistre un clic sur un bouton ou une action utilisateur clé.
  static void logButton({
    required String buttonName,
    required String screen,
    Map<String, dynamic>? details,
    String status = 'click',
  }) {
    _send(
      category: 'button',
      event: 'button_action',
      status: status,
      data: {
        'button_name': buttonName,
        'screen': screen,
        if (details != null) 'details': details,
      },
    );
  }

  /// Enregistre la visite ou le changement d'écran.
  static void logNavigation({
    required String screenName,
    String? previousScreen,
  }) {
    _send(
      category: 'screen',
      event: 'screen_view',
      status: 'view',
      data: {
        'screen_name': screenName,
        if (previousScreen != null) 'previous_screen': previousScreen,
      },
    );
  }

  /// Enregistre une action générique avec des données personnalisées.
  static void logAction({
    required String action,
    String category = 'action',
    String status = 'info',
    Map<String, dynamic>? details,
    String? errorMessage,
  }) {
    _send(
      category: category,
      event: action,
      status: status,
      data: {
        'action': action,
        if (details != null) 'details': details,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  /// Journalisation d'un ajout d'enfant réussi (rétrocompatibilité).
  static void logChildAdded({
    required User currentUser,
    required String matricule,
    required String nom,
    required String prenoms,
    required String grade,
    required CodeDrenEcole ecole,
    String? resolvedSchoolId,
  }) {
    _send(
      category: 'child_action',
      event: 'child_added',
      status: 'success',
      explicitUser: currentUser,
      data: {
        'child': {
          'matricule': matricule,
          'nom': nom,
          'prenoms': prenoms,
          'classe': grade,
          'school_name': ecole.nom,
          'school_code': ecole.code,
          'school_id': resolvedSchoolId,
        },
      },
    );
  }

  /// Journalisation d'un échec ou doublon d'ajout d'enfant (rétrocompatibilité).
  static void logChildAddFailed({
    required User currentUser,
    required String matricule,
    String? nom,
    String? prenoms,
    String? grade,
    required CodeDrenEcole ecole,
    required String errorMessage,
    String status = 'error',
  }) {
    _send(
      category: 'child_action',
      event: 'child_add_failed',
      status: status,
      explicitUser: currentUser,
      data: {
        'child': {
          'matricule': matricule,
          'nom': nom ?? '',
          'prenoms': prenoms ?? '',
          'classe': grade ?? '',
          'school_name': ecole.nom,
          'school_code': ecole.code,
        },
        'error_message': errorMessage,
      },
    );
  }

  // ─── MOTEUR D'ENVOI EN ARRIÈRE-PLAN (FIRE-AND-FORGET) ────────────────────────
  static void _send({
    required String category,
    required String event,
    required String status,
    required Map<String, dynamic> data,
    User? explicitUser,
  }) {
    // Exécution asynchrone sans bloquer l'interface
    unawaited(_executeSend(
      category: category,
      event: event,
      status: status,
      data: data,
      explicitUser: explicitUser,
    ));
  }

  static Future<void> _executeSend({
    required String category,
    required String event,
    required String status,
    required Map<String, dynamic> data,
    User? explicitUser,
  }) async {
    final url = AppConfig.APP_LOG_URL;
    if (url.trim().isEmpty) return;

    try {
      // 1. Récupération de l'utilisateur connecté
      final user = explicitUser ?? AuthService.instance.getCurrentUser();
      final Map<String, dynamic> userMap = user != null
          ? {
              'id': user.id,
              'name': '${user.firstName} ${user.lastName}'.trim(),
              'phone': user.phone,
              'email': user.email,
              'role': user.role,
              'user_level': user.userLevel,
            }
          : {
              'id': null,
              'name': 'Invité',
              'phone': null,
              'email': null,
              'role': 'guest',
            };

      // 2. Récupération du pays détecté
      final countryService = CountryService.instance;
      final countryCode = countryService.detectedCountryCode;
      final countryName = countryService.detectedCountryName;
      final countryFlag = countryService.detectedCountryFlag;

      // 3. Plateforme
      final platform = kIsWeb
          ? 'Web'
          : (Platform.isAndroid
              ? 'Android'
              : (Platform.isIOS ? 'iOS' : Platform.operatingSystem));

      // 4. Construction de la charge utile complète
      final payload = {
        'category': category,
        'event': event,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'user': userMap,
        'parent': userMap, // Rétrocompatibilité avec les anciens scripts
        'context': {
          'country_code': countryCode,
          'country_name': countryName,
          'country_flag': countryFlag,
          'platform': platform,
          'app_name': 'Pouls Scolaire Parent',
        },
        ...data,
      };

      // 5. Envoi direct via http_pkg sans passer par notre interceptor
      await http_pkg
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      // Les logs ne doivent jamais interrompre le flux principal de l'utilisateur
      debugPrint('⚠️ [AppLogService] Envoi du log ignoré ($e)');
    }
  }
}

/// Observateur de navigation pour enregistrer automatiquement chaque changement d'écran.
class AppLogRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route, previousRoute, 'push');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRoute(newRoute, oldRoute, 'replace');
    }
  }

  void _logRoute(Route<dynamic> route, Route<dynamic>? previousRoute, String type) {
    final routeName = route.settings.name ?? route.runtimeType.toString();
    // Ignorer les dialogues ou sous-routes internes sans intérêt
    if (routeName.contains('PopupRoute') || routeName == 'null') return;
    final prevName = previousRoute?.settings.name ?? previousRoute?.runtimeType.toString();

    AppLogService.logNavigation(
      screenName: routeName,
      previousScreen: prevName,
    );
  }
}

