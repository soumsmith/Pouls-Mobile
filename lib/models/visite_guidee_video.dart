class VisiteGuideeVideo {
  final int? id;
  final String typeVideo;
  final String youtubeUrl;
  final String? title;
  final String? description;
  final String code;
  final String etablissement;
  final String? slug;

  VisiteGuideeVideo({
    this.id,
    required this.typeVideo,
    required this.youtubeUrl,
    this.title,
    this.description,
    this.code = '',
    this.etablissement = '',
    this.slug,
  });

  factory VisiteGuideeVideo.fromJson(Map<String, dynamic> json) {
    return VisiteGuideeVideo(
      id: json['id'] as int?,
      typeVideo: (json['typevideo'] ?? json['type_video'] ?? '') as String,
      youtubeUrl: (json['youtube_url'] ?? '') as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      code: json['codeecole']?.toString() ?? json['code']?.toString() ?? json['ecole']?.toString() ?? '',
      etablissement: json['nomecole']?.toString() ?? json['etablissement']?.toString() ?? '',
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typevideo': typeVideo,
      'youtube_url': youtubeUrl,
      'title': title,
      'description': description,
      'code': code,
      'etablissement': etablissement,
      'slug': slug,
    };
  }

  VisiteGuideeVideo copyWith({
    int? id,
    String? typeVideo,
    String? youtubeUrl,
    String? title,
    String? description,
    String? code,
    String? etablissement,
    String? slug,
  }) {
    return VisiteGuideeVideo(
      id: id ?? this.id,
      typeVideo: typeVideo ?? this.typeVideo,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      code: code ?? this.code,
      etablissement: etablissement ?? this.etablissement,
      slug: slug ?? this.slug,
    );
  }

  String get youtubeVideoId {
    final url = Uri.parse(youtubeUrl);
    if (url.host.contains('youtube.com')) {
      // Gérer les URLs embed comme https://www.youtube.com/embed/VIDEO_ID
      if (url.pathSegments.contains('embed')) {
        final embedIndex = url.pathSegments.indexOf('embed');
        if (embedIndex + 1 < url.pathSegments.length) {
          return url.pathSegments[embedIndex + 1];
        }
      }
      // Gérer les URLs watch comme https://www.youtube.com/watch?v=VIDEO_ID
      return url.queryParameters['v'] ?? '';
    } else if (url.host.contains('youtu.be')) {
      return url.pathSegments.isNotEmpty ? url.pathSegments.last : '';
    }
    return '';
  }
  
  /// Convertit l'URL YouTube embed en URL watch pour le partage
  String get watchUrl {
    final videoId = youtubeVideoId;
    if (videoId.isEmpty) return youtubeUrl;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    switch (typeVideo.toLowerCase()) {
      case 'visiteguide':
        return 'Visite Guidée';
      case 'presentation':
        return 'Présentation';
      default:
        return 'Vidéo';
    }
  }

  String get displayDescription {
    if (description != null && description!.isNotEmpty) return description!;
    switch (typeVideo.toLowerCase()) {
      case 'visiteguide':
        return 'Découvrez nos installations lors d\'une visite guidée';
      case 'presentation':
        return 'Présentation de l\'établissement';
      default:
        return 'Vidéo de présentation';
    }
  }
}
