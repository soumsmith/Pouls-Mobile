class CoulisseExcellence {
  final int id;
  final String nom;
  final String? prenoms;
  final String? classe;
  final String titre;
  final String description;
  final String etablissement;
  final String? nompays;
  final String videoYoutube;
  final String code;

  CoulisseExcellence({
    required this.id,
    required this.nom,
    this.prenoms,
    this.classe,
    required this.titre,
    required this.description,
    required this.etablissement,
    this.nompays,
    required this.videoYoutube,
    required this.code,
  });

  factory CoulisseExcellence.fromJson(Map<String, dynamic> json) {
    return CoulisseExcellence(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenoms: json['prenoms'] as String?,
      classe: json['classe'] as String?,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      etablissement: json['etablissement']?.toString() ?? '',
      nompays: json['nompays'] as String?,
      videoYoutube: json['video_youtube']?.toString() ?? '',
      code:
          json['codeecole']?.toString() ??
          json['code']?.toString() ??
          json['ecole']?.toString() ??
          '',
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

  String get fullName {
    final List<String> parts = [];
    if (prenoms != null && prenoms!.isNotEmpty) parts.add(prenoms!);
    parts.add(nom);
    return parts.join(' ').trim();
  }

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
      // Gérer les URLs shorts comme https://www.youtube.com/shorts/VIDEO_ID
      if (url.pathSegments.contains('shorts')) {
        final shortsIndex = url.pathSegments.indexOf('shorts');
        if (shortsIndex + 1 < url.pathSegments.length) {
          return url.pathSegments[shortsIndex + 1];
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
