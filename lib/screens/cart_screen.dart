import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../models/cart_item.dart';
import '../models/lieu_livraison.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/lieu_livraison_service.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/order_wizard_bottom_sheet.dart';
import '../services/auth_service.dart';
import '../widgets/main_screen_wrapper.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CartService _cartService = MockCartService();
  final OrderService _orderService = OrderService();
  final LieuLivraisonService _lieuLivraisonService = LieuLivraisonService();
  final AuthService _authService = AuthService();
  Cart? _cart;
  bool _isLoading = true;
  bool _isCheckingOut = false;

  List<LieuLivraison> _lieuxLivraison = [];
  LieuLivraison? _selectedLieu;
  bool _isLoadingLieux = true;
  String? _lieuxError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadCart();
    _loadLieuxLivraison();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // L'application redevient active, recharger le panier
      print('DEBUG: CartScreen resumed - rechargement du panier');
      _loadCart();
    }
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _cartService.getCurrentCart();
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement du panier');
    }
  }

  Future<void> _loadLieuxLivraison() async {
    try {
      final lieux = await _lieuLivraisonService.getLieuxLivraison();
      setState(() {
        _lieuxLivraison = lieux;
        _isLoadingLieux = false;
        _lieuxError = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingLieux = false;
        _lieuxError = e.toString();
      });
    }
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.shopGreen,
          strokeWidth: 2.5,
        ),
      );
    }
    if (_cart?.isEmpty == true) return _buildEmptyCart();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildCartItems()),
          _buildModernCheckoutSummary(),
        ],
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mon Panier',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_cart != null)
                      Text(
                        '${_cart!.totalItems} article${_cart!.totalItems > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              // Clear cart button
              if (_cart?.isNotEmpty == true)
                GestureDetector(
                  onTap: _clearCart,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.shopBlueSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: AppColors.shopBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Panier vide',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez des produits pour\ncommencer vos achats',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.screenCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.screenDivider,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.screenShadow,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Continuer les achats',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CART ITEMS LIST ───────────────────────────────────────────────────────
  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _cart!.items.length,
      itemBuilder: (context, index) {
        return _buildCartItem(_cart!.items[index], index);
      },
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFFF5F5F5),
                  child: item.product.imageUrl != null
                      ? Image.network(
                          item.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFCCCCCC),
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFFCCCCCC),
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ── Bouton supprimer individuel ──
                        GestureDetector(
                          onTap: () => _removeItem(item.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 15,
                              color: Colors.red[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.product.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${item.product.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.shopGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        // Quantity stepper
                        _buildStepper(item),
                      ],
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

  Widget _buildStepper(CartItem item) {
    return Row(
      children: [
        GestureDetector(
          onTap: item.quantity > 1
              ? () => _updateQuantity(item.id, item.quantity - 1)
              : null,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.quantity > 1
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.remove,
              size: 15,
              color: item.quantity > 1
                  ? AppColors.screenTextPrimary
                  : const Color(0xFFCCCCCC),
            ),
          ),
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '${item.quantity}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _updateQuantity(item.id, item.quantity + 1),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.shopGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ─── MODERN CHECKOUT SUMMARY ───────────────────────────────────────────────────
  Widget _buildModernCheckoutSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header du résumé
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.shopBlueSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.shopBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé du panier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                    Text(
                      '${_cart?.totalItems ?? 0} article${(_cart?.totalItems ?? 0) > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Détails des prix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildPriceRow('Sous-total', '${(_cart?.totalAmount ?? 0).toStringAsFixed(0)} FCFA'),
                const SizedBox(height: 8),
                _buildPriceRow('Frais de livraison', 'Calculés à l\'étape suivante'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.screenDivider, height: 1),
                ),
                _buildPriceRow(
                  'Total',
                  '${(_cart?.totalAmount ?? 0).toStringAsFixed(0)} FCFA',
                  isTotal: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bouton de commande moderne
          _buildModernCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            color: isTotal ? AppColors.screenTextPrimary : AppColors.screenTextSecondary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.shopBlue : AppColors.screenTextPrimary,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModernCheckoutButton() {
    return GestureDetector(
      onTap: _isCheckingOut ? null : _proceedToCheckout,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isCheckingOut
              ? LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade300,
                  ],
                )
              : const LinearGradient(
                  colors: [
                    AppColors.shopBlueLight,
                    AppColors.shopBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: !_isCheckingOut
              ? [
                  BoxShadow(
                    color: AppColors.shopBlue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isCheckingOut
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Commander maintenant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── ORANGE BUTTON ────────────────────────────────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.shopBlueLight, AppColors.shopBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shopBlue.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
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
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    // Mise à jour optimiste locale — pas de rechargement complet
    final itemIndex = _cart!.items.indexWhere((i) => i.id == cartItemId);
    if (itemIndex == -1) return;

    final oldQuantity = _cart!.items[itemIndex].quantity;
    setState(() {
      _cart!.items[itemIndex] = _cart!.items[itemIndex].copyWith(
        quantity: newQuantity,
      );
    });

    final success = await _cartService.updateCartItemQuantity(
      cartItemId,
      newQuantity,
    );
    if (!success) {
      // Rollback en cas d'erreur
      setState(() {
        _cart!.items[itemIndex] = _cart!.items[itemIndex].copyWith(
          quantity: oldQuantity,
        );
      });
      _showError('Erreur lors de la mise à jour de la quantité');
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    // Suppression optimiste locale
    final itemIndex = _cart!.items.indexWhere((i) => i.id == cartItemId);
    if (itemIndex == -1) return;
    final removedItem = _cart!.items[itemIndex];
    setState(() {
      _cart!.items.removeAt(itemIndex);
    });

    final success = await _cartService.removeFromCart(cartItemId);
    if (success) {
      _showSuccess('Article supprimé du panier');
    } else {
      // Rollback
      setState(() {
        _cart!.items.insert(itemIndex, removedItem);
      });
      _showError('Erreur lors de la suppression');
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Vider le panier ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Tous les articles seront supprimés.',
          style: TextStyle(color: AppColors.screenTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.screenTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Vider',
              style: TextStyle(
                color: Colors.red[400],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cartService.clearCart();
      if (success) {
        _loadCart();
        _showSuccess('Panier vidé avec succès');
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cart?.isEmpty == true) return;
    _showOrderBottomSheet();
  }

  void _showOrderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderWizardBottomSheet(),
    );
  }

  // ─── ORDER WIZARD BOTTOM SHEET ───────────────────────────────────────────────────
  Widget _buildOrderWizardBottomSheet() {
    return OrderWizardBottomSheet(
      cart: _cart!,
      selectedLieu: _selectedLieu,
      lieuxLivraison: _lieuxLivraison,
      isLoadingLieux: _isLoadingLieux,
      lieuxError: _lieuxError,
      orderService: _orderService,
      authService: _authService,
      cartService: _cartService,
      onSuccess: (message) {
        print('DEBUG: CartScreen onSuccess appelé - redirection vers la boutique');
        _loadCart();
        // Rediriger vers la boutique (index 1 dans MainScreenWrapper)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            print('DEBUG: Navigation depuis CartScreen vers MainScreenWrapper');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainScreenWrapper(initialIndex: 1),
              ),
              (route) => false,
            );
          }
        });
      },
      onError: (message) => _showError(message),
      onLoadLieux: _loadLieuxLivraison,
    );
  }

  // ─── LEGACY ORDER BOTTOM SHEET (conservé pour référence) ───────────────────────────
  Widget _buildOrderBottomSheet() {
    // Récupérer les informations de l'utilisateur connecté
    final currentUser = _authService.getCurrentUser();

    final _nomController = TextEditingController();
    final _telephoneController = TextEditingController();
    final _adresseController = TextEditingController();
    final _emailController = TextEditingController();
    final _villeController = TextEditingController();
    final _paysController = TextEditingController();
    final _communeController = TextEditingController();
    final _ecoleController = TextEditingController();
    final _eleveIdController = TextEditingController();

    // Préremplir les champs avec les informations de l'utilisateur connecté
    if (currentUser != null) {
      _nomController.text = currentUser.fullName;
      _telephoneController.text = currentUser.phone;
      _emailController.text = currentUser.email ?? '';
      _adresseController.text = currentUser.adresse ?? '';
      _villeController.text = currentUser.ville ?? '';
      _paysController.text = 'Côte d\'Ivoire'; // Valeur par défaut
    }

    String _typeLivraison = 'domicile';
    double _prixLivraison = _selectedLieu?.prixlivraison.toDouble() ?? 2000;
    bool _isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.92,
            maxChildSize: 0.96,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Handle + header (fixed)
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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.shopBlueSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.shopBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Finaliser la commande',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.screenTextPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                                const Text(
                                  'Remplissez vos informations',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.screenTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                          color: AppColors.screenDivider,
                          height: 1,
                        ),
                      ],
                    ),
                  ),

                  // Scrollable form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Coordonnées
                          _sectionLabel('Coordonnées'),
                          const SizedBox(height: 12),
                          _buildSheetTextField(
                            controller: _nomController,
                            label: 'Nom complet',
                            hint: 'Jean Dupont',
                            icon: Icons.person_outline,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          _buildSheetTextField(
                            controller: _telephoneController,
                            label: 'Téléphone',
                            hint: '+225 07 00 00 00 00',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          _buildSheetTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'jean@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 24),
                          _sectionLabel('Livraison'),
                          const SizedBox(height: 12),

                          _buildSheetTextField(
                            controller: _adresseController,
                            label: 'Adresse',
                            hint: 'Quartier, rue...',
                            icon: Icons.location_on_outlined,
                            required: true,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSheetTextField(
                                  controller: _villeController,
                                  label: 'Ville',
                                  hint: 'Abidjan',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSheetTextField(
                                  controller: _paysController,
                                  label: 'Pays',
                                  hint: 'Côte d\'Ivoire',
                                  icon: Icons.flag_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Lieu de livraison
                          _buildLieuLivraisonField(
                            setState: setSheetState,
                            onLieuSelected: (lieu) {
                              setSheetState(() {
                                _selectedLieu = lieu;
                                _communeController.text = lieu.nomcommune;
                                _prixLivraison = _typeLivraison == 'domicile'
                                    ? lieu.prixlivraison.toDouble()
                                    : 0;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Type de livraison
                          _sectionSubLabel('Type de livraison'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _deliveryTypeChip(
                                label: 'À domicile',
                                icon: Icons.home_outlined,
                                selected: _typeLivraison == 'domicile',
                                onTap: () => setSheetState(() {
                                  _typeLivraison = 'domicile';
                                  _prixLivraison =
                                      _selectedLieu?.prixlivraison.toDouble() ??
                                      2000;
                                }),
                              ),
                              const SizedBox(width: 10),
                              _deliveryTypeChip(
                                label: 'Retrait sur place',
                                icon: Icons.store_outlined,
                                selected: _typeLivraison == 'retrait',
                                onTap: () => setSheetState(() {
                                  _typeLivraison = 'retrait';
                                  _prixLivraison = 0;
                                }),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _sectionLabel('Informations scolaires (optionnel)'),
                          const SizedBox(height: 12),
                          _buildSheetTextField(
                            controller: _ecoleController,
                            label: 'École',
                            hint: 'Nom de l\'établissement',
                            icon: Icons.school_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildSheetTextField(
                            controller: _eleveIdController,
                            label: 'ID Élève',
                            hint: 'Identifiant de l\'élève',
                            icon: Icons.badge_outlined,
                          ),

                          const SizedBox(height: 24),

                          // Order recap card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.screenSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.screenDivider,
                              ),
                            ),
                            child: Column(
                              children: [
                                _recapRow(
                                  'Sous-total',
                                  '${(_cart?.totalAmount ?? 0).toStringAsFixed(0)} FCFA',
                                  isSubtitle: true,
                                ),
                                const SizedBox(height: 8),
                                _recapRow(
                                  'Frais de livraison',
                                  '${_prixLivraison.toStringAsFixed(0)} FCFA',
                                  isSubtitle: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    color: AppColors.screenDivider,
                                    height: 1,
                                  ),
                                ),
                                _recapRow(
                                  'Total',
                                  '${((_cart?.totalAmount ?? 0) + _prixLivraison).toStringAsFixed(0)} FCFA',
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Submit button (fixed bottom)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    decoration: const BoxDecoration(
                      color: AppColors.screenCard,
                      border: Border(
                        top: BorderSide(color: AppColors.screenDivider),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: _buildOrangeButton(
                        label: 'Confirmer la commande',
                        isLoading: _isSubmitting,
                        onTap: _isSubmitting
                            ? null
                            : () async {
                                if (_nomController.text.trim().isEmpty ||
                                    _telephoneController.text.trim().isEmpty ||
                                    _adresseController.text.trim().isEmpty ||
                                    _communeController.text.trim().isEmpty) {
                                  _showError(
                                    'Veuillez remplir tous les champs obligatoires',
                                  );
                                  return;
                                }
                                setSheetState(() => _isSubmitting = true);
                                try {
                                  final result = await _orderService
                                      .createOrder(
                                        items: _cart!.items,
                                        nom: _nomController.text.trim(),
                                        telephone: _telephoneController.text
                                            .trim(),
                                        adresse: _adresseController.text.trim(),
                                        email:
                                            _emailController.text
                                                .trim()
                                                .isNotEmpty
                                            ? _emailController.text.trim()
                                            : null,
                                        ville:
                                            _villeController.text
                                                .trim()
                                                .isNotEmpty
                                            ? _villeController.text.trim()
                                            : null,
                                        pays:
                                            _paysController.text
                                                .trim()
                                                .isNotEmpty
                                            ? _paysController.text.trim()
                                            : null,
                                        commune: _communeController.text.trim(),
                                        typeLivraison: _typeLivraison,
                                        prixLivraison: _prixLivraison,
                                        ecole:
                                            _ecoleController.text
                                                .trim()
                                                .isNotEmpty
                                            ? _ecoleController.text.trim()
                                            : null,
                                        eleveId:
                                            _eleveIdController.text
                                                .trim()
                                                .isNotEmpty
                                            ? _eleveIdController.text.trim()
                                            : null,
                                      );
                                  Navigator.pop(context);
                                  _showSuccess(
                                    result['message']['message'] ??
                                        'Commande passée avec succès !',
                                  );
                                  await _cartService.clearCart();
                                  _loadCart();
                                } catch (e) {
                                  _showError('Erreur lors de la commande: $e');
                                } finally {
                                  setSheetState(() => _isSubmitting = false);
                                }
                              },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─── SHEET HELPERS ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.screenTextPrimary,
      letterSpacing: -0.3,
    ),
  );

  Widget _sectionSubLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.screenTextSecondary,
    ),
  );

  Widget _deliveryTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.screenOrangeLight
                : AppColors.screenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.screenOrange
                  : AppColors.screenDivider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.screenOrange
                    : AppColors.screenTextSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.screenOrange
                        : AppColors.screenTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recapRow(
    String label,
    String value, {
    bool isSubtitle = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            color: isTotal
                ? AppColors.screenTextPrimary
                : AppColors.screenTextSecondary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            color: isTotal
                ? AppColors.screenOrange
                : AppColors.screenTextPrimary,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.screenOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.screenTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: AppColors.screenOrange, size: 18),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.screenOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── LIEU LIVRAISON ───────────────────────────────────────────────────────
  Widget _buildLieuLivraisonField({
    required void Function(void Function()) setState,
    required Function(LieuLivraison) onLieuSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingLieux) {
      return _buildSheetLoadingField('Chargement des zones de livraison...');
    }

    if (_lieuxError != null) {
      return _buildSheetErrorField(_lieuxError!);
    }

    if (_lieuxLivraison.isEmpty) {
      return _buildSheetTextField(
        controller: TextEditingController(text: 'Aucune zone disponible'),
        label: 'Zone de livraison',
        hint: '',
        icon: Icons.location_on_outlined,
        required: true,
      );
    }

    final lieuNames = _lieuxLivraison
        .map((l) => '${l.nomcommune} — ${l.prixlivraison} FCFA')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Zone de livraison',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: AppColors.screenOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SearchableDropdown(
          label: 'Zone de livraison',
          value: _selectedLieu != null
              ? '${_selectedLieu!.nomcommune} — ${_selectedLieu!.prixlivraison} FCFA'
              : 'Sélectionner une zone...',
          items: lieuNames,
          onChanged: (String selectedName) {
            final selectedLieu = _lieuxLivraison.firstWhere(
              (l) =>
                  '${l.nomcommune} — ${l.prixlivraison} FCFA' == selectedName,
            );
            onLieuSelected(selectedLieu);
          },
          isDarkMode: isDark,
        ),
        if (_selectedLieu != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.screenOrangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.screenOrange,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frais de livraison : ${_selectedLieu!.prixlivraison} FCFA',
                  style: const TextStyle(
                    color: AppColors.screenOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSheetLoadingField(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.screenOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetErrorField(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loadLieuxLivraison,
            child: Row(
              children: [
                Icon(Icons.refresh, color: Colors.red[400], size: 14),
                const SizedBox(width: 6),
                Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
