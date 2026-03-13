import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../config/app_typography.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';
import '../utils/image_helper.dart';
import '../widgets/custom_loader.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ───────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? produitUid;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.produitUid,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = MockCartService();
  final ProduitService _produitService = ProduitService();
  bool _isLoading = false;
  bool _isDetailLoading = true;
  int _quantity = 1;
  Product? _detailedProduct;

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
    _loadProductDetail();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetail() async {
    if (widget.produitUid != null) {
      try {
        final detailedProduct =
            await _produitService.getProduitDetail(widget.produitUid!);
        setState(() {
          _detailedProduct = detailedProduct;
          _isDetailLoading = false;
        });
      } catch (e) {
        setState(() => _isDetailLoading = false);
        _showSnackBar('Erreur lors du chargement des détails: $e',
            isError: true);
      }
    } else {
      setState(() => _isDetailLoading = false);
    }
    _fadeController.forward();
  }

  void _showSnackBar(String msg, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? Colors.red[400]
            : isSuccess
                ? Colors.green[500]
                : Colors.blue[500],
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Product currentProduct = _detailedProduct ?? widget.product;
    final Color primaryColor = Color(int.parse(currentProduct.color));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: _isDetailLoading
            ? Center(
                child: CustomLoader(
                  message: 'Chargement du produit...',
                  loaderColor: AppColors.shopGreen,
                  backgroundColor: AppColors.screenSurface,
                  showBackground: false,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          _buildSliverAppBar(currentProduct, primaryColor),
                          SliverToBoxAdapter(
                            child: _buildContent(currentProduct, primaryColor),
                          ),
                        ],
                      ),
                    ),
                    // Bottom bar
                    if (currentProduct.price > 0)
                      _buildBottomActionBar(currentProduct, primaryColor)
                    else
                      _buildFreeServiceAction(currentProduct, primaryColor),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── SLIVER APP BAR avec image hero ────────────────────────────────────────
  Widget _buildSliverAppBar(Product product, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.screenCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 15, color: AppColors.screenTextPrimary),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: _shareProduct,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.share_outlined,
                  size: 16, color: AppColors.screenTextPrimary),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ImageHelper.buildNetworkImage(
              imageUrl: product.imageUrl,
              placeholder: product.title,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Gradient overlay au bas pour la transition
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x33000000),
                    Color(0x88000000),
                  ],
                  stops: [0, 0.5, 0.8, 1],
                ),
              ),
            ),
            // Type badge en bas à gauche sur l'image
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Stock badge en bas à droite
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildStockBadge(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(Product product) {
    Color color;
    String label;
    IconData icon;

    if (!product.isAvailable) {
      color = Colors.red;
      label = 'Rupture';
      icon = Icons.inventory_2_outlined;
    } else if (product.stockQuantity <= 10) {
      color = Colors.orange;
      label = 'Stock limité';
      icon = Icons.warning_amber_outlined;
    } else {
      color = Colors.green;
      label = 'Disponible';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CONTENU PRINCIPAL ─────────────────────────────────────────────────────
  Widget _buildContent(Product product, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + sous-titre
          _buildProductHeader(product, primaryColor),
          const SizedBox(height: 20),

          // Description
          _buildDescriptionCard(product),
          const SizedBox(height: 16),

          // Infos chips (stock qty, catégorie…)
          _buildInfoChips(product, primaryColor),
          const SizedBox(height: 16),

          // Sélecteur de quantité
          if (product.price > 0) _buildQuantitySelector(product),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Titre ──────────────────────────────────────────────────────────────────
  Widget _buildProductHeader(Product product, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.6,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.screenTextSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (product.price > 0) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.shopGreen,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'FCFA / unité',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.screenTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Description card ───────────────────────────────────────────────────────
  Widget _buildDescriptionCard(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDivider),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.shopGreen),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info chips ─────────────────────────────────────────────────────────────
  Widget _buildInfoChips(Product product, Color primaryColor) {
    return Row(
      children: [
        _infoChip(
          icon: Icons.inventory_2_outlined,
          label: '${product.stockQuantity} en stock',
          color: product.stockQuantity > 10
              ? Colors.green
              : product.stockQuantity > 0
                  ? Colors.orange
                  : Colors.red,
        ),
        const SizedBox(width: 10),
        _infoChip(
          icon: Icons.label_outline_rounded,
          label: product.type,
          color: primaryColor,
        ),
      ],
    );
  }

  Widget _infoChip(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quantity selector ──────────────────────────────────────────────────────
  Widget _buildQuantitySelector(Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.screenDivider),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 18, color: AppColors.screenTextSecondary),
          const SizedBox(width: 10),
          const Text(
            'Quantité',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          // Stepper — même style que CartScreen
          Row(
            children: [
              GestureDetector(
                onTap: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _quantity > 1
                        ? AppColors.screenSurface
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: _quantity > 1
                        ? AppColors.screenTextPrimary
                        : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _quantity < product.stockQuantity
                    ? () => setState(() => _quantity++)
                    : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _quantity < product.stockQuantity
                        ? AppColors.shopGreen
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: _quantity < product.stockQuantity
                        ? Colors.white
                        : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM ACTION BAR ─────────────────────────────────────────────────────
  Widget _buildBottomActionBar(Product product, Color primaryColor) {
    final double total = product.price * _quantity;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  // Prix total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.screenTextPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // CTA button
                  Expanded(
                    child: _buildOrangeButton(
                      label: 'Ajouter au panier',
                      icon: Icons.shopping_bag_outlined,
                      isLoading: _isLoading,
                      enabled: product.isAvailable && !_isLoading,
                      onTap: product.isAvailable && !_isLoading
                          ? () => _addToCart(product)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeServiceAction(Product product, Color primaryColor) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildOrangeButton(
                label: 'Accéder au service',
                icon: Icons.open_in_new_rounded,
                onTap: () => _accessFreeService(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ORANGE BUTTON (même style que CartScreen) ────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.screenOrange.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 18,
                        color: enabled ? Colors.white : AppColors.screenTextSecondary),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : AppColors.screenTextSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  Future<void> _addToCart(Product product) async {
    setState(() => _isLoading = true);
    try {
      final success =
          await _cartService.addToCart(product, quantity: _quantity);
      if (success) {
        _showSnackBar('${product.title} ajouté au panier', isSuccess: true);
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, '/cart');
        });
      } else {
        _showSnackBar('Erreur lors de l\'ajout au panier', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout au panier', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _accessFreeService(Product product) {
    _showSnackBar('Accès à ${product.title}', isSuccess: true);
  }

  void _shareProduct() {
    _showSnackBar('Partage du produit bientôt disponible');
  }
}