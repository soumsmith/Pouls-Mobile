import '../config/app_config.dart';

/// Types d'attachement supportés pour un message de groupe
enum GroupMessageAttachmentType { none, image, audio, document, unknown }

/// Modèle représentant un message de groupe (notification)
class GroupMessage {
  final String id;
  final String titre;
  final String contenu;
  final String? expediteur;
  final String? typeExpediteur;
  final DateTime dateEnvoi;
  final bool estLu;
  final String? matricule;
  final String? idEcole;
  final String? idClasse;
  final int? conversationId;
  final String? attachmentUrl;
  final String? attachmentMimeType;
  final String? attachmentName;
  final GroupMessageAttachmentType attachmentType;

  GroupMessage({
    required this.id,
    required this.titre,
    required this.contenu,
    this.expediteur,
    this.typeExpediteur,
    required this.dateEnvoi,
    this.estLu = false,
    this.matricule,
    this.idEcole,
    this.idClasse,
    this.conversationId,
    this.attachmentUrl,
    this.attachmentMimeType,
    this.attachmentName,
    this.attachmentType = GroupMessageAttachmentType.none,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // Parser la date - gérer différents formats possibles
    DateTime dateEnvoi;
    if (json['date_envoi'] != null) {
      try {
        dateEnvoi = DateTime.parse(json['date_envoi']);
      } catch (e) {
        // Si le format est invalide, utiliser la date actuelle
        dateEnvoi = DateTime.now();
      }
    } else {
      dateEnvoi = DateTime.now();
    }

    return GroupMessage(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? json['title'] ?? 'Notification',
      contenu:
          json['contenu'] ??
          json['content'] ??
          json['body'] ??
          json['description'] ??
          '',
      expediteur: json['expediteur'] ?? json['sender'],
      typeExpediteur: json['type_expediteur'] ?? json['sender_type'],
      dateEnvoi: dateEnvoi,
      estLu:
          json['statut_reception']?.toString() == '1' ||
          json['est_lu'] == 1 ||
          json['is_read'] == true ||
          json['statut'] == 1,
      matricule: json['matricule']?.toString(),
      idEcole: json['id_ecole']?.toString(),
      idClasse: json['id_classe']?.toString(),
      conversationId: json['conversation_id'] != null
          ? int.tryParse(json['conversation_id'].toString())
          : null,
      attachmentUrl: _parseAttachmentUrl(json),
      attachmentMimeType: _parseAttachmentMimeType(json),
      attachmentName: _parseAttachmentName(json),
      attachmentType: _determineAttachmentType(
        _parseAttachmentUrl(json),
        _parseAttachmentMimeType(json),
        _parseAttachmentName(json),
      ),
    );
  }

  static String? _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final trimmedUrl = url.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }

    final baseUrl = AppConfig.VIE_ECOLES_API_BASE_URL.replaceAll('/api', '');
    if (trimmedUrl.startsWith('/')) {
      return '$baseUrl$trimmedUrl';
    }
    return '$baseUrl/$trimmedUrl';
  }

  static String? _parseAttachmentUrl(Map<String, dynamic> json) {
    if (json['attachments'] != null) {
      final attachments = json['attachments'];
      if (attachments is List && attachments.isNotEmpty) {
        final first = attachments.first;
        if (first is Map<String, dynamic>) {
          return _normalizeUrl(
            first['file_path']?.toString() ??
                first['url']?.toString() ??
                first['path']?.toString() ??
                first['image']?.toString(),
          );
        }
      }
      if (attachments is Map<String, dynamic>) {
        return _normalizeUrl(
          attachments['file_path']?.toString() ??
              attachments['url']?.toString() ??
              attachments['path']?.toString() ??
              attachments['image']?.toString(),
        );
      }
    }

    if (json['image'] != null) {
      return _normalizeUrl(json['image'].toString());
    }
    if (json['audio'] != null) {
      return _normalizeUrl(json['audio'].toString());
    }
    if (json['document'] != null) {
      return _normalizeUrl(json['document'].toString());
    }
    if (json['fichier'] != null) {
      return _normalizeUrl(json['fichier'].toString());
    }
    if (json['file_path'] != null) {
      return _normalizeUrl(json['file_path'].toString());
    }
    return null;
  }

  static String? _parseAttachmentMimeType(Map<String, dynamic> json) {
    if (json['attachments'] != null) {
      final attachments = json['attachments'];
      if (attachments is List && attachments.isNotEmpty) {
        final first = attachments.first;
        if (first is Map<String, dynamic>) {
          return first['mime_type']?.toString();
        }
      }
      if (attachments is Map<String, dynamic>) {
        return attachments['mime_type']?.toString();
      }
    }

    return json['mime_type']?.toString();
  }

  static String? _parseAttachmentName(Map<String, dynamic> json) {
    if (json['attachments'] != null) {
      final attachments = json['attachments'];
      if (attachments is List && attachments.isNotEmpty) {
        final first = attachments.first;
        if (first is Map<String, dynamic>) {
          return first['file_name']?.toString() ?? first['name']?.toString();
        }
      }
      if (attachments is Map<String, dynamic>) {
        return attachments['file_name']?.toString() ??
            attachments['name']?.toString();
      }
    }
    return json['file_name']?.toString() ?? json['name']?.toString();
  }

  static GroupMessageAttachmentType _determineAttachmentType(
    String? url,
    String? mimeType,
    String? name,
  ) {
    final lowerMime = mimeType?.toLowerCase() ?? '';
    final lowerUrl = url?.toLowerCase() ?? '';
    final lowerName = name?.toLowerCase() ?? '';

    if (lowerMime.contains('image') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp')) {
      return GroupMessageAttachmentType.image;
    }

    if (lowerMime.contains('audio') ||
        lowerUrl.endsWith('.mp3') ||
        lowerUrl.endsWith('.wav') ||
        lowerUrl.endsWith('.ogg') ||
        lowerUrl.endsWith('.m4a') ||
        lowerName.endsWith('.mp3') ||
        lowerName.endsWith('.wav') ||
        lowerName.endsWith('.ogg') ||
        lowerName.endsWith('.m4a')) {
      return GroupMessageAttachmentType.audio;
    }

    if (lowerMime.contains('pdf') ||
        lowerMime.contains('officedocument') ||
        lowerMime.contains('msword') ||
        lowerMime.contains('excel') ||
        lowerMime.contains('presentation') ||
        lowerUrl.endsWith('.pdf') ||
        lowerUrl.endsWith('.doc') ||
        lowerUrl.endsWith('.docx') ||
        lowerUrl.endsWith('.xls') ||
        lowerUrl.endsWith('.xlsx') ||
        lowerUrl.endsWith('.ppt') ||
        lowerUrl.endsWith('.pptx') ||
        lowerName.endsWith('.pdf') ||
        lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx') ||
        lowerName.endsWith('.ppt') ||
        lowerName.endsWith('.pptx')) {
      return GroupMessageAttachmentType.document;
    }

    return url != null && url.isNotEmpty
        ? GroupMessageAttachmentType.unknown
        : GroupMessageAttachmentType.none;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'expediteur': expediteur,
      'type_expediteur': typeExpediteur,
      'date_envoi': dateEnvoi.toIso8601String(),
      'est_lu': estLu ? 1 : 0,
      'matricule': matricule,
      'id_ecole': idEcole,
      'id_classe': idClasse,
      'conversation_id': conversationId,
      'attachment_url': attachmentUrl,
      'attachment_mime_type': attachmentMimeType,
      'attachment_name': attachmentName,
      'attachment_type': attachmentType.toString().split('.').last,
    };
  }

  GroupMessage copyWith({
    String? id,
    String? titre,
    String? contenu,
    String? expediteur,
    String? typeExpediteur,
    DateTime? dateEnvoi,
    bool? estLu,
    String? matricule,
    String? idEcole,
    String? idClasse,
    int? conversationId,
    String? attachmentUrl,
    String? attachmentMimeType,
    String? attachmentName,
    GroupMessageAttachmentType? attachmentType,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      expediteur: expediteur ?? this.expediteur,
      typeExpediteur: typeExpediteur ?? this.typeExpediteur,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estLu: estLu ?? this.estLu,
      matricule: matricule ?? this.matricule,
      idEcole: idEcole ?? this.idEcole,
      idClasse: idClasse ?? this.idClasse,
      conversationId: conversationId ?? this.conversationId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  /// Formate la date d'envoi pour l'affichage
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateEnvoi);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateEnvoi.day}/${dateEnvoi.month}/${dateEnvoi.year}';
    }
  }

  /// Retourne vrai si le message contient un attachement affichable
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  /// Retourne le type d'attachement principal pour l'affichage
  GroupMessageAttachmentType get attachmentKind => attachmentType;

  /// Retourne le nom d'affichage de l'expéditeur
  String get expediteurDisplay {
    if (expediteur != null && expediteur!.isNotEmpty) {
      return expediteur!;
    }

    switch (typeExpediteur?.toLowerCase()) {
      case 'admin':
      case 'administration':
        return 'Administration';
      case 'prof':
      case 'professeur':
      case 'teacher':
        return 'Professeur';
      case 'direction':
        return 'Direction';
      case 'secretariat':
        return 'Secrétariat';
      default:
        return 'Établissement';
    }
  }
}
