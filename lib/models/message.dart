/// Modèle représentant un message
class Message {
  final String id;
  final String parentId;
  final String subject; // Sujet
  final String content; // Contenu
  final DateTime date;
  final String sender; // Expéditeur (établissement, professeur, etc.)
  final bool isRead;
  final MessageType type;

  Message({
    required this.id,
    required this.parentId,
    required this.subject,
    required this.content,
    required this.date,
    required this.sender,
    this.isRead = false,
    this.type = MessageType.general,
  });

  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      sender: json['sender']?.toString() ?? '',
      isRead: json['isRead'] as bool? ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.general,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'subject': subject,
      'content': content,
      'date': date.toIso8601String(),
      'sender': sender,
      'isRead': isRead,
      'type': type.toString(),
    };
  }
}

enum MessageType {
  general,
  absence,
  grade,
  fee,
  announcement,
}

