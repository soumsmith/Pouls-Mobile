import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ParrainageService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  /// Récupère les informations de parrainage pour un numéro de téléphone
  static Future<Map<String, dynamic>> getInfoParrainage(String phoneNumber) async {
    try {
      developer.log('🚀 Récupération des infos de parrainage...', name: 'ParrainageService');
      developer.log('URL: $baseUrl/vie-ecoles/info-parrainage/$phoneNumber', name: 'ParrainageService');
      
      final response = await http.get(
        Uri.parse('$baseUrl/vie-ecoles/info-parrainage/$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      developer.log('📥 Réponse reçue - Status: ${response.statusCode}', name: 'ParrainageService');
      developer.log('📄 Corps de la réponse: ${response.body}', name: 'ParrainageService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log('✅ Succès - Données décodées: $data', name: 'ParrainageService');
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': data['message'] ?? 'Opération effectuée avec succès.',
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Erreur dans la réponse',
            'statusCode': response.statusCode,
          };
        }
      } else {
        developer.log('❌ Erreur HTTP - Status: ${response.statusCode}', name: 'ParrainageService');
        developer.log('❌ Corps d\'erreur: ${response.body}', name: 'ParrainageService');
        return {
          'success': false,
          'message': 'Erreur HTTP: ${response.statusCode}',
          'error': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      developer.log('💥 Exception lors de la récupération: $e', name: 'ParrainageService');
      developer.log('💥 Stack trace: ${StackTrace.current}', name: 'ParrainageService');
      return {
        'success': false,
        'message': 'Erreur lors de la récupération des infos de parrainage: $e',
        'error': e.toString(),
      };
    }
  }

  /// Soumet une demande de parrainage
  static Future<Map<String, dynamic>> submitParrainage({
    required String telephoneParraine,
    required String nomParraine,
    required String prenomParraine,
    required String emailParraine,
  }) async {
    // Préparer les données
    final Map<String, dynamic> requestData = {
      'telephone_parraine': telephoneParraine,
      'nom_parraine': nomParraine,
      'prenom_parraine': prenomParraine,
      'email_parraine': emailParraine,
    };
    
    // Logger les données de la requête
    developer.log('🚀 Envoi de la demande de parrainage...', name: 'ParrainageService');
    developer.log('URL: $baseUrl/vie-ecoles/parrainer', name: 'ParrainageService');
    developer.log('Données envoyées: ${jsonEncode(requestData)}', name: 'ParrainageService');
    
    try {
      developer.log('📡 Envoi de la requête POST...', name: 'ParrainageService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vie-ecoles/parrainer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      // Logger la réponse
      developer.log('📥 Réponse reçue - Status: ${response.statusCode}', name: 'ParrainageService');
      developer.log('📄 Corps de la réponse: ${response.body}', name: 'ParrainageService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log('✅ Succès - Données décodées: $data', name: 'ParrainageService');
        
        if (data['status'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': data['message'] ?? 'Parrainage envoyé avec succès!',
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Erreur dans la réponse',
            'statusCode': response.statusCode,
          };
        }
      } else {
        developer.log('❌ Erreur HTTP - Status: ${response.statusCode}', name: 'ParrainageService');
        developer.log('❌ Corps d\'erreur: ${response.body}', name: 'ParrainageService');
        return {
          'success': false,
          'message': 'Erreur HTTP: ${response.statusCode}',
          'error': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      developer.log('💥 Exception lors de l\'envoi: $e', name: 'ParrainageService');
      developer.log('💥 Stack trace: ${StackTrace.current}', name: 'ParrainageService');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du parrainage: $e',
        'error': e.toString(),
      };
    }
  }
}
