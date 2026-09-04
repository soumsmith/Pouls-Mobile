/// Année scolaire renvoyée par GET /consultation/etablissements/{schoolId}/annees
///
/// `ref` est une référence opaque (`P:<uuid>` ou `H:<entier>`) — jamais interprétée
/// ni composée, uniquement reprise telle quelle depuis cette liste.
class AnneeConsultation {
  final String ref;
  final String libelle;
  final int debut;
  final int fin;
  final String statut;
  final bool courante;
  final String origine;

  AnneeConsultation({
    required this.ref,
    required this.libelle,
    required this.debut,
    required this.fin,
    required this.statut,
    required this.courante,
    required this.origine,
  });

  factory AnneeConsultation.fromJson(Map<String, dynamic> json) {
    return AnneeConsultation(
      ref: json['ref'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
      debut: json['debut'] as int? ?? 0,
      fin: json['fin'] as int? ?? 0,
      statut: json['statut'] as String? ?? '',
      courante: json['courante'] as bool? ?? false,
      origine: json['origine'] as String? ?? '',
    );
  }
}
