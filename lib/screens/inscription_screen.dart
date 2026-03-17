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

  ReservationStatus({
    required this.sommeReservation,
    required this.status,
  });

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

  const InscriptionWizardScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _InscriptionWizardScreenState createState() => _InscriptionWizardScreenState();
}

class _InscriptionWizardScreenState extends State<InscriptionWizardScreen>
    with TickerProviderStateMixin {
  // ── État du wizard ──────────────────────────────────────────────────────────
  int _currentStep = 0;
  final int _totalSteps = 7; // Réduit de 8 à 7 (suppression étape Transport)
  late PageController _pageController;
  late AnimationController _progressController;

  // ── Données de chaque étape ─────────────────────────────────────────────────
  // Étape 1 – Scolarité
  List<EcheanceScolarite> _echeancesScolarite = [];
  bool _loadingScolarite = false;

  // Étape 2 – Réservation
  ReservationStatus? _reservation;
  bool _loadingReservation = false;

  // Étape 3 – Services disponibles
  List<Service> _services = [];
  bool _loadingServices = false;

  // Étape 4 – Échéancier service (s'affiche si un service est sélectionné)
  List<EcheanceService> _echeancesService = [];
  bool _loadingEcheancesService = false;

  // Étape 5 – Zones transport (affichées sans condition de sélection TRANS)
  List<ZoneTransport> _zones = [];
  bool _loadingZones = false;
  ZoneTransport? _selectedZone;

  // Étape 6 – Points d'arrêt
  List<PointArret> _pointsArret = [];
  bool _loadingPointsArret = false;
  PointArret? _selectedPointArret;

  // ── Contrôleurs de recherche ───────────────────────────────────────────────────
  final TextEditingController _serviceSearchController = TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();
  final TextEditingController _pointArretSearchController = TextEditingController();

  // ── Listes filtrées ───────────────────────────────────────────────────────────
  List<Service> get _filteredServices {
    if (_serviceSearchController.text.isEmpty) return _services;
    return _services.where((service) =>
      service.designation.toLowerCase().contains(_serviceSearchController.text.toLowerCase()) ||
      service.description.toLowerCase().contains(_serviceSearchController.text.toLowerCase())
    ).toList();
  }

  List<ZoneTransport> get _filteredZones {
    if (_zoneSearchController.text.isEmpty) return _zones;
    return _zones.where((zone) =>
      zone.zone.toLowerCase().contains(_zoneSearchController.text.toLowerCase())
    ).toList();
  }

  List<PointArret> get _filteredPointsArret {
    if (_pointArretSearchController.text.isEmpty) return _pointsArret;
    return _pointsArret.where((point) =>
      point.designation.toLowerCase().contains(_pointArretSearchController.text.toLowerCase()) ||
      point.description.toLowerCase().contains(_pointArretSearchController.text.toLowerCase())
    ).toList();
  }

  // NOTE: L'étape Transport (ancien _echeancesTransport) est supprimée.

  // ── Config ──────────────────────────────────────────────────────────────────
  String get _matricule => widget.child.matricule ?? '67894F';
  String get _brancheId => '0ad39320077a43398034945642986e91';

  @override
  void initState() {
    super.initState();
    print('🚀 [INIT] Démarrage écran inscription pour ${widget.child.firstName} ${widget.child.lastName}');
    print('📋 [INIT] Matricule: $_matricule, Branche: $_brancheId');
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les données après que le widget soit complètement initialisé
    // pour éviter l'erreur avec ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScolarite();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _serviceSearchController.dispose();
    _zoneSearchController.dispose();
    _pointArretSearchController.dispose();
    super.dispose();
  }

  // ─── API CALLS ──────────────────────────────────────────────────────────────
  
  /// Vérifie les périodes d'inscription et retourne le statut
  Map<String, bool> _checkInscriptionPeriods() {
    // Utiliser le code de l'école de l'élève si disponible, sinon le code par défaut
    final ecoleCode = widget.child.ecoleCode ?? kEcoleCode;
    final ecoleData = EcoleEleveService.getEcoleDataFromCache(ecoleCode);
    
    if (ecoleData != null) {
      return EcoleEleveService.getStatutsInscription(ecoleData);
    }
    
    // Retourner les valeurs par défaut si aucune donnée n'est disponible
    return {
      'preinscription': false,
      'inscription': false,
      'reservation': false,
    };
  }

  Future<void> _loadScolarite() async {
    setState(() => _loadingScolarite = true);
    
    try {
      // Vérifier d'abord si les inscriptions sont ouvertes
      final statuts = _checkInscriptionPeriods();
      print('📅 [INSCRIPTION] Statut des périodes:');
      print('   - Préinscription: ${statuts['preinscription'] == true ? 'OUVERTE' : 'FERMÉE'}');
      print('   - Inscription: ${statuts['inscription'] == true ? 'OUVERTE' : 'FERMÉE'}');
      print('   - Réservation: ${statuts['reservation'] == true ? 'OUVERTE' : 'FERMÉE'}');
      
      // Si aucune période d'inscription n'est ouverte, afficher un message
      if (statuts['preinscription'] != true && statuts['inscription'] != true && statuts['reservation'] != true) {
        print('⚠️ [INSCRIPTION] Aucune période d\'inscription ouverte');
        _showError('Aucune période d\'inscription n\'est actuellement ouverte pour cette école.');
        setState(() => _loadingScolarite = false);
        return;
      }
      
      // Utiliser l'UID de l'élève et le code de l'école
      final uid = widget.child.id; // Utiliser l'ID de l'élève comme UID
      final ecoleCode = widget.child.ecoleCode ?? kEcoleCode;
      final systemeEducatif = ecoleCode.startsWith('*annour*') ? 2 : 1;
      
      final url = '$kBaseUrl/preinscription/scolarite/branche/$uid?ecole=$ecoleCode&systeme_educatif=$systemeEducatif';
      print('🔍 [API] Chargement scolarité - URL: $url');
      print('👤 [API] UID élève: $uid');
      print('🏷️ [API] Code école: $ecoleCode');
      print('📚 [API] Système éducatif: $systemeEducatif (${systemeEducatif == 1 ? 'défaut' : 'spécial'})');
      
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse scolarité - Status: ${response.statusCode}');
      print('📄 [API] Body scolarité: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ [API] Succès scolarité - ${data.length} échéances trouvées');
        setState(() {
          _echeancesScolarite = data.map((e) => EcheanceScolarite.fromJson(e)).toList();
        });
      } else {
        print('❌ [API] Erreur scolarité - Status: ${response.statusCode}');
        _showError('Erreur lors du chargement des données de scolarité: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [API] Exception scolarité: $e');
      _showError('Erreur chargement scolarité: $e');
    } finally {
      setState(() => _loadingScolarite = false);
    }
  }

  Future<void> _loadReservation() async {
    setState(() => _loadingReservation = true);
    try {
      final url = '$kBaseUrl/vie-ecoles/reservation/eleve/$_matricule';
      print('🔍 [API] Chargement réservation - URL: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse réservation - Status: ${response.statusCode}');
      print('📄 [API] Body réservation: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 500) {
        setState(() {
          _reservation = ReservationStatus.fromJson(jsonDecode(response.body));
        });
        print('✅ [API] Succès réservation - Status: ${_reservation?.status}');
      } else {
        print('❌ [API] Erreur réservation - Status: ${response.statusCode}');
        setState(() {
          _reservation = ReservationStatus(sommeReservation: 0, status: false);
        });
      }
    } catch (e) {
      print('💥 [API] Exception réservation: $e');
      setState(() {
        _reservation = ReservationStatus(sommeReservation: 0, status: false);
      });
    } finally {
      setState(() => _loadingReservation = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final url = '$kBaseUrl/preinscription/services?ecole=$kEcoleCode';
      print('🔍 [API] Chargement services - URL: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse services - Status: ${response.statusCode}');
      print('📄 [API] Body services: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ [API] Succès services - ${data.length} services trouvés');
        setState(() {
          _services = data.map((e) => Service.fromJson(e)).toList();
        });
      } else {
        print('❌ [API] Erreur services - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [API] Exception services: $e');
      _showError('Erreur chargement services: $e');
    } finally {
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadEcheancesService(String serviceId) async {
    print('🚀 [API] Début chargement échéances service pour serviceId: $serviceId');
    setState(() => _loadingEcheancesService = true);
    try {
      final url = '$kBaseUrl/preinscription/service/echeances/$serviceId?ecole=$kEcoleCode';
      print('🔍 [API] URL requête échéances service: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse échéances service - Status: ${response.statusCode}');
      print('📄 [API] Body réponse échéances service: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final echeances = data.map((e) => EcheanceService.fromJson(e)).toList();
        print('✅ [API] Succès échéances service - ${echeances.length} échéances trouvées');
        setState(() {
          _echeancesService = echeances;
        });
      } else {
        print('❌ [API] Erreur échéances service - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [API] Exception échéances service: $e');
      _showError('Erreur chargement échéancier: $e');
    } finally {
      setState(() => _loadingEcheancesService = false);
      print('🏁 [API] Fin chargement échéances service');
    }
  }

  void _selectFirstEcheanceByDefault() {
    if (_echeancesService.isNotEmpty) {
      setState(() {
        for (var echeance in _echeancesService) {
          echeance.selectionnee = false;
        }
        _echeancesService.first.selectionnee = true;
      });
      print('✅ [UI] Première échéance sélectionnée par défaut: ${_echeancesService.first.libelle}');
    }
  }

  Future<void> _loadEcheancesForSelectedServices() async {
    final selectedServices = _services.where((s) => s.selectionnee).toList();
    print('🔄 [API] Début chargement échéances pour services sélectionnés');

    if (selectedServices.isEmpty) {
      print('⚠️ [API] Aucun service sélectionné pour échéancier');
      setState(() {
        _echeancesService = [];
      });
      return;
    }

    setState(() => _loadingEcheancesService = true);
    try {
      final allEcheances = <EcheanceService>[];

      for (final service in selectedServices) {
        print('🔄 [API] Chargement échéances pour service: ${service.designation} (ID: ${service.iddetail})');
        await _loadEcheancesService(service.iddetail);
        allEcheances.addAll(_echeancesService);
        print('📊 [API] Total échéances accumulées: ${allEcheances.length}');
      }

      setState(() {
        _echeancesService = allEcheances;
      });
      print('✅ [API] Fin chargement échéances - Total: ${allEcheances.length} échéances');
      _selectFirstEcheanceByDefault();
    } catch (e) {
      print('💥 [API] Exception échéances services: $e');
      _showError('Erreur chargement échéancier: $e');
    } finally {
      setState(() => _loadingEcheancesService = false);
    }
  }

  // Les zones sont maintenant chargées sans condition de sélection TRANS
  Future<void> _loadZones() async {
    setState(() => _loadingZones = true);
    try {
      final url = '$kBaseUrl/preinscription/service/zones?ecole=$kEcoleCode';
      print('🔍 [API] Chargement zones - URL: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse zones - Status: ${response.statusCode}');
      print('📄 [API] Body réponse zones: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final zones = data.map((e) => ZoneTransport.fromJson(e)).toList();
        print('✅ [API] Succès zones - ${zones.length} zones trouvées');
        setState(() {
          _zones = zones;
        });
      } else {
        print('❌ [API] Erreur zones - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [API] Exception zones: $e');
      _showError('Erreur chargement zones: $e');
    } finally {
      setState(() => _loadingZones = false);
    }
  }

  Future<void> _loadPointsArret(String zoneId) async {
    setState(() => _loadingPointsArret = true);
    try {
      final url = '$kBaseUrl/preinscription/service/points_arret/$zoneId?ecole=$kEcoleCode';
      print('🔍 [API] Chargement points d\'arrêt - URL: $url');
      final response = await http.get(Uri.parse(url), headers: {'Content-Type': 'application/json'});
      print('📡 [API] Réponse points d\'arrêt - Status: ${response.statusCode}');
      print('📄 [API] Body points d\'arrêt: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ [API] Succès points d\'arrêt - ${data.length} points trouvés');
        setState(() {
          _pointsArret = data.map((e) => PointArret.fromJson(e)).toList();
          _selectedPointArret = null;
        });
      } else {
        print('❌ [API] Erreur points d\'arrêt - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [API] Exception points d\'arrêt: $e');
      _showError('Erreur chargement points d\'arrêt: $e');
    } finally {
      setState(() => _loadingPointsArret = false);
    }
  }

  // ─── NAVIGATION ─────────────────────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      final nextStep = _currentStep + 1;
      if (nextStep == 1 && _reservation == null) _loadReservation();
      if (nextStep == 2 && _services.isEmpty) _loadServices();
      if (nextStep == 3) _loadEcheancesForSelectedServices();
      // Étape 5 (index 4) = Zones – chargement sans condition TRANS
      if (nextStep == 4 && _zones.isEmpty) _loadZones();

      setState(() => _currentStep = nextStep);
      _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0: // Scolarité – au moins une sélectionnée
        return _echeancesScolarite.any((e) => e.selectionnee);
      case 1: // Réservation – toujours OK
        return true;
      case 2: // Services – validation non bloquante
        return true;
      case 3: // Échéancier service
        final hasSelectedService = _services.any((s) => s.selectionnee);
        if (!hasSelectedService) return true;
        return _echeancesService.any((e) => e.selectionnee);
      case 4: // Zones – optionnel, pas bloquant
        return true;
      case 5: // Points d'arrêt – optionnel si aucune zone sélectionnée
        if (_selectedZone == null) return true;
        return _selectedPointArret != null;
      case 6: // Récapitulatif
        return true;
      default:
        return true;
    }
  }

  // ─── CALCULS ────────────────────────────────────────────────────────────────

  int get _totalScolarite => _echeancesScolarite
      .where((e) => e.selectionnee)
      .fold(0, (sum, e) => sum + e.montant);

  int get _totalServices => _echeancesService
      .where((e) => e.selectionnee)
      .fold(0, (sum, e) => sum + e.montant);

  // Transport intégré dans le point d'arrêt sélectionné
  int get _totalTransport =>
      _selectedPointArret != null ? _selectedPointArret!.prix : 0;

  int get _totalBrut => _totalScolarite + _totalServices + _totalTransport;

  int get _deductionReservation =>
      (_reservation?.status == true) ? _reservation!.sommeReservation : 0;

  int get _totalNet => (_totalBrut - _deductionReservation).clamp(0, 999999999);

  // ─── UI HELPERS ─────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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

  Color _stepColor(int step) {
    const colors = [
      Color(0xFF6366F1), // Scolarité – indigo
      Color(0xFF0EA5E9), // Réservation – sky
      Color(0xFF10B981), // Services – emerald
      Color(0xFFF59E0B), // Échéancier – amber
      Color(0xFFEC4899), // Zones – pink
      Color(0xFF8B5CF6), // Points arrêt – violet
      Color(0xFF14B8A6), // Récap – teal
    ];
    return colors[step % colors.length];
  }

  // ── Labels des étapes (7 étapes) ─────────────────────────────────────────
  List<Map<String, dynamic>> get _steps => [
    {'label': 'Scolarité', 'icon': Icons.school_rounded},
    {'label': 'Réservation', 'icon': Icons.bookmark_rounded},
    {'label': 'Services', 'icon': Icons.grid_view_rounded},
    {'label': 'Échéancier', 'icon': Icons.payment_rounded},
    {'label': 'Zones', 'icon': Icons.map_rounded},
    {'label': 'Arrêt', 'icon': Icons.directions_bus_rounded},
    {'label': 'Récap', 'icon': Icons.receipt_long_rounded},
  ];

  // ─── WIDGETS COMMUNS ────────────────────────────────────────────────────────

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    final color = _stepColor(_currentStep);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.screenTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
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
        ],
      ),
    );
  }

  Widget _buildEcheanceCard({
    required String libelle,
    required int montant,
    required String dateLimite,
    required bool selectionnee,
    required bool obligatoire,
    required VoidCallback? onToggle,
    Color? accentColor,
  }) {
    final color = accentColor ?? _stepColor(_currentStep);
    return GestureDetector(
      onTap: obligatoire ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectionnee ? color.withOpacity(0.06) : AppColors.screenSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectionnee ? color.withOpacity(0.4) : AppColors.screenDivider,
            width: selectionnee ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectionnee ? color : Colors.transparent,
                border: Border.all(
                  color: selectionnee ? color : AppColors.screenDivider,
                  width: 2,
                ),
              ),
              child: selectionnee
                  ? Icon(
                      obligatoire ? Icons.lock_rounded : Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppColors.screenTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Limite: ${_formatDate(dateLimite)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                      if (obligatoire) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Obligatoire',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _formatAmount(montant),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return CustomLoader(
      message: message,
      loaderColor: _stepColor(_currentStep),
      backgroundColor: AppColors.screenCard,
      showBackground: true,
    );
  }

  Widget _buildTotalBadge(int montant, {Color? color}) {
    final c = color ?? _stepColor(_currentStep);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        'Total: ${_formatAmount(montant)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  // ─── ÉTAPES ─────────────────────────────────────────────────────────────────

  // ÉTAPE 1 – Scolarité
  Widget _buildStep1() {
    return _loadingScolarite
        ? _buildLoadingState('Chargement de la scolarité...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Scolarité',
                  'Frais scolaires pour ${widget.child.firstName}',
                  Icons.school_rounded,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Échéancier scolaire',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildTotalBadge(_totalScolarite),
                  ],
                ),
                const SizedBox(height: 12),
                if (_echeancesScolarite.isEmpty)
                  _buildEmptyState('Aucune échéance disponible', Icons.info_outline)
                else
                  ..._echeancesScolarite.map((e) => _buildEcheanceCard(
                    libelle: e.libelle,
                    montant: e.montant,
                    dateLimite: e.dateLimite,
                    selectionnee: e.selectionnee,
                    obligatoire: e.rubriqueObligatoire == 1,
                    onToggle: () => setState(() => e.selectionnee = !e.selectionnee),
                  )),
                const SizedBox(height: 16),
                if (_echeancesScolarite.isNotEmpty)
                  _buildInfoBanner(
                    '${_echeancesScolarite.first.branche}',
                    'Classe de l\'élève',
                    Icons.class_rounded,
                    _stepColor(0),
                  ),
              ],
            ),
          );
  }

  // ÉTAPE 2 – Réservation
  Widget _buildStep2() {
    return _loadingReservation
        ? _buildLoadingState('Vérification de la réservation...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Réservation',
                  'Vérification du statut de réservation',
                  Icons.bookmark_rounded,
                ),
                const SizedBox(height: 24),
                if (_reservation == null)
                  _buildEmptyState('Impossible de charger les infos réservation', Icons.error_outline)
                else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _reservation!.status
                          ? const Color(0xFF0EA5E9).withOpacity(0.08)
                          : AppColors.screenSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _reservation!.status
                            ? const Color(0xFF0EA5E9).withOpacity(0.3)
                            : AppColors.screenDivider,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _reservation!.status
                                ? const Color(0xFF0EA5E9).withOpacity(0.15)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _reservation!.status
                                ? Icons.bookmark_added_rounded
                                : Icons.bookmark_border_rounded,
                            size: 36,
                            color: _reservation!.status
                                ? const Color(0xFF0EA5E9)
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
                                ? const Color(0xFF0EA5E9)
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
                        if (_reservation!.status && _reservation!.sommeReservation > 0) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_circle_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Déduction: ${_formatAmount(_reservation!.sommeReservation)}',
                                  style: const TextStyle(
                                    fontSize: 16,
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
                ],
              ],
            ),
          );
  }

  // ÉTAPE 3 – Services disponibles
  Widget _buildStep3() {
    return _loadingServices
        ? _buildLoadingState('Chargement des services...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Services',
                  'Sélectionnez les services souhaités',
                  Icons.grid_view_rounded,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _serviceSearchController,
                    onChanged: (value) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un service...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_filteredServices.isEmpty)
                  _buildEmptyState('Aucun service trouvé', Icons.search_off)
                else ...[
                  Row(
                    children: [
                      const Text(
                        'Services disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_services.where((s) => s.selectionnee).length} sélectionné(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._filteredServices.map((service) => _buildServiceCard(service)),
                ],
              ],
            ),
          );
  }

  Widget _buildServiceCard(Service service) {
    final color = service.service == 'CANTINE'
        ? const Color(0xFFF59E0B)
        : service.service == 'TRANS'
            ? const Color(0xFF14B8A6)
            : const Color(0xFF10B981);

    return GestureDetector(
      onTap: () {
        setState(() {
          service.selectionnee = !service.selectionnee;
        });
        if (service.selectionnee) {
          _loadEcheancesForSelectedServices();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: service.selectionnee ? color.withOpacity(0.07) : AppColors.screenSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: service.selectionnee ? color.withOpacity(0.4) : AppColors.screenDivider,
            width: service.selectionnee ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: service.selectionnee ? color.withOpacity(0.15) : AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service.service == 'CANTINE'
                    ? Icons.restaurant_rounded
                    : service.service == 'TRANS'
                        ? Icons.directions_bus_rounded
                        : Icons.school_rounded,
                color: service.selectionnee ? color : AppColors.screenTextSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.designation,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.service,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(service.prix),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.selectionnee ? color : Colors.transparent,
                    border: Border.all(
                      color: service.selectionnee ? color : AppColors.screenDivider,
                      width: 2,
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
    );
  }

  // ÉTAPE 4 – Échéancier services
  Widget _buildStep4() {
    final hasSelectedService = _services.any((s) => s.selectionnee);

    if (!hasSelectedService) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildStepHeader(
              'Échéancier',
              'Aucun service sélectionné',
              Icons.payment_rounded,
            ),
            const SizedBox(height: 40),
            _buildSkipState(
              'Aucun service sélectionné',
              'Vous pouvez passer à l\'étape suivante',
              Icons.payment_rounded,
              const Color(0xFF10B981),
            ),
          ],
        ),
      );
    }

    return _loadingEcheancesService
        ? _buildLoadingState('Chargement de l\'échéancier...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Échéancier',
                  'Échéancier des services sélectionnés',
                  Icons.payment_rounded,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Échéancier services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildTotalBadge(_totalServices, color: const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_echeancesService.isEmpty)
                  _buildEmptyState('Aucune échéance disponible', Icons.info_outline)
                else
                  ..._echeancesService.map((e) => _buildEcheanceCard(
                    libelle: e.libelle,
                    montant: e.montant,
                    dateLimite: e.dateLimite,
                    selectionnee: e.selectionnee,
                    obligatoire: false,
                    onToggle: () => setState(() => e.selectionnee = !e.selectionnee),
                    accentColor: const Color(0xFF10B981),
                  )),
              ],
            ),
          );
  }

  // ÉTAPE 5 – Zones (affichées sans condition de sélection du service TRANS)
  Widget _buildStep5() {
    return _loadingZones
        ? _buildLoadingState('Chargement des zones...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Zone de transport',
                  'Sélectionnez votre zone géographique (optionnel)',
                  Icons.map_rounded,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _zoneSearchController,
                    onChanged: (value) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une zone...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_zones.isEmpty && !_loadingZones)
                  _buildEmptyState('Aucune zone disponible', Icons.info_outline)
                else if (_filteredZones.isEmpty)
                  _buildEmptyState('Aucune zone trouvée', Icons.search_off)
                else
                  ..._filteredZones.map((zone) => _buildZoneCard(zone)),
              ],
            ),
          );
  }

  Widget _buildZoneCard(ZoneTransport zone) {
    final isSelected = _selectedZone?.idzone == zone.idzone;
    const color = Color(0xFFEC4899);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedZone = zone;
          _pointsArret = [];
          _selectedPointArret = null;
        });
        _loadPointsArret(zone.idzone);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppColors.screenSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : AppColors.screenDivider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isSelected ? color : AppColors.screenTextSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.zone,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  Text(
                    'Code: ${zone.code}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // ÉTAPE 6 – Points d'arrêt
  Widget _buildStep6() {
    // Si aucune zone n'est sélectionnée, afficher un état "optionnel"
    if (_selectedZone == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildStepHeader(
              'Point d\'arrêt',
              'Sélectionnez d\'abord une zone',
              Icons.directions_bus_rounded,
            ),
            const SizedBox(height: 40),
            _buildSkipState(
              'Aucune zone sélectionnée',
              'Retournez à l\'étape précédente pour choisir une zone, ou passez cette étape',
              Icons.map_rounded,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      );
    }

    return _loadingPointsArret
        ? _buildLoadingState('Chargement des points d\'arrêt...')
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  'Point d\'arrêt',
                  'Zone: ${_selectedZone!.zone}',
                  Icons.directions_bus_rounded,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _pointArretSearchController,
                    onChanged: (value) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un point d\'arrêt...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_filteredPointsArret.isEmpty)
                  _buildEmptyState('Aucun point d\'arrêt trouvé', Icons.search_off)
                else
                  ..._filteredPointsArret.map((point) => _buildPointArretCard(point)),
              ],
            ),
          );
  }

  Widget _buildPointArretCard(PointArret point) {
    final isSelected = _selectedPointArret?.id == point.id;
    const color = Color(0xFF8B5CF6);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPointArret = point;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.07) : AppColors.screenSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : AppColors.screenDivider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppColors.screenCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.stop_circle_rounded,
                color: isSelected ? color : AppColors.screenTextSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                point.designation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenTextPrimary,
                ),
              ),
            ),
            Text(
              _formatAmount(point.prix),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ÉTAPE 7 – Récapitulatif (ancienne étape 8)
  Widget _buildStep7() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Récapitulatif',
            'Vérifiez et confirmez votre inscription',
            Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 20),

          // Infos élève
          _buildRecapSection(
            title: 'Élève',
            color: const Color(0xFF6366F1),
            icon: Icons.person_rounded,
            child: _buildRecapRow('Nom', widget.child.firstName),
          ),

          const SizedBox(height: 14),

          // Scolarité
          if (_echeancesScolarite.any((e) => e.selectionnee))
            _buildRecapSection(
              title: 'Scolarité',
              color: const Color(0xFF6366F1),
              icon: Icons.school_rounded,
              child: Column(
                children: [
                  ..._echeancesScolarite
                      .where((e) => e.selectionnee)
                      .map((e) => _buildRecapRow(e.libelle, _formatAmount(e.montant))),
                  const Divider(height: 16),
                  _buildRecapRow('Sous-total', _formatAmount(_totalScolarite), isBold: true),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Services
          if (_echeancesService.any((e) => e.selectionnee))
            _buildRecapSection(
              title: 'Services',
              color: const Color(0xFF10B981),
              icon: Icons.payment_rounded,
              child: Column(
                children: [
                  ..._echeancesService
                      .where((e) => e.selectionnee)
                      .map((e) => _buildRecapRow(e.libelle, _formatAmount(e.montant))),
                  const Divider(height: 16),
                  _buildRecapRow('Sous-total', _formatAmount(_totalServices), isBold: true),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Transport (point d'arrêt sélectionné)
          if (_selectedPointArret != null)
            _buildRecapSection(
              title: 'Transport',
              color: const Color(0xFF14B8A6),
              icon: Icons.directions_bus_rounded,
              child: Column(
                children: [
                  if (_selectedZone != null)
                    _buildRecapRow('Zone', _selectedZone!.zone),
                  _buildRecapRow('Point d\'arrêt', _selectedPointArret!.designation),
                  const Divider(height: 16),
                  _buildRecapRow('Sous-total', _formatAmount(_totalTransport), isBold: true),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Réservation
          if (_reservation?.status == true && _deductionReservation > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_added_rounded,
                      color: Color(0xFF0EA5E9), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Déduction réservation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                  Text(
                    '- ${_formatAmount(_deductionReservation)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Total final
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'TOTAL À PAYER',
                    style: TextStyle(
                      fontSize: 14,
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

          const SizedBox(height: 24),

          _buildConfirmButton(),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'L\'inscription sera confirmée après validation par l\'administration.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
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
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
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
              color: AppColors.screenTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _effectuerInscription,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Confirmer l\'inscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── États vides / skip ────────────────────────────────────────────────────

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.screenTextSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.screenTextSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipState(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Appuyez sur Suivant pour continuer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SOUMISSION ─────────────────────────────────────────────────────────────

  Future<void> _effectuerInscription() async {
    final List<Map<String, dynamic>> ids = [];

    // Scolarité
    final echeancesScol = _echeancesScolarite.where((e) => e.selectionnee).toList();
    if (echeancesScol.isNotEmpty) {
      ids.add({
        'id': 'SCO',
        'service': 'Scolarité',
        'montant': _totalScolarite,
        'reservation': _reservation?.status ?? false,
        'echeances_selectionnees': echeancesScol.map((e) => e.toJson()).toList(),
      });
    }

    // Services
    final selectedServices = _services.where((s) => s.selectionnee).toList();
    final echeancesServices = _echeancesService.where((e) => e.selectionnee).toList();
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
            'reservation': false,
            'echeances_selectionnees': serviceEcheances.map((e) => e.toJson()).toList(),
          });
        }
      }
    }

    // Transport (point d'arrêt sélectionné)
    if (_selectedPointArret != null) {
      ids.add({
        'id': _selectedPointArret!.id,
        'service': 'Transport',
        'montant': _totalTransport,
        'reservation': false,
        'echeances_selectionnees': [],
      });
    }

    final body = {
      'ids': ids,
      'engagement': {},
      'type': 'préinscription',
      'separation_flux': 0,
      'systeme_educatif': 1,
    };

    try {
      final url = '$kBaseUrl/vie-ecoles/inscription-eleve/$_matricule?ecole=$kEcoleCode';
      print('🚀 [API] Soumission inscription - URL: $url');
      print('📤 [API] Body inscription: ${jsonEncode(body)}');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );
      print('📡 [API] Réponse inscription - Status: ${response.statusCode}');
      print('📄 [API] Body inscription: ${response.body}');

      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Inscription de ${widget.child.firstName} enregistrée avec succès!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        String errorMessage = 'Erreur lors de l\'inscription';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('💥 [API] Exception inscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── BUILD PRINCIPAL ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(_currentStep);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.screenCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.screenTextPrimary),
          onPressed: _currentStep == 0
              ? () => Navigator.of(context).pop()
              : _prevStep,
        ),
        title: Column(
          children: [
            Text(
              'Inscription – ${widget.child.firstName}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.screenTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Étape ${_currentStep + 1} sur $_totalSteps',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatAmount(_totalNet),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
                _buildStep6(),
                _buildStep7(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.screenDivider,
              valueColor: AlwaysStoppedAnimation(_stepColor(_currentStep)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              final stepColor = _stepColor(index);

              return GestureDetector(
                onTap: () {
                  if (index < _currentStep) {
                    setState(() => _currentStep = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
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
                            ? stepColor
                            : isCurrent
                                ? stepColor
                                : AppColors.screenDivider,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: stepColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : (_steps[index]['icon'] as IconData),
                        color: (isCompleted || isCurrent)
                            ? Colors.white
                            : AppColors.screenTextSecondary,
                        size: isCurrent ? 18 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? _stepColor(index) : AppColors.screenTextSecondary,
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

  Widget _buildNavigationButtons() {
    final canNext = _canGoNext();
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.screenDivider, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18,
                        color: AppColors.screenTextSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Précédent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          if (!isLastStep)
            Expanded(
              flex: 3,
              child: _buildNextButton(canNext),
            ),
        ],
      ),
    );
  }

  Widget _buildNextButton(bool canNext) {
    final color = _stepColor(_currentStep);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canNext
              ? [color, color.withOpacity(0.75)]
              : [Colors.grey.shade300, Colors.grey.shade300],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: canNext
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canNext ? _nextStep : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentStep == _totalSteps - 2 ? 'Voir le récapitulatif' : 'Suivant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: canNext ? Colors.white : Colors.grey.shade500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: canNext ? Colors.white : Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}