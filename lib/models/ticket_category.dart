class TicketCategory {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;

  TicketCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: (json['description'] as String?) ?? '',
      // L'API utilise 'prix' au lieu de 'price'
      price: double.parse(
        (json['prix'] ?? json['price'] ?? '0').toString(),
      ),
      // L'API utilise 'tickets_restants' pour la quantité disponible
      quantity: json['tickets_restants'] as int? ?? json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }
}

class TicketCategoriesResponse {
  final List<TicketCategory> data;
  final String message;
  final bool status;

  TicketCategoriesResponse({
    required this.data,
    required this.message,
    required this.status,
  });

  factory TicketCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final dataList =
        (json['data'] as List?)?.map((item) {
          return TicketCategory.fromJson(item as Map<String, dynamic>);
        }).toList() ??
        [];

    return TicketCategoriesResponse(
      data: dataList,
      message: json['message'] as String? ?? '',
      status: json['status'] as bool? ?? false,
    );
  }
}
