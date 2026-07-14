import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/app_module.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

/// Service singleton pour gérer l'accès aux modules (gratuit/payant)
///
/// Appelle l'API /espace-parent/subscriptions/{userId} au démarrage
/// et persiste les données dans SQLite pour empêcher le contournement
/// des permissions hors ligne.
///
/// Stratégie de sécurité :
/// - Au démarrage → charger depuis le cache SQLite (instantané)
/// - Ensuite → tenter de rafraîchir depuis l'API
/// - Si API OK → mettre à jour mémoire + cache SQLite
/// - Si API KO → garder les données du cache (PAS de reset)
/// - À la reconnexion réseau → rafraîchir automatiquement
/// - Au logout → vider le cache
class ModuleAccessService {
  static final ModuleAccessService _instance = ModuleAccessService._internal();
  factory ModuleAccessService() => _instance;
  ModuleAccessService._internal();

  /// Liste de tous les modules retournés par l'API
  List<AppModule> _modules = [];

  /// Liste des identifiants de modules accessibles (payants débloqués)
  List<String> _accessibleModuleIds = [];

  /// Indique si les données ont été chargées (depuis cache OU API)
  bool _isLoaded = false;

  /// Indique si un chargement est en cours
  bool _isLoading = false;

  /// Indique si le cache local a été chargé au moins une fois
  bool _cacheLoaded = false;

  /// Stream controller pour notifier les widgets des changements
  final StreamController<void> _changeController = StreamController<void>.broadcast();

  /// Stream pour écouter les changements d'accès
  Stream<void> get onAccessChanged => _changeController.stream;

  /// Indique si les données sont chargées
  bool get isLoaded => _isLoaded;

  /// Liste des modules
  List<AppModule> get modules => List.unmodifiable(_modules);

  /// Callback de reconnexion pour ConnectivityService
  void Function()? _reconnectCallback;

  /// Charger les modules depuis l'API avec fallback sur le cache SQLite
  ///
  /// Flux :
  /// 1. Charger depuis le cache SQLite (instantané, pas d'attente réseau)
  /// 2. Tenter de récupérer les données fraîches depuis l'API
  /// 3. Si API OK → mettre à jour mémoire + cache SQLite
  /// 4. Si API KO → garder les données du cache (pas de reset)
  Future<void> fetchModules() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final user = AuthService.instance.getCurrentUser();
      final userId = user?.id ?? '19421';

      // ══════════════════════════════════════════════════════
      // ÉTAPE 1 : Charger depuis le cache SQLite (instantané)
      // ══════════════════════════════════════════════════════
      if (!_cacheLoaded) {
        await _loadFromCache(userId);
      }

      // ══════════════════════════════════════════════════════
      // ÉTAPE 2 : Tenter de récupérer les données fraîches depuis l'API
      // ══════════════════════════════════════════════════════
      final url = Uri.parse(
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/espace-parent/subscriptions/$userId',
      );

      print('═══════════════════════════════════════════════════════════');
      print('🔐 MODULE ACCESS SERVICE — Chargement des modules');
      print('🔗 URL: $url');
      print('═══════════════════════════════════════════════════════════');

      final response = await http.get(url);

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📦 Réponse Subscriptions API: ${response.body}');
        final data = json.decode(response.body);

        // Parser les modules
        final List<dynamic> modulesJson = data['modules'] ?? [];
        _modules = modulesJson
            .map((m) => AppModule.fromJson(m as Map<String, dynamic>))
            .toList();

        // Parser les modules accessibles
        final List<dynamic> accessibleJson = data['accessible_modules'] ?? [];
        _accessibleModuleIds = accessibleJson
            .map((e) => e.toString())
            .toList();

        _isLoaded = true;

        print('✅ ${_modules.length} modules chargés depuis l\'API');
        print('🔓 ${_accessibleModuleIds.length} modules accessibles');
        print('📋 Modules gratuits: ${_modules.where((m) => m.isGratuit).map((m) => m.identifiant).toList()}');
        print('🔒 Modules payants: ${_modules.where((m) => m.isPayant).map((m) => m.identifiant).toList()}');
        print('🔓 Accessible modules IDs: $_accessibleModuleIds');

        // ══════════════════════════════════════════════════════
        // ÉTAPE 3 : Sauvegarder dans le cache SQLite
        // ══════════════════════════════════════════════════════
        await DatabaseService.instance.saveModuleAccessCache(
          userId,
          _modules,
          _accessibleModuleIds,
        );

        // Notifier les widgets
        _changeController.add(null);
      } else {
        print('❌ Erreur API modules: ${response.statusCode}');
        // En cas d'erreur API → on GARDE les données du cache (pas de reset)
        // Si pas de cache non plus → fail-open (première utilisation)
        if (!_isLoaded) {
          _isLoaded = false; // Reste à false, isModuleAccessible retournera true
        }
        _changeController.add(null);
      }

      // Enregistrer le callback de reconnexion (une seule fois)
      _registerReconnectCallback();

    } catch (e) {
      print('❌ Erreur lors du chargement des modules: $e');
      // En cas d'erreur réseau → on GARDE les données du cache (pas de reset)
      // C'est ici la correction de la faille : avant, on remettait tout à vide
      if (!_isLoaded) {
        _isLoaded = false; // Reste à false, isModuleAccessible retournera true
      }
      _changeController.add(null);
    } finally {
      _isLoading = false;
    }
  }

  /// Charge les données depuis le cache SQLite local
  ///
  /// Cette méthode est appelée une seule fois au démarrage, avant la requête API.
  /// Elle permet d'avoir les données disponibles immédiatement, sans attendre le réseau.
  Future<void> _loadFromCache(String userId) async {
    try {
      final hasCache = await DatabaseService.instance.hasModuleAccessCache(userId);

      if (hasCache) {
        _modules = await DatabaseService.instance.getModuleAccessCache(userId);
        _accessibleModuleIds = await DatabaseService.instance.getAccessibleModulesCache(userId);
        _isLoaded = true;
        _cacheLoaded = true;

        print('═══════════════════════════════════════════════════════════');
        print('🔐 MODULE ACCESS SERVICE — Cache SQLite chargé');
        print('✅ ${_modules.length} modules depuis le cache');
        print('🔓 ${_accessibleModuleIds.length} modules accessibles depuis le cache');
        print('═══════════════════════════════════════════════════════════');

        // Notifier les widgets immédiatement avec les données du cache
        _changeController.add(null);
      } else {
        print('ℹ️ Aucun cache de modules trouvé pour l\'utilisateur $userId (première utilisation)');
        _cacheLoaded = true; // Marquer comme vérifié même si vide
      }
    } catch (e) {
      print('⚠️ Erreur lors du chargement du cache modules: $e');
      _cacheLoaded = true; // Ne pas réessayer en boucle
    }
  }

  /// Enregistre le callback de reconnexion auprès du ConnectivityService
  /// pour rafraîchir automatiquement les modules quand le réseau revient
  void _registerReconnectCallback() {
    if (_reconnectCallback != null) return; // Déjà enregistré

    _reconnectCallback = () {
      print('🌐 Connexion rétablie → Rafraîchissement des modules d\'accès');
      refresh();
    };

    ConnectivityService().onReconnect(_reconnectCallback!);
  }

  /// Vérifie si un module est accessible
  ///
  /// Retourne `true` si :
  /// - Les données ne sont pas encore chargées ET pas de cache (fail-open, première utilisation uniquement)
  /// - Le module est de type "gratuit"
  /// - Le module est "payant" mais présent dans accessible_modules
  /// - L'identifiant n'existe pas dans la liste des modules (module inconnu → accessible)
  ///
  /// Retourne `false` si :
  /// - Le module est "payant" et NON présent dans accessible_modules
  ///   (que les données viennent de l'API ou du cache SQLite)
  bool isModuleAccessible(String identifiant) {
    // Si pas encore chargé (ni API ni cache), on autorise tout (fail-open première utilisation uniquement)
    if (!_isLoaded || _modules.isEmpty) return true;

    // Chercher le module par identifiant
    final module = _modules.where((m) => m.identifiant == identifiant).firstOrNull;

    // Si le module n'existe pas dans la liste, c'est accessible
    if (module == null) return true;

    // Si gratuit → accessible
    if (module.isGratuit) return true;

    // Si payant → vérifier s'il est dans accessible_modules
    if (module.isPayant) {
      return _accessibleModuleIds.contains(identifiant);
    }

    return true;
  }

  /// Recharger les modules (utile après un achat d'abonnement)
  /// Force une requête API et met à jour le cache SQLite
  Future<void> refresh() async {
    _isLoaded = false;
    _cacheLoaded = true; // Ne pas recharger le cache, on veut des données fraîches
    await fetchModules();
  }

  /// Vider le cache en mémoire et en SQLite (appelé au logout)
  ///
  /// Empêche un utilisateur différent de bénéficier du cache d'un autre.
  Future<void> clearCache() async {
    final user = AuthService.instance.getCurrentUser();
    final userId = user?.id;

    // Vider la mémoire
    _modules = [];
    _accessibleModuleIds = [];
    _isLoaded = false;
    _cacheLoaded = false;

    // Vider le cache SQLite
    if (userId != null) {
      await DatabaseService.instance.clearModuleAccessCache(userId);
    }

    // Supprimer le callback de reconnexion
    if (_reconnectCallback != null) {
      ConnectivityService().removeReconnectCallback(_reconnectCallback!);
      _reconnectCallback = null;
    }

    print('🔐 ModuleAccessService — Cache vidé (logout)');
    _changeController.add(null);
  }

  /// Libérer les ressources
  void dispose() {
    if (_reconnectCallback != null) {
      ConnectivityService().removeReconnectCallback(_reconnectCallback!);
      _reconnectCallback = null;
    }
    _changeController.close();
  }
}
