/// Bulletin renvoyé par GET .../eleves/{matricule}/bulletin et
/// GET .../eleves/{matricule}/decision-fin-annee
///
/// `periodeRef`/`classeRef` sont des références opaques — jamais interprétées
/// ni composées. `statut` distingue un bulletin DEFINITIF d'un bulletin
/// PROVISOIRE (moyennes calculées à la demande, encore susceptibles de
/// changer) : afficher la mention à l'écran. `decisionFinAnnee` est une
/// chaîne libre à afficher telle quelle, jamais codée en dur ; un champ nul
/// n'est jamais une décision défavorable.
class BulletinConsultation {
  final String matricule;
  final String nom;
  final String prenoms;
  final String anneeLibelle;
  final String periodeRef;
  final String periodeLibelle;
  final String classeRef;
  final String classe;
  final String niveau;
  final double? moyenne;
  final int? rang;
  final int? effectifClasse;
  final String? appreciation;
  final double? moyenneAnnuelle;
  final String? decisionFinAnnee;
  final String statut;
  final List<MatiereBulletin> matieres;

  BulletinConsultation({
    required this.matricule,
    required this.nom,
    required this.prenoms,
    required this.anneeLibelle,
    required this.periodeRef,
    required this.periodeLibelle,
    required this.classeRef,
    required this.classe,
    required this.niveau,
    this.moyenne,
    this.rang,
    this.effectifClasse,
    this.appreciation,
    this.moyenneAnnuelle,
    this.decisionFinAnnee,
    required this.statut,
    required this.matieres,
  });

  bool get estProvisoire => statut == 'PROVISOIRE';

  factory BulletinConsultation.fromJson(Map<String, dynamic> json) {
    return BulletinConsultation(
      matricule: json['matricule'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenoms: json['prenoms'] as String? ?? '',
      anneeLibelle: json['anneeLibelle'] as String? ?? '',
      periodeRef: json['periodeRef'] as String? ?? '',
      periodeLibelle: json['periodeLibelle'] as String? ?? '',
      classeRef: json['classeRef'] as String? ?? '',
      classe: json['classe'] as String? ?? '',
      niveau: json['niveau'] as String? ?? '',
      moyenne: (json['moyenne'] as num?)?.toDouble(),
      rang: json['rang'] as int?,
      effectifClasse: json['effectifClasse'] as int?,
      appreciation: json['appreciation'] as String?,
      moyenneAnnuelle: (json['moyenneAnnuelle'] as num?)?.toDouble(),
      decisionFinAnnee: json['decisionFinAnnee'] as String?,
      statut: json['statut'] as String? ?? '',
      matieres: (json['matieres'] as List?)
              ?.map((e) => MatiereBulletin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MatiereBulletin {
  final String code;
  final String libelle;
  final double? coefficient;
  final double? moyenne;
  final double? moyenneCoefficientee;
  final int? rang;
  final String? appreciation;
  final String? professeur;

  MatiereBulletin({
    required this.code,
    required this.libelle,
    this.coefficient,
    this.moyenne,
    this.moyenneCoefficientee,
    this.rang,
    this.appreciation,
    this.professeur,
  });

  factory MatiereBulletin.fromJson(Map<String, dynamic> json) {
    return MatiereBulletin(
      code: json['code'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
      coefficient: (json['coefficient'] as num?)?.toDouble(),
      moyenne: (json['moyenne'] as num?)?.toDouble(),
      moyenneCoefficientee: (json['moyenneCoefficientee'] as num?)?.toDouble(),
      rang: json['rang'] as int?,
      appreciation: json['appreciation'] as String?,
      professeur: json['professeur'] as String?,
    );
  }
}
