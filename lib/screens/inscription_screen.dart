import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../models/child.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/selectable_item_card.dart';
import '../widgets/search_bar_widget.dart';
import '../services/ecole_eleve_service.dart';
import '../services/inscription_api_service.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/bottom_sheets/payment_choice_bottom_sheet.dart';
import '../widgets/snackbar.dart';
import '../widgets/components/custom_button.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../config/app_dimensions.dart';

// ─── CONSTANTES ───────────────────────────────────────────────────────────────

// ─── IDENTIFIANTS D'ÉTAPE ────────────────────────────────────────────────────
//
// On identifie chaque étape par une chaîne stable plutôt que par un index
// entier. Ainsi, ajouter ou retirer l'étape "zones" ne décale jamais les
// autres.  Le PageView est reconstruit depuis _orderedStepIds à chaque build.

const String _kStepScolarite = 'scolarite';
const String _kStepReservation = 'reservation';
const String _kStepServices = 'services';
const String _kStepZones = 'zones';
const String _kStepEcheancier = 'echeancier';
const String _kStepRecap = 'recap';

// ─── ÉCRAN WIZARD ─────────────────────────────────────────────────────────────

class InscriptionWizardScreen extends StatefulWidget {
  final Child child;
  final String? uid;
  final Map<String, dynamic>? eleveDetail; // ← AJOUTER

  const InscriptionWizardScreen({
    Key? key,
    required this.child,
    this.uid,
    this.eleveDetail, // ← AJOUTER
  }) : super(key: key);

  @override
  _InscriptionWizardScreenState createState() =>
      _InscriptionWizardScreenState();
}

class _InscriptionWizardScreenState extends State<InscriptionWizardScreen>
    with TickerProviderStateMixin {
  // ── Thème adaptatif ────────────────────────────────────────────────────────
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get screenBgColor =>
      isDark ? const Color(0xFF000000) : AppColors.pureWhite;
  Color get cardColor =>
      isDark ? const Color(0xFF000000) : AppColors.screenCard;
  Color get textColor => isDark ? Colors.white : AppColors.screenTextPrimary;
  Color get textSecondaryColor =>
      isDark ? Colors.white70 : AppColors.screenTextSecondary;
  Color get dividerColor =>
      isDark ? const Color(0xFF222222) : AppColors.screenDivider;

  // ── État du wizard ──────────────────────────────────────────────────────────
  int _currentPageIndex = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _mainScrollController = ScrollController();
  final Map<String, ScrollController> _stepControllers = {};

  ScrollController _getControllerForStep(String stepId) {
    if (!_stepControllers.containsKey(stepId)) {
      _stepControllers[stepId] = ScrollController();
    }
    return _stepControllers[stepId]!;
  }

  ScrollController get _currentScrollController {
    if (_orderedStepIds.isEmpty) return _mainScrollController;
    final currentStepId = _orderedStepIds[_currentPageIndex];
    return _getControllerForStep(currentStepId);
  }

  // ── Paramètres de l'école ───────────────────────────────────────────────────
  bool _servicesEnabled = true;
  bool _periodsClosed = false;

  // ── Données de chaque étape ─────────────────────────────────────────────────
  List<EcheanceScolarite> _echeancesScolarite = [];
  bool _loadingScolarite = false;

  ReservationStatus? _reservation;
  bool _loadingReservation = false;

  List<Service> _services = [];
  bool _loadingServices = false;

  List<EcheanceService> _echeancesService = [];
  bool _loadingEcheancesService = false;

  List<ZoneTransport> _zones = [];
  bool _loadingZones = false;
  ZoneTransport? _selectedZone;

  // ── Contrôleurs de recherche ────────────────────────────────────────────────
  final TextEditingController _serviceSearchController =
      TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();

  bool _isServiceSearching = false;
  bool _isZoneSearching = false;

  // ── Accesseurs utilitaires ──────────────────────────────────────────────────
  String get _matricule => widget.child.matricule ?? '';
  String get _ecoleCode {
    // Priorité 0 : depuis le paramEcole du Child (stocké localement)
    final fromParamEcole = widget.child.paramEcole ?? '';
    if (fromParamEcole.isNotEmpty) {
      print('_ecoleCode: depuis widget.child.paramEcole = "$fromParamEcole"');
      return fromParamEcole;
    }

    final fromEleveDetail =
        widget.eleveDetail?['ecole']?.toString() ??
        widget.eleveDetail?['ecole_code']?.toString() ??
        '';
    if (fromEleveDetail.isNotEmpty) {
      print('_ecoleCode: depuis eleveDetail = "$fromEleveDetail"');
      return fromEleveDetail;
    }

    // Priorité 2 : depuis _eleveDetailData chargé localement
    final fromLocalData =
        _eleveDetailData?['ecole']?.toString() ??
        _eleveDetailData?['ecole_code']?.toString() ??
        '';
    if (fromLocalData.isNotEmpty) {
      print('_ecoleCode: depuis _eleveDetailData = "$fromLocalData"');
      return fromLocalData;
    }

    // Priorité 3 : depuis le Child (peut être une valeur factice)
    final fromChild = widget.child.ecoleCode ?? '';
    print('_ecoleCode: depuis widget.child = "$fromChild"');
    return fromChild;
  }

  String get _uid_eleve {
    print('Recherche de l\'UID élève...');
    print('   - widget.uid: ${widget.uid ?? 'null'}');
    print('   - widget.eleveDetail disponible: ${widget.eleveDetail != null}');
    print('   - _eleveDetailData disponible: ${_eleveDetailData != null}');
    print('   - _ecoleCode: "$_ecoleCode"');

    // Priorité 1: UID passé directement en paramètre
    if (widget.uid != null && widget.uid!.isNotEmpty) {
      print('✅ UID trouvé dans widget.uid: ${widget.uid}');
      return widget.uid!;
    }

    // Priorité 2: UID depuis les détails de l'élève
    if (widget.eleveDetail != null && widget.eleveDetail!['uid'] != null) {
      print(
        '✅ UID trouvé dans widget.eleveDetail["uid"]: ${widget.eleveDetail!['uid']}',
      );
      return widget.eleveDetail!['uid'].toString();
    }

    // Priorité 3: UID depuis les données locales
    if (_eleveDetailData != null && _eleveDetailData!['uid'] != null) {
      print(
        '✅ UID trouvé dans _eleveDetailData["uid"]: ${_eleveDetailData!['uid']}',
      );
      return _eleveDetailData!['uid'].toString();
    }

    // Log détaillé des données disponibles pour debugging
    if (widget.eleveDetail != null) {
      print('📊 widget.eleveDetail contenu:');
      widget.eleveDetail!.forEach((key, value) {
        print('   - $key: $value (${value.runtimeType})');
      });

      // Priorité 4: Essayer depuis d'autres champs disponibles
      final idEleve = widget.eleveDetail!['id_eleve'];
      if (idEleve != null) {
        print(
          '⚠️ UID manquant, utilisation de id_eleve comme fallback: $idEleve',
        );
        return idEleve.toString();
      }
    }

    if (_eleveDetailData != null) {
      print('📊 _eleveDetailData contenu:');
      _eleveDetailData!.forEach((key, value) {
        print('   - $key: $value (${value.runtimeType})');
      });
    }

    print('❌ Aucun UID trouvé');
    return '';
  }

  bool _dejaInscrit = false;
  Map<String, dynamic>? _eleveDetailData; // reçu en paramètre

  // ── Gestion des erreurs critiques ─────────────────────────────────────────────
  bool _hasCriticalError = false;
  String? _criticalErrorMessage;

  // ── État de chargement initial ───────────────────────────────────────────────
  bool _isInitialLoading = true;
  bool _studentDataReady = false;

  // ─── LISTE DYNAMIQUE DES ÉTAPES ───────────────────────────────────────────
  //
  // C'est la seule source de vérité pour l'ordre et la présence des étapes.
  // Le PageView ET la barre de progression en sont dérivés automatiquement.

  List<String> get _orderedStepIds {
    final hasTransSelected = _services.any(
      (s) => s.service == 'TRANS' && s.selectionnee,
    );
    return [
      _kStepScolarite,
      if (_servicesEnabled) ...[
        _kStepServices,
        if (hasTransSelected) _kStepZones,
        _kStepEcheancier,
        _kStepReservation,
      ] else ...[
        _kStepReservation,
      ],
      _kStepRecap,
    ];
  }

  // Métadonnées d'affichage (label + icône) pour chaque identifiant d'étape.
  Map<String, dynamic> _stepMeta(String id) {
    switch (id) {
      case _kStepScolarite:
        return {'label': 'Scolarité', 'icon': Icons.school_rounded};
      case _kStepReservation:
        return {'label': 'Réservation', 'icon': Icons.bookmark_rounded};
      case _kStepServices:
        return {'label': 'Services', 'icon': Icons.grid_view_rounded};
      case _kStepZones:
        return {'label': 'Zones', 'icon': Icons.map_rounded};
      case _kStepEcheancier:
        return {'label': 'Échéancier', 'icon': Icons.payment_rounded};
      case _kStepRecap:
        return {'label': 'Récap', 'icon': Icons.receipt_long_rounded};
      default:
        return {'label': id, 'icon': Icons.circle_outlined};
    }
  }

  // Builder associé à chaque identifiant d'étape.
  Widget _buildStepById(String id) {
    switch (id) {
      case _kStepScolarite:
        return _buildStep1();
      case _kStepReservation:
        return _buildStep2();
      case _kStepServices:
        return _buildStep3();
      case _kStepZones:
        return _buildStep4();
      case _kStepEcheancier:
        return _buildStep5();
      case _kStepRecap:
        return _buildRecap();
      default:
        return const SizedBox.shrink();
    }
  }

  // Étape courante (identifiant).
  String get _currentStepId => _orderedStepIds[_currentPageIndex];

  // Listes filtrées ──────────────────────────────────────────────────────────
  List<Service> get _filteredServices {
    if (_serviceSearchController.text.isEmpty) return _services;
    return _services
        .where(
          (s) =>
              s.designation.toLowerCase().contains(
                _serviceSearchController.text.toLowerCase(),
              ) ||
              s.description.toLowerCase().contains(
                _serviceSearchController.text.toLowerCase(),
              ),
        )
        .toList();
  }

  List<ZoneTransport> get _filteredZones {
    if (_zoneSearchController.text.isEmpty) return _zones;
    return _zones
        .where(
          (z) => z.zone.toLowerCase().contains(
            _zoneSearchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  List<Service> get _cantineServices =>
      _filteredServices.where((s) => s.service == 'CANTINE').toList();
  List<Service> get _transportServices =>
      _filteredServices.where((s) => s.service == 'TRANS').toList();
  List<Service> get _otherServices => _filteredServices
      .where((s) => s.service != 'CANTINE' && s.service != 'TRANS')
      .toList();

  // ─── INIT ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    print('🎫 UID reçu dans InscriptionWizardScreen: ${widget.uid}');
    print('👤 Élève: ${widget.child.fullName}');
    print('📋 Matricule: ${widget.child.matricule}');
    print('🏷️ Code école: ${widget.child.ecoleCode}');
    print('🆔 UID qui sera utilisé dans les API: $_uid_eleve');

    // Initialiser les données de l'élève
    _eleveDetailData = widget.eleveDetail;

    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeStudentData();
      }
    });
  }

  /// Initialise les données de l'élève et attend qu'elles soient disponibles
  Future<void> _initializeStudentData() async {
    print('🔄 Initialisation des données de l\'élève...');
    print('   - widget.uid: ${widget.uid}');
    print('   - widget.eleveDetail disponible: ${widget.eleveDetail != null}');
    print('   - widget.child.ecoleCode: ${widget.child.ecoleCode}');
    print('   - widget.child.paramEcole: ${widget.child.paramEcole}');
    print('   - _ecoleCode: $_ecoleCode');
    print('   - _uid_eleve: $_uid_eleve');

    // Initialiser les données locales
    _eleveDetailData = widget.eleveDetail;

    // Si les données sont déjà disponibles, on passe directement
    if (_uid_eleve.isNotEmpty) {
      print('✅ Données déjà disponibles, démarrage immédiat');
      print('   - _isInitialLoading avant setState: $_isInitialLoading');
      setState(() {
        _isInitialLoading = false;
        _studentDataReady = true;
      });
      print('   - _isInitialLoading après setState: $_isInitialLoading');
      _loadEcoleParams();
      return;
    }

    // Sinon, essayer de récupérer les données manquantes
    if (widget.eleveDetail == null && widget.child.matricule != null) {
      print('📡 Tentative de récupération des détails de l\'élève...');
      try {
        // Essayer de récupérer le code école depuis plusieurs sources
        String ecoleCode = widget.child.ecoleCode ?? _ecoleCode ?? '';

        // Si toujours pas de code école, essayer depuis les détails précédemment chargés
        if (ecoleCode.isEmpty && _eleveDetailData != null) {
          ecoleCode =
              _eleveDetailData!['ecole']?.toString() ??
              _eleveDetailData!['ecole_code']?.toString() ??
              '';
          print('🔄 Code école récupéré depuis _eleveDetailData: $ecoleCode');
        }

        final matricule = widget.child.matricule!;

        print(
          '🔗 Requête détails élève - Matricule: $matricule, École: $ecoleCode',
        );

        if (ecoleCode.isEmpty) {
          throw Exception(
            'Code école non disponible. Impossible de récupérer les détails de l\'élève.',
          );
        }

        final eleveDetail = await EcoleEleveService.getEleveDetail(
          matricule,
          ecoleCode,
        );

        print('✅ Détails de l\'élève récupérés avec succès');
        print('   - UID trouvé: ${eleveDetail['uid']}');

        if (mounted) {
          setState(() {
            _eleveDetailData = eleveDetail;
          });

          // Maintenant que les données sont chargées, vérifier l'UID
          if (_uid_eleve.isNotEmpty) {
            setState(() {
              _isInitialLoading = false;
              _studentDataReady = true;
            });
            _loadEcoleParams();
            return;
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la récupération des détails: $e');
      }
    }

    // Si les données ne sont toujours pas disponibles, attendre un peu
    print('⏰ Données non disponibles, attente...');

    // Essayer plusieurs fois avec des délais croissants
    for (int attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));

      if (!mounted) return;

      final uid = _uid_eleve;
      print('🔄 Tentative ${attempt + 1}/5 - UID: "$uid"');

      if (uid.isNotEmpty) {
        print('✅ Données disponibles après ${attempt + 1} tentatives');
        setState(() {
          _isInitialLoading = false;
          _studentDataReady = true;
        });
        _loadEcoleParams();
        return;
      }
    }

    // Si après toutes les tentatives l'UID est toujours manquant
    if (mounted) {
      print('❌ Échec: UID toujours non disponible après 5 tentatives');
      setState(() {
        _isInitialLoading = false;
        _studentDataReady = false;
        _hasCriticalError = true;
        _criticalErrorMessage =
            'Les données de l\'élève ne sont pas disponibles. Veuillez réessayer plus tard.';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _serviceSearchController.dispose();
    _zoneSearchController.dispose();
    _mainScrollController.dispose();
    for (var controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ─── CHARGEMENT PARAMÈTRES ÉCOLE ──────────────────────────────────────────

  Future<void> _loadEcoleParams() async {
    try {
      final ecoleData = await EcoleEleveService.getEcoleParametresForEleve(
        _ecoleCode,
      );
      if (mounted) {
        setState(() => _servicesEnabled = ecoleData.serviceExtra == 1);
        _loadScolarite();
      }
    } catch (_) {
      if (mounted) _loadScolarite();
    }
  }

  Future<Map<String, bool>> _checkInscriptionPeriods() async {
    var ecoleData = EcoleEleveService.getEcoleDataFromCache(_ecoleCode);
    if (ecoleData == null) {
      try {
        ecoleData = await EcoleEleveService.getEcoleParametresForEleve(
          _ecoleCode,
        );
      } catch (_) {
        return {
          'preinscription': false,
          'inscription': false,
          'reservation': false,
        };
      }
    }
    return EcoleEleveService.getStatutsInscription(ecoleData);
  }

  // ─── APPELS API ────────────────────────────────────────────────────────────

  Future<void> _loadScolarite() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📚 [INSCRIPTION] Chargement de la scolarité');
    print('═══════════════════════════════════════════════════════════');
    print('🏷️ Code école: $_ecoleCode');
    print('🆔 UID élève: $_uid_eleve');
    print('📋 Système éducatif: ${_ecoleCode.startsWith('*annour*') ? 2 : 1}');
    print('📊 Détails élève disponibles:');
    if (widget.eleveDetail != null) {
      widget.eleveDetail!.forEach((key, value) {
        print('   - $key: $value');
      });
    } else {
      print('   - Aucun détail élève disponible');
    }
    print('═══════════════════════════════════════════════════════════');
    print('');

    final preinscrit =
        widget.eleveDetail?['preinscrit'] ?? _eleveDetailData?['preinscrit'];
    final inscrit =
        widget.eleveDetail?['status'] ?? _eleveDetailData?['status'];
    print(
      '═════════════════════════════[status]══════════════════════════════',
    );
    print(preinscrit);
    if (inscrit == 1) {
      if (mounted) {
        setState(() {
          _dejaInscrit = true;
          _loadingScolarite = false;
        });
      }
      return; // ← on sort immédiatement
    }

    setState(() => _loadingScolarite = true);
    try {
      final uid = _uid_eleve;
      print('🔍 Validation du brancheId: "$uid"');

      if (uid.isEmpty) {
        throw Exception(
          'UID élève manquant. Les données de l\'élève ne sont pas encore chargées.',
        );
      }

      print('📡 Vérification des périodes d\'inscription...');
      final statuts = await _checkInscriptionPeriods();
      print('📡 Résultat périodes: $statuts');

      if (statuts['preinscription'] != true &&
          statuts['inscription'] != true &&
          statuts['reservation'] != true) {
        print('⚠️ TOUTES les périodes sont fermées → affichage écran fermé');
        if (mounted) {
          setState(() {
            _periodsClosed = true;
            _loadingScolarite = false;
          });
        }
        return;
      }
      final systemeEducatif = _ecoleCode.startsWith('*annour*') ? 2 : 1;
      // Utiliser l'UID de l'élève comme brancheId
      String brancheId = _uid_eleve;

      print('🔍 BrancheId qui sera utilisé (UID élève): $brancheId');
      print(
        '🔗 Appel fetchScolarite avec: brancheId=$brancheId, ecoleCode=$_ecoleCode, systemeEducatif=$systemeEducatif',
      );

      final echeances = await InscriptionApiService.fetchScolarite(
        brancheId: brancheId,
        ecoleCode: _ecoleCode,
        systemeEducatif: systemeEducatif,
      );
      print('✅ fetchScolarite retourné: ${echeances.length} échéances');
      if (mounted) {
        setState(() => _echeancesScolarite = echeances);
        _fadeController.forward();
      }
    } catch (e) {
      print('❌ Erreur critique lors du chargement de la scolarité: $e');
      if (mounted) {
        String userMessage =
            'Impossible de charger les données de scolarité. Veuillez réessayer plus tard.';

        // Message plus spécifique si l'UID est manquant
        if (e.toString().contains('UID élève manquant')) {
          userMessage =
              'Les données de l\'élève ne sont pas encore disponibles. Veuillez réessayer dans quelques instants.';
        }

        setState(() {
          _hasCriticalError = true;
          _criticalErrorMessage = userMessage;
          _loadingScolarite = false;
        });
      }
      _showError('Erreur chargement scolarité : $e');
    } finally {
      if (mounted && !_hasCriticalError)
        setState(() => _loadingScolarite = false);
    }
  }

  Future<void> _loadReservation() async {
    setState(() => _loadingReservation = true);
    try {
      final reservation = await InscriptionApiService.fetchReservation(
        matricule: _matricule,
      );
      if (mounted) setState(() => _reservation = reservation);
    } catch (_) {
      if (mounted)
        setState(
          () => _reservation = ReservationStatus(
            sommeReservation: 0,
            status: false,
          ),
        );
    } finally {
      if (mounted) setState(() => _loadingReservation = false);
    }
  }

  Future<void> _loadServices() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🛍️ [INSCRIPTION] Chargement des services');
    print('═══════════════════════════════════════════════════════════');
    print('🏷️ Code école: $_ecoleCode');
    print('═══════════════════════════════════════════════════════════');
    print('');

    setState(() => _loadingServices = true);
    try {
      final services = await InscriptionApiService.fetchServices(
        ecoleCode: _ecoleCode,
      );
      if (mounted) {
        setState(() => _services = services);
        _selectDefaultServices();
      }
    } catch (e) {
      _showError('Erreur chargement services : $e');
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadEcheancesForSelectedServices() async {
    if (!_services.any((s) => s.selectionnee)) {
      setState(() => _echeancesService = []);
      return;
    }
    setState(() => _loadingEcheancesService = true);
    try {
      final echeances =
          await InscriptionApiService.fetchEcheancesForSelectedServices(
            services: _services,
            ecoleCode: _ecoleCode,
          );
      if (mounted) {
        setState(() => _echeancesService = echeances);
        _selectMostRecentEcheanceByDefault();
      }
    } catch (e) {
      _showError("Erreur chargement échéancier : $e");
    } finally {
      if (mounted) setState(() => _loadingEcheancesService = false);
    }
  }

  Future<void> _loadZones() async {
    setState(() => _loadingZones = true);
    try {
      final zones = await InscriptionApiService.fetchZones(
        ecoleCode: _ecoleCode,
      );
      if (mounted) setState(() => _zones = zones);
    } catch (e) {
      _showError('Erreur chargement zones : $e');
    } finally {
      if (mounted) setState(() => _loadingZones = false);
    }
  }

  // ─── LOGIQUE LOCALE ────────────────────────────────────────────────────────

  void _selectDefaultServices() {
    if (_services.isEmpty) return;
    setState(() {
      final firstCantine = _services.firstWhere(
        (s) => s.service == 'CANTINE',
        orElse: () => _services.first,
      );
      firstCantine.selectionnee = true;

      final firstTransport = _services.firstWhere(
        (s) => s.service == 'TRANS',
        orElse: () => _services.first,
      );
      if (firstTransport.iddetail != firstCantine.iddetail) {
        firstTransport.selectionnee = true;
      }
    });
  }

  void _selectMostRecentEcheanceByDefault() {
    if (_echeancesService.isEmpty) return;
    setState(() {
      for (var e in _echeancesService) e.selectionnee = false;
      for (final rubrique in ['CANTINE', 'TRANS']) {
        final list = _echeancesService
            .where((e) => e.codeRubrique == rubrique)
            .toList();
        if (list.isEmpty) continue;
        EcheanceService mostRecent = list.first;
        for (var e in list) {
          if (_isDateMoreRecent(e.dateLimite, mostRecent.dateLimite))
            mostRecent = e;
        }
        mostRecent.selectionnee = true;
      }
    });
  }

  bool _isDateMoreRecent(String date1, String date2) {
    try {
      return DateTime.parse(date1).isAfter(DateTime.parse(date2));
    } catch (_) {
      return false;
    }
  }

  // ─── NAVIGATION ────────────────────────────────────────────────────────────
  //
  // Principe : on navigue toujours par index dans _orderedStepIds.
  // Quand l'utilisateur coche/décoche Transport, _orderedStepIds change
  // (l'étape Zones apparaît ou disparaît) et le PageView est reconstruit
  // lors du prochain setState(), ce qui synchronise automatiquement tout.

  void _navigateToPage(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= _orderedStepIds.length) return;
    setState(() => _currentPageIndex = targetIndex);
    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    final nextIndex = _currentPageIndex + 1;
    if (nextIndex >= _orderedStepIds.length) return;

    // Déclencher les chargements selon l'étape qui arrive.
    final nextId = _orderedStepIds[nextIndex];
    if (nextId == _kStepReservation && _reservation == null) _loadReservation();
    if (nextId == _kStepServices && _services.isEmpty) _loadServices();
    if (nextId == _kStepZones) _loadZones();
    if (nextId == _kStepEcheancier) _loadEcheancesForSelectedServices();

    _navigateToPage(nextIndex);
  }

  void _prevStep() {
    if (_currentPageIndex > 0) _navigateToPage(_currentPageIndex - 1);
  }

  bool _canGoNext() {
    switch (_currentStepId) {
      case _kStepScolarite:
        return _echeancesScolarite.any((e) => e.selectionnee);
      case _kStepZones:
        return _selectedZone != null;
      case _kStepEcheancier:
        if (!_servicesEnabled) return true;
        final hasSelected = _services.any((s) => s.selectionnee);
        if (!hasSelected) return true;
        return _echeancesService.any((e) => e.selectionnee);
      default:
        return true;
    }
  }

  // ─── MISE À JOUR DYNAMIQUE APRÈS CHANGEMENT DE SERVICE TRANS ─────────────
  //
  // Appelée après chaque toggle d'un service pour resynchroniser la page
  // courante si l'étape Zones vient d'apparaître ou de disparaître.

  void _onTransportServiceToggled() {
    // Récupère les nouvelles étapes APRÈS le setState du toggle.
    final newSteps = _orderedStepIds;
    // Si l'index courant dépasse la nouvelle liste, on recule.
    if (_currentPageIndex >= newSteps.length) {
      _navigateToPage(newSteps.length - 1);
    }
    // Si on est sur une étape qui n'existe plus (ex-Zones), on recule aussi.
    // (Ne peut arriver qu'en retirant Transport depuis l'étape Zones.)
    if (!newSteps.contains(_currentStepId)) {
      _navigateToPage(_currentPageIndex - 1);
    }
  }

  // ─── CALCULS ───────────────────────────────────────────────────────────────

  int get _totalScolarite => _echeancesScolarite
      .where((e) => e.selectionnee)
      .fold(0, (sum, e) => sum + e.montant);
  int get _totalServices => _echeancesService
      .where((e) => e.selectionnee)
      .fold(0, (sum, e) => sum + e.montant);
  int get _totalTransport => 0;
  int get _totalBrut => _totalScolarite + _totalServices + _totalTransport;
  int get _deductionReservation =>
      (_reservation?.status == true) ? _reservation!.sommeReservation : 0;
  int get _totalNet => (_totalBrut - _deductionReservation).clamp(0, 999999999);

  // ─── UI HELPERS ────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    CartSnackBar.showOverlay(
      context,
      productName: 'Erreur',
      message: msg,
      backgroundColor: Colors.red[400],
      icon: Icons.error_outline_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    CartSnackBar.showOverlay(
      context,
      productName: 'Succès',
      message: msg,
      backgroundColor: Colors.green[500],
      icon: Icons.check_circle_outline_rounded,
      duration: const Duration(seconds: 4),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────

  Widget _buildCustomAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomSliverAppBar(
      title: 'Inscription – ${widget.child.firstName}',
      isDark: isDark,
      onBackTap: () => Navigator.of(context).pop(),
      // actions: [
      //   Container(
      //     margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      //     decoration: BoxDecoration(
      //       color: AppColors.shopBlueSurface,
      //       borderRadius: BorderRadius.circular(20),
      //     ),
      //     child: Text(
      //       _formatAmount(_totalNet),
      //       style: const TextStyle(
      //         fontSize: 12,
      //         fontWeight: FontWeight.w700,
      //         color: AppColors.shopBlue,
      //       ),
      //     ),
      //   ),
      // ],
      backgroundColor: cardColor,
      elevation: 0,
    );
  }

  Widget _buildAppBarSubtitle() {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        'Étape ${_currentPageIndex + 1} sur ${_orderedStepIds.length}',
        style: TextStyle(
          fontSize: 13,
          color: textSecondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ─── PROGRESS INDICATOR ────────────────────────────────────────────────────

  Widget _buildProgressIndicator() {
    final steps = _orderedStepIds;
    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPageIndex + 1) / steps.length,
              backgroundColor: dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.integrationBlue),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final meta = _stepMeta(steps[index]);
              final isCompleted = index < _currentPageIndex;
              final isCurrent = index == _currentPageIndex;

              return GestureDetector(
                onTap: () {
                  if (index < _currentPageIndex) _navigateToPage(index);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 34 : 28,
                      height: isCurrent ? 34 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                            ? AppColors.integrationBlue
                            : AppColors.screenDivider,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.integrationBlue.withOpacity(0.25),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : isCompleted
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.25),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : meta['icon'] as IconData,
                        color: (isCompleted || isCurrent)
                            ? Colors.white
                            : textSecondaryColor,
                        size: isCurrent ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : isCompleted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.integrationBlue
                            : isCompleted
                            ? Colors.green
                            : textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── COMPOSANTS RÉUTILISABLES ──────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: textColor,
      letterSpacing: -0.3,
    ),
  );

  Widget _buildStepHeader(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onSearchPressed,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.shopBlueSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: textSecondaryColor),
              ),
            ],
          ),
        ),
        if (onSearchPressed != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerColor),
            ),
            child: IconButton(
              onPressed: onSearchPressed,
              icon: Icon(
                Icons.search_rounded,
                size: 18,
                color: textSecondaryColor,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildCountBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : AppColors.shopBlueSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
      ),
    ),
  );

  Widget _buildServiceSearchBar() => SearchBarWidget(
    isSearching: _isServiceSearching,
    searchController: _serviceSearchController,
    onChanged: (_) => setState(() {}),
    onClear: () => setState(() {}),
    hintText: 'Rechercher un service...',
  );

  Widget _buildZoneSearchBar() => SearchBarWidget(
    isSearching: _isZoneSearching,
    searchController: _zoneSearchController,
    onChanged: (_) => setState(() {}),
    onClear: () => setState(() {}),
    hintText: 'Rechercher une zone...',
  );

  Widget _buildLoadingState(String message) => CustomLoader(
    message: message,
    loaderColor: AppColors.shopBlue,
    backgroundColor: cardColor,
  );

  Widget _buildEmptyState(String message, IconData icon) => Container(
    padding: const EdgeInsets.all(32),
    alignment: Alignment.center,
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.shopBlueSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 34,
            color: (isDark ? AppColors.shopBlueLight : AppColors.shopBlue)
                .withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: TextStyle(fontSize: 14, color: textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildSkipState(String title, String subtitle, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.shopBlueSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? AppColors.shopBlueLight : AppColors.shopBlue)
                .withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.shopBlueLight : AppColors.shopBlue)
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: (isDark ? AppColors.shopBlueLight : AppColors.shopBlue)
                    .withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.shopBlueLight : AppColors.shopBlue)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Appuyez sur Suivant pour continuer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
                ),
              ),
            ),
          ],
        ),
      );

  // ─── ÉTAPE 1 – Scolarité ───────────────────────────────────────────────────

  Widget _buildStep1() {
    if (_loadingScolarite)
      return _buildLoadingState('Chargement de la scolarité...');
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        key: const ValueKey('step1'),
        controller: _getControllerForStep(_kStepScolarite),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              'Scolarité',
              'Frais scolaires pour ${widget.child.firstName} | ${widget.child.grade}',
              Icons.school_rounded,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _sectionLabel('Échéancier scolaire'),
                const Spacer(),
                _buildCountBadge(_formatAmount(_totalScolarite)),
              ],
            ),
            const Divider(color: AppColors.screenDivider, height: 20),
            if (_echeancesScolarite.isEmpty)
              _buildEmptyState('Aucune échéance disponible', Icons.info_outline)
            else
              ..._echeancesScolarite.asMap().entries.map(
                (entry) => SelectableItemCard(
                  config: ItemCardFactory.echeance(
                    libelle: entry.value.libelle,
                    montantFormate: _formatAmount(entry.value.montant),
                    dateLimite: _formatDate(entry.value.dateLimite),
                    selected: entry.value.selectionnee,
                    obligatoire: entry.value.rubriqueObligatoire == 1,
                    onToggle: () => setState(
                      () =>
                          entry.value.selectionnee = !entry.value.selectionnee,
                    ),
                    index: entry.key + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── ÉTAPE 2 – Réservation ─────────────────────────────────────────────────

  Widget _buildStep2() {
    if (_loadingReservation)
      return _buildLoadingState('Vérification de la réservation...');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          _buildStepHeader(
            'Réservation',
            'Statut de votre réservation',
            Icons.bookmark_rounded,
          ),
          const Divider(color: AppColors.screenDivider, height: 24),
          Expanded(
            child: Center(
              child: _reservation == null
                  ? _buildEmptyState(
                      'Impossible de charger les infos réservation',
                      Icons.error_outline,
                    )
                  : Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppDimensions.getSettingsCardShadow(context),
                        border: _reservation!.status
                            ? Border.all(
                                color:
                                    (isDark
                                            ? AppColors.shopBlueLight
                                            : AppColors.shopBlue)
                                        .withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _reservation!.status
                                  ? AppColors.shopBlueSurface
                                  : AppColors.screenSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _reservation!.status
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 34,
                              color: _reservation!.status
                                  ? (isDark
                                        ? AppColors.shopBlueLight
                                        : AppColors.shopBlue)
                                  : textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _reservation!.status
                                ? 'Réservation active'
                                : 'Aucune réservation',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _reservation!.status
                                  ? (isDark
                                        ? AppColors.shopBlueLight
                                        : AppColors.shopBlue)
                                  : textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _reservation!.status
                                ? 'Une déduction sera appliquée au montant total'
                                : 'Aucune déduction ne sera appliquée',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_reservation!.status &&
                              _reservation!.sommeReservation > 0) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.shopBlueLight,
                                    AppColors.shopBlue,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppDimensions.getSettingsCardShadow(context),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Déduction : ${_formatAmount(_reservation!.sommeReservation)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ÉTAPE 3 – Services ────────────────────────────────────────────────────

  Widget _buildStep3() {
    if (_loadingServices)
      return _buildLoadingState('Chargement des services...');
    return SingleChildScrollView(
      controller: _getControllerForStep(_kStepServices),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Services',
            'Sélectionnez les services souhaités',
            Icons.grid_view_rounded,
            onSearchPressed: () =>
                setState(() => _isServiceSearching = !_isServiceSearching),
          ),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildServiceSearchBar(),
          const SizedBox(height: 16),
          if (_filteredServices.isEmpty)
            _buildEmptyState('Aucun service trouvé', Icons.search_off)
          else ...[
            if (_cantineServices.isNotEmpty) ...[
              ItemSectionHeader(
                title: 'Services Cantine',
                icon: Icons.restaurant_rounded,
                iconColor: Colors.orange,
                trailingLabel:
                    '${_cantineServices.where((s) => s.selectionnee).length} sélectionné(s)',
              ),
              ..._cantineServices.asMap().entries.map(
                (entry) => SelectableItemCard(
                  config: ItemCardFactory.service(
                    designation: entry.value.designation,
                    type: entry.value.service,
                    prixFormate: _formatAmount(entry.value.prix),
                    selected: entry.value.selectionnee,
                    onTap: () {
                      setState(
                        () => entry.value.selectionnee =
                            !entry.value.selectionnee,
                      );
                      if (entry.value.selectionnee)
                        _loadEcheancesForSelectedServices();
                    },
                    index: entry.key + 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_transportServices.isNotEmpty) ...[
              ItemSectionHeader(
                title: 'Services Transport',
                icon: Icons.directions_bus_rounded,
                iconColor: Colors.blue,
                trailingLabel:
                    '${_transportServices.where((s) => s.selectionnee).length} sélectionné(s)',
              ),
              ..._transportServices.asMap().entries.map(
                (entry) => SelectableItemCard(
                  config: ItemCardFactory.service(
                    designation: entry.value.designation,
                    type: entry.value.service,
                    prixFormate: _formatAmount(entry.value.prix),
                    selected: entry.value.selectionnee,
                    onTap: () {
                      // 1. Toggler le service
                      setState(
                        () => entry.value.selectionnee =
                            !entry.value.selectionnee,
                      );

                      // 2. Resynchroniser la navigation (Zones apparaît/disparaît)
                      _onTransportServiceToggled();

                      // 3. Charger les données si nécessaire
                      if (entry.value.selectionnee) {
                        _loadEcheancesForSelectedServices();
                        if (_zones.isEmpty) _loadZones();
                      }
                    },
                    index: entry.key + 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_otherServices.isNotEmpty) ...[
              ItemSectionHeader(
                title: 'Autres Services',
                icon: Icons.school_rounded,
                trailingLabel:
                    '${_otherServices.where((s) => s.selectionnee).length} sélectionné(s)',
              ),
              ..._otherServices.asMap().entries.map(
                (entry) => SelectableItemCard(
                  config: ItemCardFactory.service(
                    designation: entry.value.designation,
                    type: entry.value.service,
                    prixFormate: _formatAmount(entry.value.prix),
                    selected: entry.value.selectionnee,
                    onTap: () => setState(
                      () =>
                          entry.value.selectionnee = !entry.value.selectionnee,
                    ),
                    index: entry.key + 1,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── ÉTAPE 4 – Zones ───────────────────────────────────────────────────────

  Widget _buildStep4() {
    if (_loadingZones) return _buildLoadingState('Chargement des zones...');
    return SingleChildScrollView(
      controller: _getControllerForStep(_kStepZones),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Zone de transport',
            'Sélectionnez votre zone (optionnel)',
            Icons.map_rounded,
            onSearchPressed: () =>
                setState(() => _isZoneSearching = !_isZoneSearching),
          ),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildZoneSearchBar(),
          const SizedBox(height: 16),
          if (_zones.isEmpty)
            _buildEmptyState('Aucune zone disponible', Icons.info_outline)
          else if (_filteredZones.isEmpty)
            _buildEmptyState('Aucune zone trouvée', Icons.search_off)
          else
            ..._filteredZones.asMap().entries.map(
              (entry) => SelectableItemCard(
                config: ItemCardFactory.zone(
                  nom: entry.value.zone,
                  code: entry.value.code,
                  selected: _selectedZone?.idzone == entry.value.idzone,
                  onTap: () => setState(() => _selectedZone = entry.value),
                  index: entry.key + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── ÉTAPE 5 – Échéancier services ────────────────────────────────────────

  Widget _buildStep5() {
    if (!_services.any((s) => s.selectionnee)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
        child: Column(
          children: [
            _buildStepHeader(
              'Échéancier',
              'Aucun service sélectionné',
              Icons.payment_rounded,
            ),
            const Divider(color: AppColors.screenDivider, height: 24),
            Expanded(
              child: Center(
                child: _buildSkipState(
                  'Aucun service sélectionné',
                  "Vous pouvez passer à l'étape suivante",
                  Icons.payment_rounded,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingEcheancesService)
      return _buildLoadingState("Chargement de l'échéancier...");

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          _buildStepHeader(
            'Échéancier',
            'Échéancier des services sélectionnés',
            Icons.payment_rounded,
          ),
          const Divider(color: AppColors.screenDivider, height: 20),
          Row(
            children: [
              _sectionLabel('Échéances services'),
              const Spacer(),
              _buildCountBadge(_formatAmount(_totalServices)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _echeancesService.isEmpty
                ? Center(
                    child: _buildEmptyState(
                      'Aucune échéance disponible',
                      Icons.info_outline,
                    ),
                  )
                : SingleChildScrollView(
                    controller: _getControllerForStep(_kStepEcheancier),
                    child: Column(
                      children: [
                        if (_echeancesService.any(
                          (e) => e.codeRubrique == 'CANTINE',
                        )) ...[
                          _buildEcheanceServiceSection(
                            rubrique: 'CANTINE',
                            title: 'Services Cantine',
                            icon: Icons.restaurant_rounded,
                            iconColor: Colors.orange,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_echeancesService.any(
                          (e) => e.codeRubrique == 'TRANS',
                        ))
                          _buildEcheanceServiceSection(
                            rubrique: 'TRANS',
                            title: 'Services Transport',
                            icon: Icons.directions_bus_rounded,
                            iconColor: Colors.blue,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcheanceServiceSection({
    required String rubrique,
    required String title,
    required IconData icon,
    Color? iconColor,
  }) {
    final echeances =
        List<EcheanceService>.from(
          _echeancesService.where((e) => e.codeRubrique == rubrique),
        )..sort((a, b) {
          try {
            return DateTime.parse(
              b.dateLimite,
            ).compareTo(DateTime.parse(a.dateLimite));
          } catch (_) {
            return 0;
          }
        });
    final selectedCount = echeances.where((e) => e.selectionnee).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemSectionHeader(
          title: title,
          icon: icon,
          iconColor: iconColor,
          trailingLabel: '$selectedCount/${echeances.length}',
        ),
        ...echeances.asMap().entries.map(
          (entry) => SelectableItemCard(
            config: ItemCardFactory.echeance(
              libelle: entry.value.libelle,
              montantFormate: _formatAmount(entry.value.montant),
              dateLimite: _formatDate(entry.value.dateLimite),
              selected: entry.value.selectionnee,
              onToggle: () => setState(
                () => entry.value.selectionnee = !entry.value.selectionnee,
              ),
              index: entry.key + 1,
            ),
          ),
        ),
      ],
    );
  }

  // ─── RÉCAPITULATIF ─────────────────────────────────────────────────────────

  Widget _buildRecap() {
    return SingleChildScrollView(
      controller: _getControllerForStep(_kStepRecap),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Récapitulatif',
            'Vérifiez et confirmez votre inscription',
            Icons.receipt_long_rounded,
          ),
          const Divider(color: AppColors.screenDivider, height: 24),

          // Élève
          _buildRecapSection(
            title: 'Élève',
            icon: Icons.person_rounded,
            child: _buildRecapRow('Nom', widget.child.firstName),
          ),
          const SizedBox(height: 12),

          // Scolarité
          if (_echeancesScolarite.any((e) => e.selectionnee)) ...[
            _buildRecapSection(
              title: 'Scolarité',
              icon: Icons.school_rounded,
              child: Column(
                children: [
                  ..._echeancesScolarite
                      .where((e) => e.selectionnee)
                      .map(
                        (e) =>
                            _buildRecapRow(e.libelle, _formatAmount(e.montant)),
                      ),
                  const Divider(height: 16, color: AppColors.screenDivider),
                  _buildRecapRow(
                    'Sous-total',
                    _formatAmount(_totalScolarite),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Services
          if (_echeancesService.any((e) => e.selectionnee)) ...[
            _buildRecapSection(
              title: 'Services',
              icon: Icons.payment_rounded,
              child: Column(
                children: [
                  ..._echeancesService
                      .where((e) => e.selectionnee)
                      .map(
                        (e) =>
                            _buildRecapRow(e.libelle, _formatAmount(e.montant)),
                      ),
                  const Divider(height: 16, color: AppColors.screenDivider),
                  _buildRecapRow(
                    'Sous-total',
                    _formatAmount(_totalServices),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Transport (zone uniquement si transport coché)
          if (_selectedZone != null &&
              _services.any((s) => s.service == 'TRANS' && s.selectionnee)) ...[
            _buildRecapSection(
              title: 'Transport',
              icon: Icons.directions_bus_rounded,
              child: Column(
                children: [
                  _buildRecapRow('Zone', _selectedZone!.zone),
                  const Divider(height: 16, color: AppColors.screenDivider),
                  _buildRecapRow(
                    'Sous-total',
                    _formatAmount(_totalTransport),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Déduction réservation
          if (_reservation?.status == true && _deductionReservation > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.shopBlueSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.shopBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bookmark_added_rounded,
                    color: AppColors.shopBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Déduction réservation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.shopBlue,
                      ),
                    ),
                  ),
                  Text(
                    '- ${_formatAmount(_deductionReservation)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.shopBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Total final
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'TOTAL À PAYER',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  _formatAmount(_totalNet),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.shopBlue, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "L'inscription sera confirmée après validation par l'administration.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.shopBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppDimensions.getSettingsCardShadow(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.shopBlueSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.shopBlueLight : AppColors.shopBlue,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );

  Widget _buildRecapRow(String label, String value, {bool isBold = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  color: isBold ? textColor : textSecondaryColor,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? AppColors.shopGreen : textColor,
              ),
            ),
          ],
        ),
      );

  // ─── BOUTONS DE NAVIGATION ─────────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    final canNext = _canGoNext();
    final isLast = _currentPageIndex == _orderedStepIds.length - 1;
    final isSecondToLast = _currentPageIndex == _orderedStepIds.length - 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_currentPageIndex > 0)
            CustomButton(
              text: 'Précédent',
              onPressed: _prevStep,
              color: isDark ? Colors.white60 : Colors.grey[700]!,
              isLight: true,
              hasBorder: false,
              icon: Icons.arrow_back_ios_new,
              width: 120,
              height: 40,
              fontSize: 12,
            )
          else
            const Spacer(),
          if (_currentPageIndex > 0) const Spacer(),
          if (!isLast)
            CustomButton(
              text: isSecondToLast ? 'Récap' : 'Suivant',
              onPressed: canNext ? _nextStep : null,
              color: AppColors.integrationBlue,
              icon: Icons.arrow_forward_rounded,
              iconOnRight: true,
              width: 120,
              height: 40,
              fontSize: 12,
            ),
          if (isLast)
            CustomButton(
              text: 'Confirmer',
              onPressed: _showPaymentChoiceBottomSheet,
              color: AppColors.screenOrange,
              icon: Icons.check_circle_rounded,
              width: 120,
              height: 40,
              fontSize: 12,
            ),
        ],
      ),
    );
  }

  Widget _buildDejaInscritScreen() {
    // Formatter la date d'inscription
    String dateInscription = '–';
    final rawDate = widget.eleveDetail?['date_preinsc']?.toString();
    if (rawDate != null) {
      try {
        final d = DateTime.parse(rawDate);
        dateInscription =
            '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {}
    }

    final nomClasse = widget.eleveDetail?['nom_classe']?.toString() ?? '–';
    final matricule = widget.child.matricule ?? '–';

    return Scaffold(
      backgroundColor: screenBgColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(context),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône succès
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 56,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Titre
                  Text(
                    'Déjà inscrit(e)',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sous-titre
                  Text(
                    '${widget.child.firstName} est déjà inscrit(e) pour '
                    "l'année scolaire en cours dans cet établissement.",
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondaryColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Carte de détails
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppDimensions.getSettingsCardShadow(context),
                    ),
                    child: Column(
                      children: [
                        // En-tête carte
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppColors.shopBlueSurface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(19),
                              topRight: Radius.circular(19),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: isDark
                                    ? AppColors.shopBlueLight
                                    : AppColors.shopBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Détails de l\'inscription',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.shopBlueLight
                                      : AppColors.shopBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Lignes de détails
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDejaInscritRow(
                                'Élève',
                                widget.child.firstName,
                              ),
                              _buildDejaInscritRow('Classe', nomClasse),
                              _buildDejaInscritRow('Matricule', matricule),
                              _buildDejaInscritRow(
                                'Date d\'inscription',
                                dateInscription,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Statut',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Confirmé',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bandeau info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.shopBlueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark
                              ? AppColors.shopBlueLight
                              : AppColors.shopBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Si vous pensez que c'est une erreur, "
                            "contactez l'administration de l'école.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.shopBlueLight
                                  : AppColors.shopBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton retour
                  CustomButton(
                    text: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.shopBlue,
                    icon: Icons.arrow_back_rounded,
                    height: 50,
                    fontSize: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDejaInscritRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SOUMISSION ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _buildPaymentPayload() {
    final List<Map<String, dynamic>> ids = [];

    final echeancesScol = _echeancesScolarite
        .where((e) => e.selectionnee)
        .toList();
    if (echeancesScol.isNotEmpty) {
      ids.add({
        'id': 'SCO',
        'service': 'Scolarité',
        'montant': _totalScolarite,
        'reservation': false,
        'echeancesSelectionnees': echeancesScol.map((e) => e.toJson()).toList(),
      });
    }

    final selectedServices = _services.where((s) => s.selectionnee).toList();
    final echeancesServices = _echeancesService
        .where((e) => e.selectionnee)
        .toList();
    if (echeancesServices.isNotEmpty && selectedServices.isNotEmpty) {
      for (final service in selectedServices) {
        final serviceEcheances = echeancesServices
            .where((e) => e.codeRubrique == service.service)
            .toList();
        if (serviceEcheances.isNotEmpty) {
          ids.add({
            'id': service.iddetail,
            'service': service.service,
            'montant': serviceEcheances.fold(0, (sum, e) => sum + e.montant),
            'echeancesServicesSelectionnees': serviceEcheances
                .map((e) => e.toJson())
                .toList(),
          });
        }
      }
    }

    // Zone de transport (seulement si TRANS coché ET zone sélectionnée)
    final hasTransService = selectedServices.any((s) => s.service == 'TRANS');
    if (_selectedZone != null && hasTransService && _totalTransport > 0) {
      ids.add({
        'id': _selectedZone!.idzone,
        'service': 'Transport',
        'montant': _totalTransport,
        'echeancesServicesSelectionnees': [],
      });
    }

    return ids;
  }

  Future<void> _effectuerInscription() async {
    try {
      await InscriptionApiService.submitInscription(
        matricule: _matricule,
        ecoleCode: _ecoleCode,
        payload: InscriptionPayload(ids: _buildPaymentPayload()),
      );
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess(
          'Inscription de ${widget.child.firstName} enregistrée avec succès !',
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _effectuerPaiementEnLigne() async {
    final totalAmount = _totalScolarite + _totalServices + _totalTransport;

    try {
      final response = await InscriptionApiService.submitPaiementEnLigne(
        matricule: _matricule,
        ecoleCode: _ecoleCode,
        payload: _buildPaymentPayload(),
        totalMontant: totalAmount,
      );
      if (mounted) {
        final String? paymentUrl = response['url'];
        final String? token = response['token'];

        if (paymentUrl != null) {
          final uri = Uri.parse(paymentUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            _showPaymentVerificationLoader(_uid_eleve);
          } catch (e) {
            _showError('Impossible d\'ouvrir la page de paiement.');
          }
        } else {
          _showSuccess(
            response['message'] ??
                'Paiement en ligne initié pour ${widget.child.firstName}.',
          );
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showPaymentVerificationLoader(String uidEleve) {
    if (uidEleve.isEmpty) return;

    Timer? timer;
    bool isChecking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomLoader(
                    message: 'Attente de la confirmation du paiement...',
                    loaderColor: const Color(0xFFFF7A3C),
                    showBackground: false,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Veuillez finaliser le paiement sur la page sécurisée. L\'application vérifie actuellement le statut de votre transaction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      timer?.cancel(); // Sécurité pour s'assurer que le timer est bien tué
    });

    int attempts = 0;
    const int maxAttempts = 48; // 48 * 5s = 240s (4 minutes)

    // Lancement du polling toutes les 5 secondes
    timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (isChecking || !mounted) return;

      attempts++;
      if (attempts >= maxAttempts) {
        t.cancel();
        if (mounted) {
          Navigator.of(context).pop(); // Fermer uniquement le loader
          _showError(
            'L\'opération a échoué suite à une longue attente de paiement. Veuillez vérifier et réessayer.',
          );
        }
        return;
      }

      isChecking = true;

      try {
        final success = await InscriptionApiService.checkPaiementStatus(
          uidEleve,
        );
        if (success && mounted) {
          t.cancel();
          // 1. Fermer le loader
          Navigator.of(context).pop();
          // 2. Afficher le succès
          _showSuccess(
            'Paiement validé et inscription de ${widget.child.firstName} enregistrée avec succès !',
          );
          // 3. Quitter l'écran d'inscription
          Navigator.of(context).pop();
        }
      } catch (e) {
        // En cas d'erreur de vérification, on laisse tourner
      } finally {
        isChecking = false;
      }
    });
  }

  void _showPaymentChoiceBottomSheet() {
    PaymentChoiceBottomSheet.show(
      context: context,
      onOnlinePayment: _effectuerPaiementEnLigne,
      onCashPayment: _effectuerInscription,
    );
  }

  // ─── BUILD PRINCIPAL ───────────────────────────────────────────────────────

  /// Construit l'écran affiché lorsque les périodes d'inscription sont fermées
  Widget _buildPeriodsClosedScreen() {
    return Scaffold(
      backgroundColor: screenBgColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(context),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône d'information
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : AppColors.shopBlueSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 60,
                      color: isDark
                          ? AppColors.shopBlueLight
                          : AppColors.shopBlue,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre principal
                  Text(
                    'Périodes d\'inscription fermées',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Sous-titre
                  Text(
                    'Aucune période d\'inscription n\'est actuellement ouverte pour cette école.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Carte d'information
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withOpacity(0.3)
                          : AppColors.shopBlueSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.shopBlueLight.withOpacity(0.2)
                            : AppColors.shopBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: isDark
                                  ? AppColors.shopBlueLight
                                  : AppColors.shopBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Que faire ?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.shopBlueLight
                                      : AppColors.shopBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Contactez l\'administration de l\'école pour plus d\'informations\n'
                          '• Consultez le site web de l\'établissement\n'
                          '• Revenez plus tard pour vérifier l\'ouverture des inscriptions',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.shopBlue,
                    icon: Icons.arrow_back_rounded,
                    height: 50,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'écran affiché lorsqu'une erreur critique survient
  Widget _buildCriticalErrorScreen() {
    return Scaffold(
      backgroundColor: screenBgColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(context),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône d'erreur
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre principal
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Message d'erreur
                  Text(
                    _criticalErrorMessage ??
                        'Une erreur est survenue lors du chargement des données.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Carte d'assistance
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.red.withOpacity(0.1)
                          : Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Que faire ?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Vérifiez votre connexion internet\n'
                          '• Réessayez plus tard\n'
                          '• Contactez le support si le problème persiste\n'
                          '• Cliquez sur "Actualiser" pour recharger les données',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Boutons d'action
                  Column(
                    children: [
                      // Bouton réessayer
                      CustomButton(
                        text: 'Réessayer',
                        onPressed: () {
                          setState(() {
                            _hasCriticalError = false;
                            _criticalErrorMessage = null;
                            _isInitialLoading = true;
                          });
                          _initializeStudentData();
                        },
                        color: AppColors.shopBlue,
                        icon: Icons.refresh_rounded,
                        height: 50,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 12),
                      // Bouton actualiser (nouveau)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            setState(() {
                              _hasCriticalError = false;
                              _criticalErrorMessage = null;
                              _isInitialLoading = true;
                            });

                            // Forcer la récupération des données depuis l'API
                            if (widget.child.matricule != null) {
                              try {
                                final ecoleCode =
                                    widget.child.ecoleCode ?? _ecoleCode;
                                print(
                                  '🔄 Actualisation forcée des détails de l\'élève...',
                                );
                                print(
                                  '   - Matricule: ${widget.child.matricule}',
                                );
                                print(
                                  '   - widget.child.ecoleCode: ${widget.child.ecoleCode}',
                                );
                                print('   - _ecoleCode: $_ecoleCode');
                                print('   - École finale utilisée: $ecoleCode');

                                if (ecoleCode == null || ecoleCode.isEmpty) {
                                  throw Exception(
                                    'Code école non disponible. Veuillez réessayer plus tard.',
                                  );
                                }

                                final eleveDetail =
                                    await EcoleEleveService.getEleveDetail(
                                      widget.child.matricule!,
                                      ecoleCode!,
                                    );

                                if (mounted) {
                                  setState(() {
                                    _eleveDetailData = eleveDetail;
                                  });

                                  // Relancer l'initialisation avec les nouvelles données
                                  _initializeStudentData();
                                }
                              } catch (e) {
                                print('❌ Erreur lors de l\'actualisation: $e');
                                if (mounted) {
                                  setState(() {
                                    _hasCriticalError = true;
                                    _criticalErrorMessage =
                                        'Erreur lors de l\'actualisation: $e';
                                  });
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.shopBlue,
                            side: BorderSide(
                              color: AppColors.shopBlue,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sync_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Actualiser',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bouton retour
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            side: BorderSide(color: dividerColor, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Retour',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'écran de chargement initial
  Widget _buildInitialLoadingScreen() {
    return Scaffold(
      backgroundColor: screenBgColor,
      body: CustomScrollView(
        slivers: [
          _buildCustomAppBar(context),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // Espace pour l'app bar
                  // Loader personnalisé
                  CustomLoader(
                    message:
                        'Récupération des informations de\n${widget.child.firstName}...',
                    loaderColor: AppColors.shopBlue,
                    backgroundColor: Colors.transparent,
                    //height:60,
                    showBackground: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Chargement initial des données ──────────────────────────────────────────
    if (_isInitialLoading) {
      return _buildInitialLoadingScreen();
    }

    // ── Déjà inscrit ────────────────────────────────────────────────
    if (_dejaInscrit) {
      return _buildDejaInscritScreen();
    }

    // ── Erreur critique ────────────────────────────────────────────────
    if (_hasCriticalError) {
      return _buildCriticalErrorScreen();
    }

    // Si les périodes sont fermées, afficher l'écran d'information
    if (_periodsClosed) {
      return _buildPeriodsClosedScreen();
    }

    // On capture la liste une seule fois par build pour garantir la cohérence
    // entre le PageView et la barre de progression.
    final steps = _orderedStepIds;

    return Scaffold(
      backgroundColor: screenBgColor,
      floatingActionButton: ScrollToTopFab(
        key: ValueKey(_currentPageIndex),
        scrollController: _currentScrollController,
        bottomSpacerHeight: 140,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _mainScrollController,
            slivers: [
              _buildCustomAppBar(context),
              SliverToBoxAdapter(child: _buildAppBarSubtitle()),
              SliverToBoxAdapter(child: _buildProgressIndicator()),
              SliverFillRemaining(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  // ← PageView construit dynamiquement depuis _orderedStepIds.
                  //   Plus aucun désalignement possible entre l'index courant
                  //   et le contenu affiché.
                  children: steps.map((id) => _buildStepById(id)).toList(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          BottomFadeGradient(height: 140, endColor: screenBgColor),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }
}
