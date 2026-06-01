class UserTicket {
  final String id;
  final String eventName;
  final String establishment;
  final String date;
  final String time;
  final int quantity;
  final String unitPrice;
  final String totalPrice;
  final String status;
  final String purchaseDate;
  final Map<String, dynamic> rawData;

  UserTicket({
    required this.id,
    required this.eventName,
    required this.establishment,
    required this.date,
    required this.time,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    required this.purchaseDate,
    required this.rawData,
  });

  factory UserTicket.fromJson(Map<String, dynamic> json) {
    String formatCurrency(dynamic value) {
      if (value == null) return '0 €';
      final String valStr = value.toString().trim();
      if (valStr.isEmpty) return '0 €';
      
      // Clean non-numeric characters except decimal points
      final cleaned = valStr.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        if (parsed >= 100) {
          return '${parsed.toStringAsFixed(0)} FCFA';
        }
        return '${parsed.toStringAsFixed(0)} €';
      }
      return valStr;
    }

    // Default quantity to 1 if not specified but ticket exists
    final rawQty = json['quantity']?.toString() ?? json['quantite']?.toString();
    final int qty = rawQty != null ? (int.tryParse(rawQty) ?? 1) : 1;

    return UserTicket(
      id: json['uid']?.toString() ?? json['id']?.toString() ?? json['ticket_id']?.toString() ?? '',
      eventName: json['nom_evenement']?.toString() ?? json['event_name']?.toString() ?? json['title']?.toString() ?? json['libelle']?.toString() ?? 'Ticket Événement',
      establishment: json['ecole']?.toString() ?? json['parcelle']?.toString() ?? json['establishment']?.toString() ?? json['school']?.toString() ?? '',
      date: json['jour']?.toString() ?? json['date']?.toString() ?? json['event_date']?.toString() ?? '',
      time: json['heure']?.toString() ?? json['time']?.toString() ?? '',
      quantity: qty,
      unitPrice: formatCurrency(json['prix_unitaire'] ?? json['unit_price'] ?? json['prix'] ?? json['price']),
      totalPrice: formatCurrency(json['total'] ?? json['prix_total'] ?? json['total_price'] ?? json['prix']),
      status: json['statut']?.toString() ?? json['status']?.toString() ?? json['etat']?.toString() ?? '',
      purchaseDate: json['created_at']?.toString() ?? json['purchase_date']?.toString() ?? json['date_achat']?.toString() ?? '',
      rawData: json,
    );
  }
}

class UserTicketStats {
  final int nombreCommandes;
  final int nonUtilise;
  final int utilise;
  final int annule;

  UserTicketStats({
    required this.nombreCommandes,
    required this.nonUtilise,
    required this.utilise,
    required this.annule,
  });

  factory UserTicketStats.fromJson(Map<String, dynamic> json) {
    return UserTicketStats(
      nombreCommandes: json['nombre_commandes'] ?? 0,
      nonUtilise: json['non_utilise'] ?? 0,
      utilise: json['utilise'] ?? 0,
      annule: json['annule'] ?? 0,
    );
  }
}

class UserTicketsResponse {
  final UserTicketStats stats;
  final List<UserTicket> tickets;

  UserTicketsResponse({required this.stats, required this.tickets});

  factory UserTicketsResponse.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final ticketsJson = json['tickets'] as Map<String, dynamic>? ?? {};
    final data = ticketsJson['data'] as List<dynamic>? ?? [];
    final tickets = data
        .map((item) => UserTicket.fromJson(item as Map<String, dynamic>))
        .toList();

    return UserTicketsResponse(
      stats: UserTicketStats.fromJson(statsJson),
      tickets: tickets,
    );
  }
}
