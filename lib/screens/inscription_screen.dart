import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../models/child.dart';
import '../widgets/custom_loader.dart';
import '../services/ecole_eleve_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── CONSTANTES ──────────────────────────────────────────────────────────────
const String kEcoleCode = 'gainhs';
const String kBaseUrl = 'https://api2.vie-ecoles.com/api';

// ─── MODÈLES ──────────────────────────────────────────────────────────────────

class EcheanceScolarite {
  final int echId;
  final String uid;
  final String branche;
  final String statut;
  final String rubrique;
  final String pecheance;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final int ordre;
  final int rubriqueObligatoire;
  bool selectionnee;

  EcheanceScolarite({
    required this.echId,
    required this.uid,
    required this.branche,
    required this.statut,
    required this.rubrique,
    required this.pecheance,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.ordre,
    required this.rubriqueObligatoire,
    bool? selectionnee,
  }) : selectionnee = selectionnee ?? (rubriqueObligatoire == 1);

  factory EcheanceScolarite.fromJson(Map<String, dynamic> json) {
    return EcheanceScolarite(
      echId: json['ech_id'],
      uid: json['uid'],
      branche: json['branche'],
      statut: json['statut'],
      rubrique: json['rubrique'],
      pecheance: json['pecheance'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      ordre: json['ordre'],
      rubriqueObligatoire: json['rubrique_obligatoire'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ech_id': echId,
    'uid': uid,
    'branche': branche,
    'statut': statut,
    'rubrique': rubrique,
    'pecheance': pecheance,
    'montant': montant,
    'montant2': montant2,
    'datelimite': dateLimite,
    'libelle': libelle,
    'ordre': ordre,
    'rubrique_obligatoire': rubriqueObligatoire,
  };
}

class Service {
  final String iddetail;
  final String service;
  final String? zoneId;
  final String designation;
  final String description;
  final int prix;
  final int prix2;
  final String maitre;
  bool selectionnee;

  Service({
    required this.iddetail,
    required this.service,
    this.zoneId,
    required this.designation,
    required this.description,
    required this.prix,
    required this.prix2,
    required this.maitre,
    this.selectionnee = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      iddetail: json['iddetail'],
      service: json['service'],
      zoneId: json['zone_id'],
      designation: json['designation'],
      description: json['description'],
      prix: json['prix'],
      prix2: json['prix2'],
      maitre: json['maitre'],
    );
  }
}

class EcheanceService {
  final int idfrais;
  final String rubrique;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final String codeRubrique;
  bool selectionnee;

  EcheanceService({
    required this.idfrais,
    required this.rubrique,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.codeRubrique,
    this.selectionnee = true,
  });

  factory EcheanceService.fromJson(Map<String, dynamic> json) {
    return EcheanceService(
      idfrais: json['idfrais'],
      rubrique: json['rubrique'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      codeRubrique: json['coderubrique'],
    );
  }

  Map<String, dynamic> toJson() => {
    'idfrais': idfrais,
    'rubrique': rubrique,
    'montant': montant,
    'montant2': montant2,
    'datelimite': dateLimite,
    'libelle': libelle,
    'coderubrique': codeRubrique,
  };
}

class ZoneTransport {
  final String idzone;
  final String serviceId;
  final String code;
  final String zone;

  ZoneTransport({
    required this.idzone,
    required this.serviceId,
    required this.code,
    required this.zone,
  });

  factory ZoneTransport.fromJson(Map<String, dynamic> json) {
    return ZoneTransport(
      idzone: json['idzone'],
      serviceId: json['service_id'],
      code: json['code'],
      zone: json['zone'],
    );
  }
}

class PointArret {
  final String id;
  final String service;
  final String zoneId;
  final String designation;
  final String description;
  final int prix;

  PointArret({
    required this.id,
    required this.service,
    required this.zoneId,
    required this.designation,
    required this.description,
    required this.prix,
  });

  factory PointArret.fromJson(Map<String, dynamic> json) {
    return PointArret(
      id: json['id'],
      service: json['service'],
      zoneId: json['zone_id'],
      designation: json['designation'],
      description: json['description'],
      prix: json['prix'],
    );
  }
}

class ReservationStatus {
  final int sommeReservation;
  final bool status;

  ReservationStatus({required this.sommeReservation, required this.status});

  factory ReservationStatus.fromJson(Map<String, dynamic> json) {
    return ReservationStatus(
      sommeReservation: json['somme_reservation'],
      status: json['status'],
    );
  }
}

// ─── ÉCRAN WIZARD ─────────────────────────────────────────────────────────────

class InscriptionWizardScreen extends StatefulWidget {
  final Child child;

  const InscriptionWizardScreen({Key? key, required this.child})
    : super(key: key);

  @override
  _InscriptionWizardScreenState createState() =>
      _InscriptionWizardScreenState();
}

class _InscriptionWizardScreenState extends State<InscriptionWizardScreen>
    with TickerProviderStateMixin {
  // ── État du wizard ──────────────────────────────────────────────────────────
  int _currentStep = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // ── Paramètres de l'école ─────────────────────────────────────────────────────
  bool _servicesEnabled = true;

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

  List<PointArret> _pointsArret = [];
  bool _loadingPointsArret = false;
  PointArret? _selectedPointArret;

  // ── Contrôleurs de recherche ──────────────────────────────────────────────
  final TextEditingController _serviceSearchController = TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();
  final TextEditingController _pointArretSearchController = TextEditingController();

  // ── Listes filtrées ──────────────────────────────────────────────────────
  List<Service> get _filteredServices {
    if (_serviceSearchController.text.isEmpty) return _services;
    return _services.where((s) =>
      s.designation.toLowerCase().contains(_serviceSearchController.text.toLowerCase()) ||
      s.description.toLowerCase().contains(_serviceSearchController.text.toLowerCase()),
    ).toList();
  }

  List<ZoneTransport> get _filteredZones {
    if (_zoneSearchController.text.isEmpty) return _zones;
    return _zones.where((z) =>
      z.zone.toLowerCase().contains(_zoneSearchController.text.toLowerCase()),
    ).toList();
  }

  List<PointArret> get _filteredPointsArret {
    if (_pointArretSearchController.text.isEmpty) return _pointsArret;
    return _pointsArret.where((p) =>
      p.designation.toLowerCase().contains(_pointArretSearchController.text.toLowerCase()) ||
      p.description.toLowerCase().contains(_pointArretSearchController.text.toLowerCase()),
    ).toList();
  }

  String get _matricule => widget.child.matricule ?? '67894F';
  String get _brancheId => '0ad39320077a43398034945642986e91';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEcoleParams();
      }
    });
  }
  
  Future<void> _loadEcoleParams() async {
    try {
      final ecoleCode = widget.child.ecoleCode ?? kEcoleCode;
      final ecoleData = await EcoleEleveService.getEcoleParametresForEleve(ecoleCode);
      if (mounted) {
        setState(() {
          _servicesEnabled = ecoleData.serviceExtra == 1;
        });
        _loadScolarite();
      }
    } catch (e) {
      if (mounted) {
        _loadScolarite(); // Charger quand même en cas d'erreur
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _serviceSearchController.dispose();
    _zoneSearchController.dispose();
    _pointArretSearchController.dispose();
    super.dispose();
  }

  // ─── API CALLS ──────────────────────────────────────────────────────────────

  Future<Map<String, bool>> _checkInscriptionPeriods() async {
    final ecoleCode = widget.child.ecoleCode ?? kEcoleCode;
    var ecoleData = EcoleEleveService.getEcoleDataFromCache(ecoleCode);
    if (ecoleData == null) {
      try {
        ecoleData = await EcoleEleveService.getEcoleParametresForEleve(ecoleCode);
      } catch (e) {
        return {'preinscription': false, 'inscription': false, 'reservation': false};
      }
    }
    return EcoleEleveService.getStatutsInscription(ecoleData);
  }

  Future<void> _loadScolarite() async {
    setState(() => _loadingScolarite = true);
    try {
      final statuts = await _checkInscriptionPeriods();
      if (statuts['preinscription'] != true &&
          statuts['inscription'] != true &&
          statuts['reservation'] != true) {
        _showError('Aucune période d\'inscription n\'est actuellement ouverte pour cette école.');
        setState(() => _loadingScolarite = false);
        return;
      }
      final ecoleCode = widget.child.ecoleCode ?? kEcoleCode;
      final systemeEducatif = ecoleCode.startsWith('*annour*') ? 2 : 1;
      final uid = _brancheId;
      final url = '$kBaseUrl/preinscription/scolarite/branche/$uid?ecole=$ecoleCode&systeme_educatif=$systemeEducatif';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _echeancesScolarite = data.map((e) => EcheanceScolarite.fromJson(e)).toList();
        });
        _fadeController.forward();
      } else {
        _showError('Erreur lors du chargement des données de scolarité: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Erreur chargement scolarité: $e');
    } finally {
      setState(() => _loadingScolarite = false);
    }
  }

  Future<void> _loadReservation() async {
    setState(() => _loadingReservation = true);
    try {
      final url = '$kBaseUrl/vie-ecoles/reservation/eleve/$_matricule';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200 || response.statusCode == 500) {
        setState(() { _reservation = ReservationStatus.fromJson(jsonDecode(response.body)); });
      } else {
        setState(() { _reservation = ReservationStatus(sommeReservation: 0, status: false); });
      }
    } catch (e) {
      setState(() { _reservation = ReservationStatus(sommeReservation: 0, status: false); });
    } finally {
      setState(() => _loadingReservation = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final url = '$kBaseUrl/preinscription/services?ecole=$kEcoleCode';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() { _services = data.map((e) => Service.fromJson(e)).toList(); });
      }
    } catch (e) {
      _showError('Erreur chargement services: $e');
    } finally {
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadEcheancesService(String serviceId) async {
    setState(() => _loadingEcheancesService = true);
    try {
      final url = '$kBaseUrl/preinscription/service/echeances/$serviceId?ecole=$kEcoleCode';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() { _echeancesService = data.map((e) => EcheanceService.fromJson(e)).toList(); });
      }
    } catch (e) {
      _showError('Erreur chargement échéancier: $e');
    } finally {
      setState(() => _loadingEcheancesService = false);
    }
  }

  void _selectFirstEcheanceByDefault() {
    if (_echeancesService.isNotEmpty) {
      setState(() {
        for (var e in _echeancesService) { e.selectionnee = false; }
        _echeancesService.first.selectionnee = true;
      });
    }
  }

  Future<void> _loadEcheancesForSelectedServices() async {
    final selectedServices = _services.where((s) => s.selectionnee).toList();
    if (selectedServices.isEmpty) {
      setState(() { _echeancesService = []; });
      return;
    }
    setState(() => _loadingEcheancesService = true);
    try {
      final allEcheances = <EcheanceService>[];
      for (final service in selectedServices) {
        await _loadEcheancesService(service.iddetail);
        allEcheances.addAll(_echeancesService);
      }
      setState(() { _echeancesService = allEcheances; });
      _selectFirstEcheanceByDefault();
    } catch (e) {
      _showError('Erreur chargement échéancier: $e');
    } finally {
      setState(() => _loadingEcheancesService = false);
    }
  }

  Future<void> _loadZones() async {
    setState(() => _loadingZones = true);
    try {
      final url = '$kBaseUrl/preinscription/service/zones?ecole=$kEcoleCode';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() { _zones = data.map((e) => ZoneTransport.fromJson(e)).toList(); });
      }
    } catch (e) {
      _showError('Erreur chargement zones: $e');
    } finally {
      setState(() => _loadingZones = false);
    }
  }

  Future<void> _loadPointsArret(String zoneId) async {
    setState(() => _loadingPointsArret = true);
    try {
      final url = '$kBaseUrl/preinscription/service/points_arret/$zoneId?ecole=$kEcoleCode';
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pointsArret = data.map((e) => PointArret.fromJson(e)).toList();
          _selectedPointArret = null;
        });
      }
    } catch (e) {
      _showError('Erreur chargement points d\'arrêt: $e');
    } finally {
      setState(() => _loadingPointsArret = false);
    }
  }

  // ─── NAVIGATION ─────────────────────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      var nextStep = _currentStep + 1;
      
      // Gérer les sauts d'étapes si les services sont désactivés
      if (!_servicesEnabled) {
        // Si on est à l'étape Réservation (index 1), sauter directement au Récap
        if (_currentStep == 1) {
          nextStep = _steps.length - 1; // Dernière étape (Récap)
        }
      }
      
      if (nextStep == 1 && _reservation == null) _loadReservation();
      if (nextStep == 2 && _services.isEmpty) _loadServices();
      if (nextStep == 3) _loadEcheancesForSelectedServices();
      if (nextStep == 4 && _zones.isEmpty) _loadZones();
      
      setState(() => _currentStep = nextStep);
      _pageController.animateToPage(nextStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0: // Scolarité
        return _echeancesScolarite.any((e) => e.selectionnee);
      case 1: // Réservation
        return true;
      case 2: // Services (seulement si activés)
        if (!_servicesEnabled) return true; // Toujours autorisé si services désactivés
        return true; // Services toujours autorisés
      case 3: // Échéancier (seulement si activés)
        if (!_servicesEnabled) return true; // Toujours autorisé si services désactivés
        final hasSelectedService = _services.any((s) => s.selectionnee);
        if (!hasSelectedService) return true;
        return _echeancesService.any((e) => e.selectionnee);
      case 4: // Zones (seulement si activés)
        if (!_servicesEnabled) return true; // Toujours autorisé si services désactivés
        return true;
      case 5: // Arrêt (seulement si activés)
        if (!_servicesEnabled) return true; // Toujours autorisé si services désactivés
        if (_selectedZone == null) return true;
        return _selectedPointArret != null;
      default: // Récap
        return true;
    }
  }

  // ─── CALCULS ────────────────────────────────────────────────────────────────

  int get _totalScolarite => _echeancesScolarite.where((e) => e.selectionnee).fold(0, (sum, e) => sum + e.montant);
  int get _totalServices => _echeancesService.where((e) => e.selectionnee).fold(0, (sum, e) => sum + e.montant);
  int get _totalTransport => _selectedPointArret != null ? _selectedPointArret!.prix : 0;
  int get _totalBrut => _totalScolarite + _totalServices + _totalTransport;
  int get _deductionReservation => (_reservation?.status == true) ? _reservation!.sommeReservation : 0;
  int get _totalNet => (_totalBrut - _deductionReservation).clamp(0, 999999999);

  // ─── UI HELPERS ─────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.green[500],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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

  // ── Couleur principale par étape (palette alignée cart screen) ──────────
  // On garde une teinte unique par étape mais toutes alignées avec le style
  // bleu/vert du cart screen — exit les multicolores vifs du wizard original.
  Color _stepColor(int step) {
    const colors = [
      AppColors.shopBlue,       // Scolarité
      Color(0xFF0EA5E9),        // Réservation – sky
      AppColors.shopGreen,      // Services – green
      Color(0xFF0891B2),        // Échéancier – cyan-700
      AppColors.shopBlue,       // Zones
      Color(0xFF0369A1),        // Points arrêt – blue-700
      AppColors.shopGreen,      // Récap
    ];
    return colors[step % colors.length];
  }

  List<Map<String, dynamic>> get _steps {
  final baseSteps = [
    {'label': 'Scolarité', 'icon': Icons.school_rounded},
    {'label': 'Réservation', 'icon': Icons.bookmark_rounded},
  ];
  
  final serviceSteps = _servicesEnabled ? [
    {'label': 'Services', 'icon': Icons.grid_view_rounded},
    {'label': 'Échéancier', 'icon': Icons.payment_rounded},
    {'label': 'Zones', 'icon': Icons.map_rounded},
    {'label': 'Arrêt', 'icon': Icons.directions_bus_rounded},
  ] : <Map<String, dynamic>>[];
  
  final recapStep = [
    {'label': 'Récap', 'icon': Icons.receipt_long_rounded},
  ];
  
  return [...baseSteps, ...serviceSteps, ...recapStep];
}

  // ─── APP BAR (style cart screen) ────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppColors.screenCard,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Bouton retour
              GestureDetector(
                onTap: _currentStep == 0 ? () => Navigator.of(context).pop() : _prevStep,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.screenTextPrimary),
                ),
              ),
              const SizedBox(width: 12),
              // Titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inscription – ${widget.child.firstName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Étape ${_currentStep + 1} sur ${_steps.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.shopBlueSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatAmount(_totalNet),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.shopBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROGRESS INDICATOR ──────────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: AppColors.screenDivider,
              valueColor: const AlwaysStoppedAnimation(AppColors.shopBlue),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          // Étapes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return GestureDetector(
                onTap: () {
                  if (index < _currentStep) {
                    setState(() => _currentStep = index);
                    _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }
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
                            ? AppColors.shopBlue
                            : isCurrent
                            ? AppColors.shopBlue
                            : AppColors.screenDivider,
                        boxShadow: isCurrent
                            ? [BoxShadow(color: AppColors.shopBlue.withOpacity(0.25), blurRadius: 6, spreadRadius: 1)]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : (_steps[index]['icon'] as IconData),
                        color: (isCompleted || isCurrent) ? Colors.white : AppColors.screenTextSecondary,
                        size: isCurrent ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? AppColors.shopBlue : AppColors.screenTextSecondary,
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

  // ─── SECTION LABEL (style cart bottom sheet) ─────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.screenTextPrimary,
      letterSpacing: -0.3,
    ),
  );

  // ─── STEP HEADER (simplifié, aligné cart) ────────────────────────────────────
  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.shopBlueSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.shopBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: AppColors.screenTextPrimary, letterSpacing: -0.4,
            )),
            Text(subtitle, style: const TextStyle(
              fontSize: 13, color: AppColors.screenTextSecondary,
            )),
          ],
        ),
      ],
    );
  }

  // ─── ECHÉANCE CARD (style cart item) ─────────────────────────────────────────
  Widget _buildEcheanceCard({
    required String libelle,
    required int montant,
    required String dateLimite,
    required bool selectionnee,
    required bool obligatoire,
    required VoidCallback? onToggle,
    int index = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: obligatoire ? null : onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selectionnee ? AppColors.shopBlue.withOpacity(0.4) : Colors.transparent,
              width: selectionnee ? 1.5 : 0,
            ),
            boxShadow: const [
              BoxShadow(color: AppColors.screenShadow, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Checkbox circulaire
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectionnee ? AppColors.shopBlue : Colors.transparent,
                    border: Border.all(
                      color: selectionnee ? AppColors.shopBlue : AppColors.screenDivider,
                      width: 2,
                    ),
                  ),
                  child: selectionnee
                      ? Icon(
                          obligatoire ? Icons.lock_rounded : Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(libelle, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary, letterSpacing: -0.3,
                      )),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.screenTextSecondary),
                          const SizedBox(width: 4),
                          Text('Limite : ${_formatDate(dateLimite)}', style: const TextStyle(
                            fontSize: 11, color: AppColors.screenTextSecondary,
                          )),
                          if (obligatoire) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Obligatoire', style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red,
                              )),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(_formatAmount(montant), style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.shopGreen,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return CustomLoader(
      message: message,
      loaderColor: AppColors.shopBlue,
      backgroundColor: AppColors.screenCard,
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.shopBlueSurface, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.shopBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(fontSize: 14, color: AppColors.screenTextSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSkipState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.shopBlueSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shopBlue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.shopBlue.withOpacity(0.12), shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.shopBlue.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.shopBlue,
          )),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.shopBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Appuyez sur Suivant pour continuer',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.shopBlue)),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH FIELD (style cart) ───────────────────────────────────────────────
  Widget _buildSearchField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: AppColors.screenTextPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          prefixIcon: const Icon(Icons.search, color: AppColors.screenTextSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── COUNT BADGE ─────────────────────────────────────────────────────────────
  Widget _buildCountBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.shopBlueSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.shopBlue,
      )),
    );
  }

  // ─── ÉTAPES ─────────────────────────────────────────────────────────────────

  // ÉTAPE 1 – Scolarité
  Widget _buildStep1() {
    if (_loadingScolarite) return _buildLoadingState('Chargement de la scolarité...');
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Scolarité', 'Frais scolaires pour ${widget.child.firstName}', Icons.school_rounded),
            const SizedBox(height: 20),
            Row(
              children: [
                _sectionLabel('Échéancier scolaire'),
                const Spacer(),
                _buildCountBadge(_formatAmount(_totalScolarite)),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(color: AppColors.screenDivider, height: 20),
            if (_echeancesScolarite.isEmpty)
              _buildEmptyState('Aucune échéance disponible', Icons.info_outline)
            else
              ..._echeancesScolarite.asMap().entries.map((entry) => _buildEcheanceCard(
                libelle: entry.value.libelle,
                montant: entry.value.montant,
                dateLimite: entry.value.dateLimite,
                selectionnee: entry.value.selectionnee,
                obligatoire: entry.value.rubriqueObligatoire == 1,
                onToggle: () => setState(() => entry.value.selectionnee = !entry.value.selectionnee),
                index: entry.key,
              )),
            if (_echeancesScolarite.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.shopBlueSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_rounded, size: 15, color: AppColors.shopBlue),
                    const SizedBox(width: 8),
                    const Text('Classe : ', style: TextStyle(fontSize: 13, color: AppColors.screenTextSecondary)),
                    Text(_echeancesScolarite.first.branche, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.shopBlue,
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ÉTAPE 2 – Réservation
  Widget _buildStep2() {
    if (_loadingReservation) return _buildLoadingState('Vérification de la réservation...');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _buildStepHeader('Réservation', 'Statut de votre réservation', Icons.bookmark_rounded),
          const SizedBox(height: 4),
          const Divider(color: AppColors.screenDivider, height: 24),
          Expanded(
            child: Center(
              child: _reservation == null
                ? _buildEmptyState('Impossible de charger les infos réservation', Icons.error_outline)
                : Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.screenCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 6, offset: Offset(0, 2))],
                    border: _reservation!.status
                        ? Border.all(color: AppColors.shopBlue.withOpacity(0.3))
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: _reservation!.status ? AppColors.shopBlueSurface : AppColors.screenSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _reservation!.status ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                          size: 34,
                          color: _reservation!.status ? AppColors.shopBlue : AppColors.screenTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _reservation!.status ? 'Réservation active' : 'Aucune réservation',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: _reservation!.status ? AppColors.shopBlue : AppColors.screenTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _reservation!.status
                            ? 'Une déduction sera appliquée au montant total'
                            : 'Aucune déduction ne sera appliquée',
                        style: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                      if (_reservation!.status && _reservation!.sommeReservation > 0) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.shopBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.remove_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Déduction : ${_formatAmount(_reservation!.sommeReservation)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
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

  // ÉTAPE 3 – Services disponibles
  Widget _buildStep3() {
    if (_loadingServices) return _buildLoadingState('Chargement des services...');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Services', 'Sélectionnez les services souhaités', Icons.grid_view_rounded),
          const SizedBox(height: 4),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildSearchField(_serviceSearchController, 'Rechercher un service...'),
          const SizedBox(height: 16),
          if (_filteredServices.isEmpty)
            _buildEmptyState('Aucun service trouvé', Icons.search_off)
          else ...[
            Row(
              children: [
                _sectionLabel('Services disponibles'),
                const Spacer(),
                _buildCountBadge('${_services.where((s) => s.selectionnee).length} sélectionné(s)'),
              ],
            ),
            const SizedBox(height: 12),
            ..._filteredServices.asMap().entries.map((entry) => _buildServiceCard(entry.value, entry.key)),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service, int index) {
    const color = AppColors.shopBlue;
    final iconData = service.service == 'CANTINE'
        ? Icons.restaurant_rounded
        : service.service == 'TRANS'
        ? Icons.directions_bus_rounded
        : Icons.school_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() { service.selectionnee = !service.selectionnee; });
          if (service.selectionnee) _loadEcheancesForSelectedServices();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: service.selectionnee ? color.withOpacity(0.35) : Colors.transparent,
              width: service.selectionnee ? 1.5 : 0,
            ),
            boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: service.selectionnee ? AppColors.shopBlueSurface : AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData,
                  color: service.selectionnee ? color : AppColors.screenTextSecondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.designation, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary, letterSpacing: -0.3,
                    )),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.shopBlueSurface, borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(service.service, style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.shopBlue,
                      )),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatAmount(service.prix), style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.shopGreen,
                  )),
                  const SizedBox(height: 4),
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: service.selectionnee ? color : Colors.transparent,
                      border: Border.all(
                        color: service.selectionnee ? color : AppColors.screenDivider, width: 2,
                      ),
                    ),
                    child: service.selectionnee
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ÉTAPE 4 – Échéancier services
  Widget _buildStep4() {
    if (!_services.any((s) => s.selectionnee)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildStepHeader('Échéancier', 'Aucun service sélectionné', Icons.payment_rounded),
            const SizedBox(height: 4),
            const Divider(color: AppColors.screenDivider, height: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSkipState('Aucun service sélectionné', 'Vous pouvez passer à l\'étape suivante', Icons.payment_rounded),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (_loadingEcheancesService) return _buildLoadingState('Chargement de l\'échéancier...');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _buildStepHeader('Échéancier', 'Échéancier des services sélectionnés', Icons.payment_rounded),
          const SizedBox(height: 4),
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
                ? Center(child: _buildEmptyState('Aucune échéance disponible', Icons.info_outline))
                : SingleChildScrollView(
                    child: Column(
                      children: _echeancesService.asMap().entries.map((entry) => _buildEcheanceCard(
                        libelle: entry.value.libelle,
                        montant: entry.value.montant,
                        dateLimite: entry.value.dateLimite,
                        selectionnee: entry.value.selectionnee,
                        obligatoire: false,
                        onToggle: () => setState(() => entry.value.selectionnee = !entry.value.selectionnee),
                        index: entry.key,
                      )).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ÉTAPE 5 – Zones
  Widget _buildStep5() {
    if (_loadingZones) return _buildLoadingState('Chargement des zones...');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Zone de transport', 'Sélectionnez votre zone (optionnel)', Icons.map_rounded),
          const SizedBox(height: 4),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildSearchField(_zoneSearchController, 'Rechercher une zone...'),
          const SizedBox(height: 16),
          if (_zones.isEmpty)
            _buildEmptyState('Aucune zone disponible', Icons.info_outline)
          else if (_filteredZones.isEmpty)
            _buildEmptyState('Aucune zone trouvée', Icons.search_off)
          else
            ..._filteredZones.asMap().entries.map((entry) => _buildZoneCard(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildZoneCard(ZoneTransport zone, int index) {
    final isSelected = _selectedZone?.idzone == zone.idzone;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() { _selectedZone = zone; _pointsArret = []; _selectedPointArret = null; });
          _loadPointsArret(zone.idzone);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.shopBlue.withOpacity(0.35) : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.shopBlueSurface : AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded,
                  color: isSelected ? AppColors.shopBlue : AppColors.screenTextSecondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.zone, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary, letterSpacing: -0.3,
                    )),
                    Text('Code : ${zone.code}', style: const TextStyle(
                      fontSize: 12, color: AppColors.screenTextSecondary,
                    )),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.shopBlue),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ÉTAPE 6 – Points d'arrêt
  Widget _buildStep6() {
    if (_selectedZone == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildStepHeader('Point d\'arrêt', 'Sélectionnez d\'abord une zone', Icons.directions_bus_rounded),
            const SizedBox(height: 4),
            const Divider(color: AppColors.screenDivider, height: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSkipState(
                    'Aucune zone sélectionnée',
                    'Retournez à l\'étape précédente pour choisir une zone, ou passez cette étape',
                    Icons.map_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (_loadingPointsArret) return _buildLoadingState('Chargement des points d\'arrêt...');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _buildStepHeader('Point d\'arrêt', 'Zone : ${_selectedZone!.zone}', Icons.directions_bus_rounded),
          const SizedBox(height: 4),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildSearchField(_pointArretSearchController, 'Rechercher un point d\'arrêt...'),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredPointsArret.isEmpty
                ? Center(child: _buildEmptyState('Aucun point d\'arrêt trouvé', Icons.search_off))
                : SingleChildScrollView(
                    child: Column(
                      children: _filteredPointsArret.asMap().entries.map((entry) => _buildPointArretCard(entry.value, entry.key)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointArretCard(PointArret point, int index) {
    final isSelected = _selectedPointArret?.id == point.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: () => setState(() { _selectedPointArret = point; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.shopBlue.withOpacity(0.35) : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.shopBlueSurface : AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.stop_circle_rounded,
                  color: isSelected ? AppColors.shopBlue : AppColors.screenTextSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(point.designation, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.screenTextPrimary,
                )),
              ),
              Text(_formatAmount(point.prix), style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.shopGreen,
              )),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded, color: AppColors.shopBlue, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ÉTAPE 7 – Récapitulatif
  Widget _buildRecap() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Récapitulatif', 'Vérifiez et confirmez votre inscription', Icons.receipt_long_rounded),
          const SizedBox(height: 4),
          const Divider(color: AppColors.screenDivider, height: 24),

          // Élève
          _buildRecapSection(title: 'Élève', icon: Icons.person_rounded,
            child: _buildRecapRow('Nom', widget.child.firstName)),
          const SizedBox(height: 12),

          // Scolarité
          if (_echeancesScolarite.any((e) => e.selectionnee)) ...[
            _buildRecapSection(
              title: 'Scolarité', icon: Icons.school_rounded,
              child: Column(children: [
                ..._echeancesScolarite.where((e) => e.selectionnee)
                  .map((e) => _buildRecapRow(e.libelle, _formatAmount(e.montant))),
                const Divider(height: 16, color: AppColors.screenDivider),
                _buildRecapRow('Sous-total', _formatAmount(_totalScolarite), isBold: true),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Services
          if (_echeancesService.any((e) => e.selectionnee)) ...[
            _buildRecapSection(
              title: 'Services', icon: Icons.payment_rounded,
              child: Column(children: [
                ..._echeancesService.where((e) => e.selectionnee)
                  .map((e) => _buildRecapRow(e.libelle, _formatAmount(e.montant))),
                const Divider(height: 16, color: AppColors.screenDivider),
                _buildRecapRow('Sous-total', _formatAmount(_totalServices), isBold: true),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Transport
          if (_selectedPointArret != null) ...[
            _buildRecapSection(
              title: 'Transport', icon: Icons.directions_bus_rounded,
              child: Column(children: [
                if (_selectedZone != null) _buildRecapRow('Zone', _selectedZone!.zone),
                _buildRecapRow('Point d\'arrêt', _selectedPointArret!.designation),
                const Divider(height: 16, color: AppColors.screenDivider),
                _buildRecapRow('Sous-total', _formatAmount(_totalTransport), isBold: true),
              ]),
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
                  const Icon(Icons.bookmark_added_rounded, color: AppColors.shopBlue, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Déduction réservation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.shopBlue))),
                  Text('- ${_formatAmount(_deductionReservation)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.shopBlue)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Total final (style checkout summary cart)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: AppColors.shopBlue.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 14),
                const Expanded(child: Text('TOTAL À PAYER', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white70, letterSpacing: 0.5,
                ))),
                Text(_formatAmount(_totalNet), style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: -0.5,
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildConfirmButton(),
          const SizedBox(height: 12),
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
                Expanded(child: Text(
                  'L\'inscription sera confirmée après validation par l\'administration.',
                  style: TextStyle(fontSize: 12, color: AppColors.shopBlue, fontWeight: FontWeight.w500),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.shopBlue, size: 16),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.shopBlue,
                )),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.screenTextPrimary : AppColors.screenTextSecondary,
          ))),
          Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppColors.shopGreen : AppColors.screenTextPrimary,
          )),
        ],
      ),
    );
  }

  // ─── BOUTON CONFIRM (aligné _buildOrangeButton du cart) ──────────────────────
  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _effectuerInscription,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.shopBlueLight, AppColors.shopBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: AppColors.shopBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Confirmer l\'inscription', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.2,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NAVIGATION BUTTONS (style checkout bar cart) ────────────────────────────
  Widget _buildNavigationButtons() {
    final canNext = _canGoNext();
    final isLastStep = _currentStep == _steps.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.screenSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.screenDivider),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios_new, size: 15, color: AppColors.screenTextSecondary),
                          SizedBox(width: 6),
                          Text('Précédent', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.screenTextSecondary,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!isLastStep)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: canNext ? _nextStep : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: canNext
                            ? const LinearGradient(
                                colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              )
                            : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canNext
                            ? [BoxShadow(color: AppColors.shopBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentStep == _steps.length - 2 ? 'Voir le récapitulatif' : 'Suivant',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: canNext ? Colors.white : Colors.grey.shade500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18,
                              color: canNext ? Colors.white : Colors.grey.shade500),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SOUMISSION ─────────────────────────────────────────────────────────────

  Future<void> _effectuerInscription() async {
    final List<Map<String, dynamic>> ids = [];

    final echeancesScol = _echeancesScolarite.where((e) => e.selectionnee).toList();
    if (echeancesScol.isNotEmpty) {
      ids.add({
        'id': 'SCO', 'service': 'Scolarité', 'montant': _totalScolarite,
        'reservation': _reservation?.status ?? false,
        'echeances_selectionnees': echeancesScol.map((e) => e.toJson()).toList(),
      });
    }

    final selectedServices = _services.where((s) => s.selectionnee).toList();
    final echeancesServices = _echeancesService.where((e) => e.selectionnee).toList();
    if (echeancesServices.isNotEmpty && selectedServices.isNotEmpty) {
      for (final service in selectedServices) {
        final serviceEcheances = echeancesServices.where((e) => e.codeRubrique == service.service).toList();
        if (serviceEcheances.isNotEmpty) {
          ids.add({
            'id': service.iddetail, 'service': service.service,
            'montant': serviceEcheances.fold(0, (sum, e) => sum + e.montant),
            'reservation': false,
            'echeances_selectionnees': serviceEcheances.map((e) => e.toJson()).toList(),
          });
        }
      }
    }

    if (_selectedPointArret != null) {
      ids.add({
        'id': _selectedPointArret!.id, 'service': 'Transport',
        'montant': _totalTransport, 'reservation': false, 'echeances_selectionnees': [],
      });
    }

    final body = {
      'ids': ids, 'engagement': {}, 'type': 'préinscription',
      'separation_flux': 0, 'systeme_educatif': 1,
    };

    try {
      final url = '$kBaseUrl/vie-ecoles/inscription-eleve/$_matricule?ecole=$kEcoleCode';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        Navigator.of(context).pop();
        _showSuccess('Inscription de ${widget.child.firstName} enregistrée avec succès !');
      } else if (mounted) {
        String errorMessage = 'Erreur lors de l\'inscription';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}
        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted) _showError('Erreur réseau : $e');
    }
  }

  // ─── BUILD PRINCIPAL ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: Column(
        children: [
          _buildAppBar(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                if (_servicesEnabled) ...[
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                  _buildStep6(),
                ],
                _buildRecap(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}