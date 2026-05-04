import 'dart:convert';
import 'http_service.dart';

class StatistiquesPresence {
  final int totalSeances;
  final String totalPresent;
  final String totalAbsent;
  final double tauxPresence;
  final double tauxAbsence;

  StatistiquesPresence({
    required this.totalSeances,
    required this.totalPresent,
    required this.totalAbsent,
    required this.tauxPresence,
    required this.tauxAbsence,
  });

  factory StatistiquesPresence.fromJson(Map<String, dynamic> json) {
    return StatistiquesPresence(
      totalSeances: json['total_seances'] ?? 0,
      totalPresent: json['total_present']?.toString() ?? '0',
      totalAbsent: json['total_absent']?.toString() ?? '0',
      tauxPresence: (json['taux_presence'] ?? 0.0).toDouble(),
      tauxAbsence: (json['taux_absence'] ?? 0.0).toDouble(),
    );
  }
}

/// Service pour les statistiques de présence des élèves
class StatistiquesPresenceService {
  /// Récupère les statistiques de présence d'un élève
  /// 
  /// [matricule] : le matricule de l'élève
  /// [ecoleCode] : le code de l'école
  static Future<StatistiquesPresence?> getStatistiquesPresence(
    String matricule,
    String ecoleCode,
  ) async {
    try {
      print('📊 Chargement statistiques présence: matricule=$matricule, ecole=$ecoleCode');
      
      final response = await HttpService.get(
        '/vie-ecoles/statistiques-presence-eleve/$matricule?ecole=$ecoleCode',
      );

      if (response['status'] == 1 && response['data'] != null) {
        final statistiques = StatistiquesPresence.fromJson(response['data'] as Map<String, dynamic>);
        print('✅ Statistiques présence chargées: ${statistiques.tauxPresence}% présence');
        return statistiques;
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors du chargement des statistiques de présence: $e');
      return null;
    }
  }
}
