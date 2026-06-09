import '../models/gestion_presence_eleve_entry.dart';
import 'http_service.dart';

class GestionPresenceEleveService {
  static Future<List<GestionPresenceEleveEntry>> getGestionPresenceEleve(
    String matricule,
    String ecoleCode, {
    String? date,
    String? type,
    String? dateDebut,
    String? dateFin,
  }) async {
    print('📡 Chargement présence/absence: matricule=$matricule, ecole=$ecoleCode, date=$date, type=$type, date_debut=$dateDebut, date_fin=$dateFin');
    
    // Default dates if none provided: last month to today
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    final String effectiveDateDebut = dateDebut ?? '${oneMonthAgo.year}-${oneMonthAgo.month.toString().padLeft(2, '0')}-${oneMonthAgo.day.toString().padLeft(2, '0')}';
    final String effectiveDateFin = dateFin ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    var endpoint = '/vie-ecoles/gestion-presence-eleve/$matricule?ecole=$ecoleCode&date_debut=$effectiveDateDebut&date_fin=$effectiveDateFin';
    
    if (date != null && date.isNotEmpty) {
      endpoint += '&date=$date';
    }
    if (type != null && type.isNotEmpty) {
      endpoint += '&type=$type';
    }
    print('🌐 Endpoint complet: ${HttpService.baseUrl}$endpoint');
    try {
      final response = await HttpService.get(endpoint);

      if (response['status'] == 1 && response['data'] is List) {
        final data = response['data'] as List;
        final entries = data
            .whereType<Map>()
            .map((e) => GestionPresenceEleveEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
        print('✅ Présence/absence: ${entries.length} entrée(s) reçue(s) pour $matricule');
        return entries;
      } else {
        print('⚠️ Présence/absence: statut inattendu ou data vide pour $matricule');
        return [];
      }
    } catch (e) {
      print('❌ Erreur API présence/absence pour $matricule: $e');
      return [];
    }
  }
}
