import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class NotesApiService {
  static const String baseUrl = AppConfig.POULS_SCOLAIRE_API_URL;

  Future<Map<String, dynamic>?> getNotesForStudent({
    required String matricule,
    required String anneeId,
    required String classeId,
    required String periode,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/notes/list-matricule-notes-moyennes/$matricule/?annee=$anneeId&classe=$classeId&periode=$periode',
      );

      print('🌐 Appel API: $url');

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
        print('✅ Données reçues: ${data['details']?.length ?? 0} matières');
        return data;
      } else {
        print('❌ Erreur API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception lors de l\'appel API: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getSchoolYears({required String ecoleId}) async {
    try {
      final url = Uri.parse(
        '$baseUrl/annee/list-opened-or-closed-to-ecole?ecole=$ecoleId',
      );

      print('🌐 Appel API Années Scolaires: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📊 Status code (Années): ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Années scolaires reçues: ${data.length}');
        return data;
      } else {
        print('❌ Erreur API Années: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception lors de l\'appel API Années: $e');
      return null;
    }
  }
}
