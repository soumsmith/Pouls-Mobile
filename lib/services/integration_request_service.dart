import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IntegrationRequestService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  static Future<Map<String, dynamic>> consultIntegrationRequest({
    required String ecoleCode,
    required String matricule,
  }) async {
    try {
      debugPrint('🔍 Consultation demande intégration');
      debugPrint('📡 URL: $baseUrl/preinscription/demande-integration/consulte?ecole=$ecoleCode&matricule=$matricule');

      final response = await http.get(
        Uri.parse('$baseUrl/preinscription/demande-integration/consulte?ecole=$ecoleCode&matricule=$matricule'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Réponse HTTP - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ Données reçues: $responseData');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        debugPrint('❌ Erreur HTTP - Status: ${response.statusCode}');
        debugPrint('📄 Corps: ${response.body}');
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('💥 Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
