/// Modèle de données pour les suggestions des parents
class ParentSuggestion {
  final String id;
  final String parentId;
  final String parentName;
  final String childId;
  final String childName;
  final String title;
  final String description;
  final SuggestionCategory category;
  final SuggestionType type;
  final SuggestionPriority priority;
  final SuggestionStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComment;
  final List<String> attachments;
  final int? upvotes;
  final int? downvotes;
  final bool isAnonymous;
  final String? establishmentId;
  final String? establishmentName;
  final String? targetDepartment;
  final Map<String, dynamic>? metadata;

  ParentSuggestion({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.childId,
    required this.childName,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.priority,
    this.status = SuggestionStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComment,
    this.attachments = const [],
    this.upvotes = 0,
    this.downvotes = 0,
    this.isAnonymous = false,
    this.establishmentId,
    this.establishmentName,
    this.targetDepartment,
    this.metadata,
  });

  factory ParentSuggestion.fromMap(Map<String, dynamic> map) {
    return ParentSuggestion(
      id: map['id']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      parentName: map['parentName']?.toString() ?? '',
      childId: map['childId']?.toString() ?? '',
      childName: map['childName']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: SuggestionCategory.fromString(map['category']?.toString() ?? 'general'),
      type: SuggestionType.fromString(map['type']?.toString() ?? 'improvement'),
      priority: SuggestionPriority.fromString(map['priority']?.toString() ?? 'medium'),
      status: SuggestionStatus.fromString(map['status']?.toString() ?? 'pending'),
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null 
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      reviewedBy: map['reviewedBy']?.toString(),
      reviewComment: map['reviewComment']?.toString(),
      attachments: (map['attachments'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      upvotes: map['upvotes'] as int?,
      downvotes: map['downvotes'] as int?,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      establishmentId: map['establishmentId']?.toString(),
      establishmentName: map['establishmentName']?.toString(),
      targetDepartment: map['targetDepartment']?.toString(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'parentName': parentName,
      'childId': childId,
      'childName': childName,
      'title': title,
      'description': description,
      'category': category.displayName,
      'type': type.displayName,
      'priority': priority.displayName,
      'status': status.displayName,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewComment': reviewComment,
      'attachments': attachments,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isAnonymous': isAnonymous,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'targetDepartment': targetDepartment,
      'metadata': metadata,
    };
  }

  ParentSuggestion copyWith({
    String? id,
    String? parentId,
    String? parentName,
    String? childId,
    String? childName,
    String? title,
    String? description,
    SuggestionCategory? category,
    SuggestionType? type,
    SuggestionPriority? priority,
    SuggestionStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewComment,
    List<String>? attachments,
    int? upvotes,
    int? downvotes,
    bool? isAnonymous,
    String? establishmentId,
    String? establishmentName,
    String? targetDepartment,
    Map<String, dynamic>? metadata,
  }) {
    return ParentSuggestion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewComment: reviewComment ?? this.reviewComment,
      attachments: attachments ?? this.attachments,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Formate la date de création
  String get formattedCreatedAt => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// Formate la date de révision
  String? get formattedReviewedAt {
    if (reviewedAt == null) return null;
    return '${reviewedAt!.day}/${reviewedAt!.month}/${reviewedAt!.year}';
  }

  /// Retourne le score de vote
  int get voteScore => (upvotes ?? 0) - (downvotes ?? 0);

  /// Vérifie si la suggestion a été revue
  bool get isReviewed => status != SuggestionStatus.pending;

  /// Retourne le nom d'affichage (anonyme ou réel)
  String get displayName => isAnonymous ? 'Parent anonyme' : parentName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParentSuggestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ParentSuggestion(id: $id, title: $title, status: ${status.displayName})';
  }
}

enum SuggestionCategory {
  academic('Académique'),
  infrastructure('Infrastructure'),
  security('Sécurité'),
  communication('Communication'),
  activities('Activités'),
  nutrition('Nutrition'),
  technology('Technologie'),
  staff('Personnel'),
  finance('Finances'),
  general('Général');

  const SuggestionCategory(this.displayName);
  final String displayName;

  static SuggestionCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'académique':
      case 'academic':
        return SuggestionCategory.academic;
      case 'infrastructure':
        return SuggestionCategory.infrastructure;
      case 'sécurité':
      case 'security':
        return SuggestionCategory.security;
      case 'communication':
        return SuggestionCategory.communication;
      case 'activités':
      case 'activities':
        return SuggestionCategory.activities;
      case 'nutrition':
        return SuggestionCategory.nutrition;
      case 'technologie':
      case 'technology':
        return SuggestionCategory.technology;
      case 'personnel':
      case 'staff':
        return SuggestionCategory.staff;
      case 'finances':
      case 'finance':
        return SuggestionCategory.finance;
      case 'général':
      case 'general':
        return SuggestionCategory.general;
      default:
        return SuggestionCategory.general;
    }
  }
}

enum SuggestionType {
  improvement('Amélioration'),
  newFeature('Nouvelle fonctionnalité'),
  problem('Problème'),
  question('Question'),
  complaint('Plainte'),
  compliment('Compliment'),
  idea('Idée');

  const SuggestionType(this.displayName);
  final String displayName;

  static SuggestionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'amélioration':
      case 'improvement':
        return SuggestionType.improvement;
      case 'nouvelle fonctionnalité':
      case 'new feature':
        return SuggestionType.newFeature;
      case 'problème':
      case 'problem':
        return SuggestionType.problem;
      case 'question':
        return SuggestionType.question;
      case 'plainte':
      case 'complaint':
        return SuggestionType.complaint;
      case 'compliment':
        return SuggestionType.compliment;
      case 'idée':
      case 'idea':
        return SuggestionType.idea;
      default:
        return SuggestionType.improvement;
    }
  }
}

enum SuggestionPriority {
  low('Basse'),
  medium('Moyenne'),
  high('Haute'),
  urgent('Urgente');

  const SuggestionPriority(this.displayName);
  final String displayName;

  static SuggestionPriority fromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'basse':
      case 'low':
        return SuggestionPriority.low;
      case 'moyenne':
      case 'medium':
        return SuggestionPriority.medium;
      case 'haute':
      case 'high':
        return SuggestionPriority.high;
      case 'urgente':
      case 'urgent':
        return SuggestionPriority.urgent;
      default:
        return SuggestionPriority.medium;
    }
  }
}

enum SuggestionStatus {
  pending('En attente'),
  underReview('En cours de révision'),
  approved('Approuvée'),
  rejected('Rejetée'),
  implemented('Implémentée'),
  closed('Fermée');

  const SuggestionStatus(this.displayName);
  final String displayName;

  static SuggestionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        return SuggestionStatus.pending;
      case 'en cours de révision':
      case 'under review':
        return SuggestionStatus.underReview;
      case 'approuvée':
      case 'approved':
        return SuggestionStatus.approved;
      case 'rejetée':
      case 'rejected':
        return SuggestionStatus.rejected;
      case 'implémentée':
      case 'implemented':
        return SuggestionStatus.implemented;
      case 'fermée':
      case 'closed':
        return SuggestionStatus.closed;
      default:
        return SuggestionStatus.pending;
    }
  }
}

/// Statistiques des suggestions pour une période
class SuggestionStats {
  final String period;
  final int totalSuggestions;
  final int pendingSuggestions;
  final int approvedSuggestions;
  final int rejectedSuggestions;
  final int implementedSuggestions;
  final Map<SuggestionCategory, int> suggestionsByCategory;
  final List<ParentSuggestion> topVotedSuggestions;
  final List<ParentSuggestion> recentSuggestions;

  SuggestionStats({
    required this.period,
    required this.totalSuggestions,
    required this.pendingSuggestions,
    required this.approvedSuggestions,
    required this.rejectedSuggestions,
    required this.implementedSuggestions,
    required this.suggestionsByCategory,
    required this.topVotedSuggestions,
    required this.recentSuggestions,
  });

  /// Calcule le taux d'approbation
  double get approvalRate {
    if (totalSuggestions == 0) return 0.0;
    return (approvedSuggestions / totalSuggestions) * 100;
  }

  /// Calcule le taux d'implémentation
  double get implementationRate {
    if (approvedSuggestions == 0) return 0.0;
    return (implementedSuggestions / approvedSuggestions) * 100;
  }

  /// Retourne la catégorie la plus active
  SuggestionCategory get mostActiveCategory {
    if (suggestionsByCategory.isEmpty) return SuggestionCategory.general;
    
    return suggestionsByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Retourne le résumé des statistiques
  String get summary {
    return '$totalSuggestions suggestions ($approvalRate.toStringAsFixed(1)}% approuvées)';
  }
}
