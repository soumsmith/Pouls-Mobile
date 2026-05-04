class GestionPresenceEleveEntry {
  final String? debut;
  final String? fin;
  final String? matiere;
  final int? profpresent;
  final int? status;
  final String? appelDate;
  final String? nomProf;
  final String? prenomProf;
  final String? nomEleve;
  final String? prenomEleve;
  final String? classe;
  final String? niveau;
  final String? nomClasse;
  final String? matricule;

  const GestionPresenceEleveEntry({
    this.debut,
    this.fin,
    this.matiere,
    this.profpresent,
    this.status,
    this.appelDate,
    this.nomProf,
    this.prenomProf,
    this.nomEleve,
    this.prenomEleve,
    this.classe,
    this.niveau,
    this.nomClasse,
    this.matricule,
  });

  factory GestionPresenceEleveEntry.fromJson(Map<String, dynamic> json) {
    return GestionPresenceEleveEntry(
      debut: json['debut'] as String?,
      fin: json['fin'] as String?,
      matiere: json['matiere'] as String?,
      profpresent: (json['profpresent'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      appelDate: json['appel_date'] as String?,
      nomProf: json['nomProf'] as String?,
      prenomProf: json['prenomProf'] as String?,
      nomEleve: json['nomEleve'] as String?,
      prenomEleve: json['prenomEleve'] as String?,
      classe: json['classe'] as String?,
      niveau: json['niveau'] as String?,
      nomClasse: json['nom_classe'] as String?,
      matricule: json['matricule'] as String?,
    );
  }
}
