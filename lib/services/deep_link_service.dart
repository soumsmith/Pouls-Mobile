import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Types de contenu supportés par le deep linking
enum DeepLinkContentType {
  coulisse,
  visite,
  article,
  tip,
  event,
  product,
  unknown,
}

/// Données extraites d'un deep link
class DeepLinkData {
  final DeepLinkContentType type;
  final String id;
  final Uri originalUri;

  const DeepLinkData({
    required this.type,
    required this.id,
    required this.originalUri,
  });

  @override
  String toString() => 'DeepLinkData(type: $type, id: $id, uri: $originalUri)';
}

/// Service singleton pour gérer les deep links (Universal Links iOS + App Links Android).
///
/// Écoute les liens entrants via le package `app_links` et les convertit en
/// [DeepLinkData] exploitables par la couche navigation.
///
/// Architecture :
/// - Cold start : lien initial récupéré via [getInitialLink]
/// - Warm start : liens reçus en continu via [onLinkReceived]
class DeepLinkService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // ─── Configuration ────────────────────────────────────────────────────────
  /// Domaine(s) autorisé(s) pour les deep links
  static List<String> get _allowedHosts {
    try {
      final uri = Uri.parse(AppConfig.VIE_ECOLES_API_BASE_URL);
      return [uri.host, 'pouls-scolaire.net', 'www.pouls-scolaire.net'];
    } catch (e) {
      return ['pouls-scolaire.net', 'www.pouls-scolaire.net'];
    }
  }

  /// Préfixe de chemin pour les partages : /deep-link-hosting/share
  static const String _sharePathPrefix = '/deep-link-hosting/share';

  /// Ancien préfixe conservé pour la rétrocompatibilité
  static const String _videoPathPrefix = '/deep-link-hosting/video';

  // ─── État interne ─────────────────────────────────────────────────────────
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<DeepLinkData> _deepLinkController =
      StreamController<DeepLinkData>.broadcast();
  bool _isInitialized = false;

  /// Stream de deep links reçus (cold start + warm start)
  Stream<DeepLinkData> get onLinkReceived => _deepLinkController.stream;

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Initialise le service. À appeler une seule fois dans `main()`.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _appLinks = AppLinks();

    // 1. Vérifier s'il y a un lien initial (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 Deep Link (cold start): $initialUri');
        _handleUri(initialUri);
      }
    } catch (e) {
      print('⚠️ Erreur récupération lien initial: $e');
    }

    // 2. Écouter les liens entrants (warm start)
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          print('🔗 Deep Link (warm start): $uri');
          _handleUri(uri);
        },
        onError: (error) {
          print('⚠️ Erreur stream deep link: $error');
        },
      );
    } catch (e) {
      print('⚠️ Erreur initialisation stream deep link (hot reload ?): $e');
    }
  }

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Parse une URI et émet un [DeepLinkData] si elle correspond à un lien valide.
  void _handleUri(Uri uri) {
    // Vérifier que le domaine est autorisé
    if (!_allowedHosts.contains(uri.host.toLowerCase())) {
      print('⚠️ Deep Link ignoré (domaine non autorisé): ${uri.host}');
      return;
    }

    final deepLinkData = parseUri(uri);
    if (deepLinkData != null) {
      print('✅ Deep Link parsé: $deepLinkData');
      _deepLinkController.add(deepLinkData);
    } else {
      print('⚠️ Deep Link non reconnu: $uri');
    }
  }

  /// Parse une URI en [DeepLinkData]. Retourne null si le format est invalide.
  ///
  /// Format attendu : https://pouls-scolaire.net/video/{type}/{id}
  /// Exemples :
  ///   - https://pouls-scolaire.net/video/coulisse/123
  ///   - https://pouls-scolaire.net/video/visite/456
  static DeepLinkData? parseUri(Uri uri) {
    // Vérifier que le chemin contient 'share' ou 'video'
    if (!uri.path.contains('share') && !uri.path.contains('video')) return null;

    String? typeStr;
    String? id;

    // Nouvelle approche : via les query parameters (ex: index.html?type=visite&id=92)
    if (uri.queryParameters.containsKey('type') &&
        uri.queryParameters.containsKey('id')) {
      typeStr = uri.queryParameters['type']!.toLowerCase();
      id = uri.queryParameters['id'];
    }
    // Ancienne approche pour la rétrocompatibilité : via le chemin
    else {
      final segments = uri.pathSegments;
      if (segments.length >= 3) {
        // Chercher l'index du segment 'share' ou 'video'
        int prefixIndex = segments.indexOf('share');
        if (prefixIndex == -1) prefixIndex = segments.indexOf('video');

        if (prefixIndex != -1 && prefixIndex + 2 < segments.length) {
          typeStr = segments[prefixIndex + 1].toLowerCase();
          id = segments[prefixIndex + 2];
        }
      }
    }

    if (typeStr == null || id == null || id.isEmpty) return null;

    DeepLinkContentType type;
    switch (typeStr) {
      case 'coulisse':
        type = DeepLinkContentType.coulisse;
        break;
      case 'visite':
        type = DeepLinkContentType.visite;
        break;
      case 'article':
        type = DeepLinkContentType.article;
        break;
      case 'tip':
        type = DeepLinkContentType.tip;
        break;
      case 'event':
        type = DeepLinkContentType.event;
        break;
      case 'product':
        type = DeepLinkContentType.product;
        break;
      default:
        type = DeepLinkContentType.unknown;
    }

    return DeepLinkData(type: type, id: id, originalUri: uri);
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  /// Gère la navigation vers l'écran approprié en fonction du deep link.
  /// Utilise le [navigatorKey] global pour naviguer sans contexte.
  void handleDeepLinkNavigation(
    DeepLinkData data,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('⚠️ Navigator non disponible pour deep link: $data');
      return;
    }

    switch (data.type) {
      case DeepLinkContentType.coulisse:
      case DeepLinkContentType.visite:
      case DeepLinkContentType.article:
      case DeepLinkContentType.tip:
      case DeepLinkContentType.event:
      case DeepLinkContentType.product:
        // Import dynamique non possible en Dart, on utilise un callback
        // La navigation est gérée dans main.dart via le stream
        break;
      case DeepLinkContentType.unknown:
        print('⚠️ Type de contenu inconnu: ${data.originalUri}');
        break;
    }
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  /// Libère les ressources. Appelé quand l'application est détruite.
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
