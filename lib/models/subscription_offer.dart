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
}
