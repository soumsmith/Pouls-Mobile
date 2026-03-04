/// Modèle représentant un pointage de contrôle d'accès
class AccessControlEntry {
  final int pointageId;
  final String dateenreg;
  final String date;
  final String categorie;
  final int status;
  final String resultat;
  final int resultat0;
  final String observations;

  AccessControlEntry({
    required this.pointageId,
    required this.dateenreg,
    required this.date,
    required this.categorie,
    required this.status,
    required this.resultat,
    required this.resultat0,
    required this.observations,
  });

  factory AccessControlEntry.fromJson(Map<String, dynamic> json) {
    return AccessControlEntry(
      pointageId: json['pointage_id'] as int? ?? 0,
      dateenreg: json['dateenreg'] as String? ?? '',
      date: json['date'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      resultat: json['resultat'] as String? ?? '',
      resultat0: json['resultat0'] as int? ?? 0,
      observations: json['observations'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointage_id': pointageId,
      'dateenreg': dateenreg,
      'date': date,
      'categorie': categorie,
      'status': status,
      'resultat': resultat,
      'resultat0': resultat0,
      'observations': observations,
    };
  }

  /// Retourne la date formatée pour l'affichage
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  /// Retourne l'heure formatée pour l'affichage
  String get formattedTime {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  /// Retourne la date et heure complètes formatées
  String get formattedDateTime {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  /// Retourne la catégorie formatée
  String get formattedCategorie {
    switch (categorie) {
      case '1':
        return 'Entrée';
      case '2':
        return 'Sortie';
      default:
        return 'Inconnu';
    }
  }

  /// Retourne true si le pointage est une entrée
  bool get isEntree => categorie == '1';

  /// Retourne true si le pointage est une sortie
  bool get isSortie => categorie == '2';

  /// Retourne la couleur du statut
  bool get isStatusOk => resultat.toLowerCase() == 'ok';

  /// Retourne l'icône appropriée pour la catégorie
  String get categoryIcon {
    if (isEntree) return '🟢';
    if (isSortie) return '🔴';
    return '⚪';
  }
}

/// Modèle pour la réponse complète de l'API contrôle d'accès
class AccessControlResponse {
  final bool status;
  final List<AccessControlEntry> data;
  final String message;

  AccessControlResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory AccessControlResponse.fromJson(Map<String, dynamic> json) {
    List<AccessControlEntry> entries = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        entries = (json['data'] as List)
            .map((entry) => AccessControlEntry.fromJson(entry))
            .toList();
      }
    }

    return AccessControlResponse(
      status: json['status'] as bool? ?? false,
      data: entries,
      message: json['message'] as String? ?? '',
    );
  }

  /// Groupe les pointages par jour
  Map<String, List<AccessControlEntry>> get entriesByDay {
    final Map<String, List<AccessControlEntry>> grouped = {};
    
    for (final entry in data) {
      final day = entry.formattedDate;
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(entry);
    }
    
    // Trier les pointages de chaque jour par date/heure
    for (final dayEntries in grouped.values) {
      dayEntries.sort((a, b) => a.date.compareTo(b.date));
    }
    
    return grouped;
  }

  /// Retourne les pointages du jour
  List<AccessControlEntry> get todayEntries {
    final today = DateTime.now();
    final todayFormatted = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    
    return data.where((entry) => entry.formattedDate == todayFormatted).toList();
  }

  /// Retourne le dernier pointage
  AccessControlEntry? get lastEntry {
    if (data.isEmpty) return null;
    
    return data.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b);
  }
}
