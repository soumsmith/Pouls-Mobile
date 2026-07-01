class SubscriptionOffer {
  final String id;
  final String title;
  final String description;
  final double price;
  final String duration; // e.g. "1 mois", "1 an"
  final List<String> features;
  final String level; // e.g. "premium", "vip"
  final bool isPopular;

  SubscriptionOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.features,
    required this.level,
    this.isPopular = false,
  });

  factory SubscriptionOffer.fromJson(Map<String, dynamic> json, List<String> accessibleModules) {
    // Si is_trial est à 1, on peut forcer le prix à 0 pour l'affichage gratuit
    final isTrial = json['is_trial'] == 1;
    final rawPrice = double.tryParse(json['price']?.toString() ?? '0') ?? 0;

    return SubscriptionOffer(
      id: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      title: json['nom'] ?? 'Offre',
      description: json['package']?['description'] ?? "Abonnement ${json['nom']}",
      price: isTrial ? 0 : rawPrice,
      duration: "${json['duration_days'] ?? 30} jours",
      features: accessibleModules.isNotEmpty ? accessibleModules : ["Accès à l'application"],
      level: json['slug'] ?? 'standard',
      isPopular: !isTrial && rawPrice == 10, // Heuristique simple
    );
  }
}
