import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_message.dart';
import '../config/app_config.dart';

/// Service pour gérer les messages spécifiques à un élève
class StudentMessageService {
  static final StudentMessageService _instance =
      StudentMessageService._internal();
  factory StudentMessageService() => _instance;
  StudentMessageService._internal();

  /// Récupère les messages pour un élève spécifique
  Future<List<StudentMessage>> getMessagesForStudent(String phoneNumber, String matricule, {int perPage = 20, int page = 1}) async {
    print('🔄 Début du chargement des messages pour l\'élève: $matricule');

    // Utilise le bon endpoint spécifié par l'utilisateur
    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/$phoneNumber/eleve/$matricule?per_page=$perPage&page=$page',
    );

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📄 Response body: ${response.body}');
        
        // Vérifier différents formats de réponse possibles
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> messagesData = data['data'] as List;
          final messages = messagesData
              .map((json) => StudentMessage.fromJson(json))
              .toList();

          print('📚 ${messages.length} messages parsés avec succès');
          return messages;
        } else if (data['status'] == false && data['error'] != null) {
          print('❌ Erreur API: ${data['error']}');
          return [];
        } else {
          print('❌ Status false ou data null dans la réponse');
          print('📄 Response structure: ${data.keys.toList()}');
          if (data.containsKey('message')) {
            print('📄 Message: ${data['message']}');
          }
          return [];
        }
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception(
          'Erreur lors du chargement des messages: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Exception dans getMessagesForStudent: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les messages avec pagination
  Future<List<StudentMessage>> getMessagesPage(
    String phoneNumber, String matricule, {
    int page = 1,
    int perPage = 20,
  }) async {
    print('🔄 Chargement des messages - Page $page pour l\'élève: $matricule');

    // Utilise le bon endpoint
    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/$phoneNumber/eleve/$matricule?per_page=$perPage&page=$page',
    );

    try {
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📄 Response body: ${response.body}');
        
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> messagesData = data['data'] as List;
          return messagesData
              .map((json) => StudentMessage.fromJson(json))
              .toList();
        } else if (data['status'] == false && data['error'] != null) {
          print('❌ Erreur API: ${data['error']}');
          return [];
        } else {
          print('❌ Status false ou data null dans la réponse');
          print('📄 Response structure: ${data.keys.toList()}');
          if (data.containsKey('message')) {
            print('📄 Message: ${data['message']}');
          }
          return [];
        }
      } else {
        throw Exception(
          'Erreur lors du chargement des messages: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Exception dans getMessagesPage: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}
