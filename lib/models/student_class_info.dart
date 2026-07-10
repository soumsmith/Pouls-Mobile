/// Modèle pour stocker les informations de la classe et de l'école d'un élève
class StudentClassInfo {
  final ClasseInfo classe;
  final EcoleInfo ecole;
  final int effectifClasse;
  final EleveInfo eleve;
  final String identifiantVieEcole;

  StudentClassInfo({
    required this.classe,
    required this.ecole,
    required this.effectifClasse,
    required this.eleve,
    required this.identifiantVieEcole,
  });

  factory StudentClassInfo.fromJson(Map<String, dynamic> json) {
    return StudentClassInfo(
      classe: ClasseInfo.fromJson(json['classe'] ?? {}),
      ecole: EcoleInfo.fromJson(json['ecole'] ?? {}),
      effectifClasse: json['effectifClasse'] is int ? json['effectifClasse'] : int.tryParse(json['effectifClasse']?.toString() ?? '0') ?? 0,
      eleve: EleveInfo.fromJson(json['eleve'] ?? {}),
      identifiantVieEcole: json['identifiantVieEcole']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classe': classe.toJson(),
      'ecole': ecole.toJson(),
      'effectifClasse': effectifClasse,
      'eleve': eleve.toJson(),
      'identifiantVieEcole': identifiantVieEcole,
    };
  }

  @override
  String toString() {
    return 'StudentClassInfo{classe: ${classe.libelle}, ecole: ${ecole.libelle}, effectifClasse: $effectifClasse, eleve: ${eleve.fullName}, identifiantVieEcole: $identifiantVieEcole}';
  }
}

class ClasseInfo {
  final String code;
  final int id;
  final String libelle;

  ClasseInfo({
    required this.code,
    required this.id,
    required this.libelle,
  });

  factory ClasseInfo.fromJson(Map<String, dynamic> json) {
    return ClasseInfo(
      code: json['code']?.toString() ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      libelle: json['libelle']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'id': id,
      'libelle': libelle,
    };
  }

  @override
  String toString() {
    return 'ClasseInfo{code: $code, id: $id, libelle: $libelle}';
  }
}

class EcoleInfo {
  final String code;
  final int id;
  final String libelle;

  EcoleInfo({
    required this.code,
    required this.id,
    required this.libelle,
  });

  factory EcoleInfo.fromJson(Map<String, dynamic> json) {
    return EcoleInfo(
      code: json['code']?.toString() ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      libelle: json['libelle']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'id': id,
      'libelle': libelle,
    };
  }

  @override
  String toString() {
    return 'EcoleInfo{code: $code, id: $id, libelle: $libelle}';
  }
}

class EleveInfo {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String sexe;
  final String? urlPhoto;

  EleveInfo({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.sexe,
    this.urlPhoto,
  });

  factory EleveInfo.fromJson(Map<String, dynamic> json) {
    return EleveInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      matricule: json['matricule']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      sexe: json['sexe']?.toString() ?? '',
      urlPhoto: json['urlPhoto']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe,
      'urlPhoto': urlPhoto,
    };
  }

  String get fullName => '$prenom $nom';

  @override
  String toString() {
    return 'EleveInfo{id: $id, matricule: $matricule, nom: $nom, prenom: $prenom, sexe: $sexe, urlPhoto: $urlPhoto}';
  }
}
