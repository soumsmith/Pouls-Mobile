/// Modèle représentant une école
class Ecole {
  final String pays;
  final String ville;
  final String adresse;
  final String parametreNom;
  final String logo;
  final String telephone;
  final String parametreCode;
  final String statut;
  final List<String> filiereNom;
  final String? imagefond;

  // Champs pour la compatibilité avec le code existant
  int get ecoleid => _ecoleid ?? parametreCode.hashCode;
  String get ecolecode => _ecolecode ?? parametreCode;
  String get ecoleclibelle => parametreNom;
  
  // Champs privés pour stocker les valeurs réelles de l'API
  final int? _ecoleid;
  final String? _ecolecode;

  Ecole({
    required this.pays,
    required this.ville,
    required this.adresse,
    required this.parametreNom,
    required this.logo,
    required this.telephone,
    required this.parametreCode,
    required this.statut,
    required this.filiereNom,
    this.imagefond,
    int? ecoleid,
    String? ecocode,
  }) : _ecoleid = ecoleid, _ecolecode = ecocode;

  factory Ecole.fromJson(Map<String, dynamic> json) {
    List<String> filieres = [];
    if (json['filiere_nom'] != null) {
      if (json['filiere_nom'] is List) {
        filieres = (json['filiere_nom'] as List)
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return Ecole(
      pays: json['pays'] as String? ?? '',
      ville: json['ville'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      parametreNom: json['ecoleclibelle'] as String? ?? json['parametre_nom'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      parametreCode: json['parametre_code'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      filiereNom: filieres,
      imagefond: json['imagefond'] as String?,
      ecoleid: json['ecoleid'] as int?,
      ecocode: json['ecolecode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pays': pays,
      'ville': ville,
      'adresse': adresse,
      'parametre_nom': parametreNom,
      'logo': logo,
      'telephone': telephone,
      'parametre_code': parametreCode,
      'statut': statut,
      'filiere_nom': filiereNom,
      'imagefond': imagefond,
    };
  }

  /// Retourne l'image de l'école ou une image par défaut
  String get displayImage {
    if (imagefond != null && imagefond!.isNotEmpty) {
      return imagefond!;
    }
    return 'https://picsum.photos/seed/ecole-default/400/300.jpg';
  }

  /// Retourne le type d'école principal basé sur les filières
  String get typePrincipal {
    if (filiereNom.isEmpty) return statut;
    
    for (String filiere in filiereNom) {
      if (filiere.toUpperCase().contains('PRIMAIRE') || 
          filiere.toUpperCase().contains('MATERNELLE')) {
        return 'Primaire';
      }
      if (filiere.toUpperCase().contains('GENERAL') || 
          filiere.toUpperCase().contains('COLLEGE')) {
        return 'Collège';
      }
      if (filiere.toUpperCase().contains('TECHNIQUE') || 
          filiere.toUpperCase().contains('SUPERIEUR')) {
        return 'Lycée';
      }
    }
    
    return statut;
  }
}

