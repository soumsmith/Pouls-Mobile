import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/widgets/section_header_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/components/section_row.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';
import '../services/ecole_api_service.dart';
import '../services/recommendation_service.dart';
import '../services/integration_service.dart';
import '../services/video_api_service.dart';
import '../models/ecole.dart';
import '../models/video.dart';
import '../models/coulisse_excellence.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/see_more_card.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_row_widget.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/image_menu_card.dart';
import '../widgets/app_loader.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import 'all_events_screen.dart';
import 'coulisse_video_feed_screen.dart';
import 'establishment_detail_screen.dart';
import '../widgets/bottom_sheets/integration_bottom_sheet.dart';
import '../widgets/bottom_sheets/rating_bottom_sheet.dart';
import '../widgets/bottom_fade_gradient.dart';

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
    label: 'Intégrer',
    subtitle: 'Inscrire',
    color: Color(0xFFF59E0B),
  ),
  'rating': _ActionDef(
    icon: Icons.star_rate_rounded,
    label: 'Noter',
    subtitle: 'Évaluer',
    color: Color(0xFF10B981),
  ),
  'sponsorship': _ActionDef(
    icon: Icons.card_giftcard_rounded,
    label: 'Parrainer',
    subtitle: 'Inviter',
    color: Color(0xFFF59E0B),
  ),
  'share': _ActionDef(
    icon: Icons.share_rounded,
    label: 'Partager',
    subtitle: 'Envoyer',
    color: Color(0xFF3B82F6),
  ),
  'recommend': _ActionDef(
    icon: Icons.thumb_up_rounded,
    label: 'Recommander',
    subtitle: 'Suggérer',
    color: Color(0xFF8B5CF6),
  ),
  'events': _ActionDef(
    icon: Icons.event_rounded,
    label: 'Événements',
    subtitle: 'Découvrir',
    color: Color(0xFF6366F1),
  ),
};

// ─── Color per school type ────────────────────────────────────────────────────
Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'primaire':
      return const Color(0xFF3B82F6);
    case 'collège':
      return const Color(0xFF8B5CF6);
    case 'lycée':
      return const Color(0xFF10B981);
    case 'privé':
      return AppColors.screenOrange;
    case 'public':
      return const Color(0xFF6366F1);
    default:
      return const Color(0xFFEF4444);
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class EstablishmentScreen extends StatefulWidget implements MainScreenChild {
  const EstablishmentScreen({super.key});

  @override
  State<EstablishmentScreen> createState() => _EstablishmentScreenState();
}

class _EstablishmentScreenState extends State<EstablishmentScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _textSizeService = TextSizeService();
  double _currentTextScale = 1.0;
  List<Ecole> _ecoles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreEcoles = true;
  int _currentPage = 1;
  int _ecolesPerPage = 50;
  String? _error;

  // ── Paramètres de recherche dynamique ──────────────────────────────
  String? _pays;
  String? _ville;
  String? _quartier;
  String? _nomEtablissement;
  String? _categorie;
  String? _codepays;

  // Controllers pour les champs de recherche avancée
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _nomEtablissementController = TextEditingController();
  final _categorieController = TextEditingController();
  final _codepaysController = TextEditingController();

  // Controllers pour le formulaire de recommandation
  final _recommenderNameController = TextEditingController();
  final _etablissementController = TextEditingController();
  final _paysRecommendController = TextEditingController();
  final _villeRecommendController = TextEditingController();
  final _commentsController = TextEditingController();
  final _parentNomController = TextEditingController();
  final _parentPrenomController = TextEditingController();
  final _parentTelephoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _ordreController = TextEditingController();
  final _adresseEtablissementController = TextEditingController();
  final _paysParentController = TextEditingController();
  final _villeParentController = TextEditingController();
  final _adresseParentController = TextEditingController();

  // ── Timer pour debounce ───────────────────────────────────────
  Timer? _searchTimer;

  // ── Timer pour slider auto-défilement ────────────────────────
  Timer? _sliderTimer;
  final PageController _sliderController = PageController();
  int _currentSliderIndex = 0;
  bool _showSliderText = false;

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  int _getCrossAxisCount(BuildContext context) {
    return AppDimensions.getEcolesGridColumns(context);
  }

  // ── Données du slider d'écoles ───────────────────────────────
  List<Map<String, String>> _featuredSchools = [];
  List<Video> _videos = [];
  bool _isLoadingVideos = false;
  String? _videoError;

  final List<String> _filters = [
    'Tous',
    'Primaire',
    'Collège',
    'Lycée',
    'Privé',
    'Public',
  ];

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _currentTextScale = _textSizeService.getScale();
    _textSizeService.addListener(_onTextSizeChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadEcoles();
    _loadVideos();
    _initializeFeaturedSchools();
    _startSliderAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ecolesPerPage = AppDimensions.getEcolesPerPage(context);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _sliderTimer?.cancel();
    _sliderController.dispose();
    _textSizeService.removeListener(_onTextSizeChanged);
    _searchController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _nomEtablissementController.dispose();
    _categorieController.dispose();
    _codepaysController.dispose();
    _recommenderNameController.dispose();
    _etablissementController.dispose();
    _paysRecommendController.dispose();
    _villeRecommendController.dispose();
    _commentsController.dispose();
    _parentNomController.dispose();
    _parentPrenomController.dispose();
    _parentTelephoneController.dispose();
    _parentEmailController.dispose();
    _ordreController.dispose();
    _adresseEtablissementController.dispose();
    _paysParentController.dispose();
    _villeParentController.dispose();
    _adresseParentController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTextSizeChanged() {
    if (mounted) {
      setState(() => _currentTextScale = _textSizeService.getScale());
    }
  }

  // ── Slider auto-défilement ───────────────────────────────────
  void _startSliderAutoScroll() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_sliderController.hasClients && mounted) {
        if (_currentSliderIndex < _featuredSchools.length - 1) {
          _currentSliderIndex++;
        } else {
          _currentSliderIndex = 0;
        }
        _sliderController.animateToPage(
          _currentSliderIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSliderPageChanged(int index) {
    setState(() {
      _currentSliderIndex = index;
    });
    _sliderTimer?.cancel();
    _startSliderAutoScroll();
  }

  // ── Data ───────────────────────────────────────────────────

  // Initialiser les écoles statiques de base (vides pour ne garder que les vidéos de l'API)
  void _initializeFeaturedSchools() {
    _featuredSchools = [];
  }

  // Charger les vidéos depuis l'API
  Future<void> _loadVideos() async {
    if (!mounted) return;
    setState(() {
      _isLoadingVideos = true;
      _videoError = null;
    });

    try {
      final videos = await VideoApiService.getVideosForSchool('gainhs');
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoadingVideos = false;
          _addVideosToSlider();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = e.toString();
          _isLoadingVideos = false;
        });
      }
    }
  }

  // Ajouter les vidéos au slider
  void _addVideosToSlider() {
    final List<Map<String, String>> videoItems = _videos.map((video) {
      return {
        'name': _getVideoDisplayName(video.typeVideo),
        'type': 'Vidéo',
        'location': 'Abidjan',
        'video': video.youtubeUrl,
        'rating': '4.9',
        'description': _getVideoDescription(video.typeVideo),
        'videoType': video.typeVideo,
      };
    }).toList();

    setState(() {
      _featuredSchools = videoItems;
    });
  }

  // Obtenir le nom d'affichage selon le type de vidéo
  String _getVideoDisplayName(String typeVideo) {
    switch (typeVideo.toLowerCase()) {
      case 'visiteguide':
        return 'Visite Guidée';
      case 'presentation':
        return 'Présentation';
      default:
        return 'Vidéo';
    }
  }

  // Obtenir la description selon le type de vidéo
  String _getVideoDescription(String typeVideo) {
    switch (typeVideo.toLowerCase()) {
      case 'visiteguide':
        return 'Découvrez nos installations en vidéo';
      case 'presentation':
        return 'Présentation de notre établissement';
      default:
        return 'Découvrez notre établissement en vidéo';
    }
  }

  Future<void> _loadEcoles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _ecoles.clear();
      _currentPage = 1;
      _hasMoreEcoles = true;
    });
    try {
      final ecoles = await EcoleApiService.getEcoles(
        page: _currentPage,
        perPage: _ecolesPerPage,
        pays: _pays,
        ville: _ville,
        quartier: _quartier,
        nomEtablissement: _nomEtablissement,
        categorie: _categorie,
        codepays: _codepays,
      );
      if (mounted) {
        setState(() {
          _ecoles = ecoles;
          _isLoading = false;
          _hasMoreEcoles =
              ecoles.length >= _ecolesPerPage ||
              (_currentPage == 1 && ecoles.isNotEmpty);
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreEcoles() async {
    if (!_hasMoreEcoles || !mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      final newEcoles = await EcoleApiService.getEcoles(
        page: _currentPage,
        perPage: _ecolesPerPage,
        pays: _pays,
        ville: _ville,
        quartier: _quartier,
        nomEtablissement: _nomEtablissement,
        categorie: _categorie,
        codepays: _codepays,
      );
      if (!mounted) return;
      setState(() {
        _ecoles.addAll(newEcoles);
        _isLoadingMore = false;
        _hasMoreEcoles = newEcoles.length >= _ecolesPerPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  List<Ecole> get _filteredItems => _ecoles;

  // ── Recherche ───────────────────────────────────────────────
  void _updateSearchParameters() {
    setState(() {
      _pays = _paysController.text.trim().isEmpty
          ? null
          : _paysController.text.trim();
      _ville = _villeController.text.trim().isEmpty
          ? null
          : _villeController.text.trim();
      _quartier = _quartierController.text.trim().isEmpty
          ? null
          : _quartierController.text.trim();
      _nomEtablissement = _nomEtablissementController.text.trim().isEmpty
          ? null
          : _nomEtablissementController.text.trim();
      _categorie = _categorieController.text.trim().isEmpty
          ? null
          : _categorieController.text.trim();
      _codepays = _codepaysController.text.trim().isEmpty
          ? null
          : _codepaysController.text.trim();
    });
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    setState(() {
      _nomEtablissement = query.trim().isEmpty ? null : query.trim();
    });
    _searchTimer = Timer(const Duration(milliseconds: 800), _loadEcoles);
  }

  void _applyAdvancedSearch() {
    _updateSearchParameters();
    if (_nomEtablissement != null && _nomEtablissement!.isNotEmpty) {
      _searchController.text = _nomEtablissement!;
    } else {
      _searchController.clear();
    }
    _loadEcoles();
  }

  void _clearAdvancedSearch() {
    setState(() {
      _paysController.clear();
      _villeController.clear();
      _quartierController.clear();
      _nomEtablissementController.clear();
      _categorieController.clear();
      _codepaysController.clear();
      _pays = _ville = _quartier = _nomEtablissement = _categorie = _codepays =
          null;
      _searchController.clear();
    });
    _loadEcoles();
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_currentTextScale)),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              title: 'Établissements',
              isDark: false,
              onBackTap: () => MainScreenWrapper.of(context).navigateToHome(),
              actions: [
                _buildHeaderAction(
                  icon: _isSearching
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  onTap: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _buildHeaderAction(
                  icon: Icons.tune,
                  onTap: _showAdvancedSearchBottomSheet,
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: SearchBarWidget(
                isSearching: _isSearching,
                searchController: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchTimer?.cancel();
                  setState(() {
                    _searchController.clear();
                    _nomEtablissement = null;
                  });
                  _loadEcoles();
                },
                hintText: 'Rechercher un établissement...',
              ),
            ),
            SliverFillRemaining(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final actionButtonSize = AppDimensions.getActionButtonSize(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: actionButtonSize,
        height: actionButtonSize,
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(
            AppDimensions.getButtonBorderRadius(context),
          ),
          boxShadow: AppColors.screenCardShadowThemed(context),
        ),
        child: Icon(icon, size: 20, color: AppColors.screenTextPrimaryThemed(context)),
      ),
    );
  }

  // ── Advanced Search BottomSheet ─────────────────────────────────//  Advanced Search BottomSheet
  void _showAdvancedSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdvancedSearchBottomSheet(),
    );
  }

  Widget _buildAdvancedSearchBottomSheet() {
    return IntrinsicHeight(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.screenSurfaceThemed(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300Adaptive(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.screenOrange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recherche avancée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearAdvancedSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Effacer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.screenOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.grey100Adaptive(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.grey666Adaptive(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Pays',
                          hint: 'Entrez le pays',
                          icon: Icons.public_rounded,
                          controller: _paysController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Ville',
                          hint: 'Entrez la ville',
                          icon: Icons.location_city_rounded,
                          controller: _villeController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quartier',
                          hint: 'Entrez le quartier',
                          icon: Icons.location_on_rounded,
                          controller: _quartierController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Nom établissement',
                          hint: 'Entrez le nom',
                          icon: Icons.business_rounded,
                          controller: _nomEtablissementController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Catégorie',
                          hint: 'Ex: Primaire, Collège...',
                          icon: Icons.category_rounded,
                          controller: _categorieController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Code pays',
                          hint: 'Entrez le code',
                          icon: Icons.code_rounded,
                          controller: _codepaysController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _applyAdvancedSearch();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Appliquer les filtres',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    return _buildContent();
  }

  Widget _buildLoadingState() {
    return CustomLoader(
      message: 'Chargement des établissements...',
      loaderColor: AppColors.screenOrange,
      backgroundColor: AppColors.screenSurfaceThemed(context),
      showBackground: false,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.isDarkMode(context) 
                    ? const Color(0xFF4A1A1A) 
                    : const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimaryThemed(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                color: AppColors.screenTextSecondaryThemed(context),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadEcoles,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.screenOrangeGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.screenOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final items = _filteredItems;
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // ── Slider des écoles en vedette ─────────────────────
              if (_featuredSchools.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     const Text(
                        //       'Écoles en vedette',
                        //       style: TextStyle(
                        //         fontSize: 16,
                        //         fontWeight: FontWeight.w700,
                        //         color: Color(0xFF1A1A1A),
                        //       ),
                        //     ),
                        //     GestureDetector(
                        //       onTap: () => setState(
                        //         () => _showSliderText = !_showSliderText,
                        //       ),
                        //       child: Container(
                        //         padding: const EdgeInsets.symmetric(
                        //           horizontal: 12,
                        //           vertical: 6,
                        //         ),
                        //         decoration: BoxDecoration(
                        //           color: _showSliderText
                        //               ? AppColors.screenOrange
                        //               : Colors.grey[300],
                        //           borderRadius: BorderRadius.circular(20),
                        //           boxShadow: [
                        //             BoxShadow(
                        //               color:
                        //                   (_showSliderText
                        //                           ? AppColors.screenOrange
                        //                           : Colors.grey[300])!
                        //                       .withOpacity(0.3),
                        //               blurRadius: 4,
                        //               offset: const Offset(0, 2),
                        //             ),
                        //           ],
                        //         ),
                        //         child: Row(
                        //           mainAxisSize: MainAxisSize.min,
                        //           children: [
                        //             Icon(
                        //               _showSliderText
                        //                   ? Icons.visibility_rounded
                        //                   : Icons.visibility_off_rounded,
                        //               size: 16,
                        //               color: _showSliderText
                        //                   ? Colors.white
                        //                   : Colors.grey[600],
                        //             ),
                        //             const SizedBox(width: 6),
                        //             Text(
                        //               _showSliderText ? 'Texte' : 'Image',
                        //               style: TextStyle(
                        //                 fontSize: 12,
                        //                 fontWeight: FontWeight.w600,
                        //                 color: _showSliderText
                        //                     ? Colors.white
                        //                     : Colors.grey[600],
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 8),
                        _FeaturedSchoolsSlider(
                          featuredSchools: _featuredSchools,
                          pageController: _sliderController,
                          onPageChanged: _onSliderPageChanged,
                          currentIndex: _currentSliderIndex,
                          showText: _showSliderText,
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: SectionRow(title: 'ACTIONS RAPIDES')),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),

              // ── Actions Buttons ──
              SliverToBoxAdapter(
                child: _buildActionButtons(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 0)),
              SliverToBoxAdapter(
                child: SectionRow(title: 'Nos etablissements'),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              // ── Filtre horizontal ─────────────────────────────
              SliverToBoxAdapter(
                child: FilterRowWidget(
                  filters: _filters,
                  selectedFilter: _selectedFilter,
                  onFilterSelected: (filter) =>
                      setState(() => _selectedFilter = filter),
                ),
              ),

              // ── Results header ─────────────────────────────


              // ── Empty state ────────────────────────────────
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.screenOrangeLight,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.business_outlined,
                            size: 40,
                            color: AppColors.screenOrange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aucun établissement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimaryThemed(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun résultat pour ce filtre',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedFilter = 'Tous';
                            _searchController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.screenOrangeGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.screenOrange.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Réinitialiser les filtres',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: const SizedBox(height: 10)),

              // ── Grid ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(
                      context,
                    ),
                    childAspectRatio:
                        AppDimensions.getProductsGridChildAspectRatio(
                          context,
                          imageFlex: AppDimensions.getGridImageFlex(context),
                        ),
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    if (i == items.length && _hasMoreEcoles) {
                      return SeeMoreCard(
                        cardColor: AppColors.screenCardThemed(context),
                        borderColor: AppColors.screenOrange.withOpacity(0.3),
                        iconColor: AppColors.screenOrange,
                        textColor: AppColors.screenOrange,
                        subtitleColor: AppColors.screenOrange.withOpacity(0.5),
                        title: _isLoadingMore ? 'Chargement...' : 'Voir plus',
                        subtitle: _isLoadingMore ? '' : 'établissements',
                        onTap: _isLoadingMore ? () {} : _loadMoreEcoles,
                      );
                    }
                    if (i < items.length) {
                      return ImageMenuCardExternalTitle(
                        index: i,
                        cardKey: items[i].ecoleid.toString(),
                        title: items[i].parametreNom ?? 'École sans nom',
                        subtitle: items[i].ville,
                        imagePath: items[i].displayImage,
                        iconData: Icons.business,
                        isDark: false,
                        color: _typeColor(items[i].typePrincipal),
                        location: items[i].adresse,
                        tag: items[i].typePrincipal,
                        titleMaxLines: 2,
                        externalTitleSpacing: 8,
                        height: AppDimensions.getEcoleCardHeight(context),
                        //imageFlex: AppDimensions.getProductCardImageFlex(context),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EstablishmentDetailScreen(ecole: items[i]),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }, childCount: items.length + (_hasMoreEcoles ? 1 : 0)),
                ),
              ),
            ],
          ),
        ),
        // Gradient fade at bottom
        const BottomFadeGradient(),
      ],
    );
  }

  // ── Action buttons (quick actions) ─────────────────────────────────────────
  Widget _buildActionButtons(bool isDark) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildActionButton(
            index: 0,
            cardKey: 'integration',
            title: 'Demande\nintégration',
            actionText: 'Inscrire',
            imagePath: 'assets/images/icons/integration.png',
            color: const Color(0xFF10B981),
                      backgroundColor: isDark
                          ? const Color(0xFFF7FEFC).withOpacity(0.15)
                          : const Color(0xFFF7FEFC),
                      textColor: AppColors.screenTextPrimaryThemed(context),
            isDark: isDark,
            allowLineBreak: true,
            onTap: () => _showActionBottomSheet(
              'integration',
              _kActions['integration']!,
            ),
          ),
          _buildActionButton(
            index: 1,
            cardKey: 'rating',
            title: 'Donner un \n avis',
            actionText: 'Évaluer',
            imagePath: 'assets/images/avis-2.jpg',
             color: const Color(0xFFF59E0B),
                      backgroundColor: isDark
                          ? const Color(0xFFFFFEF7).withOpacity(0.15)
                          : const Color(0xFFFFFEF7),
                      textColor: AppColors.screenTextPrimaryThemed(context),
            isDark: isDark,
            allowLineBreak: true,
            onTap: () => _showActionBottomSheet('rating', _kActions['rating']!),
          ),
          _buildActionButton(
            index: 2,
            cardKey: 'recommend',
            title: 'Recommandation',
            actionText: 'Partager',
            imagePath: 'assets/images/ecole.jpg',
            color: const Color(0xFF0288D1),
            backgroundColor: isDark
                ? const Color(0xFFE3F2FD).withOpacity(0.15)
                : const Color(0xFFE3F2FD),
            textColor: AppColors.screenTextPrimaryThemed(context),
            isDark: isDark,
            allowLineBreak: true,
            onTap: () =>
                _showActionBottomSheet('recommend', _kActions['recommend']!),
          ),
          _buildActionButton(
            index: 3,
            cardKey: 'events',
            title: 'Événement scolaire',
            actionText: 'Voir',
            imagePath: 'assets/images/school-event.jpg',
            color: const Color(0xFF8B5CF6),
                      backgroundColor: isDark
                          ? const Color(0xFFFCFAFF).withOpacity(0.15)
                          : const Color(0xFFFCFAFF),
                      textColor: AppColors.screenTextPrimaryThemed(context),
            
            isDark: isDark,
            allowLineBreak: true,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => AllEventsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required int index,
    required String cardKey,
    required String title,
    required String actionText,
    required String imagePath,
    required Color color,
    required Color backgroundColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
    bool allowLineBreak = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: cardKey,
        title: title,
        width: 70,
        height: 100, // Augmentation de la hauteur pour accommoder les retours à la ligne
        imageFlex: 2,
        imagePath: imagePath,
        isDark: isDark,
        titleFontSize: 11,
        imageBorderRadius: 50,
        centerTitle: true,
        color: color,
        backgroundColor: backgroundColor,
        textColor: textColor,
        //actionText: actionText, // Réactivation de actionText
        actionTextColor: color,
        enableInnerBorder: true,
        enableOuterBorder: true,
        allowLineBreak: allowLineBreak,
        onTap: onTap,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Action bottom sheet dispatcher ───────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionContent(String actionType) {
    switch (actionType) {
      case 'integration':
        return _buildSelectionMessage(
          'Intégration',
          "Veuillez sélectionner un établissement pour faire une demande d'intégration.",
        );
      case 'rating':
        return _buildRatingForm();
      case 'sponsorship':
        return _buildSponsorshipForm();
      case 'share':
        return _buildShareForm();
      case 'recommend':
        return RecommendationBottomSheet(
          accentColor: _kActions['recommend']!.color,
          recommenderNameController: _recommenderNameController,
          etablissementController: _etablissementController,
          paysRecommendController: _paysRecommendController,
          villeRecommendController: _villeRecommendController,
          parentNomController: _parentNomController,
          parentPrenomController: _parentPrenomController,
          parentTelephoneController: _parentTelephoneController,
          parentEmailController: _parentEmailController,
          ordreController: _ordreController,
          adresseEtablissementController: _adresseEtablissementController,
          paysParentController: _paysParentController,
          villeParentController: _villeParentController,
          adresseParentController: _adresseParentController,
          onSubmit: (context) async {
            try {
              await RecommendationService.submitRecommendation(
                etablissement: _etablissementController.text,
                pays: _paysRecommendController.text,
                ville: _villeRecommendController.text,
                ordre: _ordreController.text.isEmpty ? '1' : _ordreController.text,
                adresseEtablissement: _adresseEtablissementController
                        .text.isEmpty
                    ? 'Non spécifiée'
                    : _adresseEtablissementController.text,
                nomParent: _parentNomController.text,
                prenomParent: _parentPrenomController.text,
                telephone: _parentTelephoneController.text,
                email: _parentEmailController.text.isEmpty
                    ? 'email@example.com'
                    : _parentEmailController.text,
                paysParent: _paysParentController.text.isEmpty
                    ? _paysRecommendController.text
                    : _paysParentController.text,
                villeParent: _villeParentController.text.isEmpty
                    ? _villeRecommendController.text
                    : _villeParentController.text,
                adresseParent: _adresseParentController.text.isEmpty
                    ? 'Non spécifiée'
                    : _adresseParentController.text,
              );

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recommandation envoyée avec succès!'),
                  backgroundColor: Colors.green,
                ),
              );

              _etablissementController.clear();
              _paysRecommendController.clear();
              _villeRecommendController.clear();
              _parentNomController.clear();
              _parentPrenomController.clear();
              _parentTelephoneController.clear();
              _parentEmailController.clear();
              _ordreController.clear();
              _adresseEtablissementController.clear();
              _paysParentController.clear();
              _villeParentController.clear();
              _adresseParentController.clear();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      default:
        return const Center(child: Text('Contenu non disponible'));
    }
  }

  Widget _buildSelectionMessage(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline,
            size: 48,
            color: AppColors.screenOrange,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.screenOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingForm() {
    return RatingBottomSheet(
      schoolId: 'general',
      schoolName: 'Établissements',
      schoolColor: _kActions['rating']!.color,
      onRatingSubmitted: (rating, comment) async {
        // Fermer le bottom sheet parent
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis soumis pour les établissements'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  Widget _buildSponsorshipForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = _kActions['sponsorship']!.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Parrainer un établissement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: actionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: actionColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.card_giftcard_rounded, size: 48, color: actionColor),
              const SizedBox(height: 12),
              Text(
                "Invitez d'autres parents à rejoindre un établissement",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Choisir un établissement à parrainer'),
        ),
      ],
    );
  }

  Widget _buildShareForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = _kActions['share']!.color;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.screenDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    size: 24,
                    color: actionColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partager la liste',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez comment partager',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : const Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
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
                      const Color(0xFFEC4899),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partage via $label bientôt disponible'),
            backgroundColor: color,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionBottomSheet(String actionType, _ActionDef def) {
    if (actionType == 'integration') {
      showIntegrationBottomSheet(
        context: context,
        onSuccess: (demandeUid) {},
        onError: (error) {},
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          minHeight: 100,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppColors.screenCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          borderRadius: BorderRadius.circular(12),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.screenTextPrimary,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              def.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.screenTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

// ─── Events Banner Card ───────────────────────────────────────────────────────
class _EventsBannerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EventsBannerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF5A1F),
                      Color(0xFFFF8C42),
                      Color(0xFFFFB347),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                right: 48,
                bottom: -40,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                left: -16,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Événements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Découvrez les activités\net actualités des écoles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.20),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Featured Schools Slider ──────────────────────────────────────────────────
class _FeaturedSchoolsSlider extends StatelessWidget {
  final List<Map<String, String>> featuredSchools;
  final PageController pageController;
  final Function(int) onPageChanged;
  final int currentIndex;
  final bool showText;

  const _FeaturedSchoolsSlider({
    required this.featuredSchools,
    required this.pageController,
    required this.onPageChanged,
    required this.currentIndex,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.getCarouselHeight(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppDimensions.getHeroCardBorderRadius(context),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.getHeroCardBorderRadius(context),
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: featuredSchools.length,
              itemBuilder: (context, index) => _FeaturedSchoolCard(
                school: featuredSchools[index],
                index: index,
                schools: featuredSchools,
                showText: showText,
              ),
            ),
            if (showText)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    featuredSchools.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? AppColors.screenOrange
                            : AppColors.screenOrange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Featured School Card ─────────────────────────────────────────────────────
class _FeaturedSchoolCard extends StatelessWidget {
  final Map<String, String> school;
  final bool showText;
  final int index;
  final List<Map<String, String>> schools;

  const _FeaturedSchoolCard({
    required this.school,
    required this.showText,
    required this.index,
    required this.schools,
  });

  List<CoulisseExcellence> _buildQueue(List<Map<String, String>> items) {
    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return CoulisseExcellence(
        id: i,
        nom: '',
        prenoms: '',
        classe: '',
        titre: item['name'] ?? 'Vidéo',
        description: item['description'] ?? '',
        etablissement: item['location'] ?? '',
        nompays: null,
        videoYoutube: item['video'] ?? '',
        code: '',
      );
    }).toList();
  }

  // Extraire l'ID YouTube d'une URL
  String? _extractYouTubeId(String url) {
    final RegExp regex = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final Match? match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 7) {
      return match.group(7);
    }
    return null;
  }

  // URL miniature YouTube
  String? _getYouTubeThumbnailUrl(String videoUrl) {
    final String? videoId = _extractYouTubeId(videoUrl);
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  Future<void> _launchVideo(BuildContext context, String videoUrl) async {
    String? videoId = _extractYouTubeId(videoUrl);
    if (videoId != null) {
      _showVideoPlayer(context, videoId);
    } else {
      // Pour les vidéos non-YouTube, on pourrait utiliser un autre lecteur
      _showUnsupportedVideoDialog(context);
    }
  }

  // Lecteur YouTube intégré avec gestion d'erreurs et fallback
  void _showVideoPlayer(BuildContext context, String videoId) {
    // Tenter d'initialiser le lecteur YouTube avec gestion d'erreurs
    try {
      YoutubePlayerController controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          forceHD: false,
          enableCaption: false,
          loop: false,
          disableDragSeek: true,
          hideControls: false,
          controlsVisibleAtStart: true,
          useHybridComposition: false, // Désactivé pour éviter les erreurs iOS
          isLive: false,
        ),
      );

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Conteneur principal avec le player YouTube
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: controller,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.red,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                        onReady: () {
                          // Vidéo prête à être jouée
                        },
                        onEnded: (metaData) {
                          // Vidéo terminée
                        },
                      ),
                    ),
                  ),
                ),
                // Bouton fermer
                Positioned(
                  top: -14,
                  right: -14,
                  child: GestureDetector(
                    onTap: () {
                      controller.dispose();
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Fallback : si le lecteur YouTube échoue, proposer le lecteur externe
      _showYouTubeFallbackDialog(context, videoId);
    }
  }

  // Dialog de fallback vers YouTube externe
  void _showYouTubeFallbackDialog(BuildContext context, String videoId) {
    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Lecteur vidéo non disponible',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ouvrir la vidéo dans YouTube',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                final Uri uri = Uri.parse(youtubeUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Ouvrir dans YouTube'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -14,
                right: -14,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog pour vidéos non supportées
  void _showUnsupportedVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_file_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Format vidéo non supporté',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Seules les vidéos YouTube sont\nsupportées actuellement',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -14,
                right: -14,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(school['type'] ?? 'Primaire');
    final bool isVideo = school['video'] != null && school['video']!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          final queue = _buildQueue(schools)
              .where((v) => v.videoYoutube.trim().isNotEmpty)
              .toList();
          if (queue.isEmpty) return;

          final initialIndex = schools
              .take(index + 1)
              .where((m) => (m['video'] ?? '').trim().isNotEmpty)
              .length -
              1;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoulisseVideoFeedScreen(
                videos: queue,
                initialIndex: initialIndex >= 0 ? initialIndex : 0,
              ),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background : image ou vidéo ──────────────────────────
          if (isVideo) ...[
            // Miniature YouTube
            Builder(
              builder: (context) {
                final thumb = _getYouTubeThumbnailUrl(school['video']!);
                return thumb != null
                    ? Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _colorBackground(typeColor),
                      )
                    : _colorBackground(typeColor);
              },
            ),
            // Overlay sombre
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Bouton play centré
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            // Badge VIDÉO avec type
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      school['videoType']?.toUpperCase() ?? 'VIDÉO',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (school['image'] != null &&
              school['image']!.startsWith('assets')) ...[
            Image.asset(
              school['image']!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _colorBackground(typeColor),
            ),
          ] else
            _colorBackground(typeColor),

          // ── Overlay texte (si showText activé) ───────────────────
          if (showText) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      school['type'] ?? 'Primaire',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          school['name'] ?? 'École',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                school['location'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              school['rating'] ?? '4.5',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                school['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ],
      ),
    );
  }

  Widget _colorBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
