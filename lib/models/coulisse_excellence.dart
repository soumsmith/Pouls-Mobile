class CoulisseExcellence {
  final int id;
  final String nom;
  final String prenoms;
  final String classe;
  final String titre;
  final String description;
  final String etablissement;
  final String? nompays;
  final String videoYoutube;
  final String code;

  CoulisseExcellence({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.classe,
    required this.titre,
    required this.description,
    required this.etablissement,
    this.nompays,
    required this.videoYoutube,
    required this.code,
  });

  factory CoulisseExcellence.fromJson(Map<String, dynamic> json) {
    return CoulisseExcellence(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenoms: json['prenoms'] as String,
      classe: json['classe'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      etablissement: json['etablissement'] as String,
      nompays: json['nompays'] as String?,
      videoYoutube: json['video_youtube'] as String,
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenoms': prenoms,
      'classe': classe,
      'titre': titre,
      'description': description,
      'etablissement': etablissement,
      'nompays': nompays,
      'video_youtube': videoYoutube,
      'code': code,
    };
  }

  String get fullName => '$prenoms $nom';
  
  String get youtubeVideoId {
    final url = Uri.parse(videoYoutube);
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
    if (videoId.isEmpty) return videoYoutube;
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
