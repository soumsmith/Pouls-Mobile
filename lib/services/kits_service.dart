import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../utils/api_exception_handler.dart';
import '../config/app_config.dart';

class KitsService {
  /// Récupère les kits scolaires pour une école et un niveau donnés
  static Future<List<Map<String, dynamic>>> getKitsByNiveau(String ecole, String niveau) async {
    final encodedEcole = Uri.encodeComponent(ecole);
    final encodedNiveau = Uri.encodeComponent(niveau);
    final url = '${AppConfig.VIE_ECOLES_API_BASE_URL}/ecoles/kits-disponibles?ecole=$encodedEcole&niveau=$encodedNiveau';
    print('🔗 URL (GET): $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        
        List<dynamic> dataList = [];
        
        // Gérer les différents formats possibles de réponse
        if (decodedBody is List) {
          dataList = decodedBody;
        } else if (decodedBody is Map) {
          if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
            dataList = decodedBody['data'];
          } else if (decodedBody.containsKey('kits') && decodedBody['kits'] is List) {
            dataList = decodedBody['kits'];
          } else {
            // Tenter de le transformer en liste si c'est un seul objet
            dataList = [decodedBody];
          }
        }

        print('✅ Kits récupérés avec succès: ${dataList.length} articles');
        return dataList.cast<Map<String, dynamic>>();
      } else {
        print('❌ Erreur HTTP ${response.statusCode} lors de la récupération des kits');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des kits: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des kits scolaires');
      throw Exception('Erreur lors de la récupération des kits: $e');
    }
  }
}
