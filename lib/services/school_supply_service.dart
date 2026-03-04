import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school_supply.dart';

class SchoolSupplyService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/vie-ecoles';

  Future<SchoolSupplyResponse> getSchoolSupplies(String matricule) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fournitures-scolaires/$matricule'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📚 API Fournitures - Status: ${response.statusCode}');
      print('📚 API Fournitures - URL: $baseUrl/fournitures-scolaires/$matricule');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Fournitures récupérées: ${responseData['data']?.length ?? 0} items');
        return SchoolSupplyResponse.fromJson(responseData);
      } else {
        print('❌ Erreur API Fournitures: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur lors de la récupération des fournitures: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception lors de la récupération des fournitures: $e');
      throw Exception('Impossible de récupérer les fournitures: $e');
    }
  }
}
