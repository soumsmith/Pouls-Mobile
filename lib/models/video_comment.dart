class VideoComment {
  final String id;
  final String videoId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;
  final String? parentCommentId; // Pour les réponses
  final List<VideoComment>? replies;

  VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    this.parentCommentId,
    this.replies,
  });

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      parentCommentId: json['parentCommentId'],
      replies: json['replies'] != null 
          ? (json['replies'] as List).map((e) => VideoComment.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'isLiked': isLiked,
      'parentCommentId': parentCommentId,
      'replies': replies?.map((e) => e.toJson()).toList(),
    };
  }

  VideoComment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    bool? isLiked,
    String? parentCommentId,
    List<VideoComment>? replies,
  }) {
    return VideoComment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}
