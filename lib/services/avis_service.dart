import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/avis.dart';

class AvisService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/ecoles';
  
  /// Récupère la liste des avis/notes depuis l'API
  /// 
  /// Endpoint: GET /api/ecoles/avis/{codeEcole}
  Future<AvisResponse> getAvisByEcole(String codeEcole) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('⭐ CHARGEMENT DES AVIS');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 Code école: $codeEcole');
    
    final url = '$baseUrl/avis/$codeEcole';
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
        return AvisResponse.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des avis: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des avis: $e');
    }
  }

  /// Récupère les avis et les convertit en format UI
  Future<List<Map<String, dynamic>>> getAvisForUI(String codeEcole) async {
    try {
      final avisResponse = await getAvisByEcole(codeEcole);
      return avisResponse.data.map((avis) => avis.toUiMap()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des avis: $e');
    }
  }

  /// Recherche des avis par terme
  Future<List<Map<String, dynamic>>> searchAvis(String codeEcole, String query) async {
    try {
      final avisResponse = await getAvisByEcole(codeEcole);
      final allAvis = avisResponse.data.map((avis) => avis.toUiMap()).toList();
      
      if (query.isEmpty) return allAvis;
      
      final searchQuery = query.toLowerCase();
      return allAvis.where((avis) {
        return (avis['title'] as String).toLowerCase().contains(searchQuery) ||
               (avis['subtitle'] as String).toLowerCase().contains(searchQuery) ||
               (avis['content'] as String).toLowerCase().contains(searchQuery) ||
               (avis['auteur'] as String).toLowerCase().contains(searchQuery) ||
               (avis['type'] as String).toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des avis: $e');
    }
  }

  /// Filtre les avis par statut
  List<Map<String, dynamic>> filterAvisByStatut(
    List<Map<String, dynamic>> avis,
    int statut,
  ) {
    if (statut == 0) return avis; // 0 = Tous
    
    return avis.where((avi) {
      return (avi['statut'] as int) == statut;
    }).toList();
  }

  /// Calcule la moyenne des notes
  double calculateAverageRating(List<Map<String, dynamic>> avis) {
    if (avis.isEmpty) return 0.0;
    
    final total = avis.fold<double>(0, (sum, avi) => sum + (avi['statut'] as int));
    return total / avis.length;
  }

  /// Compte le nombre d'avis par statut
  Map<int, int> countAvisByStatut(List<Map<String, dynamic>> avis) {
    final Map<int, int> counts = {
      1: 0, // Très négatif
      2: 0, // Négatif
      3: 0, // Neutre
      4: 0, // Positif
      5: 0, // Très positif
    };
    
    for (final avi in avis) {
      final statut = avi['statut'] as int;
      if (counts.containsKey(statut)) {
        counts[statut] = counts[statut]! + 1;
      }
    }
    
    return counts;
  }
}
