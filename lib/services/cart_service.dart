import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'auth_service.dart';

abstract class CartService {
  /// Récupère le panier actif de l'utilisateur
  Future<Cart> getCurrentCart();

  /// Ajoute un produit au panier
  Future<bool> addToCart(Product product, {int quantity = 1});

  /// Met à jour la quantité d'un article dans le panier
  Future<bool> updateCartItemQuantity(String cartItemId, int newQuantity);

  /// Supprime un article du panier
  Future<bool> removeFromCart(String cartItemId);

  /// Vide le panier
  Future<bool> clearCart();

  /// Convertit le panier en commande
  Future<Order?> checkoutCart({
    required PaymentMethod paymentMethod,
    String? shippingAddress,
    String? billingAddress,
    String? notes,
  });

  /// Récupère l'historique des commandes
  Future<List<Order>> getOrderHistory();

  /// Récupère les détails d'une commande
  Future<Order?> getOrderById(String orderId);

  /// Annule une commande
  Future<bool> cancelOrder(String orderId);

  /// Met à jour le statut d'une commande
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus);
}

class MockCartService implements CartService {
  static final MockCartService _instance = MockCartService._internal();
  factory MockCartService() => _instance;
  MockCartService._internal();

  Cart? _currentCart;
  final List<Order> _orderHistory = [];
  
  /// Récupère la clé de stockage du panier pour l'utilisateur connecté
  String get _cartKey {
    final currentUser = AuthService().getCurrentUser();
    if (currentUser != null) {
      return 'user_cart_${currentUser.id}';
    }
    // Fallback pour les utilisateurs non connectés (ne devrait pas arriver en production)
    return 'guest_cart';
  }

  /// Sauvegarde le panier dans SharedPreferences
  Future<void> _saveCart() async {
    if (_currentCart == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _cartToJson(_currentCart!);
      await prefs.setString(_cartKey, cartJson);
      final currentUser = AuthService().getCurrentUser();
      print('🛒 Panier sauvegardé pour l\'utilisateur: ${currentUser?.fullName ?? 'Guest'}');
    } catch (e) {
      print('🛒 Erreur sauvegarde panier: $e');
    }
  }

  /// Charge le panier depuis SharedPreferences
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        _currentCart = _cartFromJson(cartJson);
        print('🛒 Panier chargé depuis SharedPreferences: ${_currentCart!.items.length} articles');
      } else {
        _initializeCart();
        print('🛒 Aucun panier trouvé pour l\'utilisateur, création d\'un nouveau panier');
      }
    } catch (e) {
      print('🛒 Erreur chargement panier: $e');
      _initializeCart();
    }
  }

  /// Convertit le panier en JSON
  String _cartToJson(Cart cart) {
    return jsonEncode({
      'id': cart.id,
      'items': cart.items.map((item) => _cartItemToJson(item)).toList(),
      'createdAt': cart.createdAt.toIso8601String(),
      'updatedAt': cart.updatedAt.toIso8601String(),
    });
  }

  /// Convertit le JSON en panier
  Cart _cartFromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return Cart(
      id: data['id'] as String,
      items: (data['items'] as List)
          .map((item) => _cartItemFromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }

  /// Convertit un article du panier en JSON
  Map<String, dynamic> _cartItemToJson(CartItem item) {
    return {
      'id': item.id,
      'product': {
        'id': item.product.id,
        'title': item.product.title,
        'subtitle': item.product.subtitle,
        'description': item.product.description,
        'price': item.product.price,
        'imageUrl': item.product.imageUrl,
        'color': item.product.color,
        'type': item.product.type,
        'category': item.product.category,
        'isAvailable': item.product.isAvailable,
        'stockQuantity': item.product.stockQuantity,
      },
      'quantity': item.quantity,
      'addedAt': item.addedAt.toIso8601String(),
    };
  }

  /// Convertit le JSON en article du panier
  CartItem _cartItemFromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product(
        id: json['product']['id'] as String,
        title: json['product']['title'] as String,
        subtitle: json['product']['subtitle'] as String,
        description: json['product']['description'] as String,
        price: (json['product']['price'] as num).toDouble(),
        imageUrl: json['product']['imageUrl'] as String,
        color: json['product']['color'] as String,
        type: json['product']['type'] as String,
        category: json['product']['category'] as String,
        isAvailable: json['product']['isAvailable'] as bool,
        stockQuantity: json['product']['stockQuantity'] as int,
      ),
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  void _initializeCart() {
    final currentUser = AuthService().getCurrentUser();
    _currentCart = Cart(
      id: 'cart_${currentUser?.id ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Cart> getCurrentCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_currentCart == null) {
      await _loadCart();
    }
    return _currentCart!;
  }

  @override
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final cart = await getCurrentCart();
      print('🛒 Ajout au panier: ${product.title}, quantité: $quantity');
      print('🛒 Panier actuel: ${cart.items.length} articles');
      
      // Vérifier si le produit est déjà dans le panier
      final existingItemIndex = cart.items.indexWhere(
        (item) => item.product.id == product.id
      );

      List<CartItem> updatedItems;
      
      if (existingItemIndex != -1) {
        // Mettre à jour la quantité
        final existingItem = cart.items[existingItemIndex];
        updatedItems = cart.items.map((item) => item).toList();
        updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
          quantity: existingItem.quantity + quantity,
        );
        print('🛒 Mise à jour quantité existante');
      } else {
        // Ajouter un nouvel article
        final newCartItem = CartItem(
          id: 'cartitem_${DateTime.now().millisecondsSinceEpoch}_${product.id}',
          product: product,
          quantity: quantity,
          addedAt: DateTime.now(),
        );
        updatedItems = [...cart.items, newCartItem];
        print('🛒 Ajout nouvel article');
      }

      _currentCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      print('🛒 Panier après ajout: ${_currentCart!.items.length} articles');
      
      // Sauvegarder le panier après modification
      await _saveCart();
      return true;
    } catch (e) {
      print('🛒 Erreur ajout panier: $e');
      return false;
    }
  }

  @override
  Future<bool> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      final cart = await getCurrentCart();
      
      if (newQuantity <= 0) {
        return removeFromCart(cartItemId);
      }

      final itemIndex = cart.items.indexWhere((item) => item.id == cartItemId);
      if (itemIndex == -1) return false;

      final updatedItems = cart.items.map((item) => item).toList();
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        quantity: newQuantity,
      );

      _currentCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder le panier après modification
      await _saveCart();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeFromCart(String cartItemId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      final cart = await getCurrentCart();
      final updatedItems = cart.items.where((item) => item.id != cartItemId).toList();
      
      _currentCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder le panier après modification
      await _saveCart();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clearCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      _currentCart = (await getCurrentCart()).copyWith(
        items: [],
        updatedAt: DateTime.now(),
      );
      
      // Sauvegarder le panier après modification
      await _saveCart();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Order?> checkoutCart({
    required PaymentMethod paymentMethod,
    String? shippingAddress,
    String? billingAddress,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    try {
      final cart = await getCurrentCart();
      
      if (cart.isEmpty) {
        return null;
      }

      final order = Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        items: cart.items.map((item) => item).toList(),
        totalAmount: cart.totalAmount,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        paymentReference: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        confirmedAt: DateTime.now(),
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        notes: notes,
      );

      _orderHistory.add(order);
      
      // Vider le panier après validation
      await clearCart();

      return order;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_orderHistory);
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _orderHistory.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      final orderIndex = _orderHistory.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return false;

      final order = _orderHistory[orderIndex];
      if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
        return false;
      }

      _orderHistory[orderIndex] = order.copyWith(
        status: OrderStatus.cancelled,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final orderIndex = _orderHistory.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return false;

      _orderHistory[orderIndex] = _orderHistory[orderIndex].copyWith(
        status: newStatus,
        deliveredAt: newStatus == OrderStatus.delivered ? DateTime.now() : null,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Méthode utilitaire pour obtenir le nombre d'articles dans le panier
  Future<int> getCartItemCount() async {
    final cart = await getCurrentCart();
    return cart.totalItems;
  }

  /// Méthode utilitaire pour obtenir le montant total du panier
  Future<double> getCartTotal() async {
    final cart = await getCurrentCart();
    return cart.totalAmount;
  }

  /// Recharge le panier lors du changement d'utilisateur
  Future<void> reloadCartForCurrentUser() async {
    _currentCart = null; // Force le rechargement
    await getCurrentCart();
  }

  /// Nettoie le panier de l'utilisateur actuel (appelé lors de la déconnexion)
  Future<void> clearCurrentUserCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      _currentCart = null;
      print('🛒 Panier de l\'utilisateur supprimé');
    } catch (e) {
      print('🛒 Erreur suppression panier: $e');
    }
  }
}
