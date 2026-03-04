import '../models/product.dart';

abstract class LibraryService {
  /// Récupère la liste de tous les produits
  Future<List<Product>> getAllProducts();

  /// Récupère un produit par son ID
  Future<Product?> getProductById(String productId);

  /// Recherche des produits par terme
  Future<List<Product>> searchProducts(String query);

  /// Filtre les produits par catégorie
  Future<List<Product>> getProductsByCategory(String category);

  /// Filtre les produits par type
  Future<List<Product>> getProductsByType(String type);

  /// Récupère les produits en promotion
  Future<List<Product>> getFeaturedProducts();

  /// Récupère les produits les plus populaires
  Future<List<Product>> getPopularProducts();

  /// Vérifie la disponibilité d'un produit
  Future<bool> isProductAvailable(String productId);

  /// Met à jour le stock d'un produit
  Future<bool> updateProductStock(String productId, int newQuantity);
}

class MockLibraryService implements LibraryService {
  static final MockLibraryService _instance = MockLibraryService._internal();
  factory MockLibraryService() => _instance;
  MockLibraryService._internal();

  static final List<Product> _mockProducts = [
    Product(
      id: '1',
      title: 'LIBOULI',
      subtitle: 'Votre Boutique et Librairie en Ligne',
      description: 'Accédez à notre boutique en ligne pour tous vos besoins éducatifs. Livres, fournitures, et services scolaires disponibles.',
      type: 'Service',
      category: 'Éducation',
      price: 0.0,
      imageUrl: 'https://picsum.photos/seed/libouli/400/300.jpg',
      icon: 'shopping_bag',
      color: '0xFF6366F1',
      isAvailable: true,
      stockQuantity: 999,
    ),
    Product(
      id: '2',
      title: 'POULS-PAID',
      subtitle: 'Frais de scolarité',
      description: 'Service de paiement en ligne pour les frais de scolarité. Sécurisé, rapide et pratique.',
      type: 'Service',
      category: 'Frais de scolarité',
      price: 0.0,
      imageUrl: 'https://picsum.photos/seed/pouls-paid/400/300.jpg',
      icon: 'school',
      color: '0xFF8B5CF6',
      isAvailable: true,
      stockQuantity: 999,
    ),
    Product(
      id: '3',
      title: 'Mathématiques',
      subtitle: 'CE1 - Manuel complet',
      description: 'Manuel scolaire complet de mathématiques pour le niveau CE1. Exercices pratiques et corrigés inclus.',
      type: 'Livre',
      category: 'Livres',
      price: 2500.0,
      imageUrl: 'https://picsum.photos/seed/math-ce1/400/300.jpg',
      icon: 'calculate',
      color: '0xFF3B82F6',
      isAvailable: true,
      stockQuantity: 45,
    ),
    Product(
      id: '4',
      title: 'Sciences',
      subtitle: 'CM2 - Expériences',
      description: 'Recueil d\'expériences scientifiques pour les élèves de CM2. Idéal pour l\'apprentissage pratique.',
      type: 'PDF',
      category: 'Matériel pédagogique',
      price: 1500.0,
      imageUrl: 'https://picsum.photos/seed/sciences-cm2/400/300.jpg',
      icon: 'science',
      color: '0xFF10B981',
      isAvailable: true,
      stockQuantity: 120,
    ),
    Product(
      id: '5',
      title: 'Français',
      subtitle: 'Grammaire et conjugaison',
      description: 'Guide complet de grammaire et conjugaison française. Exercices progressifs avec corrigés.',
      type: 'Livre',
      category: 'Livres',
      price: 2800.0,
      imageUrl: 'https://picsum.photos/seed/francais-grammar/400/300.jpg',
      icon: 'menu_book',
      color: '0xFF8B5CF6',
      isAvailable: true,
      stockQuantity: 67,
    ),
    Product(
      id: '6',
      title: 'Histoire',
      subtitle: 'De la Préhistoire à nos jours',
      description: 'Série vidéo complète sur l\'histoire humaine. De la préhistoire jusqu\'à l\'ère moderne.',
      type: 'Vidéo',
      category: 'Multimédia',
      price: 3500.0,
      imageUrl: 'https://picsum.photos/seed/history/400/300.jpg',
      icon: 'history_edu',
      color: '0xFFF59E0B',
      isAvailable: true,
      stockQuantity: 200,
    ),
    Product(
      id: '7',
      title: 'Anglais',
      subtitle: 'Méthode complète débutant',
      description: 'Méthode d\'apprentissage de l\'anglais pour débutants. Audio, vidéo et exercices interactifs.',
      type: 'Vidéo',
      category: 'Multimédia',
      price: 4200.0,
      imageUrl: 'https://picsum.photos/seed/english-beginner/400/300.jpg',
      icon: 'language',
      color: '0xFFEF4444',
      isAvailable: true,
      stockQuantity: 89,
    ),
    Product(
      id: '8',
      title: 'Géographie',
      subtitle: 'Atlas mondial junior',
      description: 'Atlas géographique complet pour les juniors. Cartes détaillées et informations sur tous les pays.',
      type: 'Livre',
      category: 'Livres',
      price: 3200.0,
      imageUrl: 'https://picsum.photos/seed/geography-atlas/400/300.jpg',
      icon: 'public',
      color: '0xFF06B6D4',
      isAvailable: true,
      stockQuantity: 34,
    ),
  ];

  @override
  Future<List<Product>> getAllProducts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockProducts);
  }

  @override
  Future<Product?> getProductById(String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final searchQuery = query.toLowerCase();
    return _mockProducts.where((product) =>
      product.title.toLowerCase().contains(searchQuery) ||
      product.subtitle.toLowerCase().contains(searchQuery) ||
      product.description.toLowerCase().contains(searchQuery)
    ).toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockProducts.where((product) =>
      product.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  @override
  Future<List<Product>> getProductsByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockProducts.where((product) =>
      product.type.toLowerCase() == type.toLowerCase()
    ).toList();
  }

  @override
  Future<List<Product>> getFeaturedProducts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockProducts.where((product) => 
      product.price > 0 && product.isAvailable
    ).take(4).toList();
  }

  @override
  Future<List<Product>> getPopularProducts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockProducts.where((product) => 
      product.isAvailable && product.stockQuantity > 50
    ).toList();
  }

  @override
  Future<bool> isProductAvailable(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final product = await getProductById(productId);
    return product?.isAvailable ?? false;
  }

  @override
  Future<bool> updateProductStock(String productId, int newQuantity) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final productIndex = _mockProducts.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        _mockProducts[productIndex] = _mockProducts[productIndex].copyWith(
          stockQuantity: newQuantity,
          isAvailable: newQuantity > 0,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ajoute un nouveau produit (pour testing)
  Future<bool> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _mockProducts.add(product);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprime un produit (pour testing)
  Future<bool> removeProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _mockProducts.removeWhere((product) => product.id == productId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
