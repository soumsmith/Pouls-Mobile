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
  Future<List<StudentMessage>> getMessagesForStudent(String matricule) async {
    print('🔄 Début du chargement des messages pour l\'élève: $matricule');

    // Correction du endpoint - utilise le endpoint correct pour les messages d\'élève
    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/messages/eleve/$matricule',
    );

    try {
      print('📡 Appel API: $url');
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues: ${data['data']['total']} messages trouvés');

        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> messagesData = data['data']['data'] as List;
          final messages = messagesData
              .map((json) => StudentMessage.fromJson(json))
              .toList();

          print('📚 ${messages.length} messages parsés avec succès');
          return messages;
        } else {
          print('❌ Status false ou data null dans la réponse');
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
    String matricule, {
    int page = 1,
  }) async {
    print('🔄 Chargement des messages - Page $page pour l\'élève: $matricule');

    // Correction du endpoint
    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/messages/eleve/$matricule?page=$page',
    );

    try {
      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> messagesData = data['data']['data'] as List;
          return messagesData
              .map((json) => StudentMessage.fromJson(json))
              .toList();
        } else {
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
