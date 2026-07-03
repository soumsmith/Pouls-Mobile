class SubscriptionModule {
  final int id;
  final String nom;
  final String identifiant;
  final String? description;
  final String type;

  SubscriptionModule({
    required this.id,
    required this.nom,
    required this.identifiant,
    this.description,
    required this.type,
  });

  factory SubscriptionModule.fromJson(Map<String, dynamic> json) {
    return SubscriptionModule(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      identifiant: json['identifiant'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'gratuit',
    );
  }
}

class SubscriptionOffer {
  final String id;
  final String uid;
  final String title;
  final String description;
  final double price;
  final double promoPrice;
  final bool isPromoActive;
  final double activePrice;
  final String currency;
  final String duration;
  final int durationDays;
  final String? image;
  final bool isTrial;
  final int maxStudents;
  final String level;
  final List<SubscriptionModule> packageModules;
  final bool isPopular;

  SubscriptionOffer({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.price,
    required this.promoPrice,
    required this.isPromoActive,
    required this.activePrice,
    required this.currency,
    required this.duration,
    required this.durationDays,
    this.image,
    required this.isTrial,
    required this.maxStudents,
    required this.level,
    required this.packageModules,
    this.isPopular = false,
  });

  factory SubscriptionOffer.fromJson(Map<String, dynamic> json) {
    final isTrial = json['is_trial'] == true || json['is_trial'] == 1;
    final rawPrice = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    final activePriceRaw = double.tryParse(json['active_price']?.toString() ?? '0') ?? rawPrice;
    
    final List<dynamic> modulesJson = json['package_modules'] ?? [];
    final modules = modulesJson.map((m) => SubscriptionModule.fromJson(m)).toList();

    return SubscriptionOffer(
      id: json['id']?.toString() ?? '',
      uid: json['uid'] ?? '',
      title: json['nom'] ?? 'Abonnement',
      description: json['description'] ?? "Accès premium",
      price: isTrial ? 0 : rawPrice,
      promoPrice: double.tryParse(json['promo_price']?.toString() ?? '0') ?? rawPrice,
      isPromoActive: json['is_promo_active'] == true || json['is_promo_active'] == 1,
      activePrice: isTrial ? 0 : activePriceRaw,
      currency: json['currency'] ?? 'XOF',
      durationDays: json['duration_days'] ?? 30,
      duration: "${json['duration_days'] ?? 30} jours",
      image: json['image'],
      isTrial: isTrial,
      maxStudents: json['max_students'] ?? 1,
      level: json['slug'] ?? 'standard',
      packageModules: modules,
      isPopular: !isTrial && rawPrice > 0, // simple heuristic
    );
  }
}
