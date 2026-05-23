import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/snackbar.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String produitUid;

  const ProductDetailScreen({
    super.key,
    this.product,
    required this.produitUid,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = MockCartService();
  int _quantity = 1;
  bool _isAddingToCart = false;
  Product? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    try {
      final productDetail = await ProduitService().getProduitDetail(
        widget.produitUid,
      );
      if (mounted) {
        setState(() {
          _productDetail = productDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  Future<void> _addToCart() async {
    if (_productDetail == null) return;
    setState(() => _isAddingToCart = true);
    try {
      await _cartService.addToCart(_productDetail!, quantity: _quantity);
      if (mounted) {
        CartSnackBar.show(
          context,
          productName: _productDetail!.title,
          message: 'Ajouté au panier',
          backgroundColor: AppColors.shopGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        CartSnackBar.show(
          context,
          productName: 'Erreur',
          message: 'Impossible d\'ajouter au panier',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.screenTextSecondaryThemed(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProductDetail,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _productDetail ?? widget.product;
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: const Center(child: Text('Produit non disponible')),
      );
    }
    final Color accent = Color(int.parse(product.color));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(accent, product),
            SliverToBoxAdapter(child: _buildBody(accent, product)),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(accent, product),
      ),
    );
  }

  Widget _buildSliverAppBar(Color accent, Product product) {
    return CustomSliverAppBar(
      title: '',
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      elevation: 0,
      onBackTap: _navigateBack,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product image
            product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(accent),
                  )
                : _buildPlaceholder(accent),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // Content positioned at bottom
            Positioned(
              bottom: 36,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_bag_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    product.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.6), accent.withOpacity(0.3)],
        ),
      ),
      child: Icon(Icons.shopping_bag, color: Colors.white24, size: 80),
    );
  }

  Widget _buildBody(Color accent, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenSurfaceThemed(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildPriceSection(accent, product),
            const SizedBox(height: 24),
            _buildDescription(product),
            const SizedBox(height: 24),
            _buildMetaInfo(accent, product),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(Color accent, Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prix',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.screenTextSecondaryThemed(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.price > 0
                    ? '${product.price.toStringAsFixed(0)} F'
                    : 'Gratuit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: product.price > 0 ? accent : Colors.green,
                ),
              ),
            ],
          ),
          // Quantity selector
          Row(
            children: [
              GestureDetector(
                onTap: _decrementQuantity,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.remove_rounded, color: accent, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$_quantity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _incrementQuantity,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.screenTextPrimaryThemed(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            product.description.isNotEmpty
                ? product.description
                : 'Aucune description disponible pour ce produit.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.screenTextSecondaryThemed(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(Color accent, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.screenTextPrimaryThemed(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                width: 170,
                child: _MetaCard(
                  icon: Icons.category_rounded,
                  iconColor: accent,
                  title: product.type,
                  subtitle: 'Type',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: _MetaCard(
                  icon: product.isAvailable
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  iconColor: product.isAvailable
                      ? AppColors.shopGreen
                      : Colors.red,
                  title: product.isAvailable ? 'Disponible' : 'Indisponible',
                  subtitle: 'Statut',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: _MetaCard(
                  icon: Icons.inventory_2_rounded,
                  iconColor: accent,
                  title: '${product.stockQuantity} unités',
                  subtitle: 'Stock',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Color accent, Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isAddingToCart || !product.isAvailable
                ? null
                : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.screenTextSecondaryThemed(
                context,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isAddingToCart
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        product.isAvailable
                            ? 'Ajouter au panier'
                            : 'Non disponible',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MetaCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.screenBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.screenTextSecondaryThemed(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
