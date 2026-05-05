import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryApiService {
  static const String baseUrl = 'https://api2.vie-ecoles.com';
  static const String categoriesEndpoint = '/api/vie-ecoles/categories-produits';

  static Future<List<Category>> getCategories() async {
    try {
      final uri = Uri.parse('$baseUrl$categoriesEndpoint');
      
      print('📡 CategoryApiService - Appel GET pour les catégories');
      print('🔗 URL: $uri');
      print('📋 Headers: Content-Type: application/json, Accept: application/json');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesData = responseData['data'];
          print('✅ ${categoriesData.length} catégorie(s) récupérée(s)');
          return categoriesData.map((categoryData) => Category.fromJson(categoryData)).toList();
        } else {
          throw Exception('API returned status: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  static Future<List<Category>> getCategoriesByType(String typeProduit) async {
    try {
      final categories = await getCategories();
      return categories.where((category) => 
        category.typeProduit.toLowerCase() == typeProduit.toLowerCase()
      ).toList();
    } catch (e) {
      throw Exception('Failed to load categories by type: $e');
    }
  }
}
