class LieuLivraison {
  final int id;
  final String nomcommune;
  final String description;
  final int prixlivraison;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;

  LieuLivraison({
    required this.id,
    required this.nomcommune,
    required this.description,
    required this.prixlivraison,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LieuLivraison.fromJson(Map<String, dynamic> json) {
    return LieuLivraison(
      id: json['id'] ?? 0,
      nomcommune: json['nomcommune'] ?? '',
      description: json['description'] ?? '',
      prixlivraison: json['prixlivraison'] ?? 0,
      status: json['status'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomcommune': nomcommune,
      'description': description,
      'prixlivraison': prixlivraison,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '$nomcommune (${prixlivraison} FCFA)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LieuLivraison && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
