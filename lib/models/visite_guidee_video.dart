class VisiteGuideeVideo {
  final String typeVideo;
  final String youtubeUrl;

  VisiteGuideeVideo({
    required this.typeVideo,
    required this.youtubeUrl,
  });

  factory VisiteGuideeVideo.fromJson(Map<String, dynamic> json) {
    return VisiteGuideeVideo(
      typeVideo: json['type_video'] as String,
      youtubeUrl: json['youtube_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_video': typeVideo,
      'youtube_url': youtubeUrl,
    };
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
