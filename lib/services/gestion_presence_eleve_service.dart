import '../models/gestion_presence_eleve_entry.dart';
import 'http_service.dart';

class GestionPresenceEleveService {
  static Future<List<GestionPresenceEleveEntry>> getGestionPresenceEleve(
    String matricule,
    String ecoleCode,
  ) async {
    print('📡 Chargement présence/absence: matricule=$matricule, ecole=$ecoleCode');
    final endpoint = '/vie-ecoles/gestion-presence-eleve/$matricule?ecole=$ecoleCode';
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
