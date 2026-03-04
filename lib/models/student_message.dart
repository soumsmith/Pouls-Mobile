/// Modèle représentant un message spécifique à un élève
class StudentMessage {
  final int id;
  final String titre;
  final String description;
  final String dateEnvoi;
  final int statutReception;

  StudentMessage({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateEnvoi,
    required this.statutReception,
  });

  factory StudentMessage.fromJson(Map<String, dynamic> json) {
    return StudentMessage(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateEnvoi: json['date_envoi'] as String? ?? '',
      statutReception: json['statut_reception'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'date_envoi': dateEnvoi,
      'statut_reception': statutReception,
    };
  }

  /// Retourne la date formatée pour l'affichage
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(dateEnvoi);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateEnvoi;
    }
  }

  /// Retourne le statut formaté
  String get formattedStatut {
    switch (statutReception) {
      case 0:
        return 'Non lu';
      case 1:
        return 'Lu';
      default:
        return 'Inconnu';
    }
  }

  /// Retourne true si le message est non lu
  bool get isUnread => statutReception == 0;
}
