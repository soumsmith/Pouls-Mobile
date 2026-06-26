import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/app_module.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Service singleton pour gérer l'accès aux modules (gratuit/payant)
///
/// Appelle l'API /espace-parent/subscriptions/{userId} au démarrage
/// et détermine si un module est accessible ou verrouillé.
class ModuleAccessService {
  static final ModuleAccessService _instance = ModuleAccessService._internal();
  factory ModuleAccessService() => _instance;
  ModuleAccessService._internal();

  /// Liste de tous les modules retournés par l'API
  List<AppModule> _modules = [];

  /// Liste des identifiants de modules accessibles (payants débloqués)
  List<String> _accessibleModuleIds = [];

  /// Indique si les données ont été chargées
  bool _isLoaded = false;

  /// Indique si un chargement est en cours
  bool _isLoading = false;

  /// Stream controller pour notifier les widgets des changements
  final StreamController<void> _changeController = StreamController<void>.broadcast();

  /// Stream pour écouter les changements d'accès
  Stream<void> get onAccessChanged => _changeController.stream;

  /// Indique si les données sont chargées
  bool get isLoaded => _isLoaded;

  /// Liste des modules
  List<AppModule> get modules => List.unmodifiable(_modules);

  /// Charger les modules depuis l'API
  Future<void> fetchModules() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final user = AuthService.instance.getCurrentUser();
      final userId = user?.id ?? '19421';

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

        print('✅ ${_modules.length} modules chargés');
        print('🔓 ${_accessibleModuleIds.length} modules accessibles');
        print('📋 Modules gratuits: ${_modules.where((m) => m.isGratuit).map((m) => m.identifiant).toList()}');
        print('🔒 Modules payants: ${_modules.where((m) => m.isPayant).map((m) => m.identifiant).toList()}');
        print('🔓 Accessible modules IDs: $_accessibleModuleIds');

        // Notifier les widgets
        _changeController.add(null);
      } else {
        print('❌ Erreur API modules: ${response.statusCode}');
        // En cas d'erreur, on considère tout comme accessible (fail-open)
        _isLoaded = true;
        _modules = [];
        _accessibleModuleIds = [];
        _changeController.add(null);
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des modules: $e');
      // En cas d'erreur réseau, on considère tout comme accessible (fail-open)
      _isLoaded = true;
      _modules = [];
      _accessibleModuleIds = [];
      _changeController.add(null);
    } finally {
      _isLoading = false;
    }
  }

  /// Vérifie si un module est accessible
  ///
  /// Retourne `true` si :
  /// - Les données ne sont pas encore chargées (fail-open)
  /// - Le module est de type "gratuit"
  /// - Le module est "payant" mais présent dans accessible_modules
  /// - L'identifiant n'existe pas dans la liste des modules (module inconnu → accessible)
  bool isModuleAccessible(String identifiant) {
    // Si pas encore chargé, on autorise tout (fail-open)
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
  Future<void> refresh() async {
    _isLoaded = false;
    await fetchModules();
  }

  /// Libérer les ressources
  void dispose() {
    _changeController.close();
  }
}
