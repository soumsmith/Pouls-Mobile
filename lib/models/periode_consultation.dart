/// Période renvoyée par GET /consultation/etablissements/{schoolId}/annees/{annee}/periodes
///
/// `ref` est une référence opaque — jamais interprétée ni composée.
class PeriodeConsultation {
  final String ref;
  final String libelle;

  PeriodeConsultation({required this.ref, required this.libelle});

  factory PeriodeConsultation.fromJson(Map<String, dynamic> json) {
    return PeriodeConsultation(
      ref: json['ref'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
    );
  }
}
