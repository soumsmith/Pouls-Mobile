class VideoRating {
  final String id;
  final String videoId;
  final String userId;
  final String userName;
  final int rating; // 1-5 étoiles
  final String? comment;
  final DateTime timestamp;

  VideoRating({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory VideoRating.fromJson(Map<String, dynamic> json) {
    return VideoRating(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  VideoRating copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? userName,
    int? rating,
    String? comment,
    DateTime? timestamp,
  }) {
    return VideoRating(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class VideoRatingStats {
  final String videoId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // {1: count, 2: count, 3: count, 4: count, 5: count}

  VideoRatingStats({
    required this.videoId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory VideoRatingStats.fromJson(Map<String, dynamic> json) {
    return VideoRatingStats(
      videoId: json['videoId'] ?? '',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
    };
  }
}
