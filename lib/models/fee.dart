/// Modèle représentant des frais de scolarité
class Fee {
  final String id;
  final String childId;
  final String type; // Type de frais (Inscription, Réinscription, Scolarité, etc.)
  final double amount; // Montant
  final DateTime dueDate; // Date d'échéance
  final DateTime? paidDate; // Date de paiement
  final bool isPaid; // Statut de paiement
  final String? paymentMethod; // Méthode de paiement
  final String? reference; // Référence de paiement

  Fee({
    required this.id,
    required this.childId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.isPaid,
    this.paymentMethod,
    this.reference,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      paidDate: json['paidDate'] != null 
          ? DateTime.tryParse(json['paidDate'].toString()) 
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      paymentMethod: json['paymentMethod']?.toString(),
      reference: json['reference']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'reference': reference,
    };
  }
}

