class EcheanceNotification {
  final String data;
  final bool status;
  final String message;

  EcheanceNotification({
    required this.data,
    required this.status,
    required this.message,
  });

  factory EcheanceNotification.fromJson(Map<String, dynamic> json) {
    return EcheanceNotification(
      data: json['data'] ?? '',
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }

  bool get hasUnpaidFees => status && message.toLowerCase().contains('irregulier');
  
  String get formattedMessage {
    if (data.isEmpty) return 'Aucune information d\'échéance disponible';
    return data;
  }
}
