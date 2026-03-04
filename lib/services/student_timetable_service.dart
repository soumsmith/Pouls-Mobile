import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_timetable.dart';
import '../config/app_config.dart';
import 'school_service.dart';

/// Service pour gérer l'emploi du temps spécifique à un élève
class StudentTimetableService {
  static final StudentTimetableService _instance = StudentTimetableService._internal();
  factory StudentTimetableService() => _instance;
  StudentTimetableService._internal();

  final SchoolService _schoolService = SchoolService();

  /// Récupère l'emploi du temps pour un élève spécifique en utilisant l'ID Vie École
  Future<StudentTimetableResponse> getTimetableForStudent(String matricule) async {
    // Récupérer l'ID Vie École depuis le SchoolService
    final vieEcoleId = _schoolService.schoolVieEcoleId;
    
    if (vieEcoleId == null) {
      print('❌ ID Vie École non disponible. Veuillez charger les données de l\'école d\'abord.');
      throw Exception('ID Vie École non disponible. Chargez les données de l\'école d\'abord.');
    }
    
    print('🔄 Début du chargement de l\'emploi du temps pour l\'élève: $matricule');
    print('🏫 École: ${_schoolService.schoolName} (ID Vie École: $vieEcoleId)');
    
    final url = Uri.parse('https://api2.vie-ecoles.com/api/vie-ecoles/emploi-du-temps-eleve/$matricule?ecole=$vieEcoleId');

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues: status=${data['status']}');
        
        // Logging détaillé pour débogage
        if (data['data'] != null) {
          print('📊 Nombre de créneaux reçus: ${(data['data'] as List).length}');
          if ((data['data'] as List).isNotEmpty) {
            final firstEntry = (data['data'] as List).first;
            print('🔍 Premier créneau (pour débogage):');
            print('   edt_id: ${firstEntry['edt_id']} (${firstEntry['edt_id'].runtimeType})');
            print('   uid: ${firstEntry['uid']} (${firstEntry['uid'].runtimeType})');
            print('   type: ${firstEntry['type']} (${firstEntry['type'].runtimeType})');
            print('   horaire_id: ${firstEntry['horaire_id']} (${firstEntry['horaire_id'].runtimeType})');
            print('   jour: ${firstEntry['jour']} (${firstEntry['jour'].runtimeType})');
            print('   hdebut: ${firstEntry['hdebut']} (${firstEntry['hdebut'].runtimeType})');
            print('   hfin: ${firstEntry['hfin']} (${firstEntry['hfin'].runtimeType})');
            print('   entite: ${firstEntry['entite']} (${firstEntry['entite'].runtimeType})');
            print('   valeur: ${firstEntry['valeur']} (${firstEntry['valeur'].runtimeType})');
            print('   observations: ${firstEntry['observations']} (${firstEntry['observations'].runtimeType})');
          }
        }
        
        final timetableResponse = StudentTimetableResponse.fromJson(data);
        print('📚 ${timetableResponse.data.length} créneaux horaires parsés avec succès');
        
        return timetableResponse;
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Erreur lors du chargement de l\'emploi du temps: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception dans getTimetableForStudent: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère l'emploi du temps avec gestion d'erreur améliorée
  Future<List<StudentTimetableEntry>> getTimetableEntriesForStudent(String matricule) async {
    try {
      final response = await getTimetableForStudent(matricule);
      
      if (response.status) {
        return response.data;
      } else {
        print('❌ API a retourné status=false: ${response.message}');
        throw Exception(response.message);
      }
    } catch (e) {
      print('💥 Exception dans getTimetableEntriesForStudent: $e');
      rethrow;
    }
  }

  /// Vérifie si un élève a des cours aujourd'hui
  Future<bool> hasCoursesToday(String matricule) async {
    try {
      final entries = await getTimetableEntriesForStudent(matricule);
      final today = DateTime.now().weekday; // 1=Lundi, 7=Dimanche
      
      return entries.any((entry) => entry.jourNumber == today);
    } catch (e) {
      print('💥 Exception dans hasCoursesToday: $e');
      return false;
    }
  }

  /// Récupère les cours d'aujourd'hui pour un élève
  Future<List<StudentTimetableEntry>> getTodayCourses(String matricule) async {
    try {
      final entries = await getTimetableEntriesForStudent(matricule);
      final today = DateTime.now().weekday; // 1=Lundi, 7=Dimanche
      
      return entries.where((entry) => entry.jourNumber == today).toList();
    } catch (e) {
      print('💥 Exception dans getTodayCourses: $e');
      return [];
    }
  }
}
