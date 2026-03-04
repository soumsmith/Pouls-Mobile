import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_scolarite.dart';
import '../config/app_config.dart';
import 'school_service.dart';

/// Service pour gérer la scolarité spécifique à un élève
class StudentScolariteService {
  static final StudentScolariteService _instance = StudentScolariteService._internal();
  factory StudentScolariteService() => _instance;
  StudentScolariteService._internal();

  final SchoolService _schoolService = SchoolService();

  /// Récupère la scolarité pour un élève spécifique
  Future<StudentScolariteResponse> getScolariteForStudent(String matricule) async {
    // Récupérer l'ID Vie École depuis le SchoolService
    final vieEcoleId = _schoolService.schoolVieEcoleId;
    
    if (vieEcoleId == null) {
      print('❌ ID Vie École non disponible. Veuillez charger les données de l\'école d\'abord.');
      throw Exception('ID Vie École non disponible. Chargez les données de l\'école d\'abord.');
    }
    
    print('🔄 Début du chargement de la scolarité pour l\'élève: $matricule');
    print('🏫 École: ${_schoolService.schoolName} (ID Vie École: $vieEcoleId)');
    
    final url = Uri.parse('https://api2.vie-ecoles.com/api/vie-ecoles/scolarite-eleve/$matricule?ecole=$vieEcoleId');

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues: status=${data['status']}');
        
        final scolariteResponse = StudentScolariteResponse.fromJson(data);
        print('📚 ${scolariteResponse.data.length} échéances parsées avec succès');
        
        return scolariteResponse;
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Erreur lors du chargement de la scolarité: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception dans getScolariteForStudent: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les échéances avec gestion d'erreur améliorée
  Future<List<StudentScolariteEntry>> getScolariteEntriesForStudent(String matricule) async {
    try {
      final response = await getScolariteForStudent(matricule);
      
      if (response.status) {
        return response.data;
      } else {
        print('❌ API a retourné status=false: ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      print('💥 Exception dans getScolariteEntriesForStudent: $e');
      rethrow;
    }
  }

  /// Calcule les statistiques de scolarité pour un élève
  Future<Map<String, dynamic>> getScolariteStatistics(String matricule) async {
    try {
      final response = await getScolariteForStudent(matricule);
      
      return {
        'totalMontant': response.totalMontant,
        'totalPaye': response.totalPaye,
        'totalRapayer': response.totalRapayer,
        'paymentPercentage': response.globalPaymentPercentage,
        'totalEntries': response.data.length,
        'paidEntries': response.paidEntries.length,
        'unpaidEntries': response.unpaidEntries.length,
        'partiallyPaidEntries': response.partiallyPaidEntries.length,
        'overdueEntries': response.overdueEntries.length,
        'entriesByRubrique': response.entriesByRubrique,
      };
    } catch (e) {
      print('💥 Exception dans getScolariteStatistics: $e');
      return {
        'totalMontant': 0,
        'totalPaye': 0,
        'totalRapayer': 0,
        'paymentPercentage': 0.0,
        'totalEntries': 0,
        'paidEntries': 0,
        'unpaidEntries': 0,
        'partiallyPaidEntries': 0,
        'overdueEntries': 0,
        'entriesByRubrique': {},
      };
    }
  }

  /// Vérifie si un élève a des échéances en retard
  Future<bool> hasOverdueEntries(String matricule) async {
    try {
      final response = await getScolariteForStudent(matricule);
      return response.overdueEntries.isNotEmpty;
    } catch (e) {
      print('💥 Exception dans hasOverdueEntries: $e');
      return false;
    }
  }

  /// Récupère les échéances en retard
  Future<List<StudentScolariteEntry>> getOverdueEntries(String matricule) async {
    try {
      final response = await getScolariteForStudent(matricule);
      return response.overdueEntries;
    } catch (e) {
      print('💥 Exception dans getOverdueEntries: $e');
      return [];
    }
  }

  /// Récupère les échéances à payer prochainement (dans les 30 jours)
  Future<List<StudentScolariteEntry>> getUpcomingEntries(String matricule) async {
    try {
      final response = await getScolariteForStudent(matricule);
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      
      return response.data.where((entry) {
        if (entry.isFullyPaid) return false;
        try {
          final deadline = DateTime.parse(entry.dateLimite);
          return deadline.isAfter(now) && deadline.isBefore(thirtyDaysLater);
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      print('💥 Exception dans getUpcomingEntries: $e');
      return [];
    }
  }

  /// Calcule le montant total des échéances en retard
  Future<int> getOverdueAmount(String matricule) async {
    try {
      final overdueEntries = await getOverdueEntries(matricule);
      int total = 0;
      for (final entry in overdueEntries) {
        total += entry.rapayer;
      }
      return total;
    } catch (e) {
      print('💥 Exception dans getOverdueAmount: $e');
      return 0;
    }
  }
}
