/// Modèle représentant un enfant (élève)
class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String establishment;
  final String grade; // Classe
  final String? photoUrl;
  final String parentId;
  final String? matricule; // Matricule de l'élève
  final String? ecoleCode; // Code de l'école pour l'API
  final String?
  paramEcole; // Paramètre de l'école (paramecole) utilisé comme code école

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.establishment,
    required this.grade,
    this.photoUrl,
    required this.parentId,
    this.matricule,
    this.ecoleCode,
    this.paramEcole,
  });

  String get fullName => '$firstName $lastName';

  /// Crée une copie de l'objet Child avec des champs mis à jour
  Child copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? establishment,
    String? grade,
    String? photoUrl,
    String? parentId,
    String? matricule,
    String? ecoleCode,
    String? paramEcole,
  }) {
    return Child(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      establishment: establishment ?? this.establishment,
      grade: grade ?? this.grade,
      photoUrl: photoUrl ?? this.photoUrl,
      parentId: parentId ?? this.parentId,
      matricule: matricule ?? this.matricule,
      ecoleCode: ecoleCode ?? this.ecoleCode,
      paramEcole: paramEcole ?? this.paramEcole,
    );
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      establishment: json['establishment']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      parentId: json['parentId']?.toString() ?? '',
      matricule: json['matricule']?.toString(),
      ecoleCode: json['ecoleCode']?.toString(),
      paramEcole: json['paramEcole']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'establishment': establishment,
      'grade': grade,
      'photoUrl': photoUrl,
      'parentId': parentId,
      'matricule': matricule,
      'ecoleCode': ecoleCode,
      'paramEcole': paramEcole,
    };
  }
}
