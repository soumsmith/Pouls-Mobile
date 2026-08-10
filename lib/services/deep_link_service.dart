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

  /// Code de l'école propriétaire du contenu (optionnel, absent sur les
  /// anciens liens déjà partagés). Permet de résoudre le contenu via les
  /// mêmes appels API scopés par école que la navigation classique, au lieu
  /// de parcourir tout le catalogue toutes écoles confondues.
  final String? ecole;

  const DeepLinkData({
    required this.type,
    required this.id,
    required this.originalUri,
    this.ecole,
  });

  @override
  String toString() =>
      'DeepLinkData(type: $type, id: $id, ecole: $ecole, uri: $originalUri)';
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

  /// Lien de démarrage à froid capturé par [init], en attente d'être traité
  /// via [consumePendingInitialLink] une fois qu'un auditeur est réellement
  /// attaché à [onLinkReceived]. Nécessaire car [init] s'exécute dans
  /// `main()` AVANT `runApp()` : si on émettait ce lien immédiatement sur ce
  /// StreamController broadcast, il n'y aurait encore aucun auditeur (l'écran
  /// racine ne s'abonne qu'à son `initState`) et l'événement serait perdu
  /// silencieusement — un broadcast stream ne rejoue jamais les événements
  /// passés pour les auditeurs qui arrivent après coup.
  Uri? _pendingInitialUri;

  /// Stream de deep links reçus (cold start + warm start)
  Stream<DeepLinkData> get onLinkReceived => _deepLinkController.stream;

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Initialise le service. À appeler une seule fois dans `main()`.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _appLinks = AppLinks();

    // 1. Vérifier s'il y a un lien initial (cold start) — on le mémorise
    //    seulement, il sera traité via consumePendingInitialLink() une fois
    //    qu'un auditeur sera attaché (voir MyApp._listenDeepLinks).
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('🔗 [DeepLink] URI de démarrage à froid capturée: $initialUri');
        _pendingInitialUri = initialUri;
      } else {
        print('🔗 [DeepLink] Pas de lien de démarrage à froid.');
      }
    } catch (e) {
      print('⚠️ [DeepLink] Erreur récupération lien initial: $e');
    }

    // 2. Écouter les liens entrants (warm start)
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          print('🔗 [DeepLink] URI reçue (warm start): $uri');
          _handleUri(uri);
        },
        onError: (error) {
          print('⚠️ [DeepLink] Erreur stream deep link: $error');
        },
      );
      print('✅ [DeepLink] Abonnement au stream app_links effectué.');
    } catch (e) {
      print('⚠️ [DeepLink] Erreur initialisation stream (hot reload ?): $e');
    }
  }

  /// À appeler juste après s'être abonné à [onLinkReceived] (typiquement
  /// dans `initState` de l'écran racine), pour traiter le lien de démarrage
  /// à froid éventuellement capturé par [init] sans le perdre.
  void consumePendingInitialLink() {
    final uri = _pendingInitialUri;
    if (uri == null) {
      print('🔗 [DeepLink] Aucun lien initial en attente à traiter.');
      return;
    }
    _pendingInitialUri = null;
    print('🔗 [DeepLink] Traitement du lien de démarrage à froid en attente: $uri');
    _handleUri(uri);
  }

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Parse une URI et émet un [DeepLinkData] si elle correspond à un lien valide.
  void _handleUri(Uri uri) {
    print('🔎 [DeepLink] _handleUri: $uri');
    print('🔎 [DeepLink]   host=${uri.host} path=${uri.path} query=${uri.query}');

    // Vérifier que le domaine est autorisé
    if (!_allowedHosts.contains(uri.host.toLowerCase())) {
      print(
        '⚠️ [DeepLink] Ignoré (domaine "${uri.host}" non autorisé, '
        'attendus: $_allowedHosts)',
      );
      return;
    }

    final deepLinkData = parseUri(uri);
    if (deepLinkData != null) {
      print('✅ [DeepLink] Parsé avec succès: $deepLinkData');
      print(
        '✅ [DeepLink]   auditeurs actuellement abonnés à onLinkReceived: '
        '${_deepLinkController.hasListener}',
      );
      _deepLinkController.add(deepLinkData);
    } else {
      print('⚠️ [DeepLink] Format non reconnu, aucune donnée extraite: $uri');
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
    final String? ecole = uri.queryParameters['ecole'];

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

    print(
      '🔎 [DeepLink] parseUri → typeStr=$typeStr id=$id ecole=$ecole',
    );

    if (typeStr == null || id == null || id.isEmpty) {
      print('⚠️ [DeepLink] parseUri: type ou id manquant/vide, lien invalide.');
      return null;
    }

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

    return DeepLinkData(type: type, id: id, originalUri: uri, ecole: ecole);
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
