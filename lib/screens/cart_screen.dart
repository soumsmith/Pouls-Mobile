import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../models/cart_item.dart';
import '../models/lieu_livraison.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/lieu_livraison_service.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/searchable_dropdown.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = MockCartService();
  final OrderService _orderService = OrderService();
  final LieuLivraisonService _lieuLivraisonService = LieuLivraisonService();
  Cart? _cart;
  bool _isLoading = true;
  bool _isCheckingOut = false;
  
  // Variables pour les lieux de livraison
  List<LieuLivraison> _lieuxLivraison = [];
  LieuLivraison? _selectedLieu;
  bool _isLoadingLieux = true;
  String? _lieuxError;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadLieuxLivraison();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _cartService.getCurrentCart();
      print('🛒 Chargement panier: ${cart.items.length} articles');
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      print('🛒 Erreur chargement panier: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du chargement du panier'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        leading: const BackButtonWidget(),
        title: Text(
          'Panier',
          style: AppTypography.appBarTitle.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          if (_cart?.isNotEmpty == true)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: _clearCart,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_cart?.isEmpty == true) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        Expanded(
          child: _buildCartItems(),
        ),
        _buildCheckoutSummary(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: AppTypography.titleMedium,
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits pour commencer vos achats',
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continuer vos achats',
              style: TextStyle(
                fontSize: AppTypography.labelLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cart!.items.length,
      itemBuilder: (context, index) {
        final item = _cart!.items[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: item.product.imageUrl != null
                    ? Image.network(
                        item.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          );
                        },
                      )
                    : Icon(
                        Icons.image,
                        color: Colors.grey[400],
                        size: 40,
                      ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: TextStyle(
                      fontSize: AppTypography.titleSmall,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.subtitle,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.product.price.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: AppTypography.titleSmall,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: item.quantity > 1
                            ? () => _updateQuantity(item.id, item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                        iconSize: 18,
                        padding: const EdgeInsets.all(4),
                      ),
                      Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: AppTypography.bodyMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateQuantity(item.id, item.quantity + 1),
                        icon: const Icon(Icons.add),
                        iconSize: 18,
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _removeItem(item.id),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${_cart!.totalItems} articles)',
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  '${_cart!.totalAmount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: AppTypography.titleLarge,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingOut ? null : _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCheckingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Procéder au paiement',
                        style: TextStyle(
                          fontSize: AppTypography.labelLarge,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    final success = await _cartService.updateCartItemQuantity(cartItemId, newQuantity);
    if (success) {
      _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour de la quantité'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final success = await _cartService.removeFromCart(cartItemId);
    if (success) {
      _loadCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article supprimé du panier'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression de l\'article'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cartService.clearCart();
      if (success) {
        _loadCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panier vidé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOrderBottomSheet(),
    );
  }

  Widget _buildOrderBottomSheet() {
    final _nomController = TextEditingController();
    final _telephoneController = TextEditingController();
    final _adresseController = TextEditingController();
    final _emailController = TextEditingController();
    final _villeController = TextEditingController();
    final _paysController = TextEditingController();
    final _communeController = TextEditingController();
    final _ecoleController = TextEditingController();
    final _eleveIdController = TextEditingController();
    String _typeLivraison = 'domicile';
    double _prixLivraison = _selectedLieu?.prixlivraison.toDouble() ?? 2000;
    bool _isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Finaliser la commande',
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez remplir vos informations pour finaliser la commande',
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom complet
                          _buildTextField(
                            controller: _nomController,
                            label: 'Nom complet',
                            hint: 'Entrez votre nom complet',
                            icon: Icons.person,
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          
                          // Téléphone
                          _buildTextField(
                            controller: _telephoneController,
                            label: 'Téléphone',
                            hint: 'Entrez votre numéro de téléphone',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            required: true,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Entrez votre adresse email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          
                          // Adresse
                          _buildTextField(
                            controller: _adresseController,
                            label: 'Adresse de livraison',
                            hint: 'Entrez votre adresse complète',
                            icon: Icons.location_on,
                            required: true,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          
                          // Ville
                          _buildTextField(
                            controller: _villeController,
                            label: 'Ville',
                            hint: 'Entrez votre ville',
                            icon: Icons.location_city,
                          ),
                          const SizedBox(height: 16),
                          
                          // Pays
                          _buildTextField(
                            controller: _paysController,
                            label: 'Pays',
                            hint: 'Entrez votre pays',
                            icon: Icons.flag,
                          ),
                          const SizedBox(height: 16),
                          
                          // Lieu de livraison (remplace le champ commune)
                          _buildLieuLivraisonField(
            setState: setState,
            onLieuSelected: (lieu) {
              setState(() {
                _selectedLieu = lieu;
                _communeController.text = lieu.nomcommune;
                _prixLivraison = _typeLivraison == 'domicile' ? lieu.prixlivraison.toDouble() : 0;
              });
            },
          ),
                          const SizedBox(height: 16),
                          
                          // Type de livraison
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type de livraison',
                                style: TextStyle(
                                  fontSize: AppTypography.bodyMedium,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: DropdownButton<String>(
                                  value: _typeLivraison,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'domicile', child: Text('Livraison à domicile')),
                                    DropdownMenuItem(value: 'retrait', child: Text('Retrait sur place')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _typeLivraison = value!;
                                      _prixLivraison = value == 'domicile' ? 2000 : 0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // École (optionnel)
                          _buildTextField(
                            controller: _ecoleController,
                            label: 'École',
                            hint: 'Entrez le nom de l\'école (optionnel)',
                            icon: Icons.school,
                          ),
                          const SizedBox(height: 16),
                          
                          // ID Élève (optionnel)
                          _buildTextField(
                            controller: _eleveIdController,
                            label: 'ID Élève',
                            hint: 'Entrez l\'identifiant de l\'élève (optionnel)',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
                          
                          // Order summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Récapitulatif de la commande',
                                  style: TextStyle(
                                    fontSize: AppTypography.titleMedium,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_cart?.totalItems ?? 0} article(s)',
                                      style: TextStyle(
                                        fontSize: AppTypography.bodyMedium,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Sous-total: ${(_cart?.totalAmount ?? 0).toStringAsFixed(0)} FCFA',
                                          style: TextStyle(
                                            fontSize: AppTypography.bodySmall,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                        Text(
                                          'Livraison: ${_prixLivraison.toStringAsFixed(0)} FCFA',
                                          style: TextStyle(
                                            fontSize: AppTypography.bodySmall,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${((_cart?.totalAmount ?? 0) + _prixLivraison).toStringAsFixed(0)} FCFA',
                                          style: TextStyle(
                                            fontSize: AppTypography.titleMedium,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Submit button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        print('🔘 Bouton confirmer cliqué - _isSubmitting=$_isSubmitting');
                        print('📝 Formulaire: nom="${_nomController.text}", tel="${_telephoneController.text}", adresse="${_adresseController.text}"');
                        
                        if (_nomController.text.trim().isEmpty ||
                            _telephoneController.text.trim().isEmpty ||
                            _adresseController.text.trim().isEmpty ||
                            _communeController.text.trim().isEmpty) {
                          print('❌ Champs obligatoires manquants');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir tous les champs obligatoires'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        print('✅ Validation OK, début de la soumission');
                        setState(() => _isSubmitting = true);
                        
                        try {
                          print('📤 Appel API en cours...');
                          print('🛒 Articles: ${_cart!.items.length}');
                          
                          final result = await _orderService.createOrder(
                            items: _cart!.items,
                            nom: _nomController.text.trim(),
                            telephone: _telephoneController.text.trim(),
                            adresse: _adresseController.text.trim(),
                            email: _emailController.text.trim().isNotEmpty 
                                ? _emailController.text.trim() 
                                : null,
                            ville: _villeController.text.trim().isNotEmpty 
                                ? _villeController.text.trim() 
                                : null,
                            pays: _paysController.text.trim().isNotEmpty 
                                ? _paysController.text.trim() 
                                : null,
                            commune: _communeController.text.trim(),
                            typeLivraison: _typeLivraison,
                            prixLivraison: _prixLivraison,
                            ecole: _ecoleController.text.trim().isNotEmpty 
                                ? _ecoleController.text.trim() 
                                : null,
                            eleveId: _eleveIdController.text.trim().isNotEmpty 
                                ? _eleveIdController.text.trim() 
                                : null,
                          );
                          
                          print('✅ API response: $result');
                          
                          Navigator.pop(context); // Close bottom sheet
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']['message'] ?? 'Commande passée avec succès !'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          
                          // Clear cart and navigate
                          await _cartService.clearCart();
                          _loadCart();
                          
                        } catch (e) {
                          print('❌ Erreur lors de la commande: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la commande: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          print('🔄 Fin du processus, reset _isSubmitting');
                          setState(() => _isSubmitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirmer la commande',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
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
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
      ],
    );
  }

  Future<void> _loadLieuxLivraison() async {
    try {
      print('🔄 Chargement des lieux de livraison...');
      final lieux = await _lieuLivraisonService.getLieuxLivraison();
      setState(() {
        _lieuxLivraison = lieux;
        _isLoadingLieux = false;
        _lieuxError = null;
      });
      print('✅ ${lieux.length} lieux de livraison chargés');
    } catch (e) {
      print('❌ Erreur chargement lieux: $e');
      setState(() {
        _isLoadingLieux = false;
        _lieuxError = e.toString();
      });
    }
  }

  Widget _buildLieuLivraisonField({
    required void Function(void Function()) setState,
    required Function(LieuLivraison) onLieuSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoadingLieux) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lieu de livraison',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.getBorderColor(isDark),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chargement des lieux de livraison...',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (_lieuxError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lieu de livraison',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.toSurface(),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _lieuxError!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _loadLieuxLivraison(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Réessayer', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (_lieuxLivraison.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lieu de livraison',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SearchableDropdown(
            label: 'Lieu de livraison',
            value: 'Aucun lieu disponible',
            items: ['Aucun lieu disponible'],
            onChanged: (String value) {},
            isDarkMode: isDark,
          ),
        ],
      );
    }
    
    // Préparer la liste des noms de lieux pour le SearchableDropdown
    final lieuNames = _lieuxLivraison.map((lieu) => '${lieu.nomcommune} (${lieu.prixlivraison} FCFA)').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lieu de livraison',
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SearchableDropdown(
          label: 'Lieu de livraison',
          value: _selectedLieu != null 
              ? '${_selectedLieu!.nomcommune} (${_selectedLieu!.prixlivraison} FCFA)'
              : 'Sélectionner un lieu de livraison...',
          items: lieuNames,
          onChanged: (String selectedName) {
            // Trouver le lieu correspondant par nom formaté
            final selectedLieu = _lieuxLivraison.firstWhere(
              (lieu) => '${lieu.nomcommune} (${lieu.prixlivraison} FCFA)' == selectedName,
            );
            onLieuSelected(selectedLieu);
          },
          isDarkMode: isDark,
        ),
        if (_selectedLieu != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.toSurface(),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frais de livraison: ${_selectedLieu!.prixlivraison} FCFA',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
