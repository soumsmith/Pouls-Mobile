import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../models/product.dart';
import '../services/library_service.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/text_size_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/see_more_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ───────────────────────────

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
  int _productsPerPage = 10;
  int _cartItemCount = 0;
  int _ordersCount = 0;
  String? _error;

  // ── Paramètres de recherche dynamique ──────────────────────────────
  String? _pays;
  String? _ville;
  String? _quartier;
  String? _nomEtablissement;
  String? _nomProduit;
  String? _type;

  // Controllers pour les champs de recherche
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _nomEtablissementController = TextEditingController();
  final _nomProduitController = TextEditingController();
  final _typeController = TextEditingController();

  // ── Responsive Grid Methods ───────────────────────────
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 4; // 4 produits par ligne sur tablette
    }
    return 2; // 2 produits par ligne sur mobile
  }

  // ── Timer pour debounce ───────────────────────────────────────
  Timer? _searchTimer;

  final List<String> _filters = ['Tous', 'Papeterie', 'Livres', 'Services'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _searchTimer?.cancel(); // Annuler le timer
    _searchController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _nomEtablissementController.dispose();
    _nomProduitController.dispose();
    _typeController.dispose();
    _fadeController.dispose();
    super.dispose();
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
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        _showError('Erreur lors du chargement des produits: $e');
      }
    }
  }

  Future<void> _updateCartItemCount() async {
    if (!mounted) return;
    final cart = await _cartService.getCurrentCart();
    if (mounted) {
      setState(() => _cartItemCount = cart.totalItems);
    }
  }

  Future<void> _updateOrdersCount() async {
    if (!mounted) return;
    try {
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          setState(() => _ordersCount = 0);
        }
        return;
      }
      final orders = await OrderService().getUserOrders(currentUser.phone);
      if (mounted) {
        setState(() => _ordersCount = orders.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _ordersCount = 0);
      }
    }
  }

  // ── Load more products ───────────────────────────────────────────
  Future<void> _loadMoreProducts() async {
    if (!_hasMoreProducts || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

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
        _currentPage--; // Revert page number on error
      });
    }
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
      _nomProduit = _nomProduitController.text.trim().isEmpty
          ? null
          : _nomProduitController.text.trim();
      _type = _typeController.text.trim().isEmpty
          ? null
          : _typeController.text.trim();
    });
  }

  // ── Recherche avec debounce ───────────────────────────────────
  void _onSearchChanged(String query) {
    _searchTimer?.cancel(); // Annuler le timer précédent

    setState(() {
      _nomProduit = query.trim().isEmpty ? null : query.trim();
    });

    // Créer un nouveau timer de 800ms
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      _loadProducts();
    });
  }

  void _applyAdvancedSearch() {
    _updateSearchParameters();
    // Synchroniser la barre de recherche principale avec le nom du produit
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
      _searchController
          .clear(); // Effacer aussi la barre de recherche principale
    });
    _loadProducts();
  }

  void _applyFilters() {
    // Avec la pagination, le filtrage est maintenant géré par l'API
    // Cette méthode ne fait que synchroniser les filtres locaux
    setState(() {
      _filteredProducts = _products;
      if (_selectedFilter != 'Tous') {
        _filteredProducts = _filteredProducts
            .where(
              (p) => p.category.toLowerCase() == _selectedFilter.toLowerCase(),
            )
            .toList();
      }
    });
  }

  void _showError(String msg) {
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

  void _navigateBack() {
    final mainScreenWrapper = MainScreenWrapper.maybeOf(context);
    if (mainScreenWrapper != null) {
      mainScreenWrapper.navigateToHome();
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildFilterTabs(),
            _buildResultsHeader(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: _navigateBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.screenShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              const Expanded(
                child: Text(
                  'Boutique',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.screenTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Search button
              _appBarIconButton(
                icon: _isSearching
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: _isSearching
                    ? AppColors.shopBlue
                    : AppColors.screenTextPrimary,
                bgColor: _isSearching
                    ? AppColors.shopBlueSurface
                    : AppColors.screenCard,
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
              const SizedBox(width: 8),

              // Advanced search button
              _appBarIconButton(
                icon: Icons.tune,
                color: AppColors.screenTextPrimary,
                bgColor: AppColors.screenCard,
                onTap: _showAdvancedSearchBottomSheet,
              ),
              const SizedBox(width: 8),

              // Cart button
              _appBarIconButton(
                icon: Icons.shopping_bag_outlined,
                color: AppColors.screenTextPrimary,
                bgColor: AppColors.screenCard,
                badge: _cartItemCount > 0 ? '$_cartItemCount' : null,
                badgeColor: AppColors.shopGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ).then((_) => _updateCartItemCount());
                },
              ),
              const SizedBox(width: 8),

              // Orders button
              _appBarIconButton(
                icon: Icons.receipt_long_outlined,
                color: AppColors.screenTextPrimary,
                bgColor: AppColors.screenCard,
                badge: _ordersCount > 0
                    ? (_ordersCount > 99 ? '99+' : '$_ordersCount')
                    : null,
                badgeColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ).then((_) => _updateOrdersCount());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarIconButton({
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
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.screenShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.shopGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.screenSurface,
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

  // ─── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _isSearching ? 56 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSearching ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.shopGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shopGreen.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: _isSearching,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFBBBBBB),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.shopBlue,
                  size: 18,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchTimer?.cancel(); // Annuler le timer
                          setState(() {
                            _searchController.clear();
                            _nomProduit = null;
                          });
                          _loadProducts();
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.screenTextSecondary,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── FILTER TABS ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
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
                onTap: () {
                  setState(() {
                    _selectedFilter = f;
                    _applyFilters();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.shopGreenGradient : null,
                    color: selected ? null : AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.shopGreen.withOpacity(0.30),
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

  // ─── Advanced Search BottomSheet ─────────────────────────────────
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
                    color: AppColors.shopBlue,
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

            // Champs de recherche
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
                          iconColor: AppColors.shopBlue,
                          focusBorderColor: AppColors.shopBlue,
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
                  // Deuxième ligne
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
                  // Troisième ligne
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
                    backgroundColor: AppColors.shopBlue,
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

  // ─── RESULTS HEADER ────────────────────────────────────────────────────────
  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            '${_filteredProducts.length} résultat${_filteredProducts.length > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
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

  // ─── GRID ──────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_isLoading) {
      return CustomLoader(
        message: 'Chargement des produits...',
        loaderColor: AppColors.shopGreen,
        backgroundColor: AppColors.screenSurface,
        showBackground: false,
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Si c'est le dernier élément et qu'il y a plus de produits
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
                    );
                  }
                  return _buildProductCard(_filteredProducts[index], index);
                },
                childCount:
                    _filteredProducts.length + (_hasMoreProducts ? 1 : 0),
              ),
            ),
          ),
          // Espace en bas pour éviter que le bouton soit collé en bas
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailScreen(product: product, produitUid: product.id),
            ),
          ).then((_) => _updateCartItemCount());
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(18),
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
              // ── Image ──
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: ImageHelper.buildNetworkImage(
                        imageUrl: product.imageUrl,
                        placeholder: product.title,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Availability dot
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.screenShadow,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info ──
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.type,
                              style: TextStyle(
                                fontSize: 10,
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Price
                          if (product.price > 0)
                            Text(
                              '${product.price.toStringAsFixed(0)} F',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.shopGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else
                            const Text(
                              'Gratuit',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
