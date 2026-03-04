import 'package:flutter/material.dart';

class Blog {
  final String slug;
  final String codeecole;
  final String nomecole;
  final List<String> categories;
  final String title;
  final String content;
  final String publishedAt;
  final String? image;
  final String? auteur;

  Blog({
    required this.slug,
    required this.codeecole,
    required this.nomecole,
    required this.categories,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.image,
    this.auteur,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      slug: json['slug'] as String,
      codeecole: json['codeecole'] as String,
      nomecole: json['nomecole'] as String,
      categories: List<String>.from(json['categories'] as List? ?? []),
      title: json['title'] as String,
      content: json['content'] as String,
      publishedAt: json['published_at'] as String,
      image: json['image'] as String?,
      auteur: json['auteur'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'codeecole': codeecole,
      'nomecole': nomecole,
      'categories': categories,
      'title': title,
      'content': content,
      'published_at': publishedAt,
      'image': image,
      'auteur': auteur,
    };
  }

  /// Convertit le blog en format compatible avec l'UI
  Map<String, dynamic> toUiMap() {
    // Extraire la date de publishedAt
    String date = _formatDate(publishedAt);
    
    // Déterminer une couleur en fonction de la catégorie
    Color color = _getCategoryColor(categories.isNotEmpty ? categories.first : 'Actualité');
    
    // Déterminer une icône en fonction de la catégorie
    IconData icon = _getCategoryIcon(categories.isNotEmpty ? categories.first : 'Actualité');
    
    return {
      'id': slug,
      'title': title,
      'subtitle': nomecole,
      'date': date,
      'establishment': nomecole,
      'type': categories.isNotEmpty ? categories.first : 'Actualité',
      'color': color,
      'image': image,
      'icon': icon,
      'content': content,
      'auteur': auteur ?? 'Administration',
      'categories': categories,
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
      return dateString.split(' ')[0]; // Fallback: retourner juste la date
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'actualité':
        return const Color(0xFF3B82F6);
      case 'communication':
        return const Color(0xFF8B5CF6);
      case 'événement':
        return const Color(0xFF10B981);
      case 'information':
        return const Color(0xFFF59E0B);
      case 'annonce':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'actualité':
        return Icons.article;
      case 'communication':
        return Icons.campaign;
      case 'événement':
        return Icons.event;
      case 'information':
        return Icons.info;
      case 'annonce':
        return Icons.announcement;
      default:
        return Icons.article;
    }
  }
}

class BlogsResponse {
  final List<Blog> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;

  BlogsResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory BlogsResponse.fromJson(Map<String, dynamic> json) {
    return BlogsResponse(
      data: (json['data'] as List)
          .map((item) => Blog.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
