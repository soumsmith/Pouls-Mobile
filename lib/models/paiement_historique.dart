/// Modèle représentant un paiement dans l'historique
class PaiementHistorique {
  final int paiementId;
  final String exercice;
  final String dateEnregistrement;
  final String numeroRecu;
  final int montant;
  final String montantLettres;
  final String caissier;
  final String modePaiement;

  PaiementHistorique({
    required this.paiementId,
    required this.exercice,
    required this.dateEnregistrement,
    required this.numeroRecu,
    required this.montant,
    required this.montantLettres,
    required this.caissier,
    required this.modePaiement,
  });

  factory PaiementHistorique.fromJson(Map<String, dynamic> json) {
    return PaiementHistorique(
      paiementId: json['paiement_id'] as int,
      exercice: json['exercice'] as String,
      dateEnregistrement: json['dateenreg'] as String,
      numeroRecu: json['numero_recu'] as String,
      montant: json['montant'] as int,
      montantLettres: json['montant_lettres'] as String,
      caissier: json['caissier'] as String,
      modePaiement: json['mode_paiement'] as String,
    );
  }

  /// Formate la date d'enregistrement pour l'affichage
  String get formattedDate {
    try {
      final date = DateTime.parse(dateEnregistrement);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateEnregistrement;
    }
  }

  /// Formate l'heure d'enregistrement pour l'affichage
  String get formattedTime {
    try {
      final date = DateTime.parse(dateEnregistrement);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  /// Formate le montant pour l'affichage
  String get formattedMontant {
    return '$montant FCFA';
  }

  /// Retourne le libellé complet du mode de paiement
  String get modePaiementLibelle {
    switch (modePaiement) {
      case 'ESP':
        return 'Espèces';
      case 'CB':
        return 'Carte bancaire';
      case 'VIR':
        return 'Virement';
      case 'MOB':
        return 'Mobile money';
      default:
        return modePaiement;
    }
  }
}

/// Réponse de l'API pour l'historique des paiements
class PaiementHistoriqueResponse {
  final bool status;
  final List<PaiementHistorique> data;
  final String message;

  PaiementHistoriqueResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory PaiementHistoriqueResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List?)
        ?.map((item) => PaiementHistorique.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return PaiementHistoriqueResponse(
      status: json['status'] as bool? ?? false,
      data: dataList,
      message: json['message'] as String? ?? '',
    );
  }
}
