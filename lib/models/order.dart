import 'cart_item.dart';

enum OrderStatus {
  pending('En attente'),
  confirmed('Confirmée'),
  processing('En traitement'),
  shipped('Expédiée'),
  delivered('Livrée'),
  cancelled('Annulée'),
  refunded('Remboursée');

  const OrderStatus(this.displayName);
  final String displayName;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        return OrderStatus.pending;
      case 'confirmée':
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'en traitement':
      case 'processing':
        return OrderStatus.processing;
      case 'expédiée':
      case 'shipped':
        return OrderStatus.shipped;
      case 'livrée':
      case 'delivered':
        return OrderStatus.delivered;
      case 'annulée':
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'remboursée':
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

enum PaymentMethod {
  card('Carte bancaire'),
  mobile('Mobile Money'),
  transfer('Virement bancaire'),
  cash('Espèces');

  const PaymentMethod(this.displayName);
  final String displayName;

  static PaymentMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'carte bancaire':
      case 'card':
        return PaymentMethod.card;
      case 'mobile money':
      case 'mobile':
        return PaymentMethod.mobile;
      case 'virement bancaire':
      case 'transfer':
        return PaymentMethod.transfer;
      case 'espèces':
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.card;
    }
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final String? shippingAddress;
  final String? billingAddress;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
    this.shippingAddress,
    this.billingAddress,
    this.notes,
    this.metadata,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
        ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return Order(
      id: map['id']?.toString() ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(map['status']?.toString() ?? ''),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod']?.toString() ?? ''),
      paymentReference: map['paymentReference']?.toString(),
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      confirmedAt: map['confirmedAt'] != null 
          ? DateTime.tryParse(map['confirmedAt'].toString())
          : null,
      deliveredAt: map['deliveredAt'] != null 
          ? DateTime.tryParse(map['deliveredAt'].toString())
          : null,
      shippingAddress: map['shippingAddress']?.toString(),
      billingAddress: map['billingAddress']?.toString(),
      notes: map['notes']?.toString(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory Order.fromApiMap(Map<String, dynamic> map) {
    // Extract products from API response
    final productsData = map['produit'] as List<dynamic>? ?? [];
    final itemsList = productsData.map((productData) {
      final product = productData as Map<String, dynamic>;
      return CartItem.fromApiMap(product);
    }).toList();

    // Parse status from API
    final statusStr = map['statut']?.toString() ?? 'en_attente';
    OrderStatus status;
    switch (statusStr.toLowerCase()) {
      case 'en_attente':
        status = OrderStatus.pending;
        break;
      case 'confirmée':
      case 'confirmed':
        status = OrderStatus.confirmed;
        break;
      case 'en_traitement':
      case 'processing':
        status = OrderStatus.processing;
        break;
      case 'expédiée':
      case 'shipped':
        status = OrderStatus.shipped;
        break;
      case 'livrée':
      case 'delivered':
        status = OrderStatus.delivered;
        break;
      case 'annulée':
      case 'cancelled':
        status = OrderStatus.cancelled;
        break;
      case 'remboursée':
      case 'refunded':
        status = OrderStatus.refunded;
        break;
      default:
        status = OrderStatus.pending;
    }

    // Parse payment method from API
    final paymentMethodStr = map['type_livraison']?.toString() ?? 'domicile';
    PaymentMethod paymentMethod;
    switch (paymentMethodStr.toLowerCase()) {
      case 'domicile':
        paymentMethod = PaymentMethod.cash;
        break;
      case 'mobile':
        paymentMethod = PaymentMethod.mobile;
        break;
      case 'carte':
        paymentMethod = PaymentMethod.card;
        break;
      case 'virement':
        paymentMethod = PaymentMethod.transfer;
        break;
      default:
        paymentMethod = PaymentMethod.cash;
    }

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (map['created_at'] != null) {
      createdAt = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    }

    return Order(
      id: map['uid_commande']?.toString() ?? map['id']?.toString() ?? '',
      items: itemsList,
      totalAmount: (map['total_prix'] as num?)?.toDouble() ?? 0.0,
      status: status,
      paymentMethod: paymentMethod,
      paymentReference: map['payment_reference']?.toString(),
      createdAt: createdAt,
      confirmedAt: null, // API doesn't provide this
      deliveredAt: map['date_livraison'] != null 
          ? DateTime.tryParse(map['date_livraison'].toString())
          : null,
      shippingAddress: map['adresse_livraison']?.toString(),
      billingAddress: null, // API doesn't provide this
      notes: map['notes']?.toString(),
      metadata: {
        'ecole': map['ecole']?.toString(),
        'eleve_uid': map['eleve_uid']?.toString(),
        'frais_livraison': map['frais_livraison'],
        'type_livraison': map['type_livraison']?.toString(),
        'source': map['source']?.toString(),
        'parent_uid': map['parent_uid']?.toString(),
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.displayName,
      'paymentMethod': paymentMethod.displayName,
      'paymentReference': paymentReference,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,
      'notes': notes,
      'metadata': metadata,
    };
  }

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? deliveredAt,
    String? shippingAddress,
    String? billingAddress,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPending => status == OrderStatus.pending;
  bool get isProcessing => status == OrderStatus.processing;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, status: ${status.displayName}, total: $totalAmount)';
  }
}
