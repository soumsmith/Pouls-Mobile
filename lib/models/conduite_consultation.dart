/// Incident de conduite rattaché à une période (ex. absence injustifiée,
/// retard) — fait partie de l'historique mais ne débouche pas forcément sur
/// une sanction.
class ConduiteIncident {
  final String? date;
  final String? type;
  final String? libelle;
  final double? points;
  final String? gravite;
  final String? description;

  ConduiteIncident({
    this.date,
    this.type,
    this.libelle,
    this.points,
    this.gravite,
    this.description,
  });

  factory ConduiteIncident.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return ConduiteIncident(
      date: json['date'] as String?,
      type: json['type'] as String?,
      libelle: json['libelle'] as String?,
      points: toDouble(json['points']),
      gravite: json['gravite'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Sanction effectivement appliquée sur la période (contrairement à
/// [ConduiteIncident], qui ne fait que consigner un fait).
class ConduiteSanction {
  final String? date;
  final String? type;
  final String? libelle;
  final String? description;

  ConduiteSanction({this.date, this.type, this.libelle, this.description});

  factory ConduiteSanction.fromJson(Map<String, dynamic> json) {
    return ConduiteSanction(
      date: json['date'] as String?,
      type: json['type'] as String?,
      libelle: json['libelle'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Élément renvoyé par GET .../eleves/{matricule}/conduite — un objet par
/// trimestre, dans l'ordre de l'année.
class ConduitePeriode {
  static const statutDefinitive = 'DEFINITIVE';
  static const statutProvisoire = 'PROVISOIRE';

  final String periodeRef;
  final String periode;
  final String? statut;
  final double? noteDeBase;
  final double? note;
  final String? appreciation;
  final String? appreciationDuConseil;
  final bool sanction;
  final List<ConduiteIncident> incidents;
  final List<ConduiteSanction> sanctions;

  bool get estDefinitive => statut == statutDefinitive;

  ConduitePeriode({
    required this.periodeRef,
    required this.periode,
    this.statut,
    this.noteDeBase,
    this.note,
    this.appreciation,
    this.appreciationDuConseil,
    this.sanction = false,
    this.incidents = const [],
    this.sanctions = const [],
  });

  factory ConduitePeriode.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return ConduitePeriode(
      periodeRef: json['periodeRef'] as String? ?? '',
      periode: json['periode'] as String? ?? '',
      statut: json['statut'] as String?,
      noteDeBase: toDouble(json['noteDeBase']),
      note: toDouble(json['note']),
      appreciation: json['appreciation'] as String?,
      appreciationDuConseil: json['appreciationDuConseil'] as String?,
      sanction: json['sanction'] as bool? ?? false,
      incidents: (json['incidents'] as List<dynamic>? ?? [])
          .map((e) => ConduiteIncident.fromJson(e as Map<String, dynamic>))
          .toList(),
      sanctions: (json['sanctions'] as List<dynamic>? ?? [])
          .map((e) => ConduiteSanction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
