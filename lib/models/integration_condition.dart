class IntegrationCondition {
  final int id;
  final String nom;
  final String description;
  final String backgroundImage;
  final List<dynamic> gallery;

  IntegrationCondition({
    required this.id,
    required this.nom,
    required this.description,
    required this.backgroundImage,
    required this.gallery,
  });

  factory IntegrationCondition.fromJson(Map<String, dynamic> json) {
    return IntegrationCondition(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      backgroundImage: json['background_image'] ?? '',
      gallery: json['gallery'] ?? [],
    );
  }
}
