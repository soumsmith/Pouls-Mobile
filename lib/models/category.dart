class Category {
  final int id;
  final String nom;
  final String typeProduit;

  const Category({
    required this.id,
    required this.nom,
    required this.typeProduit,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      typeProduit: json['type_produit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type_produit': typeProduit,
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
  String toString() => 'Category(id: $id, nom: $nom, typeProduit: $typeProduit)';
}
