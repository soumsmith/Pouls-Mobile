/// Modèle de données pour les logs d'accès des élèves
class AccessLog {
  final String id;
  final String childId;
  final String childName;
  final DateTime timestamp;
  final AccessType accessType;
  final String? location;
  final String? deviceInfo;
  final String? verificationMethod;
  final bool isLate;
  final Duration? delay;
  final String? notes;
  final String? guardianName;
  final String? guardianSignature;

  AccessLog({
    required this.id,
    required this.childId,
    required this.childName,
    required this.timestamp,
    required this.accessType,
    this.location,
    this.deviceInfo,
    this.verificationMethod,
    this.isLate = false,
    this.delay,
    this.notes,
    this.guardianName,
    this.guardianSignature,
  });

  factory AccessLog.fromMap(Map<String, dynamic> map) {
    return AccessLog(
      id: map['id']?.toString() ?? '',
      childId: map['childId']?.toString() ?? '',
      childName: map['childName']?.toString() ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      accessType: AccessType.fromString(map['accessType']?.toString() ?? 'entry'),
      location: map['location']?.toString(),
      deviceInfo: map['deviceInfo']?.toString(),
      verificationMethod: map['verificationMethod']?.toString(),
      isLate: map['isLate'] as bool? ?? false,
      delay: map['delay'] != null 
          ? Duration(seconds: map['delay'] as int? ?? 0)
          : null,
      notes: map['notes']?.toString(),
      guardianName: map['guardianName']?.toString(),
      guardianSignature: map['guardianSignature']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'timestamp': timestamp.toIso8601String(),
      'accessType': accessType.displayName,
      'location': location,
      'deviceInfo': deviceInfo,
      'verificationMethod': verificationMethod,
      'isLate': isLate,
      'delay': delay?.inSeconds,
      'notes': notes,
      'guardianName': guardianName,
      'guardianSignature': guardianSignature,
    };
  }

  AccessLog copyWith({
    String? id,
    String? childId,
    String? childName,
    DateTime? timestamp,
    AccessType? accessType,
    String? location,
    String? deviceInfo,
    String? verificationMethod,
    bool? isLate,
    Duration? delay,
    String? notes,
    String? guardianName,
    String? guardianSignature,
  }) {
    return AccessLog(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      timestamp: timestamp ?? this.timestamp,
      accessType: accessType ?? this.accessType,
      location: location ?? this.location,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      isLate: isLate ?? this.isLate,
      delay: delay ?? this.delay,
      notes: notes ?? this.notes,
      guardianName: guardianName ?? this.guardianName,
      guardianSignature: guardianSignature ?? this.guardianSignature,
    );
  }

  /// Formate l'heure pour l'affichage
  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  /// Formate la date complète pour l'affichage
  String get formattedDate => '${timestamp.day}/${timestamp.month}/${timestamp.year}';

  /// Formate la date et heure complètes
  String get formattedDateTime => '$formattedDate à $formattedTime';

  /// Retourne le statut de ponctualité
  String get punctualityStatus {
    if (!isLate) return 'À l\'heure';
    if (delay != null) {
      final minutes = delay!.inMinutes;
      return 'Retard: ${minutes} min';
    }
    return 'En retard';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AccessLog(id: $id, child: $childName, type: ${accessType.displayName}, time: $formattedDateTime)';
  }
}

enum AccessType {
  entry('Entrée'),
  exit('Sortie'),
  lateEntry('Entrée en retard'),
  earlyExit('Sortie anticipée'),
  absent('Absence'),
  present('Présence');

  const AccessType(this.displayName);
  final String displayName;

  static AccessType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'entrée':
      case 'entry':
        return AccessType.entry;
      case 'sortie':
      case 'exit':
        return AccessType.exit;
      case 'entrée en retard':
      case 'late entry':
        return AccessType.lateEntry;
      case 'sortie anticipée':
      case 'early exit':
        return AccessType.earlyExit;
      case 'absence':
      case 'absent':
        return AccessType.absent;
      case 'présence':
      case 'present':
        return AccessType.present;
      default:
        return AccessType.entry;
    }
  }
}

/// Statistiques des logs d'accès pour une période
class AccessLogStats {
  final String childId;
  final String period;
  final int totalEntries;
  final int totalExits;
  final int lateEntries;
  final int earlyExits;
  final int absences;
  final double attendanceRate;
  final Duration averageDelay;
  final List<AccessLog> recentLogs;

  AccessLogStats({
    required this.childId,
    required this.period,
    required this.totalEntries,
    required this.totalExits,
    required this.lateEntries,
    required this.earlyExits,
    required this.absences,
    required this.attendanceRate,
    required this.averageDelay,
    required this.recentLogs,
  });

  /// Calcule le taux de ponctualité
  double get punctualityRate {
    if (totalEntries == 0) return 0.0;
    return ((totalEntries - lateEntries) / totalEntries) * 100;
  }

  /// Retourne le résumé des absences
  String get absenceSummary {
    if (absences == 0) return 'Aucune absence';
    if (absences == 1) return '1 absence';
    return '$absences absences';
  }

  /// Retourne le résumé des retards
  String get delaySummary {
    if (lateEntries == 0) return 'Aucun retard';
    if (lateEntries == 1) return '1 retard';
    final avgMinutes = averageDelay.inMinutes.round();
    return '$lateEntries retards (moy: ${avgMinutes}min)';
  }
}
