/// Modèle représentant une note
class Note {
  final String id;
  final String childId;
  final String subject; // Matière
  final double grade; // Note
  final double coefficient;
  final DateTime date;
  final String assignmentNumber; // N°Dev
  final double? average; // Moyenne de la matière
  final int? rank; // Rang
  final int? totalStudents; // Effectif
  final String? mention; // Mention (Très Bien, Bien, Assez Bien, etc.)
  final double? noteSur; // Note sur (depuis evaluation.noteSur)

  Note({
    required this.id,
    required this.childId,
    required this.subject,
    required this.grade,
    required this.coefficient,
    required this.date,
    required this.assignmentNumber,
    this.average,
    this.rank,
    this.totalStudents,
    this.mention,
    this.noteSur,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      grade: (json['grade'] is num) ? (json['grade'] as num).toDouble() : double.tryParse(json['grade']?.toString() ?? '0') ?? 0,
      coefficient: (json['coefficient'] is num) ? (json['coefficient'] as num).toDouble() : double.tryParse(json['coefficient']?.toString() ?? '0') ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      assignmentNumber: json['assignmentNumber']?.toString() ?? '',
      average: json['average'] != null ? ((json['average'] is num) ? (json['average'] as num).toDouble() : double.tryParse(json['average'].toString())) : null,
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? ''),
      totalStudents: json['totalStudents'] is int ? json['totalStudents'] : int.tryParse(json['totalStudents']?.toString() ?? ''),
      mention: json['mention']?.toString(),
      noteSur: json['noteSur'] != null ? ((json['noteSur'] is num) ? (json['noteSur'] as num).toDouble() : double.tryParse(json['noteSur'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'subject': subject,
      'grade': grade,
      'coefficient': coefficient,
      'date': date.toIso8601String(),
      'assignmentNumber': assignmentNumber,
      'average': average,
      'rank': rank,
      'totalStudents': totalStudents,
      'mention': mention,
      'noteSur': noteSur,
    };
  }
}

/// Modèle pour les moyennes par matière
class SubjectAverage {
  final String subject;
  final List<Note> notes;
  final double average;
  final double coefficient;
  final double weightedAverage;
  final int? rank;
  final int? totalStudents;
  final bool viewed;

  SubjectAverage({
    required this.subject,
    required this.notes,
    required this.average,
    required this.coefficient,
    required this.weightedAverage,
    this.rank,
    this.totalStudents,
    this.viewed = false,
  });
}

/// Modèle pour les moyennes globales
class GlobalAverage {
  final double trimesterAverage;
  final int trimesterRank;
  final String trimesterMention;
  final double annualAverage;
  final int annualRank;
  final String annualMention;

  GlobalAverage({
    required this.trimesterAverage,
    required this.trimesterRank,
    required this.trimesterMention,
    required this.annualAverage,
    required this.annualRank,
    required this.annualMention,
  });
}

