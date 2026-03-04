class Product {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String type;
  final String category;
  final double price;
  final String? imageUrl;
  final String? icon;
  final String color;
  final bool isAvailable;
  final int stockQuantity;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.type,
    required this.category,
    required this.price,
    this.imageUrl,
    this.icon,
    required this.color,
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.createdAt,
    this.metadata,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image']?.toString() ?? map['imageUrl']?.toString(),
      icon: map['icon']?.toString(),
      color: map['color']?.toString() ?? '0xFF000000',
      isAvailable: map['isAvailable'] as bool? ?? true,
      stockQuantity: map['stockQuantity'] as int? ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) 
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory Product.fromApiDetailMap(Map<String, dynamic> map) {
    return Product(
      id: map['produit_uid']?.toString() ?? '',
      title: map['titre']?.toString() ?? '',
      subtitle: map['categorie']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: map['type_partenaire']?.toString() ?? 'LIBRAIRIE',
      category: map['categorie']?.toString() ?? 'Papeterie',
      price: (map['prix_librairie'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image']?.toString(),
      icon: null,
      color: '0xFF2E7D32', // Vert pour les produits de librairie
      isAvailable: map['statut']?.toString().toLowerCase() == 'disponible',
      stockQuantity: map['stock_actuel'] as int? ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) 
          : null,
      metadata: {
        'id': map['id']?.toString(),
        'niveau': map['niveau']?.toString(),
        'matiere': map['matiere']?.toString(),
        'prix_engros': map['prix_engros']?.toString(),
        'prix_promo': map['prix_promo']?.toString(),
        'collection': map['collection']?.toString(),
        'maison_edition_id': map['maison_edition_id']?.toString(),
        'statut_valide': map['statut_valide']?.toString(),
        'updated_at': map['updated_at']?.toString(),
        'type_produit': map['type_produit']?.toString(),
        'stock_initial': map['stock_initial']?.toString(),
        'seuil': map['seuil']?.toString(),
        'video_url': map['video_url']?.toString(),
        'code_fournisseur': map['code_fournisseur']?.toString(),
        'nom_fournisseur': map['nom_fournisseur']?.toString(),
        'ville_fournisseur': map['ville_fournisseur']?.toString(),
        'pays_fournisseur': map['pays_fournisseur']?.toString(),
        'contact_fournisseur': map['contact_fournisseur']?.toString(),
        'adresse_fournisseur': map['adresse_fournisseur']?.toString(),
        'logo_fournisseur': map['logo_fournisseur']?.toString(),
        'imagefond_fournisseur': map['imagefond_fournisseur']?.toString(),
        'type_partenaire_fournisseur': map['type_partenaire_fournisseur']?.toString(),
        'images': map['images']?.toString(),
      },
    );
  }

  factory Product.fromApiMap(Map<String, dynamic> map) {
    return Product(
      id: map['produit_uid']?.toString() ?? '',
      title: map['titre']?.toString() ?? '',
      subtitle: map['categorie']?.toString() ?? '',
      description: '${map['nom']?.toString() ?? ''} - ${map['ville']?.toString() ?? ''}',
      type: map['type']?.toString() ?? 'LIBRAIRIE',
      category: map['categorie']?.toString() ?? 'Papeterie',
      price: (map['prix_librairie'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image']?.toString(),
      icon: null,
      color: '0xFF2E7D32', // Vert pour les produits de librairie
      isAvailable: ((map['stock_actuel'] as int?) ?? 0) > 0,
      stockQuantity: map['stock_actuel'] as int? ?? 0,
      createdAt: null,
      metadata: {
        'code': map['code']?.toString(),
        'nom': map['nom']?.toString(),
        'ville': map['ville']?.toString(),
        'pays': map['pays']?.toString(),
        'contact': map['contact']?.toString(),
        'adresse': map['adresse']?.toString(),
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'type': type,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'icon': icon,
      'color': color,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'createdAt': createdAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? type,
    String? category,
    double? price,
    String? imageUrl,
    String? icon,
    String? color,
    bool? isAvailable,
    int? stockQuantity,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, title: $title, type: $type, price: $price)';
  }
}

enum ProductType {
  service('Service'),
  book('Livre'),
  pdf('PDF'),
  video('Vidéo');

  const ProductType(this.displayName);
  final String displayName;

  static ProductType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return ProductType.service;
      case 'livre':
        return ProductType.book;
      case 'pdf':
        return ProductType.pdf;
      case 'vidéo':
      case 'video':
        return ProductType.video;
      default:
        return ProductType.service;
    }
  }
}

enum ProductCategory {
  education('Éducation'),
  tuition('Frais de scolarité'),
  books('Livres'),
  materials('Matériel pédagogique'),
  multimedia('Multimédia');

  const ProductCategory(this.displayName);
  final String displayName;

  static ProductCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'éducation':
      case 'education':
        return ProductCategory.education;
      case 'frais de scolarité':
      case 'tuition':
        return ProductCategory.tuition;
      case 'livres':
      case 'books':
        return ProductCategory.books;
      case 'matériel pédagogique':
      case 'materials':
        return ProductCategory.materials;
      case 'multimédia':
      case 'multimedia':
        return ProductCategory.multimedia;
      default:
        return ProductCategory.education;
    }
  }
}
