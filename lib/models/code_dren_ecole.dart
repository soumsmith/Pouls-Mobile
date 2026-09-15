/// École retournée par la recherche par code DREN
/// (`POST /vie-ecoles/recherche/code-dren`). Le champ [code] est le code
/// legacy vie-ecoles (ex: "gainhs") à réutiliser comme `paramEcole` pour
/// tous les appels ultérieurs (recherche élève, inscription, paiement...).
class CodeDrenEcole {
  final String code;
  final String nom;
  final String? ville;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? pays;
  final String? codeDren;

  const CodeDrenEcole({
    required this.code,
    required this.nom,
    this.ville,
    this.adresse,
    this.telephone,
    this.email,
    this.pays,
    this.codeDren,
  });

  factory CodeDrenEcole.fromJson(Map<String, dynamic> json) {
    String? s(String key) {
      final value = json[key];
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    return CodeDrenEcole(
      code: s('code') ?? '',
      nom: s('nom') ?? '',
      ville: s('ville'),
      adresse: s('adresse'),
      telephone: s('telephone'),
      email: s('email'),
      pays: s('pays'),
      codeDren: s('codedren'),
    );
  }
}
