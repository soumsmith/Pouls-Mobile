/// Devoir renvoyé par GET /consultation/etablissements/{schoolId}/eleves/{matricule}/devoirs
///
/// Source = le cahier de textes : une classe sans cahier tenu ne rend rien
/// (ce n'est pas « aucun devoir », c'est « rien d'enregistré »).
/// `prochaineSeance` est la séance suivante de la matière — la remise
/// usuelle, pas une échéance garantie : à présenter comme « pour la séance
/// du … », jamais « à rendre le … ».
class DevoirConsultation {
  final String matiereCode;
  final String matiere;
  final String classeRef;
  final String classe;
  final String donneLe;
  final String seance;
  final String professeur;
  final String consigne;
  final String? prochaineSeance;

  DevoirConsultation({
    required this.matiereCode,
    required this.matiere,
    required this.classeRef,
    required this.classe,
    required this.donneLe,
    required this.seance,
    required this.professeur,
    required this.consigne,
    this.prochaineSeance,
  });

  factory DevoirConsultation.fromJson(Map<String, dynamic> json) {
    return DevoirConsultation(
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      classeRef: json['classeRef'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      donneLe: json['donneLe'] as String? ?? '',
      seance: json['seance'] as String? ?? '',
      professeur: json['professeur'] as String? ?? '',
      consigne: json['consigne'] as String? ?? '',
      prochaineSeance: json['prochaineSeance'] as String?,
    );
  }
}
