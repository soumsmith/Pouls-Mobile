import 'package:flutter/material.dart';

class Event {
  final String? id;
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
  final String? typebilleterie;
  final String? liendetailblog;
  final String? dateDebut;
  final String? dateFin;
  final String? heureDebut;
  final String? heureFin;
  final String? lieu;

  Event({
    this.id,
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
    this.typebilleterie,
    this.liendetailblog,
    this.dateDebut,
    this.dateFin,
    this.heureDebut,
    this.heureFin,
    this.lieu,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString(),
      slug: json['slug'] as String? ?? 'unknown',
      codeecole: json['codeecole'] as String? ?? 'unknown',
      nomecole: json['nomecole'] as String? ?? 'unknown',
      categories: List<String>.from((json['categories'] as List?) ?? []),
      targets: List<String>.from((json['targets'] as List?) ?? []),
      title: json['title'] as String? ?? 'Sans titre',
      content: json['content'] as String? ?? 'Contenu non disponible',
      statutevent: json['statutevent'] as String? ?? 'en cours',
      publishedAt:
          json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      image: json['image'] as String?,
      typebilleterie: json['typebilleterie'] as String?,
      liendetailblog: json['liendetailblog'] as String?,
      dateDebut: json['datedebut'] as String?,
      dateFin: json['datefin'] as String?,
      heureDebut: json['heuredebut'] as String?,
      heureFin: json['heurefin'] as String?,
      lieu: json['lieu'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'typebilleterie': typebilleterie,
      'liendetailblog': liendetailblog,
      'datedebut': dateDebut,
      'datefin': dateFin,
      'heuredebut': heureDebut,
      'heurefin': heureFin,
      'lieu': lieu,
    };
  }

  /// Convertit l'événement en format compatible avec l'UI existant
  Map<String, dynamic> toUiMap() {
    // Calculer le statut dynamique de l'événement
    String computedStatus = statutevent ?? 'en cours';
    
    try {
      String? targetDateStr;
      if (dateFin != null && dateFin!.isNotEmpty) {
        targetDateStr = dateFin;
      } else if (dateDebut != null && dateDebut!.isNotEmpty) {
        targetDateStr = dateDebut;
      } else {
        targetDateStr = publishedAt;
      }
      
      if (targetDateStr != null && targetDateStr.isNotEmpty) {
        final targetDate = DateTime.parse(targetDateStr);
        final now = DateTime.now();
      
      // On considère que l'événement se termine à la fin de la journée (23:59:59)
      final eventEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
      
      if (now.isAfter(eventEnd)) {
        computedStatus = 'terminé';
      } else {
        computedStatus = 'en cours';
      }
      }
    } catch (e) {
      // Fallback
    }

    // Déterminer si l'événement est disponible
    bool isAvailable = computedStatus != 'terminé';

    // Extraire la date
    String date = _formatDate(dateDebut ?? publishedAt);
    if (dateDebut != null && dateFin != null && dateDebut != dateFin) {
      date = '${_formatDate(dateDebut!)} - ${_formatDate(dateFin!)}';
    }

    // Extraire l'heure
    String time = 'Toute la journée';
    if (heureDebut != null && heureDebut!.isNotEmpty) {
      String startTime = heureDebut!.length >= 5 ? heureDebut!.substring(0, 5) : heureDebut!;
      if (heureFin != null && heureFin!.isNotEmpty) {
        String endTime = heureFin!.length >= 5 ? heureFin!.substring(0, 5) : heureFin!;
        time = '$startTime - $endTime';
      } else {
        time = 'À partir de $startTime';
      }
    }

    // Déterminer une couleur en fonction de la catégorie
    Color color = _getCategoryColor(
      categories.isNotEmpty ? categories.first : 'Education',
    );

    // Déterminer une icône en fonction de la catégorie
    IconData icon = _getCategoryIcon(
      categories.isNotEmpty ? categories.first : 'Education',
    );

    return {
      'id': id ?? slug,
      'slug': slug,
      'codeecole': codeecole,
      'nomecole': nomecole,
      'categories': categories,
      'targets': targets,
      'title': title,
      'subtitle': nomecole,
      'date': date,
      'time': time,
      'establishment': nomecole,
      'type': categories.isNotEmpty ? categories.first : 'Education',
      'price': 'Gratuit', // L'API ne fournit pas de prix
      'available': isAvailable,
      'color': color,
      'image': image,
      'icon': icon,
      'content': content,
      'statutevent': computedStatus,
      'published_at': publishedAt,
      'typebilleterie': typebilleterie,
      'liendetailblog': liendetailblog,
    };
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
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
      currentPage: _parseInt(json['current_page']),
      perPage: _parseInt(json['per_page']),
      total: _parseInt(json['total']),
      totalPages: _parseInt(json['total_pages']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
