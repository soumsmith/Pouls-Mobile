import 'http_service.dart';

/// Service pour les statistiques de présence des élèves
class StatistiquesPresenceService {
  /// Récupère les statistiques de présence d'un élève
  /// 
  /// [matricule] : le matricule de l'élève
  /// [ecoleCode] : le code de l'école
  static Future<Map<String, dynamic>?> getStatistiquesPresence(
    String matricule,
    String ecoleCode,
  ) async {
    try {
      final response = await HttpService.get(
        '/api/vie-ecoles/statistiques-presence-eleve/$matricule',
        headers: {
          'ecole': ecoleCode,
        },
      );

      if (response['status'] == 1 && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement des statistiques de présence: $e');
      return null;
    }
  }
}
