import '../models/place_reservation.dart';

abstract class PlaceReservationService {
  /// Récupère toutes les réservations d'un parent
  Future<List<PlaceReservation>> getParentReservations(String parentId);
  
  /// Récupère les réservations pour un établissement
  Future<List<PlaceReservation>> getEstablishmentReservations(String establishmentId);
  
  /// Récupère les réservations par statut
  Future<List<PlaceReservation>> getReservationsByStatus(ReservationStatus status);
  
  /// Récupère les réservations par type
  Future<List<PlaceReservation>> getReservationsByType(ReservationType type);
  
  /// Récupère les réservations récentes
  Future<List<PlaceReservation>> getRecentReservations(int limit);
  
  /// Crée une nouvelle réservation
  Future<bool> createReservation(PlaceReservation reservation);
  
  /// Met à jour une réservation existante
  Future<bool> updateReservation(PlaceReservation reservation);
  
  /// Supprime une réservation
  Future<bool> deleteReservation(String reservationId);
  
  /// Soumet une réservation pour examen
  Future<bool> submitReservation(String reservationId);
  
  /// Annule une réservation
  Future<bool> cancelReservation(String reservationId, String reason);
  
  /// Récupère les disponibilités de places
  Future<List<PlaceAvailability>> getPlaceAvailability({
    String? establishmentId,
    String? academicYear,
    String? grade,
  });
  
  /// Vérifie l'éligibilité d'un enfant
  Future<Map<String, dynamic>> checkEligibility(String childId, String establishmentId, String grade);
  
  /// Calcule les frais de réservation
  Future<Map<String, double>> calculateReservationFees(String establishmentId, String grade, ReservationType type);
  
  /// Traite le paiement d'un acompte
  Future<bool> processDepositPayment(String reservationId, String paymentReference);
  
  /// Télécharge un document
  Future<bool> uploadDocument(String reservationId, String documentType, String documentUrl);
  
  /// Récupère les statistiques des réservations
  Future<ReservationStats> getReservationStats(String period, {String? establishmentId});
  
  /// Recherche des réservations
  Future<List<PlaceReservation>> searchReservations(String query, {
    ReservationStatus? status,
    ReservationType? type,
    String? establishmentId,
    String? academicYear,
  });
  
  /// Exporte les réservations au format CSV
  Future<String> exportReservationsToCSV({
    String? establishmentId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class MockPlaceReservationService implements PlaceReservationService {
  static final MockPlaceReservationService _instance = MockPlaceReservationService._internal();
  factory MockPlaceReservationService() => _instance;
  MockPlaceReservationService._internal();

  static final List<PlaceReservation> _mockReservations = [
    PlaceReservation(
      id: '1',
      parentId: 'parent1',
      parentName: 'Marie Dupont',
      childId: 'child1',
      childName: 'Jean Dupont',
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      academicYear: '2024-2025',
      grade: 'CP',
      type: ReservationType.newAdmission,
      status: ReservationStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      submittedAt: DateTime.now().subtract(const Duration(days: 29)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 25)),
      deadline: DateTime.now().subtract(const Duration(days: 20)),
      requiredDocuments: {
        'birth_certificate': 'Certificat de naissance',
        'vaccination_record': 'Carnet de vaccination',
        'proof_of_residence': 'Justificatif de domicile',
      },
      submittedDocuments: {
        'birth_certificate': 'https://example.com/doc1.pdf',
        'vaccination_record': 'https://example.com/doc2.pdf',
        'proof_of_residence': 'https://example.com/doc3.pdf',
      },
      reservationFee: 50.0,
      depositAmount: 200.0,
      isDepositPaid: true,
      paymentReference: 'PAY_2024_001',
      priorityScore: 85,
    ),
    PlaceReservation(
      id: '2',
      parentId: 'parent2',
      parentName: 'Pierre Martin',
      childId: 'child2',
      childName: 'Sophie Martin',
      establishmentId: 'school2',
      establishmentName: 'Collège Victor Hugo',
      academicYear: '2024-2025',
      grade: '6ème',
      type: ReservationType.transfer,
      status: ReservationStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      submittedAt: DateTime.now().subtract(const Duration(days: 14)),
      deadline: DateTime.now().add(const Duration(days: 10)),
      requiredDocuments: {
        'transfer_certificate': 'Certificat de transfert',
        'last_report_card': 'Dernier bulletin scolaire',
        'vaccination_record': 'Carnet de vaccination',
      },
      submittedDocuments: {
        'transfer_certificate': 'https://example.com/doc4.pdf',
      },
      reservationFee: 75.0,
      depositAmount: 300.0,
      isDepositPaid: false,
      priorityScore: 72,
      waitlistPosition: '3',
    ),
    PlaceReservation(
      id: '3',
      parentId: 'parent3',
      parentName: 'Sophie Bernard',
      childId: 'child3',
      childName: 'Lucas Bernard',
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      academicYear: '2024-2025',
      grade: 'CE1',
      type: ReservationType.siblingAdmission,
      status: ReservationStatus.waitlist,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      submittedAt: DateTime.now().subtract(const Duration(days: 9)),
      deadline: DateTime.now().add(const Duration(days: 5)),
      requiredDocuments: {
        'birth_certificate': 'Certificat de naissance',
        'vaccination_record': 'Carnet de vaccination',
        'sibling_proof': 'Preuve de fratrie',
      },
      submittedDocuments: {
        'birth_certificate': 'https://example.com/doc5.pdf',
        'vaccination_record': 'https://example.com/doc6.pdf',
      },
      reservationFee: 50.0,
      depositAmount: 200.0,
      isDepositPaid: false,
      priorityScore: 90,
      waitlistPosition: '1',
    ),
    PlaceReservation(
      id: '4',
      parentId: 'parent4',
      parentName: 'Thomas Petit',
      childId: 'child4',
      childName: 'Emma Petit',
      establishmentId: 'school3',
      establishmentName: 'Lycée Marie Curie',
      academicYear: '2024-2025',
      grade: 'Seconde',
      type: ReservationType.newAdmission,
      status: ReservationStatus.rejected,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      submittedAt: DateTime.now().subtract(const Duration(days: 19)),
      rejectedAt: DateTime.now().subtract(const Duration(days: 18)),
      rejectionReason: 'Places complètes pour cette classe',
      deadline: DateTime.now().subtract(const Duration(days: 15)),
      requiredDocuments: {
        'birth_certificate': 'Certificat de naissance',
        'last_report_card': 'Dernier bulletin scolaire',
        'recommendation_letter': 'Lettre de recommandation',
      },
      submittedDocuments: {
        'birth_certificate': 'https://example.com/doc7.pdf',
        'last_report_card': 'https://example.com/doc8.pdf',
      },
      reservationFee: 100.0,
      depositAmount: 500.0,
      isDepositPaid: false,
      priorityScore: 65,
    ),
    PlaceReservation(
      id: '5',
      parentId: 'parent5',
      parentName: 'Isabelle Laurent',
      childId: 'child5',
      childName: 'Hugo Laurent',
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      academicYear: '2024-2025',
      grade: 'CP',
      type: ReservationType.reEnrollment,
      status: ReservationStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      requiredDocuments: {
        'current_report_card': 'Bulletin scolaire actuel',
        're_enrollment_form': 'Formulaire de réinscription',
      },
      submittedDocuments: {},
      reservationFee: 25.0,
      depositAmount: 100.0,
      isDepositPaid: false,
      priorityScore: 95,
    ),
  ];

  static final List<PlaceAvailability> _mockAvailability = [
    PlaceAvailability(
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      grade: 'CP',
      academicYear: '2024-2025',
      totalPlaces: 30,
      availablePlaces: 5,
      reservedPlaces: 25,
      waitlistCount: 8,
      applicationDeadline: DateTime.now().add(const Duration(days: 30)),
      reservationFee: 50.0,
      depositAmount: 200.0,
      requiredDocuments: [
        'Certificat de naissance',
        'Carnet de vaccination',
        'Justificatif de domicile',
      ],
      admissionCriteria: {
        'age_minimum': '6 ans au 31 décembre',
        'zone_prioritaire': 'Zone A',
        'fratrie_prioritaire': 'Oui',
      },
      isOpenForApplications: true,
    ),
    PlaceAvailability(
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      grade: 'CE1',
      academicYear: '2024-2025',
      totalPlaces: 30,
      availablePlaces: 2,
      reservedPlaces: 28,
      waitlistCount: 12,
      applicationDeadline: DateTime.now().add(const Duration(days: 30)),
      reservationFee: 50.0,
      depositAmount: 200.0,
      requiredDocuments: [
        'Certificat de naissance',
        'Carnet de vaccination',
        'Justificatif de domicile',
      ],
      admissionCriteria: {
        'age_minimum': '7 ans au 31 décembre',
        'zone_prioritaire': 'Zone A',
        'fratrie_prioritaire': 'Oui',
      },
      isOpenForApplications: true,
    ),
    PlaceAvailability(
      establishmentId: 'school2',
      establishmentName: 'Collège Victor Hugo',
      grade: '6ème',
      academicYear: '2024-2025',
      totalPlaces: 120,
      availablePlaces: 15,
      reservedPlaces: 105,
      waitlistCount: 25,
      applicationDeadline: DateTime.now().add(const Duration(days: 45)),
      reservationFee: 75.0,
      depositAmount: 300.0,
      requiredDocuments: [
        'Certificat de naissance',
        'Dernier bulletin scolaire',
        'Carnet de vaccination',
      ],
      admissionCriteria: {
        'age_minimum': '11 ans au 31 décembre',
        'diplome_fin_cycle': 'Oui',
        'zone_prioritaire': 'Zone B',
      },
      isOpenForApplications: true,
    ),
    PlaceAvailability(
      establishmentId: 'school3',
      establishmentName: 'Lycée Marie Curie',
      grade: 'Seconde',
      academicYear: '2024-2025',
      totalPlaces: 150,
      availablePlaces: 0,
      reservedPlaces: 150,
      waitlistCount: 45,
      applicationDeadline: DateTime.now().subtract(const Duration(days: 10)),
      reservationFee: 100.0,
      depositAmount: 500.0,
      requiredDocuments: [
        'Certificat de naissance',
        'Dernier bulletin scolaire',
        'Lettre de recommandation',
      ],
      admissionCriteria: {
        'age_minimum': '15 ans au 31 décembre',
        'brevet_obligatoire': 'Oui',
        'moyenne_minimum': '12/20',
      },
      isOpenForApplications: false,
    ),
  ];

  @override
  Future<List<PlaceReservation>> getParentReservations(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockReservations.where((reservation) => reservation.parentId == parentId).toList();
  }

  @override
  Future<List<PlaceReservation>> getEstablishmentReservations(String establishmentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockReservations.where((reservation) => reservation.establishmentId == establishmentId).toList();
  }

  @override
  Future<List<PlaceReservation>> getReservationsByStatus(ReservationStatus status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockReservations.where((reservation) => reservation.status == status).toList();
  }

  @override
  Future<List<PlaceReservation>> getReservationsByType(ReservationType type) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockReservations.where((reservation) => reservation.type == type).toList();
  }

  @override
  Future<List<PlaceReservation>> getRecentReservations(int limit) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sortedReservations = List<PlaceReservation>.from(_mockReservations)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedReservations.take(limit).toList();
  }

  @override
  Future<bool> createReservation(PlaceReservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      _mockReservations.add(reservation);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateReservation(PlaceReservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final index = _mockReservations.indexWhere((r) => r.id == reservation.id);
      if (index != -1) {
        _mockReservations[index] = reservation;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteReservation(String reservationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _mockReservations.removeWhere((reservation) => reservation.id == reservationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> submitReservation(String reservationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final reservation = _mockReservations.firstWhere((r) => r.id == reservationId);
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.submitted,
        submittedAt: DateTime.now(),
      );
      final index = _mockReservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _mockReservations[index] = updatedReservation;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelReservation(String reservationId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final reservation = _mockReservations.firstWhere((r) => r.id == reservationId);
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.cancelled,
      );
      final index = _mockReservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _mockReservations[index] = updatedReservation;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PlaceAvailability>> getPlaceAvailability({
    String? establishmentId,
    String? academicYear,
    String? grade,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    var availability = _mockAvailability;
    
    if (establishmentId != null) {
      availability = availability.where((a) => a.establishmentId == establishmentId).toList();
    }
    
    if (academicYear != null) {
      availability = availability.where((a) => a.academicYear == academicYear).toList();
    }
    
    if (grade != null) {
      availability = availability.where((a) => a.grade == grade).toList();
    }
    
    return availability;
  }

  @override
  Future<Map<String, dynamic>> checkEligibility(String childId, String establishmentId, String grade) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simulation de vérification d'éligibilité
    return {
      'isEligible': true,
      'priorityScore': 85,
      'eligibilityReasons': [
        'Âge approprié pour la classe',
        'Zone prioritaire respectée',
        'Documents requis disponibles',
      ],
      'missingRequirements': [],
      'estimatedWaitlistPosition': null,
    };
  }

  @override
  Future<Map<String, double>> calculateReservationFees(String establishmentId, String grade, ReservationType type) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Simulation de calcul des frais
    double reservationFee = 50.0;
    double depositAmount = 200.0;
    
    // Ajustement selon le type
    switch (type) {
      case ReservationType.newAdmission:
        reservationFee = 50.0;
        depositAmount = 200.0;
        break;
      case ReservationType.reEnrollment:
        reservationFee = 25.0;
        depositAmount = 100.0;
        break;
      case ReservationType.transfer:
        reservationFee = 75.0;
        depositAmount = 300.0;
        break;
      case ReservationType.siblingAdmission:
        reservationFee = 25.0;
        depositAmount = 150.0;
        break;
      case ReservationType.specialProgram:
        reservationFee = 100.0;
        depositAmount = 500.0;
        break;
    }
    
    return {
      'reservationFee': reservationFee,
      'depositAmount': depositAmount,
      'totalAmount': reservationFee + depositAmount,
    };
  }

  @override
  Future<bool> processDepositPayment(String reservationId, String paymentReference) async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final reservation = _mockReservations.firstWhere((r) => r.id == reservationId);
      final updatedReservation = reservation.copyWith(
        isDepositPaid: true,
        paymentReference: paymentReference,
      );
      final index = _mockReservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _mockReservations[index] = updatedReservation;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> uploadDocument(String reservationId, String documentType, String documentUrl) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final reservation = _mockReservations.firstWhere((r) => r.id == reservationId);
      final updatedSubmittedDocuments = Map<String, dynamic>.from(reservation.submittedDocuments);
      updatedSubmittedDocuments[documentType] = documentUrl;
      
      final updatedReservation = reservation.copyWith(
        submittedDocuments: updatedSubmittedDocuments,
      );
      final index = _mockReservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _mockReservations[index] = updatedReservation;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<ReservationStats> getReservationStats(String period, {String? establishmentId}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    var filteredReservations = establishmentId != null
        ? _mockReservations.where((r) => r.establishmentId == establishmentId).toList()
        : _mockReservations;
    
    final totalReservations = filteredReservations.length;
    final pendingReservations = filteredReservations.where((r) => r.isPending).length;
    final confirmedReservations = filteredReservations.where((r) => r.isConfirmed).length;
    final rejectedReservations = filteredReservations.where((r) => r.isRejected).length;
    final waitlistedReservations = filteredReservations.where((r) => r.isWaitlisted).length;
    
    // Statistiques par type
    final reservationsByType = <ReservationType, int>{};
    for (final type in ReservationType.values) {
      reservationsByType[type] = filteredReservations.where((r) => r.type == type).length;
    }
    
    // Statistiques par statut
    final reservationsByStatus = <ReservationStatus, int>{};
    for (final status in ReservationStatus.values) {
      reservationsByStatus[status] = filteredReservations.where((r) => r.status == status).length;
    }
    
    // Réservations récentes
    final recentReservations = List<PlaceReservation>.from(filteredReservations)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Calcul des revenus
    final totalRevenue = filteredReservations
        .where((r) => r.isDepositPaid && r.depositAmount != null)
        .fold<double>(0.0, (sum, r) => sum + r.depositAmount!);
    
    final pendingRevenue = filteredReservations
        .where((r) => !r.isDepositPaid && r.depositAmount != null)
        .fold<double>(0.0, (sum, r) => sum + r.depositAmount!);
    
    return ReservationStats(
      period: period,
      totalReservations: totalReservations,
      pendingReservations: pendingReservations,
      confirmedReservations: confirmedReservations,
      rejectedReservations: rejectedReservations,
      waitlistedReservations: waitlistedReservations,
      reservationsByType: reservationsByType,
      reservationsByStatus: reservationsByStatus,
      recentReservations: recentReservations.take(10).toList(),
      totalRevenue: totalRevenue,
      pendingRevenue: pendingRevenue,
    );
  }

  @override
  Future<List<PlaceReservation>> searchReservations(String query, {
    ReservationStatus? status,
    ReservationType? type,
    String? establishmentId,
    String? academicYear,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    var filteredReservations = _mockReservations;
    
    if (establishmentId != null) {
      filteredReservations = filteredReservations.where((r) => r.establishmentId == establishmentId).toList();
    }
    
    if (status != null) {
      filteredReservations = filteredReservations.where((r) => r.status == status).toList();
    }
    
    if (type != null) {
      filteredReservations = filteredReservations.where((r) => r.type == type).toList();
    }
    
    if (academicYear != null) {
      filteredReservations = filteredReservations.where((r) => r.academicYear == academicYear).toList();
    }
    
    if (query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      filteredReservations = filteredReservations.where((reservation) =>
        reservation.childName.toLowerCase().contains(searchQuery) ||
        reservation.parentName.toLowerCase().contains(searchQuery) ||
        reservation.establishmentName.toLowerCase().contains(searchQuery) ||
        reservation.grade.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return filteredReservations;
  }

  @override
  Future<String> exportReservationsToCSV({
    String? establishmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    var filteredReservations = _mockReservations;
    
    if (establishmentId != null) {
      filteredReservations = filteredReservations.where((r) => r.establishmentId == establishmentId).toList();
    }
    
    if (startDate != null) {
      filteredReservations = filteredReservations.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      filteredReservations = filteredReservations.where((r) => r.createdAt.isBefore(endDate)).toList();
    }
    
    final csvData = StringBuffer();
    csvData.writeln('Enfant,Parent,Établissement,Classe,Type,Statut,Date de création,Frais réservation,Acompte,Paiement acompte');
    
    for (final reservation in filteredReservations) {
      csvData.writeln(
        '"${reservation.childName}",'
        '"${reservation.parentName}",'
        '"${reservation.establishmentName}",'
        '"${reservation.grade}",'
        '"${reservation.type.displayName}",'
        '"${reservation.status.displayName}",'
        '${reservation.formattedCreatedAt},'
        '${reservation.reservationFee ?? 0},'
        '${reservation.depositAmount ?? 0},'
        '"${reservation.paymentStatus}"'
      );
    }
    
    return csvData.toString();
  }

  /// Méthode utilitaire pour générer des réservations de test
  Future<void> generateTestReservations(String parentId, String parentName, int count) async {
    final types = ReservationType.values;
    final statuses = ReservationStatus.values;
    final establishments = ['school1', 'school2', 'school3'];
    final grades = ['CP', 'CE1', 'CE2', 'CM1', 'CM2', '6ème', '5ème'];
    
    for (int i = 0; i < count; i++) {
      final reservation = PlaceReservation(
        id: 'test_reservation_${parentId}_$i',
        parentId: parentId,
        parentName: parentName,
        childId: 'child_test_$i',
        childName: 'Enfant test $i',
        establishmentId: establishments[i % establishments.length],
        establishmentName: 'Établissement test',
        academicYear: '2024-2025',
        grade: grades[i % grades.length],
        type: types[i % types.length],
        status: statuses[i % statuses.length],
        createdAt: DateTime.now().subtract(Duration(days: i)),
        reservationFee: 50.0 + (i * 10),
        depositAmount: 200.0 + (i * 50),
        isDepositPaid: i % 2 == 0,
      );
      
      _mockReservations.add(reservation);
    }
  }
}
