/// Modèle représentant une échéance de scolarité pour un élève
class StudentScolariteEntry {
  final int epaId;
  final String uid;
  final String eleve;
  final String rubrique;
  final int montant0;
  final int remise;
  final int montant;
  final String libelle;
  final String echeance;
  final String dateLimite;
  final int paye;
  final int rapayer;
  final int status;
  final String dateenreg;
  final int type;
  final int mode;
  final String idsession;
  final String nom;

  StudentScolariteEntry({
    required this.epaId,
    required this.uid,
    required this.eleve,
    required this.rubrique,
    required this.montant0,
    required this.remise,
    required this.montant,
    required this.libelle,
    required this.echeance,
    required this.dateLimite,
    required this.paye,
    required this.rapayer,
    required this.status,
    required this.dateenreg,
    required this.type,
    required this.mode,
    required this.idsession,
    required this.nom,
  });

  factory StudentScolariteEntry.fromJson(Map<String, dynamic> json) {
    return StudentScolariteEntry(
      epaId: json['epa_id'] as int? ?? 0,
      uid: json['uid'] as String? ?? '',
      eleve: json['eleve'] as String? ?? '',
      rubrique: json['rubrique'] as String? ?? '',
      montant0: json['montant0'] as int? ?? 0,
      remise: json['remise'] as int? ?? 0,
      montant: json['montant'] as int? ?? 0,
      libelle: json['libelle'] as String? ?? '',
      echeance: json['echeance'] as String? ?? '',
      dateLimite: json['datelimite'] as String? ?? '',
      paye: json['paye'] as int? ?? 0,
      rapayer: json['rapayer'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      dateenreg: json['dateenreg'] as String? ?? '',
      type: json['type'] as int? ?? 0,
      mode: json['mode'] as int? ?? 0,
      idsession: json['idsession'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'epa_id': epaId,
      'uid': uid,
      'eleve': eleve,
      'rubrique': rubrique,
      'montant0': montant0,
      'remise': remise,
      'montant': montant,
      'libelle': libelle,
      'echeance': echeance,
      'datelimite': dateLimite,
      'paye': paye,
      'rapayer': rapayer,
      'status': status,
      'dateenreg': dateenreg,
      'type': type,
      'mode': mode,
      'idsession': idsession,
      'nom': nom,
    };
  }

  /// Retourne la date limite formatée pour l'affichage
  String get formattedDateLimite {
    try {
      final dateTime = DateTime.parse(dateLimite);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateLimite;
    }
  }

  /// Retourne la date d'enregistrement formatée
  String get formattedDateenreg {
    try {
      final dateTime = DateTime.parse(dateenreg);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateenreg;
    }
  }

  /// Retourne le montant formaté en FCFA
  String get formattedMontant => '${montant.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      )} FCFA';

  /// Retourne le montant payé formaté en FCFA
  String get formattedPaye => '${paye.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      )} FCFA';

  /// Retourne le montant restant à payer formaté en FCFA
  String get formattedRapayer => '${rapayer.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      )} FCFA';

  /// Retourne la rubrique formatée
  String get formattedRubrique {
    switch (rubrique) {
      case 'ANX':
        return 'Frais Annexes';
      case 'INS':
        return 'Inscription';
      case 'SCO':
        return 'Scolarité';
      default:
        return rubrique;
    }
  }

  /// Retourne true si l'échéance est entièrement payée
  bool get isFullyPaid => rapayer == 0;

  /// Retourne true si l'échéance est partiellement payée
  bool get isPartiallyPaid => paye > 0 && rapayer > 0;

  /// Retourne true si l'échéance n'est pas du tout payée
  bool get isUnpaid => paye == 0;

  /// Retourne le pourcentage de paiement
  double get paymentPercentage {
    if (montant == 0) return 0.0;
    return (paye / montant) * 100;
  }

  /// Retourne le statut de paiement formaté
  String get formattedStatus {
    if (isFullyPaid) return 'Payé';
    if (isPartiallyPaid) return 'Partiellement payé';
    return 'Non payé';
  }

  /// Retourne la couleur du statut
  String get statusColor {
    if (isFullyPaid) return 'green';
    if (isPartiallyPaid) return 'orange';
    return 'red';
  }

  /// Retourne true si la date limite est dépassée
  bool get isOverdue {
    try {
      final deadline = DateTime.parse(dateLimite);
      final now = DateTime.now();
      return now.isAfter(deadline) && !isFullyPaid;
    } catch (e) {
      return false;
    }
  }

  /// Retourne le nombre de jours restants avant la date limite
  int get daysUntilDeadline {
    try {
      final deadline = DateTime.parse(dateLimite);
      final now = DateTime.now();
      return deadline.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Retourne le libellé du type de frais
  String get typeLabel {
    switch (type) {
      case 1:
        return 'Frais scolaire';
      default:
        return 'Autre';
    }
  }
}

/// Modèle pour la réponse complète de l'API scolarité
class StudentScolariteResponse {
  final bool status;
  final List<StudentScolariteEntry> data;
  final String message;

  StudentScolariteResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory StudentScolariteResponse.fromJson(Map<String, dynamic> json) {
    List<StudentScolariteEntry> entries = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        entries = (json['data'] as List)
            .map((entry) => StudentScolariteEntry.fromJson(entry))
            .toList();
      }
    }

    return StudentScolariteResponse(
      status: json['status'] as bool? ?? false,
      data: entries,
      message: json['message'] as String? ?? '',
    );
  }

  /// Calcule le montant total de la scolarité
  int get totalMontant {
    return data.fold(0, (sum, entry) => sum + entry.montant);
  }

  /// Calcule le montant total payé
  int get totalPaye {
    return data.fold(0, (sum, entry) => sum + entry.paye);
  }

  /// Calcule le montant total restant à payer
  int get totalRapayer {
    return data.fold(0, (sum, entry) => sum + entry.rapayer);
  }

  /// Retourne le pourcentage global de paiement
  double get globalPaymentPercentage {
    if (totalMontant == 0) return 0.0;
    return (totalPaye / totalMontant) * 100;
  }

  /// Groupe les échéances par rubrique
  Map<String, List<StudentScolariteEntry>> get entriesByRubrique {
    final Map<String, List<StudentScolariteEntry>> grouped = {};
    
    for (final entry in data) {
      final rubrique = entry.formattedRubrique;
      if (!grouped.containsKey(rubrique)) {
        grouped[rubrique] = [];
      }
      grouped[rubrique]!.add(entry);
    }
    
    // Trier les échéances de chaque rubrique par date limite
    for (final rubriqueEntries in grouped.values) {
      rubriqueEntries.sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
    }
    
    return grouped;
  }

  /// Retourne les échéances en retard
  List<StudentScolariteEntry> get overdueEntries {
    return data.where((entry) => entry.isOverdue).toList();
  }

  /// Retourne les échéances payées
  List<StudentScolariteEntry> get paidEntries {
    return data.where((entry) => entry.isFullyPaid).toList();
  }

  /// Retourne les échéances non payées
  List<StudentScolariteEntry> get unpaidEntries {
    return data.where((entry) => entry.isUnpaid).toList();
  }

  /// Retourne les échéances partiellement payées
  List<StudentScolariteEntry> get partiallyPaidEntries {
    return data.where((entry) => entry.isPartiallyPaid).toList();
  }
}
