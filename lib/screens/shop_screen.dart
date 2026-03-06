import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);
const _kSurface = Color(0xFFF8F8F8);
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);
const _kDivider = Color(0xFFF0F0F0);
const _kShadow = Color(0x0D000000);

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
  int _cartItemCount = 0;
  int _ordersCount = 0;

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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _produitService.getProduits();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
      _applyFilters();
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des produits: $e');
    }
  }

  Future<void> _updateCartItemCount() async {
    final cart = await _cartService.getCurrentCart();
    setState(() => _cartItemCount = cart.totalItems);
  }

  Future<void> _updateOrdersCount() async {
    try {
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        setState(() => _ordersCount = 0);
        return;
      }
      final orders = await OrderService().getUserOrders(currentUser.phone);
      setState(() => _ordersCount = orders.length);
    } catch (_) {
      setState(() => _ordersCount = 0);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products;
      if (_selectedFilter != 'Tous') {
        _filteredProducts = _filteredProducts
            .where((p) =>
                p.category.toLowerCase() == _selectedFilter.toLowerCase())
            .toList();
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        _filteredProducts = _filteredProducts
            .where((p) =>
                p.title.toLowerCase().contains(q) ||
                p.subtitle.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q))
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
        backgroundColor: _kSurface,
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
      color: _kSurface,
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
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: _kShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: _kTextPrimary),
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
                    color: _kTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Search button
              _appBarIconButton(
                icon: _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
                color: _isSearching ? _kOrange : _kTextPrimary,
                bgColor: _isSearching ? _kOrangeLight : _kCard,
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _applyFilters();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),

              // Cart button
              _appBarIconButton(
                icon: Icons.shopping_bag_outlined,
                color: _kTextPrimary,
                bgColor: _kCard,
                badge: _cartItemCount > 0 ? '$_cartItemCount' : null,
                badgeColor: _kOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CartScreen()),
                  ).then((_) => _updateCartItemCount());
                },
              ),
              const SizedBox(width: 8),

              // Orders button
              _appBarIconButton(
                icon: Icons.receipt_long_outlined,
                color: _kTextPrimary,
                bgColor: _kCard,
                badge: _ordersCount > 0
                    ? (_ordersCount > 99 ? '99+' : '$_ordersCount')
                    : null,
                badgeColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrdersScreen()),
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
                    color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
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
                  color: badgeColor ?? _kOrange,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kSurface, width: 1.5),
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
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kOrange, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: _isSearching,
              onChanged: (_) => _applyFilters(),
              style: const TextStyle(
                  fontSize: 14, color: _kTextPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFBBBBBB)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kOrange, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                        child: const Icon(Icons.close_rounded,
                            color: _kTextSecondary, size: 18),
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _applyFilters();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFF7A3C), _kOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : _kCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _kOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: _kShadow,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : _kTextSecondary,
                ),
              ),
            ),
          );
        },
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
              color: _kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_selectedFilter != 'Tous') ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedFilter,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kOrange,
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
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: _kOrange),
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
      return const Center(
        child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5),
      );
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_filteredProducts[index], index);
                  },
                );
              },
            ),
          ),
          // Gradient fade at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kSurface.withOpacity(0),
                      _kSurface,
                    ],
                  ),
                ),
              ),
            ),
          ),
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
              color: _kOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 44, color: _kOrange),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun produit trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Essayez un autre filtre ou terme\nde recherche',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _kTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = 'Tous';
                _searchController.clear();
                _applyFilters();
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A3C), _kOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withOpacity(0.3),
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
              builder: (_) => ProductDetailScreen(
                  product: product, produitUid: product.id),
            ),
          ).then((_) => _updateCartItemCount());
        },
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4)),
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
                          top: Radius.circular(18)),
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
                                color: _kShadow,
                                blurRadius: 4,
                                offset: Offset(0, 1)),
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
                          color: _kTextPrimary,
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
                          color: _kTextSecondary,
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
                                horizontal: 7, vertical: 3),
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
                                color: _kOrange,
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