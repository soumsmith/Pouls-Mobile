/// Modèle de données pour les réservations de places
class PlaceReservation {
  final String id;
  final String parentId;
  final String parentName;
  final String childId;
  final String childName;
  final String establishmentId;
  final String establishmentName;
  final String academicYear;
  final String grade;
  final ReservationType type;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? deadline;
  final Map<String, dynamic> requiredDocuments;
  final Map<String, dynamic> submittedDocuments;
  final double? reservationFee;
  final double? depositAmount;
  final bool isDepositPaid;
  final String? paymentReference;
  final int? priorityScore;
  final String? waitlistPosition;
  final List<String> specialRequests;
  final Map<String, dynamic>? metadata;

  PlaceReservation({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.childId,
    required this.childName,
    required this.establishmentId,
    required this.establishmentName,
    required this.academicYear,
    required this.grade,
    required this.type,
    this.status = ReservationStatus.draft,
    required this.createdAt,
    this.submittedAt,
    this.confirmedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.deadline,
    this.requiredDocuments = const {},
    this.submittedDocuments = const {},
    this.reservationFee,
    this.depositAmount,
    this.isDepositPaid = false,
    this.paymentReference,
    this.priorityScore,
    this.waitlistPosition,
    this.specialRequests = const [],
    this.metadata,
  });

  factory PlaceReservation.fromMap(Map<String, dynamic> map) {
    return PlaceReservation(
      id: map['id']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      parentName: map['parentName']?.toString() ?? '',
      childId: map['childId']?.toString() ?? '',
      childName: map['childName']?.toString() ?? '',
      establishmentId: map['establishmentId']?.toString() ?? '',
      establishmentName: map['establishmentName']?.toString() ?? '',
      academicYear: map['academicYear']?.toString() ?? '',
      grade: map['grade']?.toString() ?? '',
      type: ReservationType.fromString(map['type']?.toString() ?? 'new_admission'),
      status: ReservationStatus.fromString(map['status']?.toString() ?? 'draft'),
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      submittedAt: map['submittedAt'] != null 
          ? DateTime.tryParse(map['submittedAt'].toString())
          : null,
      confirmedAt: map['confirmedAt'] != null 
          ? DateTime.tryParse(map['confirmedAt'].toString())
          : null,
      rejectedAt: map['rejectedAt'] != null 
          ? DateTime.tryParse(map['rejectedAt'].toString())
          : null,
      rejectionReason: map['rejectionReason']?.toString(),
      deadline: map['deadline'] != null 
          ? DateTime.tryParse(map['deadline'].toString())
          : null,
      requiredDocuments: Map<String, dynamic>.from(map['requiredDocuments'] ?? {}),
      submittedDocuments: Map<String, dynamic>.from(map['submittedDocuments'] ?? {}),
      reservationFee: map['reservationFee'] as double?,
      depositAmount: map['depositAmount'] as double?,
      isDepositPaid: map['isDepositPaid'] as bool? ?? false,
      paymentReference: map['paymentReference']?.toString(),
      priorityScore: map['priorityScore'] as int?,
      waitlistPosition: map['waitlistPosition']?.toString(),
      specialRequests: (map['specialRequests'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
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
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'academicYear': academicYear,
      'grade': grade,
      'type': type.displayName,
      'status': status.displayName,
      'createdAt': createdAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'deadline': deadline?.toIso8601String(),
      'requiredDocuments': requiredDocuments,
      'submittedDocuments': submittedDocuments,
      'reservationFee': reservationFee,
      'depositAmount': depositAmount,
      'isDepositPaid': isDepositPaid,
      'paymentReference': paymentReference,
      'priorityScore': priorityScore,
      'waitlistPosition': waitlistPosition,
      'specialRequests': specialRequests,
      'metadata': metadata,
    };
  }

  PlaceReservation copyWith({
    String? id,
    String? parentId,
    String? parentName,
    String? childId,
    String? childName,
    String? establishmentId,
    String? establishmentName,
    String? academicYear,
    String? grade,
    ReservationType? type,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? confirmedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? deadline,
    Map<String, dynamic>? requiredDocuments,
    Map<String, dynamic>? submittedDocuments,
    double? reservationFee,
    double? depositAmount,
    bool? isDepositPaid,
    String? paymentReference,
    int? priorityScore,
    String? waitlistPosition,
    List<String>? specialRequests,
    Map<String, dynamic>? metadata,
  }) {
    return PlaceReservation(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      academicYear: academicYear ?? this.academicYear,
      grade: grade ?? this.grade,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      deadline: deadline ?? this.deadline,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      submittedDocuments: submittedDocuments ?? this.submittedDocuments,
      reservationFee: reservationFee ?? this.reservationFee,
      depositAmount: depositAmount ?? this.depositAmount,
      isDepositPaid: isDepositPaid ?? this.isDepositPaid,
      paymentReference: paymentReference ?? this.paymentReference,
      priorityScore: priorityScore ?? this.priorityScore,
      waitlistPosition: waitlistPosition ?? this.waitlistPosition,
      specialRequests: specialRequests ?? this.specialRequests,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Formate la date de création
  String get formattedCreatedAt => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  /// Formate la date limite
  String? get formattedDeadline {
    if (deadline == null) return null;
    return '${deadline!.day}/${deadline!.month}/${deadline!.year}';
  }

  /// Vérifie si la réservation est en attente
  bool get isPending => status == ReservationStatus.pending || status == ReservationStatus.underReview;

  /// Vérifie si la réservation est confirmée
  bool get isConfirmed => status == ReservationStatus.confirmed;

  /// Vérifie si la réservation est rejetée
  bool get isRejected => status == ReservationStatus.rejected;

  /// Vérifie si la réservation est en liste d'attente
  bool get isWaitlisted => status == ReservationStatus.waitlist;

  /// Vérifie si la réservation est complète
  bool get isComplete => status == ReservationStatus.completed;

  /// Calcule le pourcentage de documents soumis
  double get documentsCompletionPercentage {
    if (requiredDocuments.isEmpty) return 100.0;
    final submittedCount = submittedDocuments.length;
    return (submittedCount / requiredDocuments.length) * 100;
  }

  /// Vérifie si tous les documents requis sont soumis
  bool get areAllDocumentsSubmitted => submittedDocuments.length == requiredDocuments.length;

  /// Retourne le statut de paiement
  String get paymentStatus {
    if (depositAmount == null || depositAmount == 0) return 'Aucun frais';
    if (isDepositPaid) return 'Payé';
    return 'En attente de paiement';
  }

  /// Vérifie si la réservation est en retard
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceReservation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaceReservation(id: $id, child: $childName, status: ${status.displayName})';
  }
}

enum ReservationType {
  newAdmission('Nouvelle admission'),
  reEnrollment('Réinscription'),
  transfer('Transfert'),
  siblingAdmission('Admission fratrie'),
  specialProgram('Programme spécial');

  const ReservationType(this.displayName);
  final String displayName;

  static ReservationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'nouvelle admission':
      case 'new admission':
        return ReservationType.newAdmission;
      case 'réinscription':
      case 'reenrollment':
        return ReservationType.reEnrollment;
      case 'transfert':
      case 'transfer':
        return ReservationType.transfer;
      case 'admission fratrie':
      case 'sibling admission':
        return ReservationType.siblingAdmission;
      case 'programme spécial':
      case 'special program':
        return ReservationType.specialProgram;
      default:
        return ReservationType.newAdmission;
    }
  }
}

enum ReservationStatus {
  draft('Brouillon'),
  submitted('Soumise'),
  pending('En attente'),
  underReview('En cours de révision'),
  waitlist('Liste d\'attente'),
  confirmed('Confirmée'),
  rejected('Rejetée'),
  cancelled('Annulée'),
  completed('Complétée');

  const ReservationStatus(this.displayName);
  final String displayName;

  static ReservationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'brouillon':
      case 'draft':
        return ReservationStatus.draft;
      case 'soumise':
      case 'submitted':
        return ReservationStatus.submitted;
      case 'en attente':
      case 'pending':
        return ReservationStatus.pending;
      case 'en cours de révision':
      case 'under review':
        return ReservationStatus.underReview;
      case 'liste d\'attente':
      case 'waitlist':
        return ReservationStatus.waitlist;
      case 'confirmée':
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'rejetée':
      case 'rejected':
        return ReservationStatus.rejected;
      case 'annulée':
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'complétée':
      case 'completed':
        return ReservationStatus.completed;
      default:
        return ReservationStatus.draft;
    }
  }
}

/// Informations sur les places disponibles
class PlaceAvailability {
  final String establishmentId;
  final String establishmentName;
  final String grade;
  final String academicYear;
  final int totalPlaces;
  final int availablePlaces;
  final int reservedPlaces;
  final int waitlistCount;
  final DateTime applicationDeadline;
  final double reservationFee;
  final double depositAmount;
  final List<String> requiredDocuments;
  final Map<String, String> admissionCriteria;
  final bool isOpenForApplications;

  PlaceAvailability({
    required this.establishmentId,
    required this.establishmentName,
    required this.grade,
    required this.academicYear,
    required this.totalPlaces,
    required this.availablePlaces,
    required this.reservedPlaces,
    required this.waitlistCount,
    required this.applicationDeadline,
    required this.reservationFee,
    required this.depositAmount,
    required this.requiredDocuments,
    required this.admissionCriteria,
    required this.isOpenForApplications,
  });

  /// Calcule le pourcentage de places disponibles
  double get availabilityPercentage {
    if (totalPlaces == 0) return 0.0;
    return (availablePlaces / totalPlaces) * 100;
  }

  /// Vérifie si des places sont disponibles
  bool get hasAvailablePlaces => availablePlaces > 0;

  /// Vérifie si la date limite est dépassée
  bool get isDeadlinePassed => DateTime.now().isAfter(applicationDeadline);

  /// Retourne le statut de disponibilité
  String get availabilityStatus {
    if (!isOpenForApplications) return 'Fermé';
    if (isDeadlinePassed) return 'Date limite dépassée';
    if (hasAvailablePlaces) return 'Disponible';
    return 'Complet';
  }

  /// Retourne le nombre de places restantes
  int get remainingPlaces => totalPlaces - reservedPlaces;
}

/// Statistiques des réservations
class ReservationStats {
  final String period;
  final int totalReservations;
  final int pendingReservations;
  final int confirmedReservations;
  final int rejectedReservations;
  final int waitlistedReservations;
  final Map<ReservationType, int> reservationsByType;
  final Map<ReservationStatus, int> reservationsByStatus;
  final List<PlaceReservation> recentReservations;
  final double totalRevenue;
  final double pendingRevenue;

  ReservationStats({
    required this.period,
    required this.totalReservations,
    required this.pendingReservations,
    required this.confirmedReservations,
    required this.rejectedReservations,
    required this.waitlistedReservations,
    required this.reservationsByType,
    required this.reservationsByStatus,
    required this.recentReservations,
    required this.totalRevenue,
    required this.pendingRevenue,
  });

  /// Calcule le taux de confirmation
  double get confirmationRate {
    if (totalReservations == 0) return 0.0;
    return (confirmedReservations / totalReservations) * 100;
  }

  /// Calcule le taux de rejet
  double get rejectionRate {
    if (totalReservations == 0) return 0.0;
    return (rejectedReservations / totalReservations) * 100;
  }

  /// Retourne le type de réservation le plus populaire
  ReservationType get mostPopularType {
    if (reservationsByType.isEmpty) return ReservationType.newAdmission;
    
    return reservationsByType.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Retourne le résumé des statistiques
  String get summary {
    return '$totalReservations réservations ($confirmationRate.toStringAsFixed(1)}% confirmées)';
  }
}
