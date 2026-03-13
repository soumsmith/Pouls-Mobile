import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/config/app_dimensions.dart';
import 'package:parents_responsable/widgets/custom_form_button.dart';
import 'package:parents_responsable/widgets/custom_loader.dart';
import 'package:parents_responsable/widgets/custom_text_field.dart';
import 'dart:developer' as developer;
import '../config/app_colors.dart';
import '../models/scolarite.dart';
import '../models/niveau.dart';
import '../models/avis.dart';
import '../services/text_size_service.dart';
import '../services/ecole_api_service.dart';
import '../services/theme_service.dart';
import '../services/blog_service.dart';
import '../services/events_service.dart';
import '../services/avis_service.dart';
import '../services/scolarite_service.dart';
import '../services/niveau_service.dart';
import '../services/integration_service.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/testimonial_service.dart';
import '../widgets/custom_snackbar.dart';
import '../services/integration_request_service.dart';
import '../services/parrainage_service.dart';
import '../widgets/custom_file_field.dart';
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../widgets/color_card_grid.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/establishment_header_card.dart';
import '../widgets/section_title.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import 'all_events_screen.dart';

// ── Date Input Formatter ───────────────────────────────────────────────────────
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si l'utilisateur supprime du texte, permettre la suppression naturelle
    if (newValue.text.length < oldValue.text.length) {
      // Permettre la suppression sans reformater
      String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');

      // Si on supprime après un séparateur, supprimer aussi le séparateur
      if (oldValue.selection.baseOffset > 0 &&
          oldValue.text.length > newValue.text.length) {
        int deletedIndex = newValue.selection.baseOffset;
        if (deletedIndex > 0 && deletedIndex <= text.length) {
          // Vérifier si on a supprimé juste après un séparateur
          if (deletedIndex > 0 && text[deletedIndex - 1] == '/') {
            text =
                text.substring(0, deletedIndex - 1) +
                (deletedIndex < text.length
                    ? text.substring(deletedIndex)
                    : '');
          }
        }
      }

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    // Supprimer tous les caractères non numériques sauf les séparateurs
    String text = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');

    // Si l'utilisateur tape un tiret, le convertir en slash
    if (newValue.text.contains('-') && !newValue.text.contains('/')) {
      text = text.replaceAll('-', '/');
    }

    // Limiter à 10 caractères (DD/MM/YYYY)
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    // Insertion automatique des séparateurs
    if (text.length >= 2 && !text.contains('/')) {
      // Après 2 chiffres, ajouter le premier séparateur
      text = text.substring(0, 2) + '/' + text.substring(2);
    }

    if (text.length >= 5 && text.indexOf('/', text.indexOf('/') + 1) == -1) {
      // Après 5 caractères (DD/MM), ajouter le deuxième séparateur
      int firstSlash = text.indexOf('/');
      if (firstSlash != -1) {
        String day = text.substring(0, firstSlash);
        String monthYear = text.substring(firstSlash + 1);
        if (monthYear.length >= 2) {
          text =
              day +
              '/' +
              monthYear.substring(0, 2) +
              '/' +
              monthYear.substring(2);
        }
      }
    }

    // Validation basique des nombres
    List<String> parts = text.split('/');
    if (parts.length >= 3) {
      // Validation du jour (max 31)
      if (parts[0].length == 2 && int.tryParse(parts[0]) != null) {
        int day = int.parse(parts[0]);
        if (day > 31) {
          parts[0] = '31';
        }
      }

      // Validation du mois (max 12)
      if (parts[1].length == 2 && int.tryParse(parts[1]) != null) {
        int month = int.parse(parts[1]);
        if (month > 12) {
          parts[1] = '12';
        }
      }

      text = parts.join('/');
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── Action card definition ──────────────────────────────────────────────────
class _ActionDef {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _ActionDef({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

const _kActions = <String, _ActionDef>{
  'integration': _ActionDef(
    icon: Icons.person_add_alt_1_rounded,
    label: 'Demande d\'intégration',
    subtitle: 'Rejoindre',
    color: Color(0xFF3B82F6),
  ),
  'rating': _ActionDef(
    icon: Icons.star_rate_rounded,
    label: 'Avis & commentaire',
    subtitle: 'Évaluer',
    color: Color(0xFF10B981),
  ),
  'sponsorship': _ActionDef(
    icon: Icons.card_giftcard_rounded,
    label: 'Parrainer',
    subtitle: 'Inviter',
    color: Color(0xFFF59E0B),
  ),
  'recommend': _ActionDef(
    icon: Icons.recommend_rounded,
    label: 'Recommander',
    subtitle: 'Suggérer',
    color: Color(0xFF8B5CF6),
  ),
  'share': _ActionDef(
    icon: Icons.share_rounded,
    label: 'Partager',
    subtitle: 'Diffuser',
    color: Color(0xFFEC4899),
  ),
  'informations': _ActionDef(
    icon: Icons.info_rounded,
    label: 'Informations',
    subtitle: 'Détails',
    color: Color(0xFF3B82F6),
  ),
  'communication': _ActionDef(
    icon: Icons.chat_rounded,
    label: 'Communication',
    subtitle: 'Annonces',
    color: Color(0xFF10B981),
  ),
  'niveaux': _ActionDef(
    icon: Icons.layers_rounded,
    label: 'Niveaux',
    subtitle: 'Classes',
    color: Color(0xFFF59E0B),
  ),
  'school_events': _ActionDef(
    icon: Icons.event_rounded,
    label: 'Événements',
    subtitle: 'Calendrier',
    color: Color(0xFF8B5CF6),
  ),
  'scolarite': _ActionDef(
    icon: Icons.school_rounded,
    label: 'Scolarité',
    subtitle: 'Frais',
    color: Color(0xFFEF4444),
  ),
  'voir_les_avis': _ActionDef(
    icon: Icons.grade_rounded,
    label: 'Avis & commentaire',
    subtitle: 'Donner un avis',
    color: Color(0xFFF59E0B),
  ),
  'consult_requests': _ActionDef(
    icon: Icons.search_rounded,
    label: 'Mes demandes',
    subtitle: 'Consulter',
    color: Color(0xFF06B6D4),
  ),
};

/// Écran de détail d'un établissement
class EstablishmentDetailScreen extends StatefulWidget
    implements MainScreenChild {
  final Ecole ecole;
  const EstablishmentDetailScreen({super.key, required this.ecole});

  @override
  State<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends State<EstablishmentDetailScreen>
    with TickerProviderStateMixin
    implements MainScreenChild {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  EcoleDetail? _ecoleDetail;
  late Future<ScolariteResponse> _scolariteFuture;

  final _avisNotifier = ValueNotifier<int>(0);
  final _eventsNotifier = ValueNotifier<int>(0);

  List<Map<String, dynamic>> _blogs = [];
  List<Map<String, dynamic>> _schoolEvents = [];
  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingBlogs = false;
  bool _isLoadingEvents = false;
  bool _isLoadingAvis = false;
  bool _isLoadingMoreEvents = false;
  bool _hasMoreEvents = true;
  int _currentEventsPage = 1;
  int _eventsPerPage =
      4; // Valeur par défaut, sera mise à jour dans initState()
  String? _blogsError;
  String? _eventsError;
  String? _avisError;
  final BlogService _blogService = BlogService();
  final EventsService _eventsService = EventsService();
  final AvisService _avisService = AvisService();

  // form state
  String _selectedSexe = 'M';
  String _selectedStatutAff = 'Affecté';
  String _searchQuery = '';
  String? _expandedBranche;
  late TextEditingController _searchController;

  // Integration controllers
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentFirstNameController =
      TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _lieuNaissanceController =
      TextEditingController();
  final TextEditingController _nationaliteController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _contact1Controller = TextEditingController();
  final TextEditingController _contact2Controller = TextEditingController();
  final TextEditingController _nomPereController = TextEditingController();
  final TextEditingController _nomMereController = TextEditingController();
  final TextEditingController _nomTuteurController = TextEditingController();
  final TextEditingController _niveauAntController = TextEditingController();
  final TextEditingController _ecoleAntController = TextEditingController();
  final TextEditingController _moyenneAntController = TextEditingController();
  final TextEditingController _rangAntController = TextEditingController();
  final TextEditingController _decisionAntController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _filiereController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _requestedClassController =
      TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController =
      TextEditingController();
  final TextEditingController _schoolTypeController = TextEditingController();
  final TextEditingController _schoolCityController = TextEditingController();
  final TextEditingController _recommenderNameController =
      TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  // Recommendation controllers
  final TextEditingController _parentNomController = TextEditingController();
  final TextEditingController _parentPrenomController = TextEditingController();
  final TextEditingController _parentTelephoneController =
      TextEditingController();
  final TextEditingController _recommandationEmailController =
      TextEditingController();
  final TextEditingController _parentPaysController = TextEditingController();
  final TextEditingController _parentVilleController = TextEditingController();
  final TextEditingController _parentAdresseController =
      TextEditingController();
  final TextEditingController _etablissementController =
      TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _ordreController = TextEditingController();
  final TextEditingController _adresseEtablissementController =
      TextEditingController();

  // Recommendation error states
  bool _parentNomError = false;
  bool _parentPrenomError = false;
  bool _parentTelephoneError = false;
  bool _recommandationEmailError = false;
  // Sponsorship controllers
  final TextEditingController _sponsorNameController = TextEditingController();
  final TextEditingController _sponsorEmailController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  // File upload variables
  String? _bulletinFile;
  String? _certificatVaccinationFile;
  String? _certificatScolariteFile;
  String? _extraitNaissanceFile;
  String? _cniParentFile;

  // Validation error states
  bool _studentNameError = false;
  bool _studentFirstNameError = false;
  bool _matriculeError = false;
  bool _birthDateError = false;
  bool _adresseError = false;
  bool _contact1Error = false;
  bool _nomPereError = false;
  bool _nomMereError = false;

  // ── helpers ────────────────────────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'primaire':
        return const Color(0xFF3B82F6);
      case 'collège':
        return const Color(0xFF8B5CF6);
      case 'lycée':
        return const Color(0xFF10B981);
      case 'privé':
        return const Color(0xFFF59E0B);
      case 'public':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadEcoleDetail();
    _loadBlogsAndAvisOnly();
    _fadeController.forward();
    _scolariteFuture = ScolariteService.getScolaritesByEcole(
      widget.ecole.parametreCode,
    );

    // Initialize search controller
    _searchController = TextEditingController();

    // Add listeners to clear error states when user starts typing
    _studentNameController.addListener(
      () => _clearErrorIfNotEmpty(
        _studentNameController.text,
        () => setState(() => _studentNameError = false),
      ),
    );
    _studentFirstNameController.addListener(
      () => _clearErrorIfNotEmpty(
        _studentFirstNameController.text,
        () => setState(() => _studentFirstNameError = false),
      ),
    );
    _birthDateController.addListener(
      () => _clearErrorIfNotEmpty(
        _birthDateController.text,
        () => setState(() => _birthDateError = false),
      ),
    );
    _contact1Controller.addListener(
      () => _clearErrorIfNotEmpty(
        _contact1Controller.text,
        () => setState(() => _contact1Error = false),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize responsive pagination after MediaQuery is available
    _eventsPerPage = AppDimensions.getEventsPerPage(context);
  }

  void _clearErrorIfNotEmpty(String text, VoidCallback clearError) {
    if (text.isNotEmpty) clearError();
  }

  Future<void> _loadEcoleDetail() async {
    try {
      final detail = await EcoleApiService.getEcoleDetail(
        widget.ecole.parametreCode,
      );
      setState(() => _ecoleDetail = detail);
    } catch (e) {
      debugPrint('Erreur lors du chargement des détails: $e');
    }
  }

  Future<void> _loadEventsOnly() async {
    final nom = widget.ecole.parametreNom ?? '';
    if (nom.isEmpty) return;

    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
      _schoolEvents.clear();
      _currentEventsPage = 1;
      _hasMoreEvents = true;
    });
    _eventsNotifier.value++;

    try {
      final events = await _eventsService.getEventsForUI(
        nomEtablissement: nom,
        page: _currentEventsPage,
        perPage: _eventsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _schoolEvents = events;
        _isLoadingEvents = false;
        // Check if there are more pages
        _hasMoreEvents = events.length >= _eventsPerPage;
      });
      _eventsNotifier.value++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eventsError = e.toString();
        _isLoadingEvents = false;
      });
      _eventsNotifier.value++;
    }
  }

  Future<void> _loadMoreEvents() async {
    final nom = widget.ecole.parametreNom ?? '';
    if (nom.isEmpty || !_hasMoreEvents) return;

    setState(() {
      _isLoadingMoreEvents = true;
    });
    _eventsNotifier.value++;

    try {
      _currentEventsPage++;
      final newEvents = await _eventsService.getEventsForUI(
        nomEtablissement: nom,
        page: _currentEventsPage,
        perPage: _eventsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _schoolEvents.addAll(newEvents);
        _isLoadingMoreEvents = false;
        // Check if there are more pages
        _hasMoreEvents = newEvents.length >= _eventsPerPage;
      });
      _eventsNotifier.value++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMoreEvents = false;
        // Revert page number on error
        _currentEventsPage--;
      });
      _eventsNotifier.value++;
    }
  }

  Future<void> _loadAvisOnly() async {
    final code = widget.ecole.parametreCode ?? '';
    if (code.isEmpty || !mounted) return;

    setState(() {
      _isLoadingAvis = true;
      _avisError = null;
    });
    _avisNotifier.value++; // notifier le bottom sheet

    try {
      final avis = await _avisService.getAvisForUI(code);
      if (!mounted) return;
      setState(() {
        _avis = avis;
        _isLoadingAvis = false;
      });
      _avisNotifier.value++; // notifier le bottom sheet
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avisError = e.toString();
        _isLoadingAvis = false;
      });
      _avisNotifier.value++; // notifier le bottom sheet
    }
  }

  Future<void> _loadBlogsAndAvisOnly() async {
    final nom = widget.ecole.parametreNom ?? '';
    final code = widget.ecole.parametreCode ?? '';
    if (nom.isEmpty || code.isEmpty) return;
    setState(() {
      _isLoadingBlogs = true;
      _isLoadingAvis = true;
    });
    try {
      final results = await Future.wait([
        _blogService.getBlogsForUI(nom).catchError((e) {
          setState(() {
            _blogsError = e.toString();
            _isLoadingBlogs = false;
          });
          throw e;
        }),
        _avisService.getAvisForUI(code).catchError((e) {
          setState(() {
            _avisError = e.toString();
            _isLoadingAvis = false;
          });
          throw e;
        }),
      ]);
      setState(() {
        if (_blogsError == null) {
          _blogs = results[0] as List<Map<String, dynamic>>;
          _isLoadingBlogs = false;
        }
        if (_avisError == null) {
          _avis = results[1] as List<Map<String, dynamic>>;
          _isLoadingAvis = false;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadBlogsEventsAndAvis() async {
    final nom = widget.ecole.parametreNom ?? '';
    final code = widget.ecole.parametreCode ?? '';
    if (nom.isEmpty || code.isEmpty) return;
    setState(() {
      _isLoadingBlogs = true;
      _isLoadingEvents = true;
      _isLoadingAvis = true;
    });
    try {
      final results = await Future.wait([
        _blogService.getBlogsForUI(nom).catchError((e) {
          setState(() {
            _blogsError = e.toString();
            _isLoadingBlogs = false;
          });
          throw e;
        }),
        _eventsService.getEventsForUI(nomEtablissement: nom).catchError((e) {
          setState(() {
            _eventsError = e.toString();
            _isLoadingEvents = false;
          });
          throw e;
        }),
        _avisService.getAvisForUI(code).catchError((e) {
          setState(() {
            _avisError = e.toString();
            _isLoadingAvis = false;
          });
          throw e;
        }),
      ]);
      setState(() {
        if (_blogsError == null) {
          _blogs = results[0] as List<Map<String, dynamic>>;
          _isLoadingBlogs = false;
        }
        if (_eventsError == null) {
          _schoolEvents = results[1] as List<Map<String, dynamic>>;
          _isLoadingEvents = false;
        }
        if (_avisError == null) {
          _avis = results[2] as List<Map<String, dynamic>>;
          _isLoadingAvis = false;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _avisNotifier.dispose();
    _eventsNotifier.dispose();
    _fadeController.dispose();
    // Integration controllers
    _studentNameController.dispose();
    _studentFirstNameController.dispose();
    _matriculeController.dispose();
    _birthDateController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _adresseController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _nomPereController.dispose();
    _nomMereController.dispose();
    _nomTuteurController.dispose();
    _niveauAntController.dispose();
    _ecoleAntController.dispose();
    _moyenneAntController.dispose();
    _rangAntController.dispose();
    _decisionAntController.dispose();
    _motifController.dispose();
    _filiereController.dispose();
    _ratingController.dispose();
    _commentController.dispose();
    // Recommendation controllers
    _parentNomController.dispose();
    _parentPrenomController.dispose();
    _parentTelephoneController.dispose();
    _recommandationEmailController.dispose();
    _parentPaysController.dispose();
    _parentVilleController.dispose();
    _parentAdresseController.dispose();
    _etablissementController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _ordreController.dispose();
    _adresseEtablissementController.dispose();
    // Sponsorship controllers
    _sponsorNameController.dispose();
    _sponsorEmailController.dispose();
    _promoCodeController.dispose();
    // Search controller
    _searchController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_themeService, _textSizeService]),
        builder: (context, _) {
          final isDark = _themeService.isDarkMode;
          return ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFF0F0F0F)
                  : AppColors.screenSurface,
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(isDark),
                    SliverToBoxAdapter(child: _buildContent(isDark)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : AppColors.screenSurface,
      leading: GestureDetector(
        onTap: () {
          if (MainScreenWrapper.maybeOf(context) != null) {
            MainScreenWrapper.of(context).navigateToHome();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: isDark ? Colors.white : AppColors.screenTextPrimary,
          ),
        ),
      ),
      title: Text(
        'Détails de l\'établissement',
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(18),
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.screenTextPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        _appBarIconBtn(Icons.favorite_border, isDark, () {}),
        _appBarIconBtn(Icons.share, isDark, () {}),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _appBarIconBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : AppColors.screenTextPrimary,
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildEstablishmentHeader(isDark),
        const SizedBox(height: 24),
        _buildSectionHeader('Actions rapides', isDark),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildActionButtons(isDark),
        ),
        const SizedBox(height: 24),
        _buildMenuCards(isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.screenOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.screenTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────────
  Widget _buildEstablishmentHeader(bool isDark) {
    final imageUrl = _ecoleDetail?.image ?? widget.ecole.displayImage;
    final establishmentName =
        _ecoleDetail?.data.nom ?? widget.ecole.parametreNom ?? 'École';
    final establishmentType = widget.ecole.typePrincipal ?? 'Primaire';
    final motto = _ecoleDetail?.data.slogan ?? 'L\'excellence notre priorité';
    final address =
        _ecoleDetail?.data.adresse ??
        widget.ecole.adresse ??
        'Adresse non disponible';
    final phone =
        _ecoleDetail?.data.telephone ??
        widget.ecole.telephone ??
        'Téléphone non disponible';
    final email = _ecoleDetail?.data.email ?? 'Email non disponible';
    final typeColor = _getTypeColor(establishmentType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - v)),
            child: child,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: typeColor.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Cover image ──────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Stack(
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholderCover(typeColor),
                      )
                    else
                      _placeholderCover(typeColor),
                    // Gradient overlay renforcé
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Nom en overlay bas
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            establishmentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            motto,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge type en haut à droite
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              establishmentType,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Info block ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  children: [
                    _infoRowModern(Icons.location_on_outlined, address, isDark),
                    const SizedBox(height: 8),
                    _infoRowModern(Icons.phone_outlined, phone, isDark),
                    const SizedBox(height: 8),
                    _infoRowModern(Icons.email_outlined, email, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Remplace _infoRow par cette version plus soignée
  Widget _infoRowModern(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : AppColors.screenDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.screenOrangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.screenOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCover(Color color) => Container(
    height: 160,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.school_rounded, size: 56, color: Colors.white54),
  );

  Widget _infoRow(IconData icon, String text, bool isDark) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.screenOrange),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : AppColors.screenTextSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );

  // ── Action buttons (quick actions) ─────────────────────────────────────────
  Widget _buildActionButtons(bool isDark) {
    final actions = [
      'integration',
      'rating',
      'sponsorship',
      'recommend',
      'share',
    ];
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final def = _kActions[actions[i]]!;
          return _buildActionChip(def, actions[i], isDark, i);
        },
      ),
    );
  }

  Widget _buildActionChip(_ActionDef def, String key, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(20 * (1 - v), 0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showActionBottomSheet(key, def),
        child: Container(
          width: 180,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                def.color.withOpacity(0.15),
                def.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: def.color.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: def.color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: def.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(def.icon, color: def.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                def.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.screenTextPrimary,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                def.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: def.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu cards (3 sections thématiques) ────────────────────────────────────────────
  Widget _buildMenuCards(bool isDark) {
    // Section École (pédagogique)
    final ecoleSection = [
      ['informations', 'Informations de l\'école'],
      ['niveaux', 'Niveaux scolaire'],
      ['communication', 'Communication'],
    ];

    // Section Vie école (opérationnel)
    final vieEcoleSection = [
      ['school_events', ' Evénements scolaires'],
      ['consult_requests', 'Mes demandes'],
      ['scolarite', 'Scolarité'],
    ];

    // Section Communauté
    final communauteSection = [
      ['voir_les_avis', 'Voir les avis'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('École', isDark),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuSection('École', ecoleSection, isDark),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Vie école', isDark),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuSection('Vie école', vieEcoleSection, isDark),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Communauté', isDark),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMenuSection('Communauté', communauteSection, isDark),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    String title,
    List<List<String>> items,
    bool isDark,
  ) {
    return _buildMenuRow(items, isDark);
  }

  Widget _buildMenuRow(List<List<String>> menuItems, bool isDark) {
    // Diviser en rangées de 4 éléments maximum
    final rows = <List<List<String>>>[];
    for (int i = 0; i < menuItems.length; i += 4) {
      final end = (i + 4 < menuItems.length) ? i + 4 : menuItems.length;
      rows.add(menuItems.sublist(i, end));
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row
                .asMap()
                .entries
                .map(
                  (e) => _buildMenuCard(e.key, e.value[0], e.value[1], isDark),
                )
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(int index, String key, String title, bool isDark) {
    final def = _kActions[key]!;
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 350 + index * 80),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)),
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: () => _showActionBottomSheet(key, def),
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.screenShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: def.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(def.icon, color: def.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.screenTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════════════════
  void _showActionBottomSheet(String actionType, _ActionDef def) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Déclencher le chargement si nécessaire
    if (actionType == 'voir_les_avis' && !_isLoadingAvis) {
      _loadAvisOnly();
    }

    // Charger les événements uniquement lors du clic
    if (actionType == 'school_events' &&
        !_isLoadingEvents &&
        _schoolEvents.isEmpty &&
        _eventsError == null) {
      _loadEventsOnly();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _avisNotifier,
        builder: (context, _, __) => ValueListenableBuilder<int>(
          valueListenable: _eventsNotifier, // ← AJOUTER ce wrapper
          builder: (context, _, __) {
            return Container(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.screenDivider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: def.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(def.icon, color: def.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.label,
                                    style: TextStyle(
                                      fontSize: _textSizeService
                                          .getScaledFontSize(18),
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.screenTextPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  Text(
                                    def.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.screenTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : AppColors.screenSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.screenTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.screenDivider, height: 1),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: _buildActionContent(actionType),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION CONTENT ROUTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionContent(String actionType) {
    switch (actionType) {
      case 'integration':
        return _buildIntegrationForm();
      case 'rating':
        return _buildRatingForm();
      case 'sponsorship':
        return _buildSponsorshipForm();
      case 'recommend':
        return _buildRecommendationForm();
      case 'share':
        return _buildShareForm();
      case 'consult_requests':
        return _buildConsultRequestsContent();
      case 'informations':
        return _buildInformationsContent();
      case 'communication':
        return _buildCommunicationTab();
      case 'niveaux':
        return _buildLevelsTab();
      case 'school_events':
        return _buildEventsTab();
      case 'scolarite':
        return _buildScolariteTab();
      case 'voir_les_avis':
        return _buildNotesTab();
      default:
        return const Center(child: Text('Contenu non disponible'));
    }
  }

  // ── Sponsorship form ───────────────────────────────────────────────────────
  Widget _buildSponsorshipForm() {
    final actionColor = _kActions['sponsorship']!.color;
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();
    final isDark = _themeService.isDarkMode;
    
    // Pré-remplir le numéro de téléphone de l'utilisateur connecté
    if (currentUser?.phone != null && _parentTelephoneController.text.isEmpty) {
      _parentTelephoneController.text = currentUser!.phone;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Vos informations',
          icon: Icons.person_rounded,
          children: [
            CustomTextField(
              label: 'Téléphone',
              hint: 'Votre numéro de téléphone',
              icon: Icons.phone_rounded,
              controller: _parentTelephoneController,
              keyboardType: TextInputType.phone,
              required: true,
              hasError: _parentTelephoneError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
              readOnly: currentUser?.phone != null, // Lecture seule si déjà pré-rempli
            ),
            const SizedBox(height: 12),
            Text(
              'Renseignez votre numéro de téléphone pour obtenir votre code de parrainage',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(12),
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        CustomFormButton(
          text: 'Obtenir mon code de parrainage',
          color: AppColors.screenOrange,
          icon: Icons.card_giftcard_rounded,
          onPressed: () async {
            // Validation AVANT d'afficher le loader
            if (_parentTelephoneController.text.isEmpty) {
              CustomSnackBar.warning(
                context,
                'Veuillez renseigner votre numéro de téléphone',
              );
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (_) => CustomLoader(
                message: 'Récupération en cours...',
                loaderColor: AppColors.screenOrange,
                size: 56.0,
                showBackground: true,
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
            );

            try {
              // Récupérer les infos de parrainage directement avec le numéro de téléphone
              final infoResult = await ParrainageService.getInfoParrainage(_parentTelephoneController.text);
              
              Navigator.of(context).pop(); // ferme le loader

              if (infoResult['success'] == true && infoResult['data'] != null) {
                Navigator.of(context).pop(); // ferme le bottom sheet
                
                // Afficher le modal avec le code de parrainage
                _showParrainageCodeModal(infoResult['data']['code_parrainage'] ?? 'Non disponible');
              } else {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      infoResult['message'] ?? 'Impossible de récupérer les informations de parrainage',
                    ),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (e) {
              Navigator.of(context).pop(); // ferme le loader
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text('Erreur réseau: ${e.toString()}'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Parrainage Code Modal ────────────────────────────────────────────────────
  void _showParrainageCodeModal(String codeParrainage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = _themeService.isDarkMode;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon de succès
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    size: 40,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                Text(
                  'Parrainage réussi!',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(20),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Sous-titre
                Text(
                  'Votre code de parrainage a été généré avec succès',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Code de parrainage - Grand et centré
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'VOTRE CODE DE PARRAINAGE',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        codeParrainage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(48), // Très grand
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3B82F6), // Bleu vif
                          letterSpacing: 4, // Espacement large
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton de copie
                SizedBox(
                  width: double.infinity,
                  child: CustomFormButton(
                    text: 'Copier le code',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      // Copier le code dans le presse-papiers
                      Clipboard.setData(
                        ClipboardData(text: codeParrainage),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Code copié dans le presse-papiers',
                          ),
                          backgroundColor: Colors.green[500],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton de fermeture
                SizedBox(
                  width: double.infinity,
                  child: CustomFormButton(
                    text: 'Fermer',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Recommendation form ────────────────────────────────────────────────────
  Widget _buildRecommendationForm() {
    final actionColor = _kActions['recommend']!.color;

    // Pré-remplir les données de l'établissement pour la soumission (non affichées)
    _etablissementController.text = widget.ecole.parametreNom ?? '';
    _paysController.text = 'Côte d\'Ivoire';
    _villeController.text = 'Abidjan';
    _ordreController.text = 'Primaire, collège';
    _adresseEtablissementController.text = 'Adjamé';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Vos informations',
          icon: Icons.person_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Nom',
                    hint: 'Votre nom',
                    icon: Icons.person_rounded,
                    controller: _parentNomController,
                    required: true,
                    hasError: _parentNomError,
                    iconColor: actionColor,
                    focusBorderColor: actionColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Prénom',
                    hint: 'Votre prénom',
                    icon: Icons.person_outline_rounded,
                    controller: _parentPrenomController,
                    required: true,
                    hasError: _parentPrenomError,
                    iconColor: actionColor,
                    focusBorderColor: actionColor,
                  ),
                ),
              ],
            ),
            CustomTextField(
              label: 'Téléphone',
              hint: 'Votre numéro',
              icon: Icons.phone_rounded,
              controller: _parentTelephoneController,
              keyboardType: TextInputType.phone,
              required: true,
              hasError: _parentTelephoneError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Email',
              hint: 'Votre adresse email',
              icon: Icons.email_rounded,
              controller: _recommandationEmailController,
              keyboardType: TextInputType.emailAddress,
              required: true,
              hasError: _recommandationEmailError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Pays',
              hint: 'Votre pays',
              icon: Icons.public_rounded,
              controller: _parentPaysController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Ville',
              hint: 'Votre ville',
              icon: Icons.location_city_rounded,
              controller: _parentVilleController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Adresse',
              hint: 'Votre adresse',
              icon: Icons.home_rounded,
              controller: _parentAdresseController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
          ],
        ),
        CustomFormButton(
          text: 'Envoyer la recommandation',
          color: AppColors.screenOrange,
          icon: Icons.recommend_rounded,
          onPressed: () async {
            // Validation AVANT d'afficher le loader
            if (_etablissementController.text.isEmpty ||
                _parentNomController.text.isEmpty ||
                _parentPrenomController.text.isEmpty ||
                _parentTelephoneController.text.isEmpty ||
                _recommandationEmailController.text.isEmpty) {
              CustomSnackBar.warning(
                context,
                'Veuillez remplir tous les champs obligatoires',
              );
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (_) => CustomLoader(
                message: 'Envoi en cours...',
                loaderColor: AppColors.screenOrange,
                size: 56.0,
                showBackground: true,
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
            );

            try {
              final result = await RecommendationService.submitRecommendation(
                etablissement: _etablissementController.text,
                pays: _paysController.text,
                ville: _villeController.text,
                ordre: _ordreController.text,
                adresseEtablissement: _adresseEtablissementController.text,
                nomParent: _parentNomController.text,
                prenomParent: _parentPrenomController.text,
                telephone: _parentTelephoneController.text,
                email: _recommandationEmailController.text,
                paysParent: _parentPaysController.text,
                villeParent: _parentVilleController.text,
                adresseParent: _parentAdresseController.text,
              );

              Navigator.of(context).pop(); // ferme le loader

              if (result['success'] == true) {
                _parentNomController.clear();
                _parentPrenomController.clear();
                _parentTelephoneController.clear();
                _recommandationEmailController.clear();
                Navigator.of(context).pop(); // ferme le bottom sheet
                await Future.delayed(const Duration(milliseconds: 300));
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: const Text('Recommandation envoyée avec succès!'),
                    backgroundColor: Colors.green[500],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Erreur lors de l\'envoi',
                    ),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (e) {
              Navigator.of(context).pop(); // ferme le loader
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Share form ─────────────────────────────────────────────────────────────
  Widget _buildShareForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ecole.parametreNom ?? 'École',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.ecole.adresse ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    Icons.message,
                    'WhatsApp',
                    const Color(0xFF25D366),
                  ),
                  _buildShareOption(
                    Icons.email,
                    'Email',
                    const Color(0xFF4285F4),
                  ),
                  _buildShareOption(
                    Icons.link,
                    'Copier',
                    const Color(0xFF6366F1),
                  ),
                  _buildShareOption(
                    Icons.share,
                    'Réseaux',
                    AppColors.screenOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MENU CONTENT TABS  (Communication, Niveaux, Events, Scolarité, Notes)
  // ══════════════════════════════════════════════════════════════════════════

  // ── Communication tab ─────────────────────────────────────────────────────
  Widget _buildCommunicationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication et Actualités',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dernières communications de ${widget.ecole.parametreNom}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingBlogs)
          const Center(
            child: CustomLoader(
              message: 'Chargement des communications...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          )
        else if (_blogsError != null)
          _buildTabError(_blogsError!, _loadBlogsEventsAndAvis)
        else if (_blogs.isEmpty)
          _buildTabEmpty(
            Icons.article_outlined,
            'Aucune communication',
            'Aucune communication disponible pour le moment.',
          )
        else
          ..._blogs.map((blog) => _buildBlogCard(blog)).toList(),
      ],
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final Color color = blog['color'] as Color? ?? AppColors.screenOrange;
    final String? imageUrl = blog['image'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: ImageHelper.buildNetworkImage(
                imageUrl: imageUrl,
                placeholder: blog['title'] ?? '',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  blog['icon'] as IconData? ?? Icons.article,
                  size: 40,
                  color: Colors.white70,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        blog['type'] as String? ?? 'Actualité',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      blog['date'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  blog['title'] as String? ?? 'Sans titre',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  blog['content'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.screenTextSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.screenTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        blog['auteur'] as String? ?? 'Administration',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                    ),
                    if ((blog['establishment'] as String?)?.isNotEmpty ==
                        true) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.screenTextSecondary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          blog['establishment'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.screenTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Levels tab ─────────────────────────────────────────────────────────────
  Widget _buildLevelsTab() {
    final ecoleCode = widget.ecole.parametreCode ?? '';
    return FutureBuilder<List<Niveau>>(
      future: NiveauService.getNiveauxByEcole(ecoleCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement des niveaux...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildTabError(
            snapshot.error.toString(),
            () => setState(() {}),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildTabEmpty(
            Icons.school_outlined,
            'Aucun niveau disponible',
            'Cette école n\'a pas de niveaux configurés',
          );
        }
        final niveaux = snapshot.data!;
        final Map<String, Map<String, List<Niveau>>> grouped = {};
        for (final n in niveaux) {
          final filiere = (n.filiere?.isNotEmpty == true)
              ? n.filiere!
              : 'AUTRE';
          final niveauLabel = (n.niveau?.isNotEmpty == true)
              ? n.niveau!
              : n.nom ?? '?';
          grouped.putIfAbsent(filiere, () => {});
          grouped[filiere]!.putIfAbsent(niveauLabel, () => []);
          grouped[filiere]![niveauLabel]!.add(n);
        }
        final sortedFilieres = grouped.keys.toList()..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveaux d\'enseignement',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${niveaux.length} classe${niveaux.length > 1 ? 's' : ''} disponible${niveaux.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedFilieres.map((filiere) {
              final niveauxMap = grouped[filiere]!;
              final sortedNiveauKeys = niveauxMap.keys.toList()
                ..sort((a, b) {
                  final oA = niveauxMap[a]!
                      .map((e) => e.ordre ?? 99)
                      .reduce((x, y) => x < y ? x : y);
                  final oB = niveauxMap[b]!
                      .map((e) => e.ordre ?? 99)
                      .reduce((x, y) => x < y ? x : y);
                  return oA.compareTo(oB);
                });
              return _buildFiliereSection(
                filiere,
                sortedNiveauKeys,
                niveauxMap,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFiliereSection(
    String filiere,
    List<String> sortedNiveauKeys,
    Map<String, List<Niveau>> niveauxMap,
  ) {
    final color = _getFiliereColor(filiere);
    final totalClasses = niveauxMap.values.fold(0, (s, l) => s + l.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFiliereIcon(filiere),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFiliereLabel(filiere),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        '$totalClasses classe${totalClasses > 1 ? 's' : ''} · ${sortedNiveauKeys.length} niveau${sortedNiveauKeys.length > 1 ? 'x' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filiere,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: sortedNiveauKeys.map((nl) {
                final classes = niveauxMap[nl]!
                  ..sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
                return _buildNiveauGroup(nl, classes, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauGroup(
    String niveauLabel,
    List<Niveau> classes,
    Color color,
  ) {
    if (classes.length == 1) return _buildSingleClassTile(classes.first, color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  niveauLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${classes.length} séries',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: classes.map((c) => _buildClassChip(c, color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleClassTile(Niveau niveau, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (niveau.nom ?? '?').substring(
                  0,
                  (niveau.nom?.length ?? 0).clamp(0, 2),
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  niveau.nom ?? 'Classe',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                if (niveau.niveau != null && niveau.niveau!.isNotEmpty)
                  Text(
                    'Niveau : ${niveau.niveau}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (niveau.code != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                niveau.code!,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassChip(Niveau niveau, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            niveau.nom ?? '?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (niveau.serie != null && niveau.serie!.isNotEmpty)
            Text(
              'Série ${niveau.serie}',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }

  Color _getFiliereColor(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return const Color(0xFF3B82F6);
      case 'GENERAL':
        return const Color(0xFF8B5CF6);
      case 'TECHNIQUE':
        return const Color(0xFF10B981);
      case 'PROFESSIONNEL':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getFiliereIcon(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return Icons.child_care_rounded;
      case 'GENERAL':
        return Icons.menu_book_rounded;
      case 'TECHNIQUE':
        return Icons.precision_manufacturing_rounded;
      case 'PROFESSIONNEL':
        return Icons.work_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getFiliereLabel(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':
        return 'Enseignement Primaire';
      case 'GENERAL':
        return 'Enseignement Général';
      case 'TECHNIQUE':
        return 'Enseignement Technique';
      case 'PROFESSIONNEL':
        return 'Enseignement Professionnel';
      default:
        return f;
    }
  }

  // ── Events tab ─────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    // Ne plus recharger automatiquement les événements ici
    // Ils sont maintenant chargés uniquement lors du clic sur le bouton

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements scolaires',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Découvrez les événements de ${widget.ecole.parametreNom}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingEvents)
          const Center(
            child: CustomLoader(
              message: 'Chargement des événements...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          )
        else if (_eventsError != null)
          _buildTabError(_eventsError!, _loadBlogsEventsAndAvis)
        else if (_schoolEvents.isEmpty)
          _buildTabEmpty(
            Icons.event_outlined,
            'Aucun événement',
            'Aucun événement disponible pour le moment.',
          )
        else
          Column(
            children: [
              // Liste des événements
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schoolEvents.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _buildEventCard(_schoolEvents[i]),
              ),

              // Bouton "Voir plus" ou indicateur de fin
              if (_hasMoreEvents && !_isLoadingMoreEvents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: GestureDetector(
                      onTap: _loadMoreEvents,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.screenOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.screenOrange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.expand_more,
                              color: AppColors.screenOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voir plus',
                              style: TextStyle(
                                color: AppColors.screenOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Indicateur de chargement
              if (_isLoadingMoreEvents)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CustomLoader(
                      message: 'Chargement...',
                      loaderColor: AppColors.screenOrange,
                      size: 32.0,
                      showBackground: false,
                    ),
                  ),
                ),

              // Indicateur de fin de liste
              if (!_hasMoreEvents && _schoolEvents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Fin des événements',
                      style: TextStyle(
                        color: AppColors.screenTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final Color color = event['color'] as Color? ?? AppColors.screenOrange;
    final String? imageUrl = event['image'] as String?;
    final bool isAvailable = event['available'] as bool? ?? true;
    final String title = event['title'] as String? ?? '';
    final String subtitle =
        event['subtitle'] as String? ?? event['establishment'] as String? ?? '';
    final String price = event['price'] as String? ?? 'Gratuit';
    final String date = event['date'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(
        bottom: AppDimensions.getEventCardSpacing(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.getEventCardPadding(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (taille responsive) ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: AppDimensions.getEventImageSize(context),
                height: AppDimensions.getEventImageSize(context),
                color: const Color(0xFFF5F5F5),
                child: Stack(
                  children: [
                    imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: AppDimensions.getEventImageSize(context),
                            height: AppDimensions.getEventImageSize(context),
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFFCCCCCC),
                              size: 30,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.85),
                                  color.withOpacity(0.45),
                                ],
                              ),
                            ),
                            child: Icon(
                              event['icon'] as IconData? ?? Icons.event_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 30,
                            ),
                          ),

                    // Badge COMPLET
                    if (!isAvailable)
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'COMPLET',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Infos (droite) ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: AppDimensions.getEventTitleFontSize(
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône info
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppDimensions.getEventSubtitleFontSize(context),
                      color: AppColors.screenTextSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: AppDimensions.getEventTitleFontSize(
                            context,
                          ),
                          color: isAvailable
                              ? color
                              : AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // Badge date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketPurchaseDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Achat de ticket\n${event['title']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event['date']}'),
            Text('Lieu: ${event['location'] ?? event['establishment']}'),
            Text('Prix: ${event['price']}'),
            const SizedBox(height: 16),
            const Text(
              'Nombre de tickets :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.screenOrange,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.screenOrange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.screenOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.screenTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ticket acheté avec succès!'),
                  backgroundColor: Colors.green[500],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.screenOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ── Scolarité tab ──────────────────────────────────────────────────────────
  Widget _buildScolariteTab() {
    return FutureBuilder<ScolariteResponse>(
      future: _scolariteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement de la scolarité...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildTabError(snapshot.error.toString(), () {
            setState(() {
              _scolariteFuture = ScolariteService.getScolaritesByEcole(
                widget.ecole.parametreCode ?? '',
              );
            });
          });
        }
        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return _buildTabEmpty(
            Icons.account_balance_wallet_outlined,
            'Aucun frais de scolarité',
            'Cette école n\'a pas de frais configurés',
          );
        }
        final scolarites = ScolariteService.filtrerEtTrierScolarites(
          snapshot.data!.data,
        );
        final scolaritesParBranche = ScolariteService.grouperParBranche(
          scolarites,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frais de scolarité',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Frais par branche et statut',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.screenSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.screenDivider),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: FocusNode(),
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) {
                  setState(() => _searchQuery = v.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un niveau...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.screenOrange,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...scolaritesParBranche.entries
                .where(
                  (e) =>
                      _searchQuery.isEmpty ||
                      e.key.toLowerCase().contains(_searchQuery),
                )
                .map(
                  (e) => StatefulBuilder(
                    builder: (context, setState) {
                      String? expandedBranche = _expandedBranche;
                      return _buildBrancheSection(
                        e.key,
                        e.value,
                        setState,
                        expandedBranche,
                        (newValue) {
                          setState(() => expandedBranche = newValue);
                          setState(() => _expandedBranche = newValue);
                        },
                      );
                    },
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildBrancheSection(
    String branche,
    List<Scolarite> scolarites,
    StateSetter setState,
    String? expandedBranche,
    Function(String?) onExpandedChanged,
  ) {
    final scolaritesParStatut = ScolariteService.separerParStatut(scolarites);
    final affectes = scolaritesParStatut['AFF'] ?? [];
    final nonAffectes = scolaritesParStatut['NAFF'] ?? [];
    final totaux = ScolariteService.calculerTotauxParStatut(scolarites);
    final isExpanded = expandedBranche == branche;
    return GestureDetector(
      onTap: () => onExpandedChanged(isExpanded ? null : branche),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          // border: Border.all(
                          //   color: Colors.grey.withOpacity(0.3),
                          //   width: 1,
                          // ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branche,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(
                                  16,
                                ),
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenOrange,
                              ),
                            ),
                            Text(
                              '${scolarites.length} frais',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.screenTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTotalItem(
                          'Affectés',
                          totaux['AFF'] ?? 0,
                          const Color(0xFF3B82F6),
                          Icons.check_circle_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.screenDivider,
                        ),
                        _buildTotalItem(
                          'Non Affectés',
                          totaux['NAFF'] ?? 0,
                          const Color(0xFFEF4444),
                          Icons.remove_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (affectes.isNotEmpty) ...[
                            _buildStatutSection(
                              title: 'Montants affectés',
                              scolarites: affectes,
                              color: const Color(0xFF3B82F6),
                              isAffecte: true,
                              totalMontant: totaux['AFF'] ?? 0,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (nonAffectes.isNotEmpty)
                            _buildStatutSection(
                              title: 'Montants non affectés',
                              scolarites: nonAffectes,
                              color: const Color(0xFFEF4444),
                              isAffecte: false,
                              totalMontant: totaux['NAFF'] ?? 0,
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(
    String label,
    int montant,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ScolariteService.formaterMontant(montant),
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatutSection({
    required String title,
    required List<Scolarite> scolarites,
    required Color color,
    required bool isAffecte,
    required int totalMontant,
  }) {
    final scolaritesParRubrique = ScolariteService.separerParRubrique(
      scolarites,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ScolariteService.formaterMontant(totalMontant),
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...scolaritesParRubrique.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  entry.key == 'INS' ? 'Inscription' : 'Scolarité',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
              ),
              ...entry.value.map((s) => _buildScolariteCard(s, color)).toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScolariteCard(Scolarite scolarite, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            scolarite.rubrique == 'INS'
                ? Icons.how_to_reg_rounded
                : Icons.menu_book_rounded,
            color: color,
            size: 16,
          ),
        ),
        title: Text(
          ScolariteService.formaterMontant(scolarite.totalMontant ?? 0),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        subtitle: Text(
          'Date limite: ${scolarite.dateLimiteFormatee}',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.screenTextSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            ScolariteService.getStatutLibelle(scolarite.statut),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Notes (Avis) tab ───────────────────────────────────────────────────────
  Widget _buildNotesTab() {
    // Toujours charger les avis quand on ouvre l'onglet pour s'assurer que les données sont à jour
    print(
      '🔍 DEBUG: _buildNotesTab appelé - _avis.isEmpty: ${_avis.isEmpty}, _avisError: $_avisError, _isLoadingAvis: $_isLoadingAvis',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes et Avis',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Avis des parents et élèves sur ${widget.ecole.parametreNom}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingAvis)
          const Center(
            child: CustomLoader(
              message: 'Chargement des avis...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          )
        else if (_avisError != null)
          Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _avisError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.screenTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _loadAvisOnly,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          )
        else if (_avis.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rate_outlined,
                      size: 40,
                      color: AppColors.screenOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun avis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aucun avis disponible.\nSoyez le premier à donner votre avis !',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.screenTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showActionBottomSheet('rating', _kActions['rating']!),
                    icon: const Icon(Icons.star_rate_rounded, size: 18),
                    label: const Text('Donner mon avis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.screenOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._avis.map((a) => _buildAvisCard(a)).toList(),
      ],
    );
  }

  // ── Widget pour afficher les étoiles de rating ───────────────────────────────────
  Widget _buildStarRating(int rating, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 20,
          color: index < rating ? color : color.withOpacity(0.3),
        );
      }),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avi) {
    final Color color = avi['color'] as Color? ?? AppColors.screenOrange;
    final int statut = avi['statut'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    avi['icon'] as IconData? ?? Icons.person_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              avi['auteur'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        avi['date'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStarRating(statut, color),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                        child: Text(
                          avi['content'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (avi['image'] != null &&
                          (avi['image'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageHelper.buildNetworkImage(
                              imageUrl: avi['image'] as String,
                              placeholder: '',
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16),
                      //   child: Text(
                      //     avi['content'] as String? ?? '',
                      //     style: const TextStyle(
                      //       fontSize: 13,
                      //       color: AppColors.screenTextSecondary,
                      //       height: 1.5,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Convert date format (JJ/MM/AAAA to AAAA-MM-JJ) ───────────────────────
  String _convertDateFormat(String inputDate) {
    if (inputDate.isEmpty) return '';

    // Remove any spaces and validate format
    final cleanedDate = inputDate.replaceAll(' ', '');
    final dateRegex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

    if (!dateRegex.hasMatch(cleanedDate)) {
      return inputDate; // Return original if format is invalid
    }

    final match = dateRegex.firstMatch(cleanedDate)!;
    final day = match.group(1)!;
    final month = match.group(2)!;
    final year = match.group(3)!;

    return '$year-$month-$day';
  }

  // ── Submit integration ─────────────────────────────────────────────────────
  void _submitIntegrationRequest() async {
    // Reset error states
    setState(() {
      _studentNameError = false;
      _studentFirstNameError = false;
      _matriculeError = false;
      _birthDateError = false;
      _adresseError = false;
      _contact1Error = false;
      _nomPereError = false;
      _nomMereError = false;
    });

    // Check for empty required fields
    bool hasError = false;

    if (_studentNameController.text.isEmpty) {
      setState(() => _studentNameError = true);
      hasError = true;
    }
    if (_studentFirstNameController.text.isEmpty) {
      setState(() => _studentFirstNameError = true);
      hasError = true;
    }
    if (_matriculeController.text.isEmpty) {
      setState(() => _matriculeError = true);
      hasError = true;
    }
    if (_birthDateController.text.isEmpty) {
      setState(() => _birthDateError = true);
      hasError = true;
    }
    if (_adresseController.text.isEmpty) {
      setState(() => _adresseError = true);
      hasError = true;
    }
    if (_contact1Controller.text.isEmpty) {
      setState(() => _contact1Error = true);
      hasError = true;
    }
    if (_nomPereController.text.isEmpty) {
      setState(() => _nomPereError = true);
      hasError = true;
    }
    if (_nomMereController.text.isEmpty) {
      setState(() => _nomMereError = true);
      hasError = true;
    }

    if (hasError) {
      // Use the GlobalKey to show SnackBar above the bottom sheet
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Validation format date (JJ/MM/AAAA)
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(_birthDateController.text)) {
      setState(() => _birthDateError = true);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Format de date invalide. Utilisez JJ/MM/AAAA'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final requestData = <String, dynamic>{
      'nom': _studentNameController.text,
      'prenoms': _studentFirstNameController.text,
      'matricule': _matriculeController.text,
      'sexe': _selectedSexe,
      'date_naissance': _convertDateFormat(_birthDateController.text),
      'lieu_naissance':
          _lieuNaissanceController.text, // plus de null, chaîne vide si vide
      'nationalite': _nationaliteController.text.isNotEmpty
          ? _nationaliteController.text
          : 'Ivoirienne',
      'adresse': _adresseController.text, // plus de null
      'contact_1': _contact1Controller.text,
      'contact_2': _contact2Controller.text, // plus de null
      'nom_pere': _nomPereController.text.isNotEmpty
          ? _nomPereController.text
          : null,
      'nom_mere': _nomMereController.text.isNotEmpty
          ? _nomMereController.text
          : null,
      'nom_tuteur': _nomTuteurController.text, // plus de null
      'niveau_ant': _niveauAntController.text,
      'ecole_ant': _ecoleAntController.text,
      'moyenne_ant': _moyenneAntController.text,
      'rang_ant': _rangAntController.text.isNotEmpty
          ? int.tryParse(_rangAntController.text)
          : '',
      'decision_ant': _decisionAntController.text,
      'bulletin': _bulletinFile ?? '',
      'certificat_vaccination': _certificatVaccinationFile ?? '',
      'certificat_scolarite': _certificatScolariteFile ?? '',
      'extrait_naissance': _extraitNaissanceFile ?? '',
      'cni_parent': _cniParentFile ?? '',
      'motif': _motifController.text.isNotEmpty
          ? _motifController.text
          : 'Nouvelle inscription',
      'statut_aff': _selectedStatutAff,
      'filiere': _filiereController.text.isNotEmpty
          ? _filiereController.text
          : 'primaire',
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Fond transparent
      builder: (_) => CustomLoader(
        message: 'Envoi de la demande...',
        loaderColor: Colors.red,
        size: 80.0,
        showBackground: true,
        backgroundColor: Colors.white.withOpacity(0.9),
      ),
    );
    try {
      final result = await IntegrationService.submitIntegrationRequest(
        widget.ecole.parametreCode ?? '',
        requestData,
      );
      Navigator.of(context).pop(); // ferme le loader

      if (result['success'] == true) {
        Navigator.of(context).pop(); // ferme le bottom sheet
        // Attendre la fin de l'animation du bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text('Demande d\'intégration envoyée avec succès!'),
            backgroundColor: Colors.green[500],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        final responseData = result['data'];
        if (responseData != null && responseData['demande_uid'] != null) {
          _showSuccessDialog(responseData['demande_uid']);
        }
      } else {
        Navigator.of(context).pop(); // ferme le bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // ferme le loader
      Navigator.of(context).pop(); // ferme le bottom sheet
      await Future.delayed(const Duration(milliseconds: 300));
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccessDialog(String demandeUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône succès
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              const Text(
                'Demande envoyée !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Sous-titre
              const Text(
                'Votre demande d\'intégration a été soumise avec succès et est en cours de traitement.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Numéro de suivi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEFF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.screenOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tag_rounded,
                            color: AppColors.screenOrange,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Numéro de suivi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A8A9A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      demandeUid,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OK, j\'ai compris',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab helpers ────────────────────────────────────────────────────────────
  Widget _buildTabError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red[300]),
            const SizedBox(height: 12),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.screenOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabEmpty(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.screenOrangeLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.screenOrange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
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
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FORMS
  // ══════════════════════════════════════════════════════════════════════════

  // ── Shared form field helpers ─────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(Icons.circle, size: 6, color: AppColors.screenOrange),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.screenTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdown(
    String label,
    String hint,
    IconData icon, {
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.screenOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: AppColors.screenOrange, size: 18),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.screenOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrangeLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.screenOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Divider(color: AppColors.screenDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _intersperse(children, const SizedBox(height: 12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) result.add(separator);
    }
    return result;
  }

  // ── Integration form ───────────────────────────────────────────────────────
  Widget _buildIntegrationForm() {
    final actionColor = _kActions['integration']!.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Informations de l\'élève',
          icon: Icons.person_rounded,
          children: [
            CustomTextField(
              label: 'Nom',
              hint: 'Entrez le nom complet',
              icon: Icons.person_rounded,
              controller: _studentNameController,
              required: true,
              hasError: _studentNameError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Prénoms',
              hint: 'Entrez les prénoms',
              icon: Icons.person_outline_rounded,
              controller: _studentFirstNameController,
              required: true,
              hasError: _studentFirstNameError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Matricule',
              hint: 'Entrez le matricule',
              icon: Icons.badge_rounded,
              controller: _matriculeController,
              required: true,
              hasError: _matriculeError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            StatefulBuilder(
              builder: (context, ss) => _buildDropdown(
                'Sexe',
                'Sélectionner le sexe',
                Icons.person_rounded,
                value: _selectedSexe,
                items: ['M', 'F'],
                onChanged: (v) => ss(() => _selectedSexe = v ?? 'M'),
              ),
            ),
            CustomTextField(
              label: 'Date de naissance',
              hint: 'JJ/MM/AAAA',
              icon: Icons.cake_rounded,
              controller: _birthDateController,
              keyboardType: TextInputType.number,
              required: true,
              hasError: _birthDateError,
              inputFormatters: [_DateInputFormatter()],
            ),
            CustomTextField(
              label: 'Lieu de naissance',
              hint: 'Entrez le lieu de naissance',
              icon: Icons.location_on_rounded,
              controller: _lieuNaissanceController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Nationalité',
              hint: 'Entrez la nationalité',
              icon: Icons.flag_rounded,
              controller: _nationaliteController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Adresse',
              hint: 'Entrez l\'adresse complète',
              icon: Icons.home_rounded,
              controller: _adresseController,
              maxLines: 2,
              required: true,
              hasError: _adresseError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
          ],
        ),
        _formSectionCard(
          title: 'Contacts',
          icon: Icons.phone_rounded,
          children: [
            CustomTextField(
              label: 'Contact 1',
              hint: 'Numéro principal',
              icon: Icons.phone_rounded,
              controller: _contact1Controller,
              keyboardType: TextInputType.phone,
              required: true,
              hasError: _contact1Error,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Contact 2',
              hint: 'Numéro secondaire',
              icon: Icons.phone_android_rounded,
              controller: _contact2Controller,
              keyboardType: TextInputType.phone,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
          ],
        ),
        _formSectionCard(
          title: 'Informations des parents',
          icon: Icons.family_restroom_rounded,
          children: [
            CustomTextField(
              label: 'Nom du père',
              hint: 'Nom complet du père',
              icon: Icons.person_rounded,
              controller: _nomPereController,
              required: true,
              hasError: _nomPereError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Nom de la mère',
              hint: 'Nom complet de la mère',
              icon: Icons.person_outline_rounded,
              controller: _nomMereController,
              required: true,
              hasError: _nomMereError,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Nom du tuteur',
              hint: 'Nom du tuteur (optionnel)',
              icon: Icons.supervisor_account_rounded,
              controller: _nomTuteurController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
          ],
        ),
        _formSectionCard(
          title: 'Scolarité antérieure',
          icon: Icons.school_rounded,
          children: [
            CustomTextField(
              label: 'Niveau antérieur',
              hint: 'Ex: CP1, 6ème...',
              icon: Icons.school_rounded,
              controller: _niveauAntController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'École antérieure',
              hint: 'Nom de l\'école précédente',
              icon: Icons.account_balance_rounded,
              controller: _ecoleAntController,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Moyenne antérieure',
              hint: 'Ex: 12.5',
              icon: Icons.grade_rounded,
              controller: _moyenneAntController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Rang antérieur',
              hint: 'Ex: 3ème',
              icon: Icons.format_list_numbered_rounded,
              controller: _rangAntController,
              keyboardType: TextInputType.number,
              iconColor: actionColor,
              focusBorderColor: actionColor,
            ),
            CustomTextField(
              label: 'Décision',
              hint: 'Ex: Passage, Redoublement...',
              icon: Icons.gavel_rounded,
              controller: _decisionAntController,
            ),
          ],
        ),
        _formSectionCard(
          title: 'Documents à fournir',
          icon: Icons.description_rounded,
          children: [
            CustomFileField(
              label: 'Bulletin scolaire',
              hint: 'Sélectionner le bulletin',
              icon: Icons.description_rounded,
              fileName: _bulletinFile,
              onTap: () => _showFilePickerMessage('bulletin'),
            ),
            CustomFileField(
              label: 'Certificat de vaccination',
              hint: 'Sélectionner le certificat',
              icon: Icons.medical_services_rounded,
              fileName: _certificatVaccinationFile,
              onTap: () => _showFilePickerMessage('certificat_vaccination'),
            ),
            CustomFileField(
              label: 'Certificat de scolarité',
              hint: 'Sélectionner le certificat',
              icon: Icons.school_rounded,
              fileName: _certificatScolariteFile,
              onTap: () => _showFilePickerMessage('certificat_scolarite'),
            ),
            CustomFileField(
              label: 'Extrait de naissance',
              hint: 'Sélectionner l\'extrait',
              icon: Icons.card_membership_rounded,
              fileName: _extraitNaissanceFile,
              onTap: () => _showFilePickerMessage('extrait_naissance'),
            ),
            CustomFileField(
              label: 'CNI des parents',
              hint: 'Sélectionner la CNI',
              icon: Icons.credit_card_rounded,
              fileName: _cniParentFile,
              onTap: () => _showFilePickerMessage('cni_parent'),
            ),
          ],
        ),
        _formSectionCard(
          title: 'Détails de la demande',
          icon: Icons.note_rounded,
          children: [
            CustomTextField(
              label: 'Motif',
              hint: 'Ex: Nouvelle inscription, Transfert...',
              icon: Icons.note_rounded,
              controller: _motifController,
            ),
            StatefulBuilder(
              builder: (context, ss) => _buildDropdown(
                'Statut d\'affectation',
                'Sélectionner le statut',
                Icons.assignment_turned_in_rounded,
                value: _selectedStatutAff,
                items: ['Affecté', 'En attente', 'Refusé'],
                onChanged: (v) => ss(() => _selectedStatutAff = v ?? 'Affecté'),
              ),
            ),
            CustomTextField(
              label: 'Filière',
              hint: 'Ex: primaire, secondaire, technique...',
              icon: Icons.category_rounded,
              controller: _filiereController,
            ),
          ],
        ),
        CustomFormButton(
          text: 'Envoyer la demande',
          color: AppColors.screenOrange,
          icon: Icons.send_rounded,
          onPressed: () {
            _submitIntegrationRequest();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showFilePickerMessage(String fileType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sélection de fichier pour: $fileType'),
        backgroundColor: AppColors.screenOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Rating form ────────────────────────────────────────────────────────────
  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.grade_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Votre note',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, ss) {
                  final current = int.tryParse(_ratingController.text) ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final selected = current > i;
                      return GestureDetector(
                        onTap: () => ss(
                          () => _ratingController.text = (i + 1).toString(),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFF8E0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            selected
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: selected
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFDDDDDD),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Comment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.screenDivider),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.screenTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Votre commentaire',
              hintText: 'Partagez votre expérience...',
              labelStyle: const TextStyle(
                color: AppColors.screenTextSecondary,
                fontWeight: FontWeight.w600,
              ),
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 4, right: 8),
                child: Icon(
                  Icons.comment_rounded,
                  color: AppColors.screenOrange,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomFormButton(
          text: 'Envoyer le témoignage',
          color: const Color(0xFFF59E0B),
          icon: Icons.star_rounded,
          onPressed: () async {
            if (_ratingController.text.isEmpty ||
                _commentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Veuillez remplir la note et le commentaire',
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return;
            }
            final currentUser = AuthService().getCurrentUser();
            if (currentUser == null || currentUser.phone.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Utilisateur non connecté'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return;
            }
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent, // Fond transparent
              builder: (_) => CustomLoader(
                message: 'Envoi du témoignage...',
                loaderColor: const Color(0xFFF59E0B),
                size: 56.0,
                showBackground: true,
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
            );
            try {
              final result = await TestimonialService.submitTestimonial(
                codeecole: widget.ecole.parametreCode ?? '',
                note: _ratingController.text,
                contenu: _commentController.text,
                userNumero: currentUser.phone,
              );
              Navigator.of(context).pop();
              if (result['success'] == true) {
                Navigator.of(context).pop();
                _ratingController.clear();
                _commentController.clear();
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: const Text('Témoignage envoyé avec succès!'),
                    backgroundColor: Colors.green[500],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Erreur lors de l\'envoi',
                    ),
                    backgroundColor: Colors.red[400],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (_) {
              Navigator.of(context).pop();
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: const Text('Erreur lors de l\'envoi du témoignage'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Informations content ───────────────────────────────────────────────────
  Widget _buildInformationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewSection(),
        const SizedBox(height: 16),
        _buildContactSection(),
        const SizedBox(height: 16),
        _buildInfoSection(),
        const SizedBox(height: 16),
        _buildDetailedInfoSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Overview section ───────────────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.screenOrange.withOpacity(0.08),
            AppColors.screenOrange.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.screenOrange.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.screenOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.screenOrange,
                      ),
                    ),
                    Text(
                      widget.ecole.parametreNom ?? 'Établissement',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Type',
                  widget.ecole.typePrincipal,
                  Icons.category_rounded,
                  _getTypeColor(widget.ecole.typePrincipal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Statut',
                  widget.ecole.statut ?? 'Actif',
                  Icons.verified_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.ecole.parametreNom ?? 'Aucune description disponible',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    color: AppColors.screenTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(9),
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.bold,
                    color: AppColors.screenTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact section ────────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      'Informations de contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactInfoCard(
            'Adresse',
            '${widget.ecole.adresse ?? 'Non disponible'}, ${widget.ecole.ville ?? ''}, ${widget.ecole.pays ?? ''}',
            Icons.location_on_rounded,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          if (widget.ecole.telephone?.isNotEmpty == true) ...[
            _buildContactInfoCard(
              'Téléphone',
              widget.ecole.telephone!,
              Icons.phone_rounded,
              Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          FutureBuilder<EcoleDetail>(
            future: EcoleApiService.getEcoleDetail(
              widget.ecole.parametreCode ?? '',
            ),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final d = snap.data!.data;
              return Column(
                children: [
                  if (d.email?.isNotEmpty == true) ...[
                    _buildContactInfoCard(
                      'Email',
                      d.email!,
                      Icons.email_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (d.site?.isNotEmpty == true)
                    _buildContactInfoCard(
                      'Site web',
                      d.site!,
                      Icons.web_rounded,
                      Colors.purple,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info section ───────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.08),
            Colors.green.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Détails administratifs',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoDetailCard(
            'Code établissement',
            widget.ecole.parametreCode ?? 'Non disponible',
            Icons.code_rounded,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 8),
          _buildInfoDetailCard(
            'Ville',
            widget.ecole.ville ?? 'Non spécifiée',
            Icons.location_city_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildInfoDetailCard(
            'Pays',
            widget.ecole.pays ?? 'Non spécifié',
            Icons.public_rounded,
            Colors.purple,
          ),
          const SizedBox(height: 8),
          if (widget.ecole.filiereNom.isNotEmpty)
            _buildInfoDetailCard(
              'Filières',
              widget.ecole.filiereNom.join(', '),
              Icons.school_rounded,
              const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Detailed info from API (logo, infos académiques, infra, rubriques) ─────
  Widget _buildDetailedInfoSection() {
    return FutureBuilder<EcoleDetail>(
      future: EcoleApiService.getEcoleDetail(widget.ecole.parametreCode ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CustomLoader(
              message: 'Chargement des informations...',
              loaderColor: AppColors.screenOrange,
              size: 56.0,
              showBackground: false,
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData)
          return const SizedBox.shrink();
        final detail = snapshot.data!;
        final data = detail.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero logo card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(20),
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
                  if (data.logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        data.logo!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.screenSurface,
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.screenOrange,
                        size: 30,
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.nom,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenTextPrimary,
                          ),
                          maxLines: 2,
                        ),
                        if (data.slogan != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.slogan!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.screenOrange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _infoCard('Informations principales', [
              _infoDetailRow('Code', data.code),
              _infoDetailRow('Type', data.type),
              _infoDetailRow('Statut', data.statut),
              _infoDetailRow('Période', data.periode),
              _infoDetailRow('Année', data.annee),
            ]),
            _infoCard('Informations académiques', [
              _infoDetailRow('Directeur rentrée', data.dren),
              _infoDetailRow(
                'Nbre d\'années',
                data.nbrannee?.toString() ?? 'N/A',
              ),
              _infoDetailRow('Mode inscription', data.modeinsc.toString()),
              _infoDetailRow(
                'Statut inscription',
                data.inscriptionsatatus.toString(),
              ),
              if (detail.client.effectif != null)
                _infoDetailRow('Effectif', '${detail.client.effectif} élèves'),
            ]),
            if (data.montantReservation != null && data.montantReservation! > 0)
              _infoCard('Réservations', [
                _infoDetailRow('Montant', '${data.montantReservation} FCFA'),
                _infoDetailRow('Début', data.debutReservation ?? 'N/A'),
                _infoDetailRow('Fin', data.finReservation ?? 'N/A'),
              ]),
            if (detail.infrastructures.isNotEmpty)
              _infoCard(
                'Infrastructure & services',
                detail.infrastructures
                    .map(
                      (i) => _infoDetailRow(
                        i['nom']?.toString() ?? 'Service',
                        i['description']?.toString() ?? 'Disponible',
                      ),
                    )
                    .toList(),
              ),
            if (detail.rubriques.isNotEmpty)
              _infoCard(
                'Rubriques',
                detail.rubriques
                    .map(
                      (r) => _infoDetailRow(
                        r['nom']?.toString() ?? 'Rubrique',
                        r['description']?.toString() ?? 'Disponible',
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Divider(color: AppColors.screenDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONSULT REQUESTS CONTENT ───────────────────────────────────────────────
  Widget _buildConsultRequestsContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = _kActions['consult_requests']!.color;
    final TextEditingController _matriculeController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          /*Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Consulter mes demandes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez le statut de votre demande d\'intégration',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),*/

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white24 : AppColors.screenDivider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.screenOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comment faire ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppColors.screenTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '1.',
                  'Entrez votre matricule dans le champ ci-dessous',
                  isDark,
                ),
                _buildInstructionStep(
                  '2.',
                  'Cliquez sur "Consulter" pour vérifier votre demande',
                  isDark,
                ),
                _buildInstructionStep(
                  '3.',
                  'Le résultat s\'affichera instantanément',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Matricule input
          Text(
            'Votre matricule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Matricule',
            hint: 'Ex: 1234RTFGHJ',
            icon: Icons.badge_rounded,
            controller: _matriculeController,
            keyboardType: TextInputType.text,
            iconColor: actionColor,
            focusBorderColor: actionColor,
          ),
          const SizedBox(height: 20),

          // Consult button
          CustomFormButton(
            text: 'Consulter ma demande',
            icon: Icons.star_rounded,
            onPressed: () => _submitConsultRequest(_matriculeController.text),
            color: actionColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitConsultRequest(String matricule) async {
    if (matricule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un matricule'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoader(
        message: 'Consultation en cours...',
        loaderColor: Color(0xFF06B6D4),
      ),
    );

    try {
      final result = await IntegrationRequestService.consultIntegrationRequest(
        ecoleCode: widget.ecole.parametreCode ?? 'gainhs',
        matricule: matricule,
      );

      // Close loader
      Navigator.of(context).pop();

      if (result['success'] == true) {
        _showIntegrationResultDialog(result['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la consultation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loader
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIntegrationResultDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: data['statut'] == 2 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  data['statut'] == 2
                      ? Icons.check_rounded
                      : Icons.info_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Résultat de votre demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Text(
                data['message'] ?? 'Aucun message disponible',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CustomTabBarDelegate(this.child);
  @override
  double get minExtent => 58.0;
  @override
  double get maxExtent => 58.0;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(_CustomTabBarDelegate old) => false;
}
