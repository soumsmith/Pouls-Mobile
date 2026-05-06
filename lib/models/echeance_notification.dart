class EcheanceNotification {
  final String data;
  final bool status;
  final String message;
  final int? conversationId;
  final bool estLu;

  EcheanceNotification({
    required this.data,
    required this.status,
    required this.message,
    this.conversationId,
    this.estLu = false,
  });

  factory EcheanceNotification.fromJson(Map<String, dynamic> json) {
    return EcheanceNotification(
      data: json['data'] ?? '',
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      conversationId: json['conversation_id'] != null ? int.tryParse(json['conversation_id'].toString()) : null,
      estLu: json['est_lu'] == true || json['is_read'] == true,
    );
  }

  bool get hasUnpaidFees => status && message.toLowerCase().contains('irregulier');
  
  String get formattedMessage {
    if (data.isEmpty) return 'Aucune information d\'échéance disponible';
    return data;
  }
}
