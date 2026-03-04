import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/back_button_widget.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../models/product.dart';
import '../services/library_service.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class LibraryScreen extends StatefulWidget implements MainScreenChild {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des produits: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCartItemCount() async {
    final cart = await _cartService.getCurrentCart();
    setState(() {
      _cartItemCount = cart.totalItems;
    });
  }

  Future<void> _updateOrdersCount() async {
    try {
      final orders = await _cartService.getOrderHistory();
      setState(() {
        _ordersCount = orders.length;
      });
    } catch (e) {
      setState(() {
        _ordersCount = 0;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products;

      // Apply type filter
      if (_selectedFilter != 'Tous') {
        _filteredProducts = _filteredProducts
            .where(
              (product) =>
                  product.category.toLowerCase() ==
                  _selectedFilter.toLowerCase(),
            )
            .toList();
      }

      // Apply search
      if (_searchController.text.isNotEmpty) {
        final searchQuery = _searchController.text.toLowerCase();
        _filteredProducts = _filteredProducts
            .where(
              (product) =>
                  product.title.toLowerCase().contains(searchQuery) ||
                  product.subtitle.toLowerCase().contains(searchQuery) ||
                  product.description.toLowerCase().contains(searchQuery),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButtonWidget(onPressed: _navigateBack),
        title: Text(
          'Boutique',
          style: TextStyle(
            fontSize: AppTypography.headlineMedium,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).iconTheme.color,
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$_cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ).then((_) => _updateCartItemCount());
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).iconTheme.color,
                ),
                if (_ordersCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _ordersCount > 99 ? '99+' : '$_ordersCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersScreen()),
              ).then((_) => _updateOrdersCount());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Slide Down Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearching ? 56 : 0,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: _isSearching ? 8 : 0,
            ),
            child: _isSearching
                ? CustomSearchBar(
                    hintText: 'Rechercher un produit...',
                    controller: _searchController,
                    onChanged: (value) {
                      _applyFilters();
                    },
                    onClear: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _applyFilters();
                      });
                    },
                    autoFocus: true,
                  )
                : null,
          ),

          // Filter Tabs
          Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilters();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: !isSelected
                          ? AppColors.getSurfaceColor(isDark)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDark),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} résultats',
                  style: TextStyle(
                    fontSize: AppTypography.labelMedium,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Grid View
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 600) {
                              crossAxisCount = 4;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            );
                          },
                        ),
                      ),

                // ← Gradient fade en bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.getPureBackground(isDark).withOpacity(0),
                            AppColors.getPureBackground(isDark),
                            AppColors.getPureBackground(isDark),
                          ],
                        ),
                      ),
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

  Widget _buildProductCard(Product product) {
    final Color color = Color(int.parse(product.color));
    final String? imageUrl = product.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(product: product, produitUid: product.id),
          ),
        ).then((_) => _updateCartItemCount());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ImageHelper.buildNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: product.title,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: AppTypography.titleSmall,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      product.subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price and Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Type Badge
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
                            product.type,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTypography.bodySmall,
                            ),
                          ),
                        ),

                        // Price
                        if (product.price > 0)
                          Text(
                            '${product.price.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: color,
                              fontWeight: FontWeight.bold,
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

  void _navigateBack() {
    // Check if we're in a MainScreenWrapper context
    final mainScreenWrapper = MainScreenWrapper.maybeOf(context);
    if (mainScreenWrapper != null) {
      // If we're in MainScreenWrapper, navigate to home tab
      mainScreenWrapper.navigateToHome();
    } else {
      // Otherwise, use normal navigation
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
