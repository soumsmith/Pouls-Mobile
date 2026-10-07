/// Élément renvoyé par GET .../eleves/{matricule}/difficultes (doc recette
/// 05/10/2026, §1) — une ligne par matière où l'élève décroche, verdict
/// calculé sur les notes de la période (jamais sur les moyennes du
/// bulletin, qui ne naissent qu'en fin de trimestre).
class DifficulteConsultation {
  static const niveauCritique = 'CRITIQUE';
  static const niveauFragile = 'FRAGILE';
  static const niveauEnBaisse = 'EN_BAISSE';

  final String matiereCode;
  final String matiere;
  final double? moyenne;
  final int? notes;
  final double? moyenneDebut;
  final double? moyenneFin;
  final double? evolution;
  final String? tendance;
  final double? moyenneClasse;
  final double? ecartALaClasse;
  final double? moyenneArretee;
  final int? rang;
  final int? classes;
  final String? niveau;
  final String motif;

  bool get estCritique => niveau == niveauCritique;
  bool get estFragile => niveau == niveauFragile;
  bool get estEnBaisse => niveau == niveauEnBaisse;

  DifficulteConsultation({
    required this.matiereCode,
    required this.matiere,
    this.moyenne,
    this.notes,
    this.moyenneDebut,
    this.moyenneFin,
    this.evolution,
    this.tendance,
    this.moyenneClasse,
    this.ecartALaClasse,
    this.moyenneArretee,
    this.rang,
    this.classes,
    this.niveau,
    required this.motif,
  });

  factory DifficulteConsultation.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return DifficulteConsultation(
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      moyenne: toDouble(json['moyenne']),
      notes: json['notes'] as int?,
      moyenneDebut: toDouble(json['moyenneDebut']),
      moyenneFin: toDouble(json['moyenneFin']),
      evolution: toDouble(json['evolution']),
      tendance: json['tendance'] as String?,
      moyenneClasse: toDouble(json['moyenneClasse']),
      ecartALaClasse: toDouble(json['ecartALaClasse']),
      moyenneArretee: toDouble(json['moyenneArretee']),
      rang: json['rang'] as int?,
      classes: json['classes'] as int?,
      niveau: json['niveau'] as String?,
      motif: json['motif'] as String? ?? '',
    );
  }
}
