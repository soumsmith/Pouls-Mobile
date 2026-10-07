/// Devoir surveillé (composition) renvoyé par
/// GET .../eleves/{matricule}/devoirs-surveilles — à ne pas confondre avec
/// /devoirs, qui rend les devoirs de *maison* : ici, les compositions (doc
/// §3). Un DS en brouillon n'apparaît jamais (une date qui peut encore
/// changer n'est pas une convocation) ; un DS annulé n'apparaît plus non
/// plus depuis le correctif serveur du 05/10/2026 (doc recette, §3). Un DS
/// rattaché à plusieurs classes de l'élève apparaît une fois par classe, pas
/// seulement pour la classe principale. `salle`/`place` restent `null` tant
/// que la répartition n'est pas faite — jamais devinées côté application, à
/// afficher comme « pas encore connu(e) » plutôt qu'une valeur par défaut.
/// Réservé aux années P: — les années H: (archive) répondent 400
/// (compositions non archivées).
class DevoirSurveilleConsultation {
  static const statutProgramme = 'PROGRAMME';
  static const statutTermine = 'TERMINE';
  static const statutReporte = 'REPORTE';
  static const statutAnnule = 'ANNULE';

  final String examId;
  final String label;
  final String examType;
  final String matiereCode;
  final String matiere;
  final String classeRef;
  final String classe;
  final String date;
  final String? debut;
  final String? fin;
  final int? dureeMinutes;
  final String? statut;
  final String? salle;
  final int? place;

  DevoirSurveilleConsultation({
    required this.examId,
    required this.label,
    required this.examType,
    required this.matiereCode,
    required this.matiere,
    required this.classeRef,
    required this.classe,
    required this.date,
    this.debut,
    this.fin,
    this.dureeMinutes,
    this.statut,
    this.salle,
    this.place,
  });

  /// "10:00 - 11:00" à partir de `debut`/`fin` (secondes tronquées) — `null`
  /// si l'heure de début n'est pas connue.
  String? get horaireLabel {
    if (debut == null || debut!.isEmpty) return null;
    final debutCourt = debut!.length >= 5 ? debut!.substring(0, 5) : debut!;
    if (fin == null || fin!.isEmpty) return debutCourt;
    final finCourt = fin!.length >= 5 ? fin!.substring(0, 5) : fin!;
    return '$debutCourt - $finCourt';
  }

  factory DevoirSurveilleConsultation.fromJson(Map<String, dynamic> json) {
    return DevoirSurveilleConsultation(
      examId: json['examId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      examType: json['examType'] as String? ?? '',
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      classeRef: json['classId'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      date: json['date'] as String? ?? '',
      debut: json['debut'] as String?,
      fin: json['fin'] as String?,
      dureeMinutes: json['dureeMinutes'] as int?,
      statut: json['statut'] as String?,
      salle: json['salle'] as String?,
      place: json['place'] as int?,
    );
  }
}
