/// Un chapitre du programme, renvoyé dans `chapitres` (uniquement présent
/// quand `classe` est passé à la requête — voir [ProgressionConsultation]).
class ChapitreProgression {
  final int ordre;
  final String libelle;
  final String statut; // FAIT, EN_COURS, A_VENIR
  final String? date;

  ChapitreProgression({
    required this.ordre,
    required this.libelle,
    required this.statut,
    this.date,
  });

  factory ChapitreProgression.fromJson(Map<String, dynamic> json) {
    return ChapitreProgression(
      ordre: json['ordre'] as int? ?? 0,
      libelle: json['libelle'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      date: json['date'] as String?,
    );
  }
}

/// Ligne classe-matière renvoyée par
/// GET /consultation/etablissements/{schoolId}/annees/{annee}/progressions
///
/// Une matière absente de la liste n'est pas « à 0 % » : aucune progression
/// ne lui a été affectée, elle n'a rien à dire — ne jamais l'afficher comme
/// un retard. `chapitres` reste nul tant que la requête ne précise pas une
/// classe donnée (doc §4.10).
class ProgressionConsultation {
  final String classeRef;
  final String classe;
  final String? niveau;
  final String matiereCode;
  final String matiere;
  final int chapitresPrevus;
  final int chapitresFaits;
  final double taux;
  final int seancesFaites;
  final String? chapitreEnCours;
  final List<ChapitreProgression>? chapitres;

  ProgressionConsultation({
    required this.classeRef,
    required this.classe,
    this.niveau,
    required this.matiereCode,
    required this.matiere,
    required this.chapitresPrevus,
    required this.chapitresFaits,
    required this.taux,
    required this.seancesFaites,
    this.chapitreEnCours,
    this.chapitres,
  });

  factory ProgressionConsultation.fromJson(Map<String, dynamic> json) {
    return ProgressionConsultation(
      classeRef: json['classeRef'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      niveau: json['niveau'] as String?,
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      chapitresPrevus: json['chapitresPrevus'] as int? ?? 0,
      chapitresFaits: json['chapitresFaits'] as int? ?? 0,
      taux: (json['taux'] as num?)?.toDouble() ?? 0.0,
      seancesFaites: json['seancesFaites'] as int? ?? 0,
      chapitreEnCours: json['chapitreEnCours'] as String?,
      chapitres: (json['chapitres'] as List?)
          ?.map((e) => ChapitreProgression.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
