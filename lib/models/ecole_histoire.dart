/// Une image de la galerie attachée à une "histoire" (mémoire) d'école.
class HistoireGalleryImage {
  final int id;
  final String image;
  final String? title;
  final String? description;
  final bool isFeatured;

  const HistoireGalleryImage({
    required this.id,
    required this.image,
    this.title,
    this.description,
    this.isFeatured = false,
  });

  factory HistoireGalleryImage.fromJson(Map<String, dynamic> json) {
    return HistoireGalleryImage(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      image: json['image']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
    );
  }
}

/// Une "histoire" (mémoire/événement marquant) d'un établissement — endpoints
/// GET /vie-ecoles/histoires (liste globale, toutes écoles) et
/// GET /ecoles/histoire/{codeecole} (liste spécifique à une école).
class EcoleHistoire {
  final int id;
  final String codeEcole;
  final String etablissement;
  final String? nomPays;
  final String title;
  final String content;
  final String? image;
  final List<HistoireGalleryImage> gallery;
  final String? historyYear;
  final String? historyYearEnd;
  final String? historyPeriod;
  final int historyOrder;
  final String typeDeContenu;
  final String? youtubeUrl;
  final String validationStatus;
  final bool displayOnHome;
  final String? createdAt;

  const EcoleHistoire({
    required this.id,
    required this.codeEcole,
    required this.etablissement,
    this.nomPays,
    required this.title,
    required this.content,
    this.image,
    this.gallery = const [],
    this.historyYear,
    this.historyYearEnd,
    this.historyPeriod,
    this.historyOrder = 0,
    this.typeDeContenu = 'image',
    this.youtubeUrl,
    this.validationStatus = 'approved',
    this.displayOnHome = false,
    this.createdAt,
  });

  factory EcoleHistoire.fromJson(Map<String, dynamic> json) {
    return EcoleHistoire(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      codeEcole: json['codeecole']?.toString() ?? '',
      etablissement: json['etablissement']?.toString() ?? '',
      nomPays: json['nompays']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      image: json['image']?.toString(),
      gallery: (json['gallery'] as List?)
              ?.map((g) => HistoireGalleryImage.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      historyYear: json['history_year']?.toString(),
      historyYearEnd: json['history_year_end']?.toString(),
      historyPeriod: json['history_period']?.toString(),
      historyOrder: json['history_order'] is int
          ? json['history_order']
          : int.tryParse(json['history_order']?.toString() ?? '') ?? 0,
      typeDeContenu: json['typedecontenu']?.toString() ?? 'image',
      youtubeUrl: json['youtube_url']?.toString(),
      validationStatus: json['validation_status']?.toString() ?? 'approved',
      displayOnHome: json['display_on_home'] == 1 || json['display_on_home'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  bool get isVideo => typeDeContenu.toLowerCase() == 'video' && (youtubeUrl?.isNotEmpty ?? false);

  /// Libellé d'année à afficher : priorité à `history_period` (texte libre
  /// saisi côté admin, ex. "2010" ou "pause de la première pierre"), sinon
  /// l'année extraite de `history_year`.
  String get yearLabel {
    if (historyPeriod != null && historyPeriod!.trim().isNotEmpty) {
      return historyPeriod!.trim();
    }
    if (historyYear != null && historyYear!.isNotEmpty) {
      final parsed = DateTime.tryParse(historyYear!);
      if (parsed != null) return parsed.year.toString();
    }
    return '';
  }
}

/// Réponse paginée (format Laravel) des endpoints "histoires".
class EcoleHistoiresResponse {
  final List<EcoleHistoire> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const EcoleHistoiresResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory EcoleHistoiresResponse.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return EcoleHistoiresResponse(
      data: (json['data'] as List?)
              ?.map((item) => EcoleHistoire.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      currentPage: parseInt(json['current_page'], 1),
      lastPage: parseInt(json['last_page'], 1),
      perPage: parseInt(json['per_page'], 6),
      total: parseInt(json['total'], 0),
    );
  }

  static const empty = EcoleHistoiresResponse(
    data: [],
    currentPage: 1,
    lastPage: 1,
    perPage: 6,
    total: 0,
  );
}
