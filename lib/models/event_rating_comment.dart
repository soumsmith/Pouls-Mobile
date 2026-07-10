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
      id: json['id']?.toString() ?? '',
      eventSlug: json['event_slug']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString() ?? '',
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
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
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    try {
      if (json['rating_distribution'] is Map) {
        (json['rating_distribution'] as Map).forEach((key, value) {
          final intKey = int.tryParse(key.toString());
          final intValue = value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0;
          if (intKey != null) {
            distribution[intKey] = intValue;
          }
        });
      }
    } catch (_) {}

    return EventRatingSummary(
      averageRating: (json['average_rating'] is num) ? (json['average_rating'] as num).toDouble() : double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] is int ? json['total_ratings'] : int.tryParse(json['total_ratings']?.toString() ?? '0') ?? 0,
      ratingDistribution: distribution,
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
