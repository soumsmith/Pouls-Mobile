import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class BulletinApiService {
  static const String baseUrl = AppConfig.POULS_SCOLAIRE_API_URL;

  Future<List<dynamic>?> getBulletinsForStudent({
    required String annee,
    required String classe,
    required String matricule,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/bulletin/get-bulletins-eleve-annee?annee=$annee&classe=$classe&matricule=$matricule',
      );

      print('🌐 Appel API Bulletins: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📊 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Données bulletins reçues: ${data.length} bulletin(s)');
        return data;
      } else {
        print('❌ Erreur API Bulletins: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception lors de l\'appel API Bulletins: $e');
      return null;
    }
  }
}
