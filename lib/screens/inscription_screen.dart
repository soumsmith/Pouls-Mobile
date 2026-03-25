import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import '../models/child.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../services/ecole_eleve_service.dart';
import '../services/inscription_api_service.dart';

// ─── CONSTANTES ───────────────────────────────────────────────────────────────

const String kEcoleCode = 'gainhs';

// ─── ÉCRAN WIZARD ─────────────────────────────────────────────────────────────

class InscriptionWizardScreen extends StatefulWidget {
  final Child child;
  final String? uid;

  const InscriptionWizardScreen({Key? key, required this.child, this.uid})
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

  // ── Paramètres de l'école ───────────────────────────────────────────────────
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

  // ── Contrôleurs de recherche ────────────────────────────────────────────────
  final TextEditingController _serviceSearchController =
      TextEditingController();
  final TextEditingController _zoneSearchController = TextEditingController();

  // ── Accesseurs utilitaires ──────────────────────────────────────────────────
  String get _matricule => widget.child.matricule ?? '67894F';
  String get _ecoleCode => widget.child.ecoleCode ?? kEcoleCode;
  String get _uid_eleve =>
      //widget.uid ??
      //widget.child.matricule ??
      'fe5e28c5-23b9-4908-a0e8-5e02b128f2b6';

  // ── Listes filtrées ─────────────────────────────────────────────────────────
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
    try {
      super.initState();
      print('🎫 UID reçu dans InscriptionWizardScreen: ${widget.uid}');
      print('👤 Élève: ${widget.child.fullName}');
      print('📋 Matricule de l\'enfant: ${widget.child.matricule}');
      print('🏷️ Code école de l\'enfant: ${widget.child.ecoleCode}');
      print('🏷️ Valeur de kEcoleCode: $kEcoleCode');
      print('📋 Matricule utilisé: ${_matricule}');
      print('🏷️ Code école utilisé: ${_ecoleCode}');
      print('🆔 UID élève utilisé: ${_uid_eleve}');

      // Vérification des valeurs critiques
      if (_uid_eleve.isEmpty) {
        print('❌ ERREUR: UID élève est vide!');
      }
      if (_ecoleCode.isEmpty) {
        print('❌ ERREUR: Code école est vide!');
      }

      _pageController = PageController();
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
      );

      print('✅ initState terminé avec succès');
    } catch (e, stackTrace) {
      print('❌ ERREUR dans initState: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEcoleParams();
    });
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
    setState(() => _loadingScolarite = true);
    try {
      final statuts = await _checkInscriptionPeriods();
      if (statuts['preinscription'] != true &&
          statuts['inscription'] != true &&
          statuts['reservation'] != true) {
        _showError(
          'Aucune période d\'inscription n\'est actuellement ouverte pour cette école.',
        );
        return;
      }

      final systemeEducatif = _ecoleCode.startsWith('*annour*') ? 2 : 1;

      print('📡 Appel API fetchScolarite avec:');
      print('   - UID élève: ${_uid_eleve}');
      print('   - Code école: ${_ecoleCode}');
      print('   - Système éducatif: $systemeEducatif');

      final echeances = await InscriptionApiService.fetchScolarite(
        brancheId: _uid_eleve,
        ecoleCode: _ecoleCode,
        systemeEducatif: systemeEducatif,
      );

      if (mounted) {
        setState(() => _echeancesScolarite = echeances);
        _fadeController.forward();
      }
    } catch (e) {
      _showError('Erreur chargement scolarité : $e');
    } finally {
      if (mounted) setState(() => _loadingScolarite = false);
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
      if (mounted) {
        setState(
          () => _reservation = ReservationStatus(
            sommeReservation: 0,
            status: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingReservation = false);
    }
  }

  Future<void> _loadServices() async {
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
      _showError('Erreur chargement échéancier : $e');
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
          if (_isDateMoreRecent(e.dateLimite, mostRecent.dateLimite)) {
            mostRecent = e;
          }
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

  void _nextStep() {
    if (_currentStep >= _steps.length - 1) return;

    var nextStep = _currentStep + 1;

    if (!_servicesEnabled && _currentStep == 1) {
      nextStep = _steps.length - 1;
    }

    if (nextStep == 1 && _reservation == null) _loadReservation();
    if (nextStep == 2 && _services.isEmpty) _loadServices();
    if (nextStep == 3) _loadZones();
    if (nextStep == 4) _loadEcheancesForSelectedServices();

    setState(() => _currentStep = nextStep);
    _pageController.animateToPage(
      nextStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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
      case 0:
        return _echeancesScolarite.any((e) => e.selectionnee);
      case 4:
        if (!_servicesEnabled) return true;
        final hasSelectedService = _services.any((s) => s.selectionnee);
        if (!hasSelectedService) return true;
        return _echeancesService.any((e) => e.selectionnee);
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
  int get _totalTransport => 0;
  int get _totalBrut => _totalScolarite + _totalServices + _totalTransport;
  int get _deductionReservation =>
      (_reservation?.status == true) ? _reservation!.sommeReservation : 0;
  int get _totalNet => (_totalBrut - _deductionReservation).clamp(0, 999999999);

  // ─── STEPS CONFIG ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _steps => [
    {'label': 'Scolarité', 'icon': Icons.school_rounded},
    {'label': 'Réservation', 'icon': Icons.bookmark_rounded},
    if (_servicesEnabled) ...[
      {'label': 'Services', 'icon': Icons.grid_view_rounded},
      {'label': 'Zones', 'icon': Icons.map_rounded},
      {'label': 'Échéancier', 'icon': Icons.payment_rounded},
    ],
    {'label': 'Récap', 'icon': Icons.receipt_long_rounded},
  ];

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

  // ─── APP BAR ───────────────────────────────────────────────────────────────

  Widget _buildCustomAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomSliverAppBar(
      title: 'Inscription – ${widget.child.firstName}',
      isDark: isDark,
      onBackTap: _currentStep == 0
          ? () => Navigator.of(context).pop()
          : _prevStep,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
      backgroundColor: AppColors.screenCard,
      elevation: 0,
    );
  }

  Widget _buildAppBarSubtitle() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        'Étape ${_currentStep + 1} sur ${_steps.length}',
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
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

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
                        color: isCompleted || isCurrent
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
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.shopBlue
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
      ],
    );
  }

  Widget _buildCountBadge(String label) {
    return Container(
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
  }

  Widget _buildSearchField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.screenTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.screenTextSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
  }

  // ─── ÉCHÉANCE CARD ─────────────────────────────────────────────────────────

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
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
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
              color: selectionnee
                  ? AppColors.shopBlue.withOpacity(0.4)
                  : Colors.transparent,
              width: selectionnee ? 1.5 : 0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectionnee
                        ? AppColors.shopBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: selectionnee
                          ? AppColors.shopBlue
                          : AppColors.screenDivider,
                      width: 2,
                    ),
                  ),
                  child: selectionnee
                      ? Icon(
                          obligatoire
                              ? Icons.lock_rounded
                              : Icons.check_rounded,
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
                      Text(
                        libelle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.screenTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Limite : ${_formatDate(dateLimite)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.screenTextSecondary,
                            ),
                          ),
                          if (obligatoire) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.shopGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── SERVICE SECTION ───────────────────────────────────────────────────────

  Widget _buildServiceSection({
    required String title,
    required IconData icon,
    required List<EcheanceService> echeances,
  }) {
    final sortedEcheances = List<EcheanceService>.from(echeances)
      ..sort((a, b) {
        try {
          return DateTime.parse(
            b.dateLimite,
          ).compareTo(DateTime.parse(a.dateLimite));
        } catch (_) {
          return 0;
        }
      });

    final isRestaurant = icon == Icons.restaurant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRestaurant
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isRestaurant ? Colors.orange : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${sortedEcheances.where((e) => e.selectionnee).length}/${sortedEcheances.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedEcheances.asMap().entries.map(
          (entry) => _buildEcheanceCard(
            libelle: entry.value.libelle,
            montant: entry.value.montant,
            dateLimite: entry.value.dateLimite,
            selectionnee: entry.value.selectionnee,
            obligatoire: false,
            onToggle: () => setState(
              () => entry.value.selectionnee = !entry.value.selectionnee,
            ),
            index: entry.key,
          ),
        ),
      ],
    );
  }

  // ─── SERVICE CARD ──────────────────────────────────────────────────────────

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
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() => service.selectionnee = !service.selectionnee);
          if (service.selectionnee) {
            _loadEcheancesForSelectedServices();
            if (service.service == 'TRANS' && _zones.isEmpty) _loadZones();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: service.selectionnee
                  ? color.withOpacity(0.35)
                  : Colors.transparent,
              width: service.selectionnee ? 1.5 : 0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: service.selectionnee
                      ? AppColors.shopBlueSurface
                      : AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: service.selectionnee
                      ? color
                      : AppColors.screenTextSecondary,
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
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.shopBlueSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.service,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.shopBlue,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.shopGreen,
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
                        color: service.selectionnee
                            ? color
                            : AppColors.screenDivider,
                        width: 2,
                      ),
                    ),
                    child: service.selectionnee
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
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

  // ─── ZONE CARD ─────────────────────────────────────────────────────────────

  Widget _buildZoneCard(ZoneTransport zone, int index) {
    final isSelected = _selectedZone?.idzone == zone.idzone;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = zone),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.shopBlue.withOpacity(0.35)
                  : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.shopBlueSurface
                      : AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isSelected
                      ? AppColors.shopBlue
                      : AppColors.screenTextSecondary,
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
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Code : ${zone.code}',
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
                    color: AppColors.shopBlue,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
              'Frais scolaires pour ${widget.child.firstName}',
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
                (entry) => _buildEcheanceCard(
                  libelle: entry.value.libelle,
                  montant: entry.value.montant,
                  dateLimite: entry.value.dateLimite,
                  selectionnee: entry.value.selectionnee,
                  obligatoire: entry.value.rubriqueObligatoire == 1,
                  onToggle: () => setState(
                    () => entry.value.selectionnee = !entry.value.selectionnee,
                  ),
                  index: entry.key,
                ),
              ),
            if (_echeancesScolarite.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.shopBlueSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.class_rounded,
                      size: 15,
                      color: AppColors.shopBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Classe : ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                    Text(
                      _echeancesScolarite.first.branche,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.shopBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Services',
            'Sélectionnez les services souhaités',
            Icons.grid_view_rounded,
          ),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildSearchField(
            _serviceSearchController,
            'Rechercher un service...',
          ),
          const SizedBox(height: 16),
          if (_filteredServices.isEmpty)
            _buildEmptyState('Aucun service trouvé', Icons.search_off)
          else ...[
            if (_cantineServices.isNotEmpty) ...[
              Row(
                children: [
                  _sectionLabel('Services Cantine'),
                  const Spacer(),
                  _buildCountBadge(
                    '${_cantineServices.where((s) => s.selectionnee).length} sélectionné(s)',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._cantineServices.asMap().entries.map(
                (entry) => _buildServiceCard(entry.value, entry.key),
              ),
              const SizedBox(height: 20),
            ],
            if (_transportServices.isNotEmpty) ...[
              Row(
                children: [
                  _sectionLabel('Services Transport'),
                  const Spacer(),
                  _buildCountBadge(
                    '${_transportServices.where((s) => s.selectionnee).length} sélectionné(s)',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._transportServices.asMap().entries.map(
                (entry) => _buildServiceCard(entry.value, entry.key),
              ),
              const SizedBox(height: 20),
            ],
            if (_otherServices.isNotEmpty) ...[
              Row(
                children: [
                  _sectionLabel('Autres Services'),
                  const Spacer(),
                  _buildCountBadge(
                    '${_otherServices.where((s) => s.selectionnee).length} sélectionné(s)',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._otherServices.asMap().entries.map(
                (entry) => _buildServiceCard(entry.value, entry.key),
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
          ),
          const Divider(color: AppColors.screenDivider, height: 20),
          _buildSearchField(_zoneSearchController, 'Rechercher une zone...'),
          const SizedBox(height: 16),
          if (_zones.isEmpty)
            _buildEmptyState('Aucune zone disponible', Icons.info_outline)
          else if (_filteredZones.isEmpty)
            _buildEmptyState('Aucune zone trouvée', Icons.search_off)
          else
            ..._filteredZones.asMap().entries.map(
              (entry) => _buildZoneCard(entry.value, entry.key),
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
                  'Vous pouvez passer à l\'étape suivante',
                  Icons.payment_rounded,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingEcheancesService)
      return _buildLoadingState('Chargement de l\'échéancier...');

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
                          _buildServiceSection(
                            title: 'Services Cantine',
                            icon: Icons.restaurant,
                            echeances: _echeancesService
                                .where((e) => e.codeRubrique == 'CANTINE')
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_echeancesService.any(
                          (e) => e.codeRubrique == 'TRANS',
                        ))
                          _buildServiceSection(
                            title: 'Services Transport',
                            icon: Icons.directions_bus,
                            echeances: _echeancesService
                                .where((e) => e.codeRubrique == 'TRANS')
                                .toList(),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
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

          // Transport
          if (_selectedZone != null) ...[
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
                    'L\'inscription sera confirmée après validation par l\'administration.',
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
  }) {
    return Container(
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
            decoration: BoxDecoration(
              color: AppColors.shopBlueSurface,
              borderRadius: const BorderRadius.only(
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
              color: isBold ? AppColors.shopGreen : AppColors.screenTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOUTONS DE NAVIGATION ─────────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    final canNext = _canGoNext();
    final isLastStep = _currentStep == _steps.length - 1;

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
          mainAxisAlignment: _currentStep > 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
          children: [
            if (_currentStep > 0)
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
            if (!isLastStep)
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
                        _currentStep == _steps.length - 2
                            ? 'Récap'
                            : 'Suivant',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: canNext
                              ? Colors.white
                              : Colors.grey.shade500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: canNext
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            // Bouton de confirmation uniquement à la dernière étape
            if (isLastStep)
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

  // ─── SOUMISSION ────────────────────────────────────────────────────────────

  Future<void> _effectuerInscription() async {
    final List<Map<String, dynamic>> ids = [];

    // Scolarité
    final echeancesScol = _echeancesScolarite
        .where((e) => e.selectionnee)
        .toList();
    if (echeancesScol.isNotEmpty) {
      ids.add({
        'id': 'SCO',
        'service': 'Scolarité',
        'montant': _totalScolarite,
        'reservation': _reservation?.status ?? false,
        'echeances_selectionnees': echeancesScol
            .map((e) => e.toJson())
            .toList(),
      });
    }

    // Services
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
            'reservation': false,
            'echeances_selectionnees': serviceEcheances
                .map((e) => e.toJson())
                .toList(),
          });
        }
      }
    }

    // Transport
    if (_selectedZone != null) {
      ids.add({
        'id': _selectedZone!.idzone,
        'service': 'Transport',
        'montant': _totalTransport,
        'reservation': false,
        'echeances_selectionnees': [],
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

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    if (_servicesEnabled) ...[
                      _buildStep3(),
                      _buildStep4(),
                      _buildStep5(),
                    ],
                    _buildRecap(),
                  ],
                ),
              ),
              // Ajout d'un padding pour éviter que le contenu ne soit caché par les boutons flottants
              const SliverToBoxAdapter(
                child: SizedBox(height: 80), // Hauteur des boutons + marge
              ),
            ],
          ),
          // Boutons de navigation flottants en bas
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
