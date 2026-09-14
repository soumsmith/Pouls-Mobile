/// Établissement renvoyé par GET /consultation/etablissements
///
/// `schoolId` est une référence opaque (UUID) — à repasser telle quelle aux
/// autres appels de ConsultationApiService, jamais interprétée ni composée.
class EtablissementConsultation {
  final String schoolId;
  final String code;
  final String nom;
  final bool archive;

  /// Code legacy (`vieEcolesCode`) attendu par les intégrations tierces
  /// (inscription en ligne via api2.vie-ecoles.com, demandes d'intégration...).
  /// N'existe PAS dans la réponse JSON de cette API — résolu et rempli une
  /// seule fois par `ConsultationApiService.getEtablissements()` via
  /// `GET /integrations/vie-ecoles/admin/schools` (même hôte api-pedagogie),
  /// par correspondance exacte sur `schoolId`, puis mis en cache avec le
  /// reste de l'objet. `null` si l'établissement n'a pas d'intégration
  /// vie-ecoles configurée.
  String? paramEcole;

  EtablissementConsultation({
    required this.schoolId,
    required this.code,
    required this.nom,
    required this.archive,
    this.paramEcole,
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
