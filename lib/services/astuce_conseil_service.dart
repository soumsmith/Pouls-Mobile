import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/astuce_conseil.dart';
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

class AstuceConseilResponse {
  final int currentPage;
  final List<AstuceConseil> data;
  final int lastPage;
  final int total;

  AstuceConseilResponse({
    required this.currentPage,
    required this.data,
    required this.lastPage,
    required this.total,
  });

  factory AstuceConseilResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<AstuceConseil> astucesList = list.map((i) => AstuceConseil.fromJson(i)).toList();

    return AstuceConseilResponse(
      currentPage: json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      data: astucesList,
      lastPage: json['last_page'] is int ? json['last_page'] : int.tryParse(json['last_page']?.toString() ?? '1') ?? 1,
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    );
  }
}

class AstuceConseilService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  /// Récupère la liste paginée des astuces et conseils
  Future<AstuceConseilResponse> getAstucesConseils({int page = 1}) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('💡 CHARGEMENT DES ASTUCES & CONSEILS');
    print('═══════════════════════════════════════════════════════════');
    print('📄 Page: $page');

    final url = '$baseUrl/forum-astuce-conseil?page=$page';
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues et parsées avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return AstuceConseilResponse.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des astuces: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des astuces');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des astuces: $e');
    }
  }

  /// Récupère les astuces et les convertit en format UI
  Future<List<Map<String, dynamic>>> getAstucesForUI({int page = 1}) async {
    try {
      final response = await getAstucesConseils(page: page);
      return response.data.map((astuce) => astuce.toUiMap()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des astuces: $e');
    }
  }

  // --- ACTIONS INTERACTION ---

  Future<List<dynamic>> getComments(String slug, {int page = 1}) async {
    final url = '$baseUrl/forums/$slug/commentaires?per_page=50&page=$page';
    print('═══════════════════════════════════════════════════════════');
    print('💬 CHARGEMENT DES COMMENTAIRES');
    print('🔗 URL: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      print('📥 Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        print('❌ Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 Erreur: $e');
      return [];
    }
  }

  Future<bool> addComment(String slug, {required String nom, required int userId, required String contenu}) async {
    final url = '$baseUrl/forums/$slug/commentaires';
    print('═══════════════════════════════════════════════════════════');
    print('💬 AJOUT D\'UN COMMENTAIRE');
    print('🔗 URL: $url');
    print('📦 Paramètres: nom=$nom, userid=$userId, contenu=$contenu');
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
    print('❤️ CHARGEMENT DES LIKES');
    print('🔗 URL: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});
      print('📥 Status: ${response.statusCode}');
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
    print('❤️ LIKE / DISLIKE');
    print('🔗 URL: $url');
    print('📦 Paramètres: nom=$nom, userid=$userId');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nom': nom, 'userid': userId}),
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

  Future<bool> recordShare(String slug, {required String nom, required int userId}) async {
    final url = '$baseUrl/forums/$slug/share';
    print('═══════════════════════════════════════════════════════════');
    print('📤 ENREGISTREMENT PARTAGE');
    print('🔗 URL: $url');
    print('📦 Paramètres: nom=$nom, userid=$userId');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nom': nom, 'userid': userId}),
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
}
