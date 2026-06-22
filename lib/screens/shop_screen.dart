import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/widgets/snackbar.dart';
import 'dart:async';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../config/app_typography.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/library_service.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/text_size_service.dart';
import '../services/category_api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/see_more_card.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_row_widget.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/snackbar.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/main_screen_wrapper.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import '../services/pays_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/scroll_to_top_fab.dart';

class LibraryScreen extends StatefulWidget implements MainScreenChild {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextSizeService _textSizeService = TextSizeService();
  final LibraryService _libraryService = MockLibraryService();
  final CartService _cartService = MockCartService();
  final ProduitService _produitService = ProduitService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  int _productsPerPage = 25;
  int _cartItemCount = 0;
  int _ordersCount = 0;
  String? _error;

  String? _pays;
  String? _ville;
  String? _quartier;
  String? _nomEtablissement;
  String? _nomProduit;
  String? _type;
  String? _categorieId;
  String? _sousCategorieId;

  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _nomEtablissementController = TextEditingController();
  final _nomProduitController = TextEditingController();
  final _typeController = TextEditingController();

  Timer? _searchTimer;

  List<Category> _categories = [];
  List<String> _filters = ['Tous'];
  List<String> _subFilters = [];
  String _selectedSubFilter = 'Tous';
  bool _isLoadingCategories = false;
  String? _categoryError;

  List<String> _countriesList = ['Tous'];
  Map<String, String> _paysMap = {'Tous': ''};
  Map<String, String> _paysReverseMap = {'': 'Tous'};
  bool _isLoadingPays = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _mainScrollController = ScrollController();

  // ✅ FIX: Ratio calculé pour inclure image + texte externe sans overflow.
  // Formule : largeur_cellule / (hauteur_image + hauteur_texte_estimée)
  int _getCrossAxisCount(BuildContext context) {
    return AppDimensions.getEcolesGridColumns(context);
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadProducts();
    _loadCategories();
    _loadPays();
    _updateCartItemCount();
    _updateOrdersCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCartItemCount();
    _updateOrdersCount();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _nomEtablissementController.dispose();
    _nomProduitController.dispose();
    _typeController.dispose();
    _fadeController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPays() async {
    try {
      final results = await Future.wait([
        PaysService.getPaysNames(),
        PaysService.getPaysMap(),
        PaysService.getPaysReverseMap(),
      ]);
      if (mounted) {
        setState(() {
          _countriesList = results[0] as List<String>;
          _paysMap = results[1] as Map<String, String>;
          _paysReverseMap = results[2] as Map<String, String>;
          _isLoadingPays = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPays = false);
      }
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _products.clear();
      _currentPage = 1;
      _hasMoreProducts = true;
    });
    try {
      final products = await _produitService.getProduits(
        page: _currentPage,
        perPage: _productsPerPage,
        pays: _pays,
        ville: _ville,
        quartier: _quartier,
        nomEtablissement: _nomEtablissement,
        nomProduit: _nomProduit,
        type: _type,
        categorieId: _categorieId,
        sousCategorieId: _sousCategorieId,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
          _hasMoreProducts = products.length >= _productsPerPage;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        final isNetworkError =
            errorString.contains('SocketException') ||
            errorString.contains('ClientException') ||
            errorString.contains('Failed host lookup') ||
            errorString.contains('No address associated') ||
            errorString.contains('Connection refused') ||
            errorString.contains('Network is unreachable') ||
            errorString.contains('Software caused connection abort');

        setState(() {
          _error = isNetworkError
              ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.'
              : 'Une erreur est survenue lors du chargement des produits.';
          _isLoading = false;
        });

        if (!isNetworkError) {
          _showError('Erreur lors du chargement des produits: $e');
        }
      }
    }
  }

  Future<void> _updateCartItemCount() async {
    if (!mounted) return;
    final cart = await _cartService.getCurrentCart();
    if (mounted) setState(() => _cartItemCount = cart.totalItems);
  }

  Future<void> _updateOrdersCount() async {
    if (!mounted) return;
    try {
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        if (mounted) setState(() => _ordersCount = 0);
        return;
      }
      final orders = await OrderService().getUserOrders(currentUser.phone);
      if (mounted) setState(() => _ordersCount = orders.length);
    } catch (_) {
      if (mounted) setState(() => _ordersCount = 0);
    }
  }

  // Charger les catégories depuis l'API
  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final categories = await CategoryApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
          _buildFiltersFromCategories();
        });
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        final isNetworkError =
            errorString.contains('SocketException') ||
            errorString.contains('ClientException') ||
            errorString.contains('Failed host lookup') ||
            errorString.contains('No address associated') ||
            errorString.contains('Connection refused') ||
            errorString.contains('Network is unreachable') ||
            errorString.contains('Software caused connection abort');
        setState(() {
          _categoryError = isNetworkError
              ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.'
              : 'Une erreur est survenue lors du chargement des catégories.';
          _isLoadingCategories = false;
        });
      }
    }
  }

  // Construire la liste des filtres à partir des catégories
  void _buildFiltersFromCategories() {
    final List<String> categoryNames = _categories
        .map((category) => category.nom)
        .toSet()
        .toList();

    setState(() {
      _filters = ['Tous', ...categoryNames];
    });
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || !mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      final newProducts = await _produitService.getProduits(
        page: _currentPage,
        perPage: _productsPerPage,
        pays: _pays,
        ville: _ville,
        quartier: _quartier,
        nomEtablissement: _nomEtablissement,
        nomProduit: _nomProduit,
        type: _type,
        categorieId: _categorieId,
        sousCategorieId: _sousCategorieId,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(newProducts);
        _filteredProducts = _products;
        _isLoadingMore = false;
        _hasMoreProducts = newProducts.length >= _productsPerPage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

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
      _nomProduit = _nomProduitController.text.trim().isEmpty
          ? null
          : _nomProduitController.text.trim();
      _type = _typeController.text.trim().isEmpty
          ? null
          : _typeController.text.trim();
    });
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    setState(() {
      _nomProduit = query.trim().isEmpty ? null : query.trim();
    });
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      _loadProducts();
    });
  }

  void _applyAdvancedSearch() {
    _updateSearchParameters();
    if (_nomProduit != null && _nomProduit!.isNotEmpty) {
      _searchController.text = _nomProduit!;
    } else {
      _searchController.clear();
    }
    _loadProducts();
  }

  void _clearAdvancedSearch() {
    setState(() {
      _paysController.clear();
      _villeController.clear();
      _quartierController.clear();
      _nomEtablissementController.clear();
      _nomProduitController.clear();
      _typeController.clear();
      _pays = null;
      _ville = null;
      _quartier = null;
      _nomEtablissement = null;
      _nomProduit = null;
      _type = null;
      _categorieId = null;
      _sousCategorieId = null;
      _searchController.clear();
    });
    _loadProducts();
  }

  void _applyFilters() {
    setState(() {
      _categorieId = null;
      _sousCategorieId = null;

      if (_selectedFilter != 'Tous') {
        try {
          final category = _categories.firstWhere(
            (c) => c.nom == _selectedFilter,
          );
          _categorieId = category.id.toString();

          if (_selectedSubFilter != 'Tous') {
            final subCat = category.sousCategories.firstWhere(
              (s) => s.nom == _selectedSubFilter,
            );
            _sousCategorieId = subCat.id.toString();
          }
        } catch (e) {
          // Ignorer si non trouvé
        }
      }
    });
    _loadProducts();
  }

  void _showError(String msg) {
    CartSnackBar.show(
      context,
      productName: 'Erreur',
      message: msg,
      backgroundColor: Colors.red[400],
      duration: const Duration(seconds: 3),
    );
  }

  void _navigateBack() {
    final mainScreenWrapper = MainScreenWrapper.maybeOf(context);
    if (mainScreenWrapper != null) {
      mainScreenWrapper.navigateToHome();
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        floatingActionButton: ScrollToTopFab(
          scrollController: _mainScrollController,
          bottomSpacerHeight: 70,
        ),
        body: Stack(
          children: [
            CustomScrollView(
              controller: _mainScrollController,
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _buildFilterTabs(),
                  ),
                ),
                SliverToBoxAdapter(child: _buildResultsHeader()),
                ..._buildGridSlivers(),
              ],
            ),
            if (!_isLoading && _error == null && _filteredProducts.isNotEmpty)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomFadeGradient(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return CustomSliverAppBar(
      title: 'Boutique',
      isDark: false,
      onBackTap: _navigateBack,
      automaticallyImplyLeading: true,
      pinned: true,
      floating: false,
      elevation: 0,
      actions: _buildCustomActions(),
    );
  }

  List<Widget> _buildCustomActions() {
    return [
      _buildCustomActionButton(
        icon: _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
        color: _isSearching
            ? AppColors.shopBlue
            : AppColors.screenTextPrimaryThemed(context),
        bgColor: _isSearching
            ? AppColors.shopBlueSurface
            : AppColors.screenCardThemed(context),
        onTap: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchTimer?.cancel();
              _searchController.clear();
              _nomProduit = null;
              _loadProducts();
            }
          });
        },
      ),
      const SizedBox(width: 4),
      _buildCustomActionButton(
        icon: Icons.tune,
        color: AppColors.screenTextPrimaryThemed(context),
        bgColor: AppColors.screenCardThemed(context),
        onTap: _showAdvancedSearchBottomSheet,
      ),
      const SizedBox(width: 4),
      _buildCustomActionButton(
        icon: Icons.shopping_bag_outlined,
        color: AppColors.screenTextPrimaryThemed(context),
        bgColor: AppColors.screenCardThemed(context),
        badge: _cartItemCount > 0 ? '$_cartItemCount' : null,
        badgeColor: AppColors.shopGreen,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ).then((_) => _updateCartItemCount());
        },
      ),
      const SizedBox(width: 4),
      _buildCustomActionButton(
        icon: Icons.receipt_long_outlined,
        color: AppColors.screenTextPrimaryThemed(context),
        bgColor: AppColors.screenCardThemed(context),
        badge: _ordersCount > 0
            ? (_ordersCount > 99 ? '99+' : '$_ordersCount')
            : null,
        badgeColor: Colors.green,
        onTap: () {
          MainScreenWrapper.of(
            context,
          ).navigateToExtraScreen(const OrdersScreen());
        },
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildCustomActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                AppDimensions.getSmallCardBorderRadius(context),
              ),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.shopGreen,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getSmallCardBorderRadius(context),
                  ),
                  border: Border.all(
                    color: AppColors.screenSurfaceThemed(context),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SearchBarWidget(
      isSearching: _isSearching,
      searchController: _searchController,
      onChanged: _onSearchChanged,
      onClear: () {
        _searchTimer?.cancel();
        setState(() {
          _searchController.clear();
          _nomProduit = null;
        });
        _loadProducts();
      },
      hintText: 'Rechercher un produit...',
    );
  }

  Widget _buildFilterTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterRowWidget(
          filters: _filters,
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
              _selectedSubFilter = 'Tous';
              if (filter == 'Tous') {
                _subFilters = [];
              } else {
                try {
                  final category = _categories.firstWhere(
                    (c) => c.nom == filter,
                  );
                  if (category.sousCategories.isNotEmpty) {
                    _subFilters = [
                      'Tous',
                      ...category.sousCategories.map((s) => s.nom),
                    ];
                  } else {
                    _subFilters = [];
                  }
                } catch (e) {
                  _subFilters = [];
                }
              }
              _applyFilters();
            });
          },
          selectedColor: AppColors.shopGreen,
          selectedGradient: AppColors.shopGreenGradient,
          selectedTextColor: Colors.white,
        ),
        if (_subFilters.isNotEmpty) ...[
          const SizedBox(height: 12),
          FilterRowWidget(
            filters: _subFilters,
            selectedFilter: _selectedSubFilter,
            onFilterSelected: (subFilter) {
              setState(() {
                _selectedSubFilter = subFilter;
                _applyFilters();
              });
            },
            selectedColor: AppColors.shopBlue,
            selectedTextColor: Colors.white,
            unselectedColor: AppColors.grey100Adaptive(context),
          ),
        ],
      ],
    );
  }

  void _showAdvancedSearchBottomSheet() {
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAdvancedSearchBottomSheet(ctx),
    );
  }

  Widget _buildAdvancedSearchBottomSheet(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.95,
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
                  color: AppColors.shopBlue,
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
                      color: AppColors.shopBlueSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Effacer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.shopBlue,
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
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchableDropdown(
                          label: 'Pays',
                          value:
                              _paysReverseMap[_paysController.text] ?? 'Tous',
                          items: _countriesList,
                          isDarkMode:
                              Theme.of(context).brightness == Brightness.dark,
                          onChanged: (String val) {
                            setState(() {
                              _paysController.text = _paysMap[val] ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Ville',
                          hint: 'Entrez la ville',
                          icon: Icons.location_city_rounded,
                          controller: _villeController,
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
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
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Nom établissement',
                          hint: 'Entrez le nom',
                          icon: Icons.business_rounded,
                          controller: _nomEtablissementController,
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Nom produit',
                          hint: 'Entrez le nom du produit',
                          icon: Icons.shopping_bag_rounded,
                          controller: _nomProduitController,
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Type',
                          hint: 'Ex: Papeterie, Livres...',
                          icon: Icons.category_rounded,
                          controller: _typeController,
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyAdvancedSearch();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shopBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Appliquer les filtres',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const BottomSpacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Text(
          //   '${_filteredProducts.length} résultat${_filteredProducts.length > 1 ? 's' : ''}',
          //   style: const TextStyle(
          //     fontSize: 13,
          //     color: AppColors.screenTextSecondary,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          if (_selectedFilter != 'Tous') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.shopGreenSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedFilter,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.shopGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Tous';
                        _applyFilters();
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.shopGreen,
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

  // ─── GRID SLIVERS ──────────────────────────────────────────────────────────
  List<Widget> _buildGridSlivers() {
    if (_isLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing:
                  AppDimensions.getAdaptiveGridSpacing(context) *
                  (((AppDimensions.isTablet(context) ||
                              AppDimensions.isLargeTablet(context)) &&
                          AppDimensions.isLandscape(context))
                      ? 1.8
                      : 1.0),
              mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
              mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return const SkeletonBox();
            }, childCount: 16),
          ),
        ),
      ];
    }

    if (_error != null) return [SliverToBoxAdapter(child: _buildErrorState())];
    if (_filteredProducts.isEmpty)
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState()),
      ];

    return [
      SliverFadeTransition(
        opacity: _fadeAnimation,
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing:
                  AppDimensions.getAdaptiveGridSpacing(context) *
                  (((AppDimensions.isTablet(context) ||
                              AppDimensions.isLargeTablet(context)) &&
                          AppDimensions.isLandscape(context))
                      ? 1.8
                      : 1.0),
              mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
              mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _filteredProducts.length && _hasMoreProducts) {
                  return SeeMoreCard(
                    cardColor: AppColors.screenCard,
                    borderColor: AppColors.shopGreen.withOpacity(0.3),
                    iconColor: AppColors.shopGreen,
                    textColor: AppColors.shopGreen,
                    subtitleColor: const Color(0xFF999999),
                    title: 'Voir plus',
                    subtitle: 'produits',
                    onTap: _loadMoreProducts,
                    icon: Icons.add,
                  );
                }
                return _buildProductCard(_filteredProducts[index], index);
              },
              childCount: _filteredProducts.length + (_hasMoreProducts ? 1 : 0),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
    ];
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.shopBlueSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.shopBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun produit trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Essayez un autre filtre ou terme\nde recherche',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = 'Tous';
                _searchController.clear();
                _clearAdvancedSearch();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shopBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ERROR STATE ───────────────────────────────────────────────────────────
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
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadProducts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.shopBlueLight, AppColors.shopBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shopBlue.withOpacity(0.3),
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

  // ─── PRODUCT CARD ──────────────────────────────────────────────────────────
  Widget _buildProductCard(Product product, int index) {
    final Color accent = Color(int.parse(product.color));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index % 6) * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: product.id,
        title: product.title,
        subtitle: product.subtitle,
        imagePath: product.imageUrl,
        iconData: Icons.shopping_bag,
        isDark: false,
        color: accent,
        tag: product.type,
        height: AppDimensions.getEcoleCardHeight(context),
        //imageFlex: AppDimensions.getProductCardImageFlex(context), // Adaptatif selon taille de l'appareil
        externalTitleSpacing: 4,
        titleMaxLines: 2,
        allowLineBreak: true,
        //buttonText: 'Ajouter',
        buttonColor: AppColors.shopGreen,
        buttonTextColor: Colors.white,
        onButtonTap: () {
          CartSnackBar.show(context, productName: product.title);
        },
        actionText: product.price > 0
            ? '${product.price.toStringAsFixed(0)} F'
            : 'Gratuit',
        actionTextColor: product.price > 0 ? AppColors.shopGreen : Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailScreen(product: product, produitUid: product.id),
            ),
          ).then((_) => _updateCartItemCount());
        },
      ),
    );
  }
}
