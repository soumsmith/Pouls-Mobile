/// Modèle représentant un message de groupe (notification)
class GroupMessage {
  final String id;
  final String titre;
  final String contenu;
  final String? expediteur;
  final String? typeExpediteur;
  final DateTime dateEnvoi;
  final bool estLu;
  final String? matricule;
  final String? idEcole;
  final String? idClasse;

  GroupMessage({
    required this.id,
    required this.titre,
    required this.contenu,
    this.expediteur,
    this.typeExpediteur,
    required this.dateEnvoi,
    this.estLu = false,
    this.matricule,
    this.idEcole,
    this.idClasse,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // Parser la date - gérer différents formats possibles
    DateTime dateEnvoi;
    if (json['date_envoi'] != null) {
      try {
        dateEnvoi = DateTime.parse(json['date_envoi']);
      } catch (e) {
        // Si le format est invalide, utiliser la date actuelle
        dateEnvoi = DateTime.now();
      }
    } else {
      dateEnvoi = DateTime.now();
    }

    return GroupMessage(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? json['title'] ?? 'Notification',
      contenu: json['contenu'] ?? json['content'] ?? json['body'] ?? '',
      expediteur: json['expediteur'] ?? json['sender'],
      typeExpediteur: json['type_expediteur'] ?? json['sender_type'],
      dateEnvoi: dateEnvoi,
      estLu: json['est_lu'] == 1 || json['is_read'] == true || json['statut'] == 1,
      matricule: json['matricule']?.toString(),
      idEcole: json['id_ecole']?.toString(),
      idClasse: json['id_classe']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'expediteur': expediteur,
      'type_expediteur': typeExpediteur,
      'date_envoi': dateEnvoi.toIso8601String(),
      'est_lu': estLu ? 1 : 0,
      'matricule': matricule,
      'id_ecole': idEcole,
      'id_classe': idClasse,
    };
  }

  GroupMessage copyWith({
    String? id,
    String? titre,
    String? contenu,
    String? expediteur,
    String? typeExpediteur,
    DateTime? dateEnvoi,
    bool? estLu,
    String? matricule,
    String? idEcole,
    String? idClasse,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      expediteur: expediteur ?? this.expediteur,
      typeExpediteur: typeExpediteur ?? this.typeExpediteur,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estLu: estLu ?? this.estLu,
      matricule: matricule ?? this.matricule,
      idEcole: idEcole ?? this.idEcole,
      idClasse: idClasse ?? this.idClasse,
    );
  }

  /// Formate la date d'envoi pour l'affichage
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateEnvoi);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateEnvoi.day}/${dateEnvoi.month}/${dateEnvoi.year}';
    }
  }

  /// Retourne le nom d'affichage de l'expéditeur
  String get expediteurDisplay {
    if (expediteur != null && expediteur!.isNotEmpty) {
      return expediteur!;
    }
    
    switch (typeExpediteur?.toLowerCase()) {
      case 'admin':
      case 'administration':
        return 'Administration';
      case 'prof':
      case 'professeur':
      case 'teacher':
        return 'Professeur';
      case 'direction':
        return 'Direction';
      case 'secretariat':
        return 'Secrétariat';
      default:
        return 'Établissement';
    }
  }
}
