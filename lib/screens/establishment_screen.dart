import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';
import '../services/ecole_api_service.dart';
import '../models/ecole.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/see_more_card.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../widgets/custom_loader.dart';
import 'all_events_screen.dart';
import 'establishment_detail_screen.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
];

const _kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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

IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'primaire':
      return Icons.child_care_rounded;
    case 'collège':
      return Icons.menu_book_rounded;
    case 'lycée':
      return Icons.school_rounded;
    case 'privé':
      return Icons.star_rounded;
    case 'public':
      return Icons.account_balance_rounded;
    default:
      return Icons.business_rounded;
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
  int _ecolesPerPage = 50; // Valeur par défaut, sera mise à jour dans didChangeDependencies
  String? _error;

  // ── Paramètres de recherche dynamique ──────────────────────────────
  String? _pays;
  String? _ville;
  String? _quartier;
  String? _nomEtablissement;
  String? _categorie;
  String? _codepays;

  // Controllers pour les champs de recherche
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _nomEtablissementController = TextEditingController();
  final _categorieController = TextEditingController();
  final _codepaysController = TextEditingController();

  // ── Timer pour debounce ───────────────────────────────────────
  Timer? _searchTimer;

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize responsive pagination after context is available
    _ecolesPerPage = AppDimensions.getEcolesPerPage(context);
  }

  @override
  void dispose() {
    _searchTimer?.cancel(); // Annuler le timer
    _textSizeService.removeListener(_onTextSizeChanged);
    _searchController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _nomEtablissementController.dispose();
    _categorieController.dispose();
    _codepaysController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTextSizeChanged() {
    if (mounted) {
      setState(() => _currentTextScale = _textSizeService.getScale());
    }
  }

  // ── Data ───────────────────────────────────────────────────
  Future<void> _loadEcoles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _ecoles.clear();
      _currentPage = 1;
      _hasMoreEcoles =
          true; // Toujours true au début pour permettre le chargement
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
          // Considérer qu'il y a plus d'écoles si on a reçu le nombre demandé OU si c'est la première page
          _hasMoreEcoles =
              ecoles.length >= _ecolesPerPage ||
              (_currentPage == 1 && ecoles.length > 0);
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

  // ── Load more ecoles ───────────────────────────────────────────
  Future<void> _loadMoreEcoles() async {
    if (!_hasMoreEcoles || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

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
        // Considérer qu'il y a plus d'écoles si on a reçu le nombre demandé
        _hasMoreEcoles = newEcoles.length >= _ecolesPerPage;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page number on error
      });
    }
  }

  List<Ecole> get _filteredItems {
    // Plus besoin de filtrer localement car l'API fait le filtrage
    return _ecoles;
  }

  // ── Méthodes de recherche avancée ───────────────────────────────
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

  // ── Recherche avec debounce ───────────────────────────────────
  void _onSearchChanged(String query) {
    _searchTimer?.cancel(); // Annuler le timer précédent

    setState(() {
      _nomEtablissement = query.trim().isEmpty ? null : query.trim();
    });

    // Créer un nouveau timer de 800ms
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      _loadEcoles();
    });
  }

  void _applyAdvancedSearch() {
    _updateSearchParameters();
    // Synchroniser la barre de recherche principale avec le nom d'établissement
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
      _pays = null;
      _ville = null;
      _quartier = null;
      _nomEtablissement = null;
      _categorie = null;
      _codepays = null;
      _searchController
          .clear(); // Effacer aussi la barre de recherche principale
    });
    _loadEcoles();
  }

  // ── Responsive Grid Methods ───────────────────────────
  int _getCrossAxisCount(BuildContext context) {
    return AppDimensions.getEcolesGridColumns(context);
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 0.85; // Slightly wider for tablet layout
    }
    return 0.78; // Original aspect ratio for mobile
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
        backgroundColor: AppColors.screenSurface,
        body: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header (sans bouton Événements) ───────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.screenCard,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => MainScreenWrapper.of(context).navigateToHome(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.screenCardShadow,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          const Expanded(
            child: Text(
              'Établissements',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Search button et advanced search
          _buildHeaderAction(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
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
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.screenCardShadow,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearching ? 60 : 0,
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: _isSearching
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.screenSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.screenOrange.withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.screenOrange.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un établissement...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.screenOrange,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchTimer?.cancel(); // Annuler le timer
                            setState(() {
                              _searchController.clear();
                              _nomEtablissement = null;
                            });
                            _loadEcoles();
                          },
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ── Advanced Search BottomSheet ─────────────────────────────────
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
        decoration: const BoxDecoration(
          color: AppColors.screenSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
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
                  const Text(
                    'Recherche avancée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Champs de recherche avec le même style que les formulaires d'intégration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Première ligne
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
                  // Deuxième ligne
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
                  // Troisième ligne
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

            // Bouton appliquer
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

  // ── Filter Row ─────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final selected = f == _selectedFilter;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 40),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.screenOrangeGradient : null,
                    color: selected ? null : AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.screenOrange.withOpacity(0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            );
          },
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
      backgroundColor: AppColors.screenSurface,
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
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
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
              // ── Événements Banner Card ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _EventsBannerCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllEventsScreen(),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Results header ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${items.length} ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenOrange,
                              ),
                            ),
                            const TextSpan(
                              text: 'établissement',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                            TextSpan(
                              text: items.length > 1 ? 's' : '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFilter != 'Tous') ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedFilter = 'Tous'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.screenOrangeLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedFilter,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.screenOrange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: AppColors.screenOrange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

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
                        const Text(
                          'Aucun établissement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aucun résultat pour ce filtre',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
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
                // ── Grid ──────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: AppDimensions.getEcoleCardSpacing(
                        context,
                      ),
                      mainAxisSpacing: AppDimensions.getEcoleCardSpacing(
                        context,
                      ),
                      childAspectRatio: _getChildAspectRatio(context),
                    ),
                    delegate: SliverChildBuilderDelegate((_, i) {
                      // ── "Voir plus" card intégrée à la fin ──
                      if (i == items.length && _hasMoreEcoles) {
                        return SeeMoreCard(
                          cardColor: AppColors.screenCard,
                          borderColor: AppColors.screenOrange.withOpacity(0.3),
                          iconColor: AppColors.screenOrange,
                          textColor: AppColors.screenOrange,
                          subtitleColor: AppColors.screenOrange.withOpacity(
                            0.5,
                          ),
                          title: _isLoadingMore ? 'Chargement...' : 'Voir plus',
                          subtitle: _isLoadingMore ? '' : 'établissements',
                          onTap: _isLoadingMore ? () {} : _loadMoreEcoles,
                        );
                      }
                      if (i < items.length) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + (i % 6) * 60),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - v)),
                              child: child,
                            ),
                          ),
                          child: _EcoleCard(
                            ecole: items[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EstablishmentDetailScreen(ecole: items[i]),
                              ),
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
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F8F8F8), AppColors.screenSurface],
                ),
              ),
            ),
          ),
        ),
      ],
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
              // ── Fond dégradé principal ──────────────────────
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

              // ── Cercles décoratifs translucides ────────────
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

              // ── Points décoratifs ───────────────────────────
              Positioned(
                top: 18,
                right: 110,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white30,
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                right: 88,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                ),
              ),

              // ── Contenu ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icône dans un cercle blanc
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

                    // Textes
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

                    // Flèche droite
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

// ─── École Card ───────────────────────────────────────────────────────────────
class _EcoleCard extends StatelessWidget {
  final Ecole ecole;
  final VoidCallback onTap;

  const _EcoleCard({required this.ecole, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(ecole.typePrincipal);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.screenCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image zone ────────────────────────────────────
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageHelper.buildNetworkImage(
                      imageUrl: ecole.displayImage,
                      placeholder: ecole.parametreNom ?? 'École',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          ecole.typePrincipal,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info zone ─────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ecole.parametreNom ?? 'École sans nom',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ecole.adresse,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ecole.ville,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                              height: 1.2,
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
            ),
          ],
        ),
      ),
    );
  }
}
