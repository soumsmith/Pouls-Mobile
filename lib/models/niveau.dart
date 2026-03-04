class Niveau {
  final String? code;
  final String? nom;
  final String? niveau;
  final String? serie;
  final String? filiere;
  final int? ordre;
  final bool? montantAffecte;

  Niveau({
    this.code,
    this.nom,
    this.niveau,
    this.serie,
    this.filiere,
    this.ordre,
    this.montantAffecte,
  });

  factory Niveau.fromJson(Map<String, dynamic> json) {
    return Niveau(
      code: json['code'] as String?,
      nom: json['nom'] as String?,
      niveau: json['niveau'] as String?,
      serie: json['serie'] as String?,
      filiere: json['filiere'] as String?,
      ordre: json['ordre'] as int?,
      montantAffecte: json['montant_affecte'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'nom': nom,
      'niveau': niveau,
      'serie': serie,
      'filiere': filiere,
      'ordre': ordre,
      'montant_affecte': montantAffecte,
    };
  }

  @override
  String toString() {
    return 'Niveau(code: $code, nom: $nom, filiere: $filiere, ordre: $ordre, montantAffecte: $montantAffecte)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Niveau &&
        other.code == code &&
        other.nom == nom &&
        other.niveau == niveau &&
        other.serie == serie &&
        other.filiere == filiere &&
        other.ordre == ordre &&
        other.montantAffecte == montantAffecte;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        nom.hashCode ^
        niveau.hashCode ^
        serie.hashCode ^
        filiere.hashCode ^
        ordre.hashCode ^
        montantAffecte.hashCode;
  }
}
