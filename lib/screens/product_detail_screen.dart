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
import '../widgets/snackbar.dart';

// ─── DESIGN TOKENS LOCAUX ─────────────────────────────────────────────────
// Tous les tokens utilisent les couleurs originales du projet.
// Aucune dépendance externe ajoutée.
class _T {
  // Surfaces
  static const bg = Color(0xFFF4F4F0); // fond principal légèrement chaud
  static const card = Colors.white;
  static const cardBorder = Color(0xFFEAEAE6);
  static const divider = Color(0xFFEEEEEA);
  static const stepperBg = Color(0xFFF4F4F0);

  // Textes
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFFAAAAAA);

  // Accents (reprend AppColors.shopGreen et AppColors.screenOrange)
  static const green = AppColors.shopGreen; // #2E7D32 ou équivalent
  static const greenLight = Color(0xFFEDF7EE);
  static const greenBorder = Color(0xFFB8D9BA);
  static const orange = AppColors.screenOrange; // #FF5500 ou équivalent
  static const orangeLight = Color(0xFFFFF3E8);
  static const orangeBorder = Color(0xFFF5C9A0);
  static const orangeGlow = Color(0x4DFF5500);

  // Nav pill
  static const navPill = Color(0xCCFFFFFF);
  static const navBorder = Color(0x0F000000);

  // Shadows
  static const shadowSoft = Color(0x0A000000);
  static const shadowMedium = Color(0x14000000);
  static const shadowStrong = Color(0x20000000);
}

// ─── SCREEN ───────────────────────────────────────────────────────────────
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
    with TickerProviderStateMixin {
  // ── Services (inchangés) ──────────────────────────────────────────────
  final CartService _cartService = MockCartService();
  final ProduitService _produitService = ProduitService();

  // ── State (inchangé) ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isDetailLoading = true;
  int _quantity = 1;
  Product? _detailedProduct;
  int _selectedTab = 0;
  bool _descExpanded = false;

  static const _tabs = ['Détails', 'Specs', 'Avis'];

  // ── Animations ────────────────────────────────────────────────────────
  // late final : initialisé au premier accès, garanti après création du State.
  // Évite le LateInitializationError causé par un rebuild parent avant initState.
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _slideCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

  // ─────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Load (logique inchangée) ──────────────────────────────────────────
  Future<void> _loadProductDetail() async {
    if (widget.produitUid != null) {
      try {
        final detailedProduct = await _produitService.getProduitDetail(
          widget.produitUid!,
        );
        setState(() {
          _detailedProduct = detailedProduct;
          _isDetailLoading = false;
        });
      } catch (e) {
        setState(() => _isDetailLoading = false);
        _showSnackBar(
          'Erreur lors du chargement des détails: $e',
          isError: true,
        );
      }
    } else {
      setState(() => _isDetailLoading = false);
    }
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  // ── SnackBar (logique inchangée) ──────────────────────────────────────
  void _showSnackBar(
    String msg, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? Colors.red[400]
            : isSuccess
            ? Colors.green[500]
            : Colors.blue[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Product p = _detailedProduct ?? widget.product;
    final Color productColor = Color(int.parse(p.color));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: _isDetailLoading
            ? Center(
                child: CustomLoader(
                  message: 'Chargement du produit...',
                  loaderColor: AppColors.shopGreen,
                  backgroundColor: _T.bg,
                  showBackground: false,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: Stack(
                  children: [
                    // ── Scrollable content ──
                    CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(p, productColor),
                        SliverToBoxAdapter(
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildContent(p, productColor),
                          ),
                        ),
                        // espace pour la bottom bar
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                    // ── Bottom bar flottante ──
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: p.price > 0
                          ? _buildBottomActionBar(p, productColor)
                          : _buildFreeServiceAction(p, productColor),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SLIVER APP BAR
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(Product product, Color productColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _T.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image produit
            ImageHelper.buildNetworkImage(
              imageUrl: product.imageUrl,
              placeholder: product.title,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            // Fade progressif bas → fond clair
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 0.82, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x66F4F4F0),
                    _T.bg,
                  ],
                ),
              ),
            ),
            // Badges bas
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTypeBadge(product.type, productColor),
                  _buildStockBadge(product),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bouton retour
      leading: _buildNavButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      // Actions
      actions: [
        _buildNavButton(icon: Icons.favorite_border_rounded, onTap: () {}),
        _buildNavButton(
          icon: Icons.ios_share_rounded,
          onTap: _shareProduct,
          rightPadding: 12,
        ),
      ],
    );
  }

  // ── Nav button (glassmorphism léger) ─────────────────────────────────
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    double rightPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 8, right: rightPadding, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _T.navPill,
            shape: BoxShape.circle,
            border: Border.all(color: _T.navBorder),
            boxShadow: const [
              BoxShadow(
                color: _T.shadowMedium,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: _T.textPrimary),
        ),
      ),
    );
  }

  // ── Type badge ───────────────────────────────────────────────────────
  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ── Stock badge ──────────────────────────────────────────────────────
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
      color = _T.green;
      label = 'Disponible';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _T.shadowMedium,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CONTENU PRINCIPAL
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildContent(Product product, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(product, primaryColor),
          const SizedBox(height: 4),
          _buildDivider(),
          _buildTabs(),
          _buildDescriptionCard(product),
          const SizedBox(height: 12),
          _buildInfoChips(product, primaryColor),
          const SizedBox(height: 12),
          if (product.price > 0) _buildQuantitySelector(product),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: _T.divider,
      margin: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  // ── Titre + Prix ─────────────────────────────────────────────────────
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
                  color: _T.textPrimary,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                product.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: _T.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (product.price > 0) ...[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.price.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _T.green,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'FCFA / unité',
                style: TextStyle(fontSize: 10, color: _T.textMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Tabs Détails / Specs / Avis ───────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAE6),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final bool active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: _T.shadowMedium,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: active ? _T.textPrimary : _T.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Description card avec "Voir plus" ───────────────────────────────
  static const int _descMaxLines = 3;

  Widget _buildDescriptionCard(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [
          BoxShadow(color: _T.shadowSoft, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ──
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 14, color: _T.green),
              SizedBox(width: 7),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.green,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Texte avec AnimatedCrossFade ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _descExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            // Version tronquée
            firstChild: Text(
              product.description,
              maxLines: _descMaxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _T.textSecondary,
                height: 1.65,
              ),
            ),
            // Version complète
            secondChild: Text(
              product.description,
              style: const TextStyle(
                fontSize: 13,
                color: _T.textSecondary,
                height: 1.65,
              ),
            ),
          ),
          // ── Bouton Voir plus / Voir moins ──
          // Affiché uniquement si la description dépasse _descMaxLines
          LayoutBuilder(
            builder: (context, constraints) {
              // Mesure si le texte déborde sur plus de _descMaxLines lignes
              final tp = TextPainter(
                text: TextSpan(
                  text: product.description,
                  style: const TextStyle(fontSize: 13, height: 1.65),
                ),
                maxLines: _descMaxLines,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final bool overflows = tp.didExceedMaxLines;

              if (!overflows) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _descExpanded ? 'Voir moins' : 'Voir plus',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _T.green,
                        ),
                      ),
                      const SizedBox(width: 3),
                      AnimatedRotation(
                        turns: _descExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _T.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Info chips ────────────────────────────────────────────────────────
  Widget _buildInfoChips(Product product, Color primaryColor) {
    return Row(
      children: [
        _infoChip(
          icon: Icons.inventory_2_outlined,
          label: '${product.stockQuantity} en stock',
          color: product.stockQuantity > 10
              ? _T.green
              : product.stockQuantity > 0
              ? Colors.orange
              : Colors.red,
          isGreen: product.stockQuantity > 10,
        ),
        const SizedBox(width: 10),
        _infoChip(
          icon: Icons.label_outline_rounded,
          label: product.type,
          color: _T.orange,
          isOrange: true,
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isGreen = false,
    bool isOrange = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isGreen
            ? _T.greenLight
            : isOrange
            ? _T.orangeLight
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGreen
              ? _T.greenBorder
              : isOrange
              ? _T.orangeBorder
              : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

  // ── Quantity selector ─────────────────────────────────────────────────
  Widget _buildQuantitySelector(Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [
          BoxShadow(color: _T.shadowSoft, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 17,
            color: _T.textSecondary,
          ),
          const SizedBox(width: 10),
          const Text(
            'Quantité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          // Stepper
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _T.stepperBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _T.cardBorder),
            ),
            child: Row(
              children: [
                _stepperButton(
                  icon: Icons.remove,
                  enabled: _quantity > 1,
                  onTap: () => setState(() => _quantity--),
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _T.textPrimary,
                      ),
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add,
                  enabled: _quantity < product.stockQuantity,
                  onTap: () => setState(() => _quantity++),
                  isAdd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xFFEEEEEE)
              : isAdd
              ? _T.orange
              : const Color(0xFFF4F4F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 15,
          color: !enabled
              ? const Color(0xFFCCCCCC)
              : isAdd
              ? Colors.white
              : _T.textPrimary,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(Product product, Color primaryColor) {
    final double total = product.price * _quantity;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        // boxShadow: [
        //   BoxShadow(
        //     color: _T.shadowStrong,
        //     blurRadius: 24,
        //     offset: Offset(0, -6),
        //   ),
        // ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0DA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: _T.textMuted),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${total.toStringAsFixed(0)} ',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _T.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            WidgetSpan(
                              child: Transform.translate(
                                offset: const Offset(0, -4),
                                child: const Text(
                                  'FCFA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _T.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // CTA
                  SizedBox(
                    width: 160,
                    child: _buildCTAButton(
                      label: 'Commander',
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _T.shadowStrong,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0DA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildCTAButton(
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

  // ── CTA Button (gradient orange) ─────────────────────────────────────
  Widget _buildCTAButton({
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
        height: 42,
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
                    color: _T.orangeGlow,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color: enabled ? Colors.white : const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : const Color(0xFFAAAAAA),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // ACTIONS (logique 100% inchangée)
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _addToCart(Product product) async {
    setState(() => _isLoading = true);
    try {
      final success = await _cartService.addToCart(
        product,
        quantity: _quantity,
      );
      if (success) {
        CartSnackBar.show(context, productName: product.title);
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
