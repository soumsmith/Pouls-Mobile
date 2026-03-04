import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../config/app_typography.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/produit_service.dart';
import '../utils/image_helper.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/custom_button.dart';

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

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = MockCartService();
  final ProduitService _produitService = ProduitService();
  bool _isLoading = false;
  bool _isDetailLoading = true;
  int _quantity = 1;
  Product? _detailedProduct;

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    if (widget.produitUid != null) {
      try {
        final detailedProduct = await _produitService.getProduitDetail(widget.produitUid!);
        setState(() {
          _detailedProduct = detailedProduct;
          _isDetailLoading = false;
        });
      } catch (e) {
        setState(() {
          _isDetailLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des détails: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        _isDetailLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Product currentProduct = _detailedProduct ?? widget.product;
    final Color primaryColor = Color(int.parse(currentProduct.color));

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButtonWidget(),
        title: Text(
          'Détails du produit',
          style: TextStyle(
            fontSize: AppTypography.headlineMedium,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: _isDetailLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        _buildProductImage(currentProduct),
                        SizedBox(height: AppDimensions.spacingL),
                        
                        // Product Info
                        _buildProductInfo(currentProduct, primaryColor),
                        SizedBox(height: AppDimensions.spacingL),
                        
                        // Description and Stock in same row for compact layout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDescription(currentProduct),
                            ),
                            SizedBox(width: AppDimensions.spacingM),
                            Expanded(
                              child: _buildStockStatus(currentProduct),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDimensions.spacingL),
                        
                        // Quantity Selector
                        if (currentProduct.price > 0) _buildQuantitySelector(currentProduct),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Action Bar
                if (currentProduct.price > 0)
                  _buildBottomActionBar(currentProduct, primaryColor)
                else
                  _buildFreeServiceAction(currentProduct, primaryColor),
              ],
            ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: ImageHelper.buildNetworkImage(
          imageUrl: product.imageUrl,
          placeholder: product.title,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product product, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: AppTypography.titleSmall,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingS),
                  Text(
                    product.subtitle,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.type,
                style: TextStyle(
                  fontSize: AppTypography.labelMedium,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppDimensions.spacingM),
        
        // Price section removed - price shown in bottom action bar
      ],
    );
  }

  Widget _buildDescription(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: AppTypography.titleMedium,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.spacingS),
        Text(
          product.description,
          style: TextStyle(
            fontSize: AppTypography.bodyMedium,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStockStatus(Product product) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!product.isAvailable) {
      statusColor = Colors.red;
      statusText = 'Rupture';
      statusIcon = Icons.inventory_2_outlined;
    } else if (product.stockQuantity <= 10) {
      statusColor = Colors.orange;
      statusText = 'Limité';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = Colors.green;
      statusText = 'Disponible';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          SizedBox(width: AppDimensions.spacingXS),
          Text(
            statusText,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(Product product) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantité',
            style: TextStyle(
              fontSize: AppTypography.titleMedium,
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: TextStyle(
                      fontSize: AppTypography.titleMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _quantity < product.stockQuantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Product product, Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    '${(product.price * _quantity).toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: AppTypography.titleLarge,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.spacingM),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Ajouter au panier',
                onPressed: product.isAvailable && !_isLoading ? () => _addToCart(product) : null,
                isLoading: _isLoading,
                backgroundColor: primaryColor,
                height: AppDimensions.buttonHeight,
                borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeServiceAction(Product product, Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Accéder au service',
          onPressed: () => _accessFreeService(product),
          backgroundColor: primaryColor,
          height: AppDimensions.buttonHeight,
          borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _isLoading = true);

    try {
      final success = await _cartService.addToCart(
        product,
        quantity: _quantity,
      );

      if (success) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} ajouté au panier'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Redirection automatique vers le panier
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, '/cart');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout au panier'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ajout au panier'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _accessFreeService(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accès à ${product.title}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _shareProduct() {
    final Product currentProduct = _detailedProduct ?? widget.product;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage du produit bientôt disponible'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  }
