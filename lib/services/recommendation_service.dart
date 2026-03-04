import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class RecommendationService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  static Future<Map<String, dynamic>> submitRecommendation({
    required String etablissement,
    required String pays,
    required String ville,
    required String ordre,
    required String adresseEtablissement,
    required String nomParent,
    required String prenomParent,
    required String telephone,
    required String email,
    required String paysParent,
    required String villeParent,
    required String adresseParent,
  }) async {
    // Préparer les données
    final Map<String, dynamic> requestData = {
      'etablissement': etablissement,
      'pays': pays,
      'ville': ville,
      'ordre': ordre,
      'adresseEtablissement': adresseEtablissement,
      'nomParent': nomParent,
      'prenomParent': prenomParent,
      'telephone': telephone,
      'email': email,
      'paysParent': paysParent,
      'villeParent': villeParent,
      'adresseParent': adresseParent,
    };
    
    // Logger les données de la requête
    developer.log('🚀 Envoi de la recommandation...', name: 'RecommendationService');
    developer.log('URL: $baseUrl/ecoles/nonpartenaires', name: 'RecommendationService');
    developer.log('Données envoyées: ${jsonEncode(requestData)}', name: 'RecommendationService');
    
    try {
      developer.log('📡 Envoi de la requête POST...', name: 'RecommendationService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/ecoles/nonpartenaires'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      // Logger la réponse
      developer.log('📥 Réponse reçue - Status: ${response.statusCode}', name: 'RecommendationService');
      developer.log('📄 Corps de la réponse: ${response.body}', name: 'RecommendationService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log('✅ Succès - Données décodées: $data', name: 'RecommendationService');
        return {
          'success': true,
          'data': data,
          'message': 'Recommandation envoyée avec succès!',
          'statusCode': response.statusCode,
        };
      } else {
        developer.log('❌ Erreur HTTP - Status: ${response.statusCode}', name: 'RecommendationService');
        developer.log('❌ Corps d\'erreur: ${response.body}', name: 'RecommendationService');
        return {
          'success': false,
          'message': 'Erreur HTTP: ${response.statusCode}',
          'error': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      developer.log('💥 Exception lors de l\'envoi: $e', name: 'RecommendationService');
      developer.log('💥 Stack trace: ${StackTrace.current}', name: 'RecommendationService');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi de la recommandation: $e',
        'error': e.toString(),
      };
    }
  }
}
