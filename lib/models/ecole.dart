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
  final String? paramecole;
  final String? codedren;
  final double? longitude;
  final double? latitude;

  // Champs pour la compatibilité avec le code existant
  int get ecoleid => _ecoleid ?? parametreCode.hashCode;
  String get ecolecode => _ecolecode ?? parametreCode;
  String get ecoleclibelle => parametreNom;
  
  // Getters pour la compatibilité avec le code existant
  String get id => _ecoleid?.toString() ?? parametreCode;
  String get type => typePrincipal ?? 'Primaire';
  
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
    this.paramecole,
    this.codedren,
    this.longitude,
    this.latitude,
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
      paramecole: json['paramecole'] as String?,
      codedren: json['codedren'] as String?,
      longitude: json['longitude'] as double?,
      latitude: json['latitude'] as double?,
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
      'paramecole': paramecole,
      'codedren': codedren,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  /// Retourne l'image de l'école ou une image par défaut
  String get displayImage {
    if (imagefond != null && imagefond!.isNotEmpty) {
      return imagefond!;
    }
    return 'assets/images/img-shcool-not-found.jpg';
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

