// models/video.dart
class Video {
  final int? id;
  final String typevideo;
  final String youtubeUrl;
  final String title;
  final String description;
  final String createdAt;
  final String code;
  final String etablissement;

  const Video({
    this.id,
    required this.typevideo,
    required this.youtubeUrl,
    required this.title,
    required this.description,
    required this.createdAt,
    this.code = '',
    this.etablissement = '',
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as int?,
      typevideo: json['typevideo'] ?? '',
      youtubeUrl: json['youtube_url'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      code: json['codeecole']?.toString() ?? json['code']?.toString() ?? json['ecole']?.toString() ?? '',
      etablissement: json['nomecole']?.toString() ?? json['etablissement']?.toString() ?? '',
    );
  }

  // Extraire l'ID YouTube de l'URL
  String get youtubeVideoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri != null) {
      // Pour les URLs de type youtube.com/embed/ID
      if (youtubeUrl.contains('/embed/')) {
        return youtubeUrl.split('/embed/').last.split('?').first;
      }
      // Pour les URLs de type youtube.com/shorts/ID
      if (youtubeUrl.contains('/shorts/')) {
        return youtubeUrl.split('/shorts/').last.split('?').first;
      }
      // Pour les URLs avec paramètre v=
      if (youtubeUrl.contains('v=')) {
        return youtubeUrl.split('v=').last.split('&').first;
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typevideo': typevideo,
      'youtube_url': youtubeUrl,
      'title': title,
      'description': description,
      'created_at': createdAt,
      'code': code,
      'etablissement': etablissement,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.typevideo == typevideo &&
        other.youtubeUrl == youtubeUrl &&
        other.title == title;
  }

  @override
  int get hashCode => typevideo.hashCode ^ youtubeUrl.hashCode ^ title.hashCode;

  @override
  String toString() => 'Video(typevideo: $typevideo, title: $title)';
}