class Interaction {
  final int id;
  final int videoId;
  final int userId;
  final String type; // comment, share, rating
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;

  Interaction({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.type,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    // Extraire les informations utilisateur depuis l'objet user imbriqué
    String? userName;
    if (json['user'] != null) {
      final user = json['user'] as Map<String, dynamic>;
      final nom = user['nom'] as String?;
      final prenoms = user['prenoms'] as String?;
      userName = '$prenoms $nom'.trim();
    } else {
      userName = json['user_name'];
    }

    return Interaction(
      id: json['id'] ?? 0,
      videoId: json['video_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? '',
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      userName: userName,
      userAvatar: json['user_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_id': videoId,
      'user_id': userId,
      'type': type,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_name': userName,
      'user_avatar': userAvatar,
    };
  }

  Interaction copyWith({
    int? id,
    int? videoId,
    int? userId,
    String? type,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
  }) {
    return Interaction(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }
}
