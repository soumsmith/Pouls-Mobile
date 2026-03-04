import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ecole.dart';
import '../config/app_config.dart';

class EcolesApiService {
  static final EcolesApiService _instance = EcolesApiService._internal();
  factory EcolesApiService() => _instance;
  EcolesApiService._internal();

  /// Récupère la liste des écoles depuis l'API
  Future<List<Ecole>> getAllEcoles() async {
    print('🔄 Début du chargement des écoles depuis API2...');
    
    final url = Uri.parse('https://api2.vie-ecoles.com/api/ecoles/list');

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues: ${data['total']} écoles trouvées');
        
        final List<dynamic> ecolesData = data['data'] as List;
        final ecoles = ecolesData.map((json) => Ecole.fromJson(json)).toList();
        
        print('📚 ${ecoles.length} écoles parsées avec succès');
        return ecoles;
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Erreur lors du chargement des écoles: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception dans getAllEcoles: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les écoles avec pagination
  Future<List<Ecole>> getEcolesPage({int page = 1}) async {
    print('🔄 Chargement des écoles - Page $page');
    
    final url = Uri.parse('https://api2.vie-ecoles.com/api/ecoles/list?page=$page');

    try {
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> ecolesData = data['data'] as List;
        return ecolesData.map((json) => Ecole.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des écoles: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception dans getEcolesPage: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Recherche des écoles par nom (utilise l'API de pagination)
  Future<List<Ecole>> searchEcoles(String query) async {
    print('🔍 Recherche d\'écoles: "$query"');
    
    // Pour l'instant, on charge toutes les écoles et on filtre localement
    // L'API ne semble pas avoir de endpoint de recherche direct
    try {
      final allEcoles = await getAllEcoles();
      final filteredEcoles = allEcoles.where((ecole) =>
        ecole.parametreNom.toLowerCase().contains(query.toLowerCase()) ||
        ecole.ville.toLowerCase().contains(query.toLowerCase()) ||
        ecole.parametreCode.toLowerCase().contains(query.toLowerCase())
      ).toList();
      
      print('🔍 ${filteredEcoles.length} écoles trouvées pour "$query"');
      return filteredEcoles;
    } catch (e) {
      print('💥 Exception dans searchEcoles: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
