/// Établissement renvoyé par GET /consultation/etablissements
///
/// `schoolId` est une référence opaque (UUID) — à repasser telle quelle aux
/// autres appels de ConsultationApiService, jamais interprétée ni composée.
class EtablissementConsultation {
  final String schoolId;
  final String code;
  final String nom;
  final bool archive;

  /// Numéro d'ordre stable et lisible (ex. "E-000013"), attribué une fois et
  /// jamais repris — ajouté le 15/09/2026 pour désambiguïser deux
  /// établissements qui partagent le même `code` (ex. primaire/secondaire
  /// d'un même groupe scolaire), ce que `code` seul ne permet plus de faire
  /// de façon fiable. Non consommé pour l'instant.
  final String? reference;

  /// Indice VOLONTAIREMENT MASQUÉ (ex. "ce••••"), ajouté le 15/09/2026 —
  /// PAS le code vie-ecoles.com utilisable. Sert uniquement à reconnaître
  /// visuellement une école dans une table de correspondance ; ne jamais
  /// l'utiliser comme `paramEcole` ni le passer à une URL api2.vie-ecoles.com,
  /// ça échouerait silencieusement (ex. 404 "Ecole not found"). Le vrai code
  /// (`paramEcole`, ci-dessous) reste résolu séparément via
  /// `GET /integrations/vie-ecoles/admin/schools`, la seule source valide.
  /// `null` si l'établissement n'a pas de connecteur vie-ecoles configuré.
  final String? indiceVieEcoles;

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
    this.reference,
    this.indiceVieEcoles,
    this.paramEcole,
  });

  factory EtablissementConsultation.fromJson(Map<String, dynamic> json) {
    return EtablissementConsultation(
      schoolId: json['schoolId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      archive: json['archive'] as bool? ?? false,
      reference: json['reference'] as String?,
      indiceVieEcoles: json['indiceVieEcoles'] as String?,
    );
  }
}
