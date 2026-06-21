import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
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
        final dynamic decodedResponse = json.decode(response.body);
        
        List<dynamic> categoriesData;
        
        if (decodedResponse is List) {
          categoriesData = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic> && decodedResponse['data'] != null) {
          categoriesData = decodedResponse['data'];
        } else {
          throw Exception('Format de réponse API inattendu');
        }
        
        print('✅ ${categoriesData.length} catégorie(s) récupérée(s)');
        return categoriesData.map((categoryData) => Category.fromJson(categoryData)).toList();
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

  static Future<List<String>> getEventBlogCategories() async {
    try {
      final uri = Uri.parse('https://api-africa.vie-ecoles.com/api/africa/categories/evenement-blog');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic> && decodedResponse['data'] != null) {
          final List<dynamic> data = decodedResponse['data'];
          return data.map((e) => e['name'].toString()).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching event blog categories: $e');
      return [];
    }
  }
}
