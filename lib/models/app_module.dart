/// Modèle représentant un module de l'application (retourné par l'API subscriptions)
class AppModule {
  final int id;
  final String nom;
  final String identifiant;
  final String section;
  final String? description;
  final String type; // "gratuit" ou "payant"

  const AppModule({
    required this.id,
    required this.nom,
    required this.identifiant,
    required this.section,
    this.description,
    required this.type,
  });

  /// Indique si le module est gratuit
  bool get isGratuit => type.toLowerCase() == 'gratuit';

  /// Indique si le module est payant
  bool get isPayant => type.toLowerCase() == 'payant';

  factory AppModule.fromJson(Map<String, dynamic> json) {
    return AppModule(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nom: json['nom']?.toString() ?? '',
      identifiant: json['identifiant']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'gratuit',
    );
  }

  @override
  String toString() => 'AppModule(id: $id, nom: $nom, identifiant: $identifiant, type: $type)';
}
