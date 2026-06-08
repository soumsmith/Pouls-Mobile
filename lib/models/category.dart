class SubCategory {
  final int id;
  final String nom;
  final int categorieId;

  const SubCategory({
    required this.id,
    required this.nom,
    required this.categorieId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      categorieId: json['categorie_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorie_id': categorieId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubCategory &&
        other.id == id &&
        other.nom == nom &&
        other.categorieId == categorieId;
  }

  @override
  int get hashCode => id.hashCode ^ nom.hashCode ^ categorieId.hashCode;

  @override
  String toString() => 'SubCategory(id: $id, nom: $nom, categorieId: $categorieId)';
}

class Category {
  final int id;
  final String nom;
  final String typeProduit;
  final List<SubCategory> sousCategories;

  const Category({
    required this.id,
    required this.nom,
    required this.typeProduit,
    this.sousCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      typeProduit: json['type_produit'] ?? '',
      sousCategories: (json['sous_categories'] as List<dynamic>?)
              ?.map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type_produit': typeProduit,
      'sous_categories': sousCategories.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.nom == nom &&
        other.typeProduit == typeProduit;
  }

  @override
  int get hashCode => id.hashCode ^ nom.hashCode ^ typeProduit.hashCode;

  @override
  String toString() => 'Category(id: $id, nom: $nom, typeProduit: $typeProduit, sousCategories: $sousCategories)';
}
