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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      typeVideo: json['typevideo']?.toString() ?? json['type_video']?.toString() ?? '',
      youtubeUrl: json['video_youtube']?.toString() ?? json['youtube_url']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      code: json['codeecole']?.toString() ?? json['code']?.toString() ?? json['ecole']?.toString() ?? '',
      etablissement: json['nomecole']?.toString() ?? json['etablissement']?.toString() ?? '',
      slug: json['slug']?.toString(),
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
    var raw = youtubeUrl.trim();
    if (raw.isEmpty) return '';
    // Certaines URLs en base n'ont pas de schéma explicite (ex:
    // "www.youtube.com/watch?v=XXX") : Uri.parse les interprète alors comme
    // un chemin relatif (host vide), ce qui faisait échouer silencieusement
    // toute la détection ci-dessous.
    if (!raw.contains('://')) {
      raw = 'https://$raw';
    }

    Uri? url;
    try {
      url = Uri.parse(raw);
    } catch (_) {
      url = null;
    }

    if (url != null) {
      final host = url.host.toLowerCase();
      if (host.contains('youtube.com')) {
        // Gérer les URLs embed comme https://www.youtube.com/embed/VIDEO_ID
        if (url.pathSegments.contains('embed')) {
          final embedIndex = url.pathSegments.indexOf('embed');
          if (embedIndex + 1 < url.pathSegments.length) {
            return url.pathSegments[embedIndex + 1];
          }
        }
        // Gérer les URLs shorts comme https://www.youtube.com/shorts/VIDEO_ID
        if (url.pathSegments.contains('shorts')) {
          final shortsIndex = url.pathSegments.indexOf('shorts');
          if (shortsIndex + 1 < url.pathSegments.length) {
            return url.pathSegments[shortsIndex + 1];
          }
        }
        // Gérer les URLs watch comme https://www.youtube.com/watch?v=VIDEO_ID
        final v = url.queryParameters['v'];
        if (v != null && v.isNotEmpty) return v;
      } else if (host.contains('youtu.be')) {
        if (url.pathSegments.isNotEmpty) return url.pathSegments.last;
      }
    }

    // Filet de sécurité : extraction par regex si le parsing par URL n'a
    // rien donné (format inattendu/légèrement malformé en base). Un ID
    // YouTube fait 11 caractères alphanumériques (+ "-"/"_").
    final match = RegExp(
      r'(?:v=|/embed/|/shorts/|youtu\.be/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(raw);
    return match?.group(1) ?? '';
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
