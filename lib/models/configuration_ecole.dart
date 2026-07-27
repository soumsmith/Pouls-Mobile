class OptionConfiguration {
  final int id;
  final String libelle;
  final String? description;

  const OptionConfiguration({
    required this.id,
    required this.libelle,
    this.description,
  });

  factory OptionConfiguration.fromJson(Map<String, dynamic> json) {
    return OptionConfiguration(
      id: json['id'] as int? ?? 0,
      libelle: json['libelle'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'description': description,
    };
  }
}

class ConfigurationEcoleData {
  final List<OptionConfiguration> statuts;
  final List<OptionConfiguration> programmesEnseignement;
  final List<OptionConfiguration> ordresEnseignement;
  final List<OptionConfiguration> typesEnseignement;

  const ConfigurationEcoleData({
    required this.statuts,
    required this.programmesEnseignement,
    required this.ordresEnseignement,
    required this.typesEnseignement,
  });

  factory ConfigurationEcoleData.fromJson(Map<String, dynamic> json) {
    return ConfigurationEcoleData(
      statuts: (json['statuts'] as List<dynamic>?)
              ?.map((e) => OptionConfiguration.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      programmesEnseignement: (json['programmes_enseignement'] as List<dynamic>?)
              ?.map((e) => OptionConfiguration.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ordresEnseignement: (json['ordres_enseignement'] as List<dynamic>?)
              ?.map((e) => OptionConfiguration.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      typesEnseignement: (json['types_enseignement'] as List<dynamic>?)
              ?.map((e) => OptionConfiguration.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
