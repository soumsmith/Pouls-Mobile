/// Modèle représentant un créneau d'emploi du temps pour un élève
class StudentTimetableEntry {
  final String id;
  final int jourNumber;
  final String jour;
  final String heureDebut;
  final String heureFin;
  final String matiere;
  final String? professeur;
  final String? salle;
  final String? typeCours;
  final String? edtId;
  final String? uid;
  final String? entite;
  final String? observations;

  StudentTimetableEntry({
    required this.id,
    required this.jourNumber,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.matiere,
    this.professeur,
    this.salle,
    this.typeCours,
    this.edtId,
    this.uid,
    this.entite,
    this.observations,
  });

  factory StudentTimetableEntry.fromJson(Map<String, dynamic> json) {
    return StudentTimetableEntry(
      id: json['edt_id']?.toString() ?? '',
      jourNumber: json['jour'] as int? ?? 1,
      jour: _getDayName(json['jour'] as int? ?? 1),
      heureDebut: json['hdebut']?.toString() ?? '',
      heureFin: json['hfin']?.toString() ?? '',
      matiere: json['valeur']?.toString() ?? '',
      professeur: json['professeur']?.toString(),
      salle: json['salle']?.toString(),
      typeCours: json['type_cours']?.toString(),
      edtId: json['edt_id']?.toString(),
      uid: json['uid']?.toString(),
      entite: json['entite']?.toString(),
      observations: json['observations']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'edt_id': edtId,
      'uid': uid,
      'type': 1,
      'horaire_id': 1,
      'jour': jourNumber,
      'hdebut': heureDebut,
      'hfin': heureFin,
      'entite': entite,
      'valeur': matiere,
      'observations': observations,
    };
  }

  /// Retourne l'heure formatée pour l'affichage
  String get formattedTime => '$heureDebut - $heureFin';

  /// Retourne le numéro du jour (déjà disponible directement)
  int get jourNumberValue => jourNumber;

  /// Retourne le jour formaté avec première lettre majuscule
  String get formattedJour {
    if (jour.isEmpty) return '';
    return jour[0].toUpperCase() + jour.substring(1).toLowerCase();
  }

  /// Convertit le numéro du jour en nom de jour
  static String _getDayName(int jourNumber) {
    switch (jourNumber) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Lundi';
    }
  }
}

/// Modèle pour la réponse complète de l'API emploi du temps
class StudentTimetableResponse {
  final bool status;
  final List<StudentTimetableEntry> data;
  final String message;

  StudentTimetableResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory StudentTimetableResponse.fromJson(Map<String, dynamic> json) {
    List<StudentTimetableEntry> timetableEntries = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        timetableEntries = (json['data'] as List)
            .map((entry) => StudentTimetableEntry.fromJson(entry))
            .toList();
      }
    }

    return StudentTimetableResponse(
      status: json['status'] as bool? ?? false,
      data: timetableEntries,
      message: json['message'] as String? ?? '',
    );
  }

  /// Groupe les cours par jour
  Map<String, List<StudentTimetableEntry>> get coursesByDay {
    final Map<String, List<StudentTimetableEntry>> grouped = {};
    
    for (final entry in data) {
      if (!grouped.containsKey(entry.jour)) {
        grouped[entry.jour] = [];
      }
      grouped[entry.jour]!.add(entry);
    }
    
    // Trier les cours de chaque jour par heure de début
    for (final dayEntries in grouped.values) {
      dayEntries.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
    }
    
    return grouped;
  }
}
