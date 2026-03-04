import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ecole.dart';
import '../models/ecole_detail.dart';

class EcoleApiService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/ecoles/list';

  /// Récupère la liste des écoles depuis l'API
  static Future<List<Ecole>> getEcoles({int page = 1}) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 CHARGEMENT DES ÉCOLES (PAGE $page)');
    print('═══════════════════════════════════════════════════════════');
    
    final url = '$baseUrl?page=$page';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['data'] != null && data['data'] is List) {
          final List<dynamic> ecolesData = data['data'];
          print('✅ ${ecolesData.length} école(s) récupérée(s)');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return ecolesData.map((json) => Ecole.fromJson(json)).toList();
        }
        print('⚠️ Aucune donnée d\'école trouvée dans la réponse');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return [];
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des écoles: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des écoles: $e');
    }
  }

  /// Récupère toutes les écoles avec pagination
  static Future<List<Ecole>> getAllEcoles() async {
    List<Ecole> allEcoles = [];
    int currentPage = 1;
    bool hasMorePages = true;

    while (hasMorePages) {
      try {
        final ecoles = await getEcoles(page: currentPage);
        allEcoles.addAll(ecoles);
        
        // Si moins de 50 écoles, c'est probablement la dernière page
        if (ecoles.length < 50) {
          hasMorePages = false;
        } else {
          currentPage++;
        }
      } catch (e) {
        // En cas d'erreur, on arrête la pagination
        hasMorePages = false;
        if (allEcoles.isEmpty) {
          rethrow; // Si aucune école n'a été récupérée, on propage l'erreur
        }
      }
    }

    return allEcoles;
  }

  /// Récupère les détails d'une école spécifique
  static Future<EcoleDetail> getEcoleDetail(String parametreCode) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 DÉTAILS DE L\'ÉCOLE');
    print('═══════════════════════════════════════════════════════════');
    print('🏷️ Code paramètre: $parametreCode');
    
    final url = 'https://api2.vie-ecoles.com/api/ecoles/detail-ecole/$parametreCode';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Détails de l\'école récupérés avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return EcoleDetail.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des détails de l\'école: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des détails de l\'école: $e');
    }
  }
}
