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
      if (value == null) return '0€';
      if (value is num) return '${value.toString()}€';
      return value.toString();
    }

    return UserTicket(
      id: json['id']?.toString() ?? json['ticket_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? json['title']?.toString() ?? json['nom_evenement']?.toString() ?? json['libelle']?.toString() ?? 'Ticket',
      establishment: json['establishment']?.toString() ?? json['ecole']?.toString() ?? json['school']?.toString() ?? json['parcelle']?.toString() ?? '',
      date: json['date']?.toString() ?? json['event_date']?.toString() ?? json['jour']?.toString() ?? '',
      time: json['time']?.toString() ?? json['heure']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? json['quantite']?.toString() ?? '0') ?? 0,
      unitPrice: formatCurrency(json['unit_price'] ?? json['prix_unitaire'] ?? json['price']),
      totalPrice: formatCurrency(json['total'] ?? json['prix_total'] ?? json['total_price']),
      status: json['status']?.toString() ?? json['etat']?.toString() ?? '',
      purchaseDate: json['purchase_date']?.toString() ?? json['date_achat']?.toString() ?? '',
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
