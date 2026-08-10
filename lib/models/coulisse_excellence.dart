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
    var raw = videoYoutube.trim();
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
    if (videoId.isEmpty) return videoYoutube;
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
