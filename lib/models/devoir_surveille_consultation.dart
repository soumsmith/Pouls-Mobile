/// Devoir surveillé (composition) renvoyé par
/// GET .../eleves/{matricule}/devoirs-surveilles — à ne pas confondre avec
/// /devoirs, qui rend les devoirs de *maison* : ici, les compositions (doc
/// §3). Un DS en brouillon n'apparaît jamais (une date qui peut encore
/// changer n'est pas une convocation). Un DS rattaché à plusieurs classes de
/// l'élève apparaît une fois par classe, pas seulement pour la classe
/// principale. `salle`/`place` restent `null` tant que la répartition n'est
/// pas faite — jamais devinées côté application, à afficher comme « pas
/// encore connu(e) » plutôt qu'une valeur par défaut. Réservé aux années
/// P: — les années H: (archive) répondent 400 (compositions non archivées).
class DevoirSurveilleConsultation {
  final String matiereCode;
  final String matiere;
  final String classeRef;
  final String classe;
  final String date;
  final String? horaire;
  final String? duree;
  final String? salle;
  final String? place;

  DevoirSurveilleConsultation({
    required this.matiereCode,
    required this.matiere,
    required this.classeRef,
    required this.classe,
    required this.date,
    this.horaire,
    this.duree,
    this.salle,
    this.place,
  });

  factory DevoirSurveilleConsultation.fromJson(Map<String, dynamic> json) {
    return DevoirSurveilleConsultation(
      matiereCode: json['matiereCode'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      classeRef: json['classeRef'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      date: json['date'] as String? ?? '',
      horaire: json['horaire']?.toString(),
      duree: json['duree']?.toString(),
      salle: json['salle'] as String?,
      place: json['place']?.toString(),
    );
  }
}
