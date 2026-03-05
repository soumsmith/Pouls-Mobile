import 'package:flutter/material.dart';

class Avis {
  final int id;
  final String nom;
  final String? etablissement;
  final int statut;
  final String contenu;
  final String? photo;
  final String createdAt;

  Avis({
    required this.id,
    required this.nom,
    this.etablissement,
    required this.statut,
    required this.contenu,
    this.photo,
    required this.createdAt,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'] as int,
      nom: json['nom'] as String,
      etablissement: json['etablissement'] as String?,
      statut: json['statut'] as int,
      contenu: json['contenu'] as String,
      photo: json['photo'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'etablissement': etablissement,
      'statut': statut,
      'contenu': contenu,
      'photo': photo,
      'created_at': createdAt,
    };
  }

  /// Convertit l'avis en format compatible avec l'UI
  Map<String, dynamic> toUiMap() {
    // Extraire la date de createdAt
    String date = _formatDate(createdAt);
    
    // Déterminer une couleur en fonction du statut
    Color color = _getStatutColor(statut);
    
    // Déterminer une icône en fonction du statut
    IconData icon = _getStatutIcon(statut);
    
    return {
      'id': id.toString(),
      'title': 'Avis de ${nom}',
      'subtitle': etablissement ?? 'Établissement non spécifié',
      'date': date,
      'establishment': etablissement ?? 'Établissement non spécifié',
      'type': _getStatutLabel(statut),
      'color': color,
      'image': photo,
      'icon': icon,
      'content': contenu,
      'auteur': nom,
      'statut': statut,
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

  Color _getStatutColor(int statut) {
    switch (statut) {
      case 1:
        return const Color(0xFFEF4444); // Rouge - très négatif
      case 2:
        return const Color(0xFFF59E0B); // Orange - négatif
      case 3:
        return const Color(0xFF6366F1); // Bleu - neutre
      case 4:
        return const Color(0xFF10B981); // Vert - positif
      case 5:
        return const Color(0xFF8B5CF6); // Violet - très positif
      default:
        return const Color(0xFF6B7280); // Gris - par défaut
    }
  }

  IconData _getStatutIcon(int statut) {
    switch (statut) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.star_rate;
    }
  }

  String _getStatutLabel(int statut) {
    switch (statut) {
      case 1:
        return 'Très négatif';
      case 2:
        return 'Négatif';
      case 3:
        return 'Neutre';
      case 4:
        return 'Positif';
      case 5:
        return 'Très positif';
      default:
        return 'Non défini';
    }
  }
}

class AvisResponse {
  final List<Avis> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;

  AvisResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
    this.firstPageUrl,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory AvisResponse.fromJson(Map<String, dynamic> json) {
    return AvisResponse(
      data: (json['data'] as List)
          .map((item) => Avis.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['last_page'] as int? ?? 0,
      firstPageUrl: json['first_page_url'] as String?,
      lastPageUrl: json['last_page_url'] as String?,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
    );
  }
}
