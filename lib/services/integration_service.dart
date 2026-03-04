import 'dart:convert';
import 'package:http/http.dart' as http;

class IntegrationService {
  static Future<Map<String, dynamic>> submitIntegrationRequest(
    String ecoleCode, 
    Map<String, dynamic> requestData
  ) async {
    final url = Uri.parse('https://api2.vie-ecoles.com/api/preinscription/demande-integration?ecole=$ecoleCode');
    
    print('🌐 URL de l\'API: $url');
    print('📤 Headers: Content-Type: application/json, Accept: application/json');
    print('📋 Corps de la requête: ${jsonEncode(requestData)}');
    
    try {
      print('⏳ Début de l\'appel HTTP POST...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('📥 Réponse HTTP reçue - Status: ${response.statusCode}');
      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Parse JSON réussi: $responseData');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}, Body: ${response.body}');
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      print('💥 Exception dans IntegrationService: $e');
      return {
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }
}
