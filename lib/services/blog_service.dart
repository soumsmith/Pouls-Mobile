import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blog.dart';

class BlogService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/ecoles';
  
  /// Récupère la liste des blogs/communications depuis l'API
  /// 
  /// Endpoint: GET /api/ecoles/blogs-list?nomEtablissement={nomEtablissement}
  Future<BlogsResponse> getBlogsByEcole(String nomEtablissement) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📝 CHARGEMENT DES BLOGS/COMMUNICATIONS');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 Établissement: $nomEtablissement');
    
    final url = '$baseUrl/blogs-list?nomEtablissement=${Uri.encodeComponent(nomEtablissement)}';
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
        print('✅ Données reçues et parsées avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return BlogsResponse.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des blogs: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des blogs: $e');
    }
  }

  /// Récupère les blogs et les convertit en format UI
  Future<List<Map<String, dynamic>>> getBlogsForUI(String nomEtablissement) async {
    try {
      final blogsResponse = await getBlogsByEcole(nomEtablissement);
      return blogsResponse.data.map((blog) => blog.toUiMap()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des blogs: $e');
    }
  }

  /// Recherche des blogs par terme
  Future<List<Map<String, dynamic>>> searchBlogs(String nomEtablissement, String query) async {
    try {
      final blogsResponse = await getBlogsByEcole(nomEtablissement);
      final allBlogs = blogsResponse.data.map((blog) => blog.toUiMap()).toList();
      
      if (query.isEmpty) return allBlogs;
      
      final searchQuery = query.toLowerCase();
      return allBlogs.where((blog) {
        return (blog['title'] as String).toLowerCase().contains(searchQuery) ||
               (blog['subtitle'] as String).toLowerCase().contains(searchQuery) ||
               (blog['content'] as String).toLowerCase().contains(searchQuery) ||
               (blog['type'] as String).toLowerCase().contains(searchQuery) ||
               (blog['auteur'] as String).toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des blogs: $e');
    }
  }

  /// Filtre les blogs par catégorie
  List<Map<String, dynamic>> filterBlogsByCategory(
    List<Map<String, dynamic>> blogs,
    String category,
  ) {
    if (category == 'Tous') return blogs;
    
    return blogs.where((blog) {
      return (blog['type'] as String).toLowerCase() == category.toLowerCase();
    }).toList();
  }
}
