import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../models/child.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/selectable_item_card.dart';
import '../widgets/search_bar_widget.dart';
import '../services/ecole_eleve_service.dart';
import '../services/inscription_api_service.dart';

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
  // ── État du wizard ──────────────────────────────────────────────────────────
  int _currentPageIndex = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

      final statuts = await _checkInscriptionPeriods();
      if (statuts['preinscription'] != true &&
          statuts['inscription'] != true &&
          statuts['reservation'] != true) {
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

      final echeances = await InscriptionApiService.fetchScolarite(
        brancheId: brancheId,
        ecoleCode: _ecoleCode,
        systemeEducatif: systemeEducatif,
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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
      onBackTap: _currentPageIndex == 0
          ? () => Navigator.of(context).pop()
          : _prevStep,
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
      backgroundColor: AppColors.screenCard,
      elevation: 0,
    );
  }

  Widget _buildAppBarSubtitle() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        'Étape ${_currentPageIndex + 1} sur ${_orderedStepIds.length}',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.screenTextSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ─── PROGRESS INDICATOR ────────────────────────────────────────────────────

  Widget _buildProgressIndicator() {
    final steps = _orderedStepIds;
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPageIndex + 1) / steps.length,
              backgroundColor: AppColors.screenDivider,
              valueColor: const AlwaysStoppedAnimation(AppColors.shopBlue),
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
                            ? AppColors.shopBlue
                            : AppColors.screenDivider,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.shopBlue.withOpacity(0.25),
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
                            : AppColors.screenTextSecondary,
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
                            ? AppColors.shopBlue
                            : isCompleted
                            ? Colors.green
                            : AppColors.screenTextSecondary,
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
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.screenTextPrimary,
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
            color: AppColors.shopBlueSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.shopBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (onSearchPressed != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.screenDivider),
            ),
            child: IconButton(
              onPressed: onSearchPressed,
              icon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.screenTextSecondary,
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
      color: AppColors.shopBlueSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.shopBlue,
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
    backgroundColor: AppColors.screenCard,
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
            color: AppColors.shopBlueSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 34,
            color: AppColors.shopBlue.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.screenTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildSkipState(String title, String subtitle, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.shopBlueSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.shopBlue.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.shopBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.shopBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.shopBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.shopBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Appuyez sur Suivant pour continuer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.shopBlue,
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
                        color: AppColors.screenCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.screenShadow,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: _reservation!.status
                            ? Border.all(
                                color: AppColors.shopBlue.withOpacity(0.3),
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
                                  ? AppColors.shopBlue
                                  : AppColors.screenTextSecondary,
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
                                  ? AppColors.shopBlue
                                  : AppColors.screenTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _reservation!.status
                                ? 'Une déduction sera appliquée au montant total'
                                : 'Aucune déduction ne sera appliquée',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.screenTextSecondary,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shopBlue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.shopBlue.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
      color: AppColors.screenCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: AppColors.screenShadow,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.shopBlueSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.shopBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.shopBlue,
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
                  color: isBold
                      ? AppColors.screenTextPrimary
                      : AppColors.screenTextSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold
                    ? AppColors.shopGreen
                    : AppColors.screenTextPrimary,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: _currentPageIndex > 0
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          children: [
            if (_currentPageIndex > 0)
              GestureDetector(
                onTap: _prevStep,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.screenDivider),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 14,
                        color: AppColors.screenTextSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Précédent',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isLast)
              GestureDetector(
                onTap: canNext ? _nextStep : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: canNext
                        ? const LinearGradient(
                            colors: [
                              AppColors.shopBlueLight,
                              AppColors.shopBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade300,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: canNext
                        ? [
                            BoxShadow(
                              color: AppColors.shopBlue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isSecondToLast ? 'Récap' : 'Suivant',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: canNext ? Colors.white : Colors.grey.shade500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: canNext ? Colors.white : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            if (isLast)
              GestureDetector(
                onTap: _effectuerInscription,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shopBlue.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Confirmer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
      backgroundColor: AppColors.pureWhite,
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
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.screenTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sous-titre
                  Text(
                    '${widget.child.firstName} est déjà inscrit(e) pour '
                    "l'année scolaire en cours dans cet établissement.",
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.screenTextSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Carte de détails
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.screenCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.screenShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // En-tête carte
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.shopBlueSurface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(19),
                              topRight: Radius.circular(19),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.person_rounded,
                                color: AppColors.shopBlue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Détails de l\'inscription',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.shopBlue,
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
                                    const Text(
                                      'Statut',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.screenTextSecondary,
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
                      color: AppColors.shopBlueSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.shopBlue,
                          size: 16,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Si vous pensez que c'est une erreur, "
                            "contactez l'administration de l'école.",
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
                  const SizedBox(height: 32),

                  // Bouton retour
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shopBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SOUMISSION ────────────────────────────────────────────────────────────

  Future<void> _effectuerInscription() async {
    final List<Map<String, dynamic>> ids = [];

    final echeancesScol = _echeancesScolarite
        .where((e) => e.selectionnee)
        .toList();
    if (echeancesScol.isNotEmpty) {
      ids.add({
        'id': 'SCO',
        'service': 'Scolarité',
        'montant': _totalScolarite,
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
    if (_selectedZone != null && hasTransService) {
      ids.add({
        'id': _selectedZone!.idzone,
        'service': 'Transport',
        'montant': _totalTransport,
        'echeancesServicesSelectionnees': [],
      });
    }

    try {
      await InscriptionApiService.submitInscription(
        matricule: _matricule,
        ecoleCode: _ecoleCode,
        payload: InscriptionPayload(ids: ids),
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

  // ─── BUILD PRINCIPAL ───────────────────────────────────────────────────────

  /// Construit l'écran affiché lorsque les périodes d'inscription sont fermées
  Widget _buildPeriodsClosedScreen() {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
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
                      color: AppColors.shopBlueSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 60,
                      color: AppColors.shopBlue,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre principal
                  Text(
                    'Périodes d\'inscription fermées',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.screenTextPrimary,
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
                      color: AppColors.screenTextSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Carte d'information
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.shopBlueSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.shopBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.shopBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Que faire ?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.shopBlue,
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
                            color: AppColors.screenTextSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton de retour
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shopBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'écran affiché lorsqu'une erreur critique survient
  Widget _buildCriticalErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
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
                      color: AppColors.screenTextPrimary,
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
                      color: AppColors.screenTextSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Carte d'assistance
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
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
                            color: AppColors.screenTextSecondary,
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasCriticalError = false;
                              _criticalErrorMessage = null;
                              _isInitialLoading = true;
                            });
                            _initializeStudentData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shopBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Réessayer',
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
                            foregroundColor: AppColors.screenTextSecondary,
                            side: BorderSide(
                              color: AppColors.screenDivider,
                              width: 1,
                            ),
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
      backgroundColor: AppColors.pureWhite,
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
      backgroundColor: AppColors.pureWhite,
      body: Stack(
        children: [
          CustomScrollView(
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }
}
