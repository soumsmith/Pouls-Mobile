import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_exception_handler.dart';

class ExtraScolaireService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  /// 1.10 Récupération des produits scolaires souscrits (abonnements actifs)
  static Future<List<dynamic>> getSubscribedServices({
    required String matricule,
    required String ecoleCode,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🍽️ RÉCUPÉRATION DES ABONNEMENTS ACTIFS');
    print('═══════════════════════════════════════════════════════════');
    print('👤 Matricule: $matricule');
    print('🏫 École: $ecoleCode');

    final url = Uri.parse('$baseUrl/vie-ecoles/service/abonnement/eleve/$matricule?ecole=$ecoleCode');
    print('🔗 URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];
        if (data is Map<String, dynamic> && data['status'] == true) {
          list = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          list = data;
        }
        print('✅ ${list.length} abonnement(s) actif(s) récupéré(s)');
        return list;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 Exception abonnements actifs: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des abonnements');
      return [];
    }
  }

  /// 1.11 Consultation des activités extra-scolaires quotidiennes d'un service
  static Future<Map<String, dynamic>> getServiceActivities({
    required String serviceUid,
    required String matricule,
    required String ecoleCode,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🚌 RÉCUPÉRATION DES ACTIVITÉS EXTRA-SCOLAIRES');
    print('═══════════════════════════════════════════════════════════');
    print('🔑 Service UID: $serviceUid');
    print('👤 Matricule: $matricule');
    print('🏫 École: $ecoleCode');

    final url = Uri.parse('$baseUrl/vie-ecoles/service/activite/$serviceUid/eleve/$matricule?ecole=$ecoleCode');
    print('🔗 URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> activitiesList = [];
        Map<String, dynamic>? detailsMap;

        if (data is Map<String, dynamic>) {
          final rawData = data['data'];
          if (rawData is List) {
            activitiesList = rawData;
          } else if (rawData is Map<String, dynamic>) {
            detailsMap = rawData;
            for (var val in rawData.values) {
              if (val is List) {
                activitiesList = val;
                break;
              }
            }
          }
        } else if (data is List) {
          activitiesList = data;
        }

        print('✅ ${activitiesList.length} activité(s) récupérée(s)');
        return {
          'activities': activitiesList,
          'details': detailsMap,
        };
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        return {
          'activities': [],
          'details': null,
        };
      }
    } catch (e) {
      print('💥 Exception activités service: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des activités');
      return {
        'activities': [],
        'details': null,
      };
    }
  }
}
