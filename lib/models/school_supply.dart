class SchoolSupply {
  final String produitUid;
  final String libelle;
  final String type;
  final String niveau;
  final String matiere;
  final int prix;
  final String? collection;
  final String statut;
  final String? maisonEdition;
  final String? code;
  final String? email;

  SchoolSupply({
    required this.produitUid,
    required this.libelle,
    required this.type,
    required this.niveau,
    required this.matiere,
    required this.prix,
    this.collection,
    required this.statut,
    this.maisonEdition,
    this.code,
    this.email,
  });

  factory SchoolSupply.fromJson(Map<String, dynamic> json) {
    return SchoolSupply(
      produitUid: json['produit_uid'] ?? '',
      libelle: json['libelle'] ?? '',
      type: json['type'] ?? '',
      niveau: json['niveau'] ?? '',
      matiere: json['matiere'] ?? '',
      prix: json['prix'] ?? 0,
      collection: json['collection'],
      statut: json['statut'] ?? '',
      maisonEdition: json['maison_edition'],
      code: json['code'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit_uid': produitUid,
      'libelle': libelle,
      'type': type,
      'niveau': niveau,
      'matiere': matiere,
      'prix': prix,
      'collection': collection,
      'statut': statut,
      'maison_edition': maisonEdition,
      'code': code,
      'email': email,
    };
  }
}

class SchoolSupplyResponse {
  final bool status;
  final List<SchoolSupply> data;
  final String message;

  SchoolSupplyResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory SchoolSupplyResponse.fromJson(Map<String, dynamic> json) {
    return SchoolSupplyResponse(
      status: json['status'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => SchoolSupply.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      message: json['message'] ?? '',
    );
  }
}
