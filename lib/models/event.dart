import 'package:flutter/material.dart';

class Event {
  final String slug;
  final String codeecole;
  final String nomecole;
  final List<String> categories;
  final List<String> targets;
  final String title;
  final String content;
  final String statutevent;
  final String publishedAt;
  final String? image;

  Event({
    required this.slug,
    required this.codeecole,
    required this.nomecole,
    this.categories = const [],
    this.targets = const [],
    required this.title,
    required this.content,
    this.statutevent = 'en cours',
    required this.publishedAt,
    this.image,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      slug: json['slug'] as String,
      codeecole: json['codeecole'] as String,
      nomecole: json['nomecole'] as String,
      categories: List<String>.from((json['categories'] as List?) ?? []),
      targets: List<String>.from((json['targets'] as List?) ?? []),
      title: json['title'] as String,
      content: json['content'] as String,
      statutevent: json['statutevent'] as String? ?? 'en cours',
      publishedAt: json['published_at'] as String,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'codeecole': codeecole,
      'nomecole': nomecole,
      'categories': categories,
      'targets': targets,
      'title': title,
      'content': content,
      'statutevent': statutevent,
      'published_at': publishedAt,
      'image': image,
    };
  }

  /// Convertit l'événement en format compatible avec l'UI existant
  Map<String, dynamic> toUiMap() {
    // Déterminer si l'événement est disponible
    bool isAvailable = statutevent != 'terminé';
    
    // Extraire la date de publishedAt
    String date = _formatDate(publishedAt);
    
    // Déterminer une couleur en fonction de la catégorie
    Color color = _getCategoryColor(categories.isNotEmpty ? categories.first : 'Education');
    
    // Déterminer une icône en fonction de la catégorie
    IconData icon = _getCategoryIcon(categories.isNotEmpty ? categories.first : 'Education');
    
    return {
      'id': slug,
      'title': title,
      'subtitle': nomecole,
      'date': date,
      'time': 'Toute la journée', // L'API ne fournit pas d'heure
      'establishment': nomecole,
      'type': categories.isNotEmpty ? categories.first : 'Education',
      'price': 'Gratuit', // L'API ne fournit pas de prix
      'available': isAvailable,
      'color': color,
      'image': image,
      'icon': icon,
      'content': content,
      'statutevent': statutevent,
      'targets': targets,
    };
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]}';
    } catch (e) {
      return dateString.split(' ')[0]; // Fallback: retourner juste la date
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF3B82F6);
      case 'culturel':
        return const Color(0xFF8B5CF6);
      case 'sportif':
        return const Color(0xFF10B981);
      case 'mardi gras scolaire':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return Icons.school;
      case 'culturel':
        return Icons.music_note;
      case 'sportif':
        return Icons.sports_soccer;
      case 'mardi gras scolaire':
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }
}

class EventsResponse {
  final List<Event> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;

  EventsResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      data: (json['data'] as List)
          .map((item) => Event.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
