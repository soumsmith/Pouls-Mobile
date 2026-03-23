import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blog.dart';
import '../config/app_config.dart';

class BlogService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  /// Récupère la liste des blogs/communications depuis l'API
  ///
  /// Endpoint: GET /api/ecoles/blogs-list?titre={titre}&ecole={ecole}
  Future<BlogsResponse> getBlogsByEcole(String titre, String ecole) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📝 CHARGEMENT DES BLOGS/COMMUNICATIONS');
    print('═══════════════════════════════════════════════════════════');
    print('🔍 Titre: $titre');
    print('🏫 École: $ecole');

    final url =
        '$baseUrl/ecoles/blogs-list?titre=${Uri.encodeComponent(titre)}&ecole=${Uri.encodeComponent(ecole)}';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

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
  Future<List<Map<String, dynamic>>> getBlogsForUI(
    String titre,
    String ecole,
  ) async {
    try {
      final blogsResponse = await getBlogsByEcole(titre, ecole);
      return blogsResponse.data.map((blog) => blog.toUiMap()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des blogs: $e');
    }
  }

  /// Recherche des blogs par terme
  Future<List<Map<String, dynamic>>> searchBlogs(
    String titre,
    String ecole,
    String query,
  ) async {
    try {
      final blogsResponse = await getBlogsByEcole(titre, ecole);
      final allBlogs = blogsResponse.data
          .map((blog) => blog.toUiMap())
          .toList();

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
