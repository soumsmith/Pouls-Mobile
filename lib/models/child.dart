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
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      establishment: json['establishment'] as String,
      grade: json['grade'] as String,
      photoUrl: json['photoUrl'] as String?,
      parentId: json['parentId'] as String,
      matricule: json['matricule'] as String?,
      ecoleCode: json['ecoleCode'] as String?,
      paramEcole: json['paramEcole'] as String?,
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
