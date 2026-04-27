class EventRatingComment {
  final String id;
  final String eventSlug;
  final String userId;
  final String userName;
  final String userAvatar;
  final int rating; // 1-5 étoiles
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventRatingComment({
    required this.id,
    required this.eventSlug,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventRatingComment.fromJson(Map<String, dynamic> json) {
    return EventRatingComment(
      id: json['id'] as String,
      eventSlug: json['event_slug'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String? ?? '',
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_slug': eventSlug,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer un nouveau commentaire (pour l'envoi à l'API)
  Map<String, dynamic> toCreateJson() {
    return {
      'event_slug': eventSlug,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
    };
  }

  // Getters pour l'affichage
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  List<String> get ratingStars {
    return List.generate(5, (index) {
      return index < rating ? 'filled' : 'empty';
    });
  }
}

class EventRatingSummary {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // nombre de notes par étoile (1-5)

  EventRatingSummary({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory EventRatingSummary.fromJson(Map<String, dynamic> json) {
    return EventRatingSummary(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalRatings: json['total_ratings'] as int,
      ratingDistribution: Map<int, int>.from(
        (json['rating_distribution'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value as int),
        ),
      ),
    );
  }

  List<String> get averageRatingStars {
    final fullStars = averageRating.floor();
    final hasHalfStar = (averageRating - fullStars) >= 0.5;
    
    return List.generate(5, (index) {
      if (index < fullStars) return 'filled';
      if (index == fullStars && hasHalfStar) return 'half';
      return 'empty';
    });
  }

  String get formattedRating {
    return averageRating.toStringAsFixed(1);
  }
}
