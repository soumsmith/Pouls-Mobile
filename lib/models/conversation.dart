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
      id: json['id'] as int,
      parentId: json['parent_id'] as int,
      schoolId: json['school_id'] as int,
      studentId: json['student_id'] as String,
      subject: json['subject'] as String,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      unreadCount: json['unread_count'] as int,
      participants: (json['participants'] as List<dynamic>)
          .map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList(),
      school: SchoolInfo.fromJson(json['school'] as Map<String, dynamic>),
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Retourne le dernier message de la conversation
  Message? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.reduce((a, b) => 
      a.createdAt.isAfter(b.createdAt) ? a : b
    );
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
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      participantType: json['participant_type'] as String,
      participantId: json['participant_id'] as int,
      schoolId: json['school_id'] as int,
      staffPseudo: json['staff_pseudo'] as String?,
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class SchoolInfo {
  final int clientId;
  final String nom;
  final String code;

  SchoolInfo({
    required this.clientId,
    required this.nom,
    required this.code,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      clientId: json['client_id'] as int,
      nom: json['nom'] as String,
      code: json['code'] as String,
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
      uid: json['uid'] as String,
      nom: json['nom'] as String,
      prenoms: json['prenoms'] as String,
      classe: json['classe'] as String,
      photo: json['photo'] as String?,
    );
  }

  /// Retourne le nom complet de l'élève
  String get fullName => '$prenoms $nom';
}

class Message {
  final int id;
  final int conversationId;
  final String senderType;
  final int senderId;
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
    required this.senderId,
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
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as int,
      schoolId: json['school_id'] as int,
      senderPseudo: json['sender_pseudo'] as String,
      body: json['body'] as String,
      messageType: json['message_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }
}
