import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../config/app_config.dart';

class TestimonialService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static Future<Map<String, dynamic>> submitTestimonial({
    required String codeecole,
    required String note,
    required String contenu,
    required String userNumero,
  }) async {
    // Préparer les données
    final Map<String, dynamic> requestData = {
      'codeecole': codeecole,
      'note': note,
      'contenu': contenu,
    };

    // Logger les données de la requête
    developer.log('🌟 Envoi du témoignage...', name: 'TestimonialService');
    developer.log(
      'URL: $baseUrl/vie-ecoles/avis/$userNumero',
      name: 'TestimonialService',
    );
    developer.log(
      'Données envoyées: ${jsonEncode(requestData)}',
      name: 'TestimonialService',
    );

    try {
      developer.log(
        '📡 Envoi de la requête POST...',
        name: 'TestimonialService',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/vie-ecoles/avis/$userNumero'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      // Logger la réponse
      developer.log(
        '📥 Réponse reçue - Status: ${response.statusCode}',
        name: 'TestimonialService',
      );
      developer.log(
        '📄 Corps de la réponse: ${response.body}',
        name: 'TestimonialService',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log(
          '✅ Succès - Données décodées: $data',
          name: 'TestimonialService',
        );
        return {
          'success': true,
          'data': data,
          'message': 'Témoignage envoyé avec succès!',
          'statusCode': response.statusCode,
        };
      } else {
        developer.log(
          '❌ Erreur HTTP - Status: ${response.statusCode}',
          name: 'TestimonialService',
        );
        developer.log(
          '❌ Corps d\'erreur: ${response.body}',
          name: 'TestimonialService',
        );
        return {
          'success': false,
          'message': 'Erreur HTTP: ${response.statusCode}',
          'error': response.body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      developer.log(
        '💥 Exception lors de l\'envoi: $e',
        name: 'TestimonialService',
      );
      developer.log(
        '💥 Stack trace: ${StackTrace.current}',
        name: 'TestimonialService',
      );
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du témoignage: $e',
        'error': e.toString(),
      };
    }
  }
}
