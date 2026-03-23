import 'product.dart';
import '../config/app_config.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id']?.toString() ?? '',
      product: Product.fromMap(map['product'] as Map<String, dynamic>? ?? {}),
      quantity: map['quantity'] as int? ?? 1,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory CartItem.fromApiMap(Map<String, dynamic> map) {
    // Construire l'URL complète de l'image
    String? imageUrl = map['produit_image']?.toString();
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl =
          '${AppConfig.VIE_ECOLES_API_BASE_URL.replaceAll('/api', '')}/$imageUrl';
    }

    return CartItem(
      id: map['id_cf']?.toString() ?? '',
      product: Product.fromApiMap({
        'produit_uid': map['produit_scolaire_uid'],
        'titre': map['produit_nom'],
        'image': imageUrl,
        'prix_librairie': map['prix_unitaire'],
      }),
      quantity: map['quantite'] as int? ?? 1,
      addedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get subtotal => product.price * quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.title}, quantity: $quantity)';
  }
}

class Cart {
  final String id;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromMap(Map<String, dynamic> map) {
    final itemsList =
        (map['items'] as List<dynamic>?)
            ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Cart(
      id: map['id']?.toString() ?? '',
      items: itemsList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Cart copyWith({
    String? id,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() {
    return 'Cart(id: $id, items: ${items.length}, total: $totalAmount)';
  }
}
