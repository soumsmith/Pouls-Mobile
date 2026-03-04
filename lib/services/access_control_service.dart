import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/access_control.dart';
import '../config/app_config.dart';
import 'school_service.dart';

/// Service pour gérer le contrôle d'accès spécifique à un élève
class AccessControlService {
  static final AccessControlService _instance = AccessControlService._internal();
  factory AccessControlService() => _instance;
  AccessControlService._internal();

  final SchoolService _schoolService = SchoolService();

  /// Récupère les pointages de contrôle d'accès pour un élève spécifique
  Future<AccessControlResponse> getAccessControlForStudent(String matricule) async {
    // Récupérer l'ID Vie École depuis le SchoolService
    final vieEcoleId = _schoolService.schoolVieEcoleId;
    
    if (vieEcoleId == null) {
      print('❌ ID Vie École non disponible. Veuillez charger les données de l\'école d\'abord.');
      throw Exception('ID Vie École non disponible. Chargez les données de l\'école d\'abord.');
    }
    
    print('🔄 Début du chargement du contrôle d\'accès pour l\'élève: $matricule');
    print('🏫 École: ${_schoolService.schoolName} (ID Vie École: $vieEcoleId)');
    
    final url = Uri.parse('https://api2.vie-ecoles.com/api/vie-ecoles/controle-acces/$matricule?ecole=$vieEcoleId');

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues: status=${data['status']}');
        
        final accessControlResponse = AccessControlResponse.fromJson(data);
        print('📚 ${accessControlResponse.data.length} pointages parsés avec succès');
        
        return accessControlResponse;
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Erreur lors du chargement du contrôle d\'accès: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception dans getAccessControlForStudent: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les pointages avec gestion d'erreur améliorée
  Future<List<AccessControlEntry>> getAccessControlEntriesForStudent(String matricule) async {
    try {
      final response = await getAccessControlForStudent(matricule);
      
      if (response.status) {
        return response.data;
      } else {
        print('❌ API a retourné status=false: ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      print('💥 Exception dans getAccessControlEntriesForStudent: $e');
      rethrow;
    }
  }

  /// Vérifie si un élève a des pointages aujourd'hui
  Future<bool> hasEntriesToday(String matricule) async {
    try {
      final response = await getAccessControlForStudent(matricule);
      return response.todayEntries.isNotEmpty;
    } catch (e) {
      print('💥 Exception dans hasEntriesToday: $e');
      return false;
    }
  }

  /// Récupère les pointages d'aujourd'hui pour un élève
  Future<List<AccessControlEntry>> getTodayEntries(String matricule) async {
    try {
      final response = await getAccessControlForStudent(matricule);
      return response.todayEntries;
    } catch (e) {
      print('💥 Exception dans getTodayEntries: $e');
      return [];
    }
  }

  /// Récupère le dernier pointage d'un élève
  Future<AccessControlEntry?> getLastEntry(String matricule) async {
    try {
      final response = await getAccessControlForStudent(matricule);
      return response.lastEntry;
    } catch (e) {
      print('💥 Exception dans getLastEntry: $e');
      return null;
    }
  }

  /// Calcule les statistiques de pointage pour une période
  Future<Map<String, dynamic>> getStatistics(String matricule) async {
    try {
      final entries = await getAccessControlEntriesForStudent(matricule);
      
      final totalEntries = entries.length;
      final entrees = entries.where((e) => e.isEntree).length;
      final sorties = entries.where((e) => e.isSortie).length;
      final statusOk = entries.where((e) => e.isStatusOk).length;
      
      return {
        'total': totalEntries,
        'entrees': entrees,
        'sorties': sorties,
        'statusOk': statusOk,
        'statusKo': totalEntries - statusOk,
        'lastEntry': entries.isNotEmpty ? entries.last : null,
      };
    } catch (e) {
      print('💥 Exception dans getStatistics: $e');
      return {
        'total': 0,
        'entrees': 0,
        'sorties': 0,
        'statusOk': 0,
        'statusKo': 0,
        'lastEntry': null,
      };
    }
  }
}
