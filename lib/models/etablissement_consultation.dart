/// Établissement renvoyé par GET /consultation/etablissements
///
/// `schoolId` est une référence opaque (UUID) — à repasser telle quelle aux
/// autres appels de ConsultationApiService, jamais interprétée ni composée.
class EtablissementConsultation {
  final String schoolId;
  final String code;
  final String nom;
  final bool archive;

  EtablissementConsultation({
    required this.schoolId,
    required this.code,
    required this.nom,
    required this.archive,
  });

  factory EtablissementConsultation.fromJson(Map<String, dynamic> json) {
    return EtablissementConsultation(
      schoolId: json['schoolId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      archive: json['archive'] as bool? ?? false,
    );
  }
}
