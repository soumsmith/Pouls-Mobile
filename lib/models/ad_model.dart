class AdModel {
  final int id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final String? youtubeUrl;
  final String position;
  final String page;
  final String section;
  final String device;
  final String format;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final String typedecontenu;

  AdModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    this.youtubeUrl,
    required this.position,
    required this.page,
    required this.section,
    required this.device,
    required this.format,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.typedecontenu,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'] ?? '',
      youtubeUrl: json['youtube_url'],
      position: json['position'] ?? '',
      page: json['page'] ?? '',
      section: json['section'] ?? '',
      device: json['device'] ?? '',
      format: json['format'] ?? '',
      priority: json['priority'] ?? 0,
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      typedecontenu: json['typedecontenu'] ?? '',
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
