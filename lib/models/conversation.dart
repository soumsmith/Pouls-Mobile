class Conversation {
  final int id;
  final int parentId;
  final int schoolId;
  final String studentId;
  final String subject;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final List<Participant> participants;
  final SchoolInfo school;
  final StudentInfo student;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.parentId,
    required this.schoolId,
    required this.studentId,
    required this.subject,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
    required this.participants,
    required this.school,
    required this.student,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      parentId: json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
      schoolId: json['school_id'] is int ? json['school_id'] : int.tryParse(json['school_id']?.toString() ?? '0') ?? 0,
      studentId: json['student_id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(json['last_message_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] is int ? json['unread_count'] : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      school: SchoolInfo.fromJson(json['school'] as Map<String, dynamic>? ?? {}),
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>? ?? {}),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Retourne le dernier message de la conversation
  Message? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  /// Vérifie si la conversation contient des messages non lus
  bool get hasUnreadMessages => unreadCount > 0;
}

class Participant {
  final int id;
  final int conversationId;
  final String participantType;
  final int participantId;
  final int schoolId;
  final String? staffPseudo;
  final DateTime? lastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Participant({
    required this.id,
    required this.conversationId,
    required this.participantType,
    required this.participantId,
    required this.schoolId,
    this.staffPseudo,
    this.lastReadAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      conversationId: json['conversation_id'] is int ? json['conversation_id'] : int.tryParse(json['conversation_id']?.toString() ?? '0') ?? 0,
      participantType: json['participant_type']?.toString() ?? '',
      participantId: json['participant_id'] is int ? json['participant_id'] : int.tryParse(json['participant_id']?.toString() ?? '0') ?? 0,
      schoolId: json['school_id'] is int ? json['school_id'] : int.tryParse(json['school_id']?.toString() ?? '0') ?? 0,
      staffPseudo: json['staff_pseudo']?.toString(),
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SchoolInfo {
  final int clientId;
  final String nom;
  final String code;

  SchoolInfo({required this.clientId, required this.nom, required this.code});

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      clientId: json['client_id'] is int ? json['client_id'] : int.tryParse(json['client_id']?.toString() ?? '0') ?? 0,
      nom: json['nom']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class StudentInfo {
  final String uid;
  final String nom;
  final String prenoms;
  final String classe;
  final String? photo;

  StudentInfo({
    required this.uid,
    required this.nom,
    required this.prenoms,
    required this.classe,
    this.photo,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      uid: json['uid']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenoms: json['prenoms']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      photo: json['photo']?.toString(),
    );
  }

  /// Retourne le nom complet de l'élève
  String get fullName => '$prenoms $nom';
}

class Message {
  final int id;
  final int conversationId;
  final String senderType;
  final int? senderId;
  final int schoolId;
  final String senderPseudo;
  final String body;
  final String messageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    required this.schoolId,
    required this.senderPseudo,
    required this.body,
    required this.messageType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      conversationId: json['conversation_id'] is int ? json['conversation_id'] : int.tryParse(json['conversation_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? '',
      senderId: json['sender_id'] is int ? json['sender_id'] : int.tryParse(json['sender_id']?.toString() ?? ''),
      schoolId: json['school_id'] is int ? json['school_id'] : int.tryParse(json['school_id']?.toString() ?? '0') ?? 0,
      senderPseudo: json['sender_pseudo']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }
}
