import '../models/access_log.dart';

abstract class AccessLogService {
  /// Récupère tous les logs d'accès pour un enfant
  Future<List<AccessLog>> getAccessLogsForChild(String childId);
  
  /// Récupère les logs d'accès pour une période spécifique
  Future<List<AccessLog>> getAccessLogsForChildInPeriod(String childId, DateTime startDate, DateTime endDate);
  
  /// Récupère les logs d'accès du jour
  Future<List<AccessLog>> getTodayAccessLogs(String childId);
  
  /// Récupère les logs d'accès récents (derniers 7 jours)
  Future<List<AccessLog>> getRecentAccessLogs(String childId);
  
  /// Calcule les statistiques d'accès pour une période
  Future<AccessLogStats> getAccessLogStats(String childId, String period);
  
  /// Ajoute un nouveau log d'accès
  Future<bool> addAccessLog(AccessLog accessLog);
  
  /// Marque un log comme consulté par le parent
  Future<bool> markLogAsViewed(String logId, String parentId);
  
  /// Vérifie si un log a été consulté
  Future<bool> isLogViewed(String logId, String parentId);
  
  /// Exporte les logs d'accès au format CSV
  Future<String> exportAccessLogsToCSV(String childId, DateTime startDate, DateTime endDate);
  
  /// Recherche des logs par critères
  Future<List<AccessLog>> searchAccessLogs(String childId, {
    AccessType? accessType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLate,
  });
}

class MockAccessLogService implements AccessLogService {
  static final MockAccessLogService _instance = MockAccessLogService._internal();
  factory MockAccessLogService() => _instance;
  MockAccessLogService._internal();

  static final List<AccessLog> _mockLogs = [
    // Aujourd'hui
    AccessLog(
      id: '1',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(hours: 8)),
      accessType: AccessType.entry,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Entrée normale',
    ),
    AccessLog(
      id: '2',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(hours: 4)),
      accessType: AccessType.exit,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Sortie pour déjeuner',
    ),
    AccessLog(
      id: '3',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      accessType: AccessType.entry,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Retour de déjeuner',
    ),
    
    // Hier
    AccessLog(
      id: '4',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 8)),
      accessType: AccessType.lateEntry,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: true,
      delay: Duration(minutes: 15),
      notes: 'Retard de 15 minutes',
    ),
    AccessLog(
      id: '5',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 16)),
      accessType: AccessType.exit,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Sortie normale',
    ),
    
    // Il y a 2 jours
    AccessLog(
      id: '6',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(days: 2, hours: 8)),
      accessType: AccessType.entry,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Entrée normale',
    ),
    AccessLog(
      id: '7',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(days: 2, hours: 15, minutes: 30)),
      accessType: AccessType.earlyExit,
      location: 'Portail Principal',
      deviceInfo: 'Badge RFID #1234',
      verificationMethod: 'Badge + Signature Parent',
      isLate: false,
      guardianName: 'Marie Dupont',
      guardianSignature: 'signature_data_123',
      notes: 'Sortie anticipée pour rendez-vous médical',
    ),
    
    // Il y a 3 jours (absence)
    AccessLog(
      id: '8',
      childId: 'child1',
      childName: 'Jean Dupont',
      timestamp: DateTime.now().subtract(Duration(days: 3, hours: 8)),
      accessType: AccessType.absent,
      location: 'Bureau du Directeur',
      deviceInfo: 'Justificatif médical',
      verificationMethod: 'Parent',
      isLate: false,
      notes: 'Absence justifiée - maladie',
      guardianName: 'Marie Dupont',
    ),
    
    // Logs pour un autre enfant (pour tests)
    AccessLog(
      id: '9',
      childId: 'child2',
      childName: 'Marie Durand',
      timestamp: DateTime.now().subtract(Duration(hours: 8)),
      accessType: AccessType.entry,
      location: 'Portail Secondaire',
      deviceInfo: 'Badge RFID #5678',
      verificationMethod: 'Badge',
      isLate: false,
      notes: 'Entrée normale',
    ),
  ];

  @override
  Future<List<AccessLog>> getAccessLogsForChild(String childId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLogs.where((log) => log.childId == childId).toList();
  }

  @override
  Future<List<AccessLog>> getAccessLogsForChildInPeriod(
    String childId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockLogs.where((log) {
      return log.childId == childId &&
             log.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             log.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<AccessLog>> getTodayAccessLogs(String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _mockLogs.where((log) {
      return log.childId == childId &&
             log.timestamp.isAfter(today) &&
             log.timestamp.isBefore(tomorrow);
    }).toList();
  }

  @override
  Future<List<AccessLog>> getRecentAccessLogs(String childId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return _mockLogs.where((log) {
      return log.childId == childId && log.timestamp.isAfter(sevenDaysAgo);
    }).toList();
  }

  @override
  Future<AccessLogStats> getAccessLogStats(String childId, String period) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final logs = await getRecentAccessLogs(childId);
    
    final totalEntries = logs.where((log) => 
      log.accessType == AccessType.entry || log.accessType == AccessType.lateEntry
    ).length;
    
    final totalExits = logs.where((log) => 
      log.accessType == AccessType.exit || log.accessType == AccessType.earlyExit
    ).length;
    
    final lateEntries = logs.where((log) => 
      log.accessType == AccessType.lateEntry
    ).length;
    
    final earlyExits = logs.where((log) => 
      log.accessType == AccessType.earlyExit
    ).length;
    
    final absences = logs.where((log) => 
      log.accessType == AccessType.absent
    ).length;
    
    // Calcul du taux de présence
    final totalSchoolDays = 7; // Simplifié
    final attendanceRate = ((totalSchoolDays - absences) / totalSchoolDays) * 100;
    
    // Calcul du retard moyen
    final lateLogs = logs.where((log) => log.isLate && log.delay != null);
    final avgDelay = lateLogs.isNotEmpty
        ? Duration(
            seconds: lateLogs
                .map((log) => log.delay!.inSeconds)
                .reduce((a, b) => a + b) ~/ lateLogs.length
          )
        : Duration.zero;
    
    return AccessLogStats(
      childId: childId,
      period: period,
      totalEntries: totalEntries,
      totalExits: totalExits,
      lateEntries: lateEntries,
      earlyExits: earlyExits,
      absences: absences,
      attendanceRate: attendanceRate,
      averageDelay: avgDelay,
      recentLogs: logs.take(10).toList(),
    );
  }

  @override
  Future<bool> addAccessLog(AccessLog accessLog) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _mockLogs.add(accessLog);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> markLogAsViewed(String logId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulation de marquage comme consulté
    return true;
  }

  @override
  Future<bool> isLogViewed(String logId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulation: retourne false pour les nouveaux logs
    return false;
  }

  @override
  Future<String> exportAccessLogsToCSV(
    String childId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final logs = await getAccessLogsForChildInPeriod(childId, startDate, endDate);
    
    final csvData = StringBuffer();
    csvData.writeln('Date,Heure,Type,Location,Méthode,Retard,Notes');
    
    for (final log in logs) {
      csvData.writeln(
        '${log.formattedDate},'
        '${log.formattedTime},'
        '${log.accessType.displayName},'
        '${log.location ?? ''},'
        '${log.verificationMethod ?? ''},'
        '${log.punctualityStatus},'
        '"${log.notes ?? ''}"'
      );
    }
    
    return csvData.toString();
  }

  @override
  Future<List<AccessLog>> searchAccessLogs(
    String childId, {
    AccessType? accessType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    var filteredLogs = _mockLogs.where((log) => log.childId == childId).toList();
    
    if (accessType != null) {
      filteredLogs = filteredLogs.where((log) => log.accessType == accessType).toList();
    }
    
    if (startDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }
    
    if (isLate != null) {
      filteredLogs = filteredLogs.where((log) => log.isLate == isLate).toList();
    }
    
    return filteredLogs;
  }

  /// Méthode utilitaire pour générer des logs de test
  Future<void> generateTestLogs(String childId, String childName, int days) async {
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Log d'entrée
      final entryLog = AccessLog(
        id: 'entry_${childId}_$i',
        childId: childId,
        childName: childName,
        timestamp: DateTime(date.year, date.month, date.day, 8, 0 + (i % 30)),
        accessType: i % 5 == 0 ? AccessType.lateEntry : AccessType.entry,
        location: 'Portail Principal',
        deviceInfo: 'Badge RFID #${childId.hashCode}',
        verificationMethod: 'Badge',
        isLate: i % 5 == 0,
        delay: i % 5 == 0 ? Duration(minutes: 10 + (i % 20)) : null,
        notes: i % 5 == 0 ? 'Retard de ${(10 + (i % 20))} minutes' : 'Entrée normale',
      );
      
      _mockLogs.add(entryLog);
      
      // Log de sortie
      final exitLog = AccessLog(
        id: 'exit_${childId}_$i',
        childId: childId,
        childName: childName,
        timestamp: DateTime(date.year, date.month, date.day, 16, 30 - (i % 15)),
        accessType: i % 7 == 0 ? AccessType.earlyExit : AccessType.exit,
        location: 'Portail Principal',
        deviceInfo: 'Badge RFID #${childId.hashCode}',
        verificationMethod: 'Badge',
        isLate: false,
        notes: i % 7 == 0 ? 'Sortie anticipée' : 'Sortie normale',
      );
      
      _mockLogs.add(exitLog);
    }
  }
}
