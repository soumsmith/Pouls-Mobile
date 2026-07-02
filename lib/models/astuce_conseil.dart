import 'package:flutter/material.dart';

class AstuceConseil {
  final int id;
  final String uid;
  final String title;
  final String slug;
  final String content;
  final String codeecole;
  final String status;
  final String publishedAt;
  final String typedecontenu;
  final String? youtubeUrl;
  final String? image;
  final int commentsCount;
  final int likesCount;
  final int sharesCount;
  final String createdAt;

  AstuceConseil({
    required this.id,
    required this.uid,
    required this.title,
    required this.slug,
    required this.content,
    required this.codeecole,
    required this.status,
    required this.publishedAt,
    required this.typedecontenu,
    this.youtubeUrl,
    this.image,
    required this.commentsCount,
    required this.likesCount,
    required this.sharesCount,
    required this.createdAt,
  });

  factory AstuceConseil.fromJson(Map<String, dynamic> json) {
    return AstuceConseil(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uid: json['uid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      codeecole: json['codeecole']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      typedecontenu: json['typedecontenu']?.toString() ?? '',
      youtubeUrl: json['video_youtube']?.toString() ?? json['youtube_url']?.toString(),
      image: json['image']?.toString(),
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is int ? json['likes_count'] : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      sharesCount: json['shares_count'] is int ? json['shares_count'] : int.tryParse(json['shares_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'slug': slug,
      'content': content,
      'codeecole': codeecole,
      'status': status,
      'published_at': publishedAt,
      'typedecontenu': typedecontenu,
      'youtube_url': youtubeUrl,
      'image': image,
      'comments_count': commentsCount,
      'likes_count': likesCount,
      'shares_count': sharesCount,
      'created_at': createdAt,
    };
  }

  String get youtubeVideoId {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return '';
    final url = Uri.parse(youtubeUrl!);
    if (url.host.contains('youtube.com')) {
      if (url.pathSegments.contains('embed')) {
        final embedIndex = url.pathSegments.indexOf('embed');
        if (embedIndex + 1 < url.pathSegments.length) {
          return url.pathSegments[embedIndex + 1];
        }
      }
      if (url.pathSegments.contains('shorts')) {
        final shortsIndex = url.pathSegments.indexOf('shorts');
        if (shortsIndex + 1 < url.pathSegments.length) {
          return url.pathSegments[shortsIndex + 1];
        }
      }
      return url.queryParameters['v'] ?? '';
    } else if (url.host.contains('youtu.be')) {
      return url.pathSegments.isNotEmpty ? url.pathSegments.last : '';
    }
    return '';
  }

  /// Convertit l'astuce en format compatible avec l'UI générique (similaire à Blog)
  Map<String, dynamic> toUiMap() {
    String date = _formatDate(publishedAt);
    Color color = Colors.orange; // Default color for Tips
    IconData icon = Icons.lightbulb_outline; // Default icon for Tips
    
    return {
      'id': id.toString(),
      'originalId': id,
      'title': title,
      'subtitle': 'Astuces & Conseils',
      'date': date,
      'establishment': codeecole,
      'type': 'Conseil',
      'color': color,
      'image': youtubeVideoId.isNotEmpty 
          ? 'https://img.youtube.com/vi/$youtubeVideoId/mqdefault.jpg' 
          : image,
      'icon': icon,
      'content': content,
      'auteur': 'Administration', // Pas d'auteur dans l'API par défaut
      'youtubeUrl': youtubeUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
    };
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return dateString.split(' ')[0]; // Fallback
    }
  }
}
