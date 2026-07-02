import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:developer' as developer;
import '../models/blog.dart';
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

class BlogService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  /// Récupère la liste des blogs/communications depuis l'API
  ///
  /// Endpoint: GET /api/ecoles/blogs-list?titre={titre}&ecole={ecole}
  Future<BlogsResponse> getBlogsByEcole(String titre, String ecole, {int page = 1, int perPage = 20}) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📝 CHARGEMENT DES BLOGS/COMMUNICATIONS');
    print('═══════════════════════════════════════════════════════════');
    print('🔍 Titre: $titre');
    print('🏫 École: $ecole');

    final url =
        '${AppConfig.API_AFRICA_URL}/africa/blogs-list?titre=${Uri.encodeComponent(titre)}&ecole=${Uri.encodeComponent(ecole)}&page=$page&per_page=$perPage';
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
      ApiExceptionHandler.handle(e, context: 'la récupération des blogs');
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

  /// Récupère la liste des blogs depuis l'API (sans filtres)
  static Future<BlogsResponse> getBlogs({
    int page = 1,
    int perPage = 16,
    String? country,
    String? categorie,
    String? date,
  }) async {
    try {
      String url = '${AppConfig.API_AFRICA_URL}/africa/blogs-list?page=$page&per_page=$perPage';
      
      if (country != null && country.isNotEmpty) {
        url += '&country=${Uri.encodeComponent(country)}';
      }

      if (categorie != null && categorie.isNotEmpty) {
        url += '&categorie=${Uri.encodeComponent(categorie)}';
      }

      if (date != null && date.isNotEmpty) {
        url += '&date=${Uri.encodeComponent(date)}';
      }
      
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📝 CHARGEMENT DES ACTUALITÉS (HOME PAGE)');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL: $url');
      print('📡 Envoi de la requête...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues et parsées avec succès');
        print('═══════════════════════════════════════════════════════════');
        return BlogsResponse.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('═══════════════════════════════════════════════════════════');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des actualités (Home): $e');
      print('═══════════════════════════════════════════════════════════');
      throw Exception('Erreur lors de la récupération des blogs: $e');
    }
  }

  /// Récupère la liste des blogs (méthode simplifiée)
  static Future<List<Blog>> getBlogsList() async {
    try {
      final response = await getBlogs();
      return response.data;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération de la liste des blogs: $e',
      );
    }
  }

  // --- ACTIONS INTERACTION ---

  Future<List<dynamic>> getComments(String slug, {int page = 1}) async {
    final url = '$baseUrl/forums/$slug/commentaires?per_page=50&page=$page';
    print('═══════════════════════════════════════════════════════════');
    print('💬 CHARGEMENT DES COMMENTAIRES (BLOG)');
    print('🔗 URL: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['commentaire'] != null && data['commentaire']['data'] != null) {
          return data['commentaire']['data'];
        }
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('💥 Erreur: $e');
      return [];
    }
  }

  Future<bool> addComment(String slug, {required String nom, required int userId, required String contenu}) async {
    final url = '$baseUrl/forums/$slug/commentaires';
    print('═══════════════════════════════════════════════════════════');
    print('💬 AJOUT D\'UN COMMENTAIRE (BLOG)');
    print('🔗 URL: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nom': nom, 'userid': userId, 'contenu': contenu}),
      );
      print('📥 Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 Erreur: $e');
      return false;
    }
  }

  Future<List<dynamic>> getLikes(String slug) async {
    final url = '$baseUrl/forums/$slug/like';
    print('═══════════════════════════════════════════════════════════');
    print('❤️ CHARGEMENT DES LIKES (BLOG)');
    print('🔗 URL: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : (data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('💥 Erreur: $e');
      return [];
    }
  }

  Future<bool> likeArticle(String slug, {required String nom, required int userId}) async {
    final url = '$baseUrl/forums/$slug/like';
    print('═══════════════════════════════════════════════════════════');
    print('❤️ LIKE / DISLIKE (BLOG)');
    print('🔗 URL: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nom': nom, 'userid': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('💥 Erreur: $e');
      return false;
    }
  }

  Future<bool> recordShare(String slug, {required String nom, required int userId}) async {
    final url = '$baseUrl/forums/$slug/share';
    print('═══════════════════════════════════════════════════════════');
    print('📤 ENREGISTREMENT PARTAGE (BLOG)');
    print('🔗 URL: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nom': nom, 'userid': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('💥 Erreur: $e');
      return false;
    }
  }
}
