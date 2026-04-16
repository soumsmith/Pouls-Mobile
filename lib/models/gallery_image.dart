/// Modèle pour représenter une image de la galerie d'une école
class GalleryImage {
  final String imageUrl;
  final String? id;
  final DateTime? createdAt;

  const GalleryImage({
    required this.imageUrl,
    this.id,
    this.createdAt,
  });

  /// Crée une instance à partir d'un JSON
  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      imageUrl: json['image'] as String? ?? '',
      id: _extractIdFromUrl(json['image'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// Extrait l'ID de l'image à partir de l'URL
  static String? _extractIdFromUrl(String url) {
    if (url.isEmpty) return null;
    
    // L'URL format: https://s3.eu-west-1.amazonaws.com/groupegain/galerie/1760720289_GHS Cantine.png
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    
    // Le dernier segment contient l'ID et le nom du fichier
    if (segments.isNotEmpty) {
      final fileName = segments.last;
      // Extraire la partie numérique au début (ID)
      final match = RegExp(r'^(\d+)').firstMatch(fileName);
      return match?.group(1);
    }
    
    return null;
  }

  /// Convertit l'instance en JSON
  Map<String, dynamic> toJson() {
    return {
      'image': imageUrl,
      'id': id,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryImage && other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => imageUrl.hashCode;

  @override
  String toString() {
    return 'GalleryImage(imageUrl: $imageUrl, id: $id)';
  }
}
