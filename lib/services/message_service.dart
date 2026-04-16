import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();
  
  /// Stocke le conversation_id actuel pour éviter les appels répétés
  int? _currentConversationId;
  
  /// Réinitialise le conversation_id stocké (utile pour changer d'élève)
  void resetConversationId() {
    _currentConversationId = null;
  }

  /// Vérifie s'il existe une conversation existante et retourne le conversation_id
  /// Selon la documentation: retourne l'ID de l'objet conversation si présent, null sinon
  Future<int?> _determineConversationId({
    required String userPhoneNumber,
    required String matricule,
  }) async {
    // Si on a déjà un conversation_id en cache, on le retourne
    if (_currentConversationId != null) {
      print('📝 Utilisation du conversation_id en cache: $_currentConversationId');
      return _currentConversationId;
    }
    
    try {
      print('🔍 Vérification des conversations existantes pour $userPhoneNumber / $matricule');

      final url = Uri.parse(
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/$userPhoneNumber/eleve/$matricule?per_page=1&page=1',
      );

      final response = await http.get(url).timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📄 Réponse vérification conversation: ${response.body}');

        // Selon la documentation: si success = true et contient un objet conversation
        if (responseData['status'] == true &&
            responseData['data'] != null &&
            responseData['data']['data'] != null &&
            responseData['data']['data']['conversation'] != null) {
          
          final conversationId = responseData['data']['data']['conversation']['id'] as int?;
          if (conversationId != null) {
            _currentConversationId = conversationId; // Mettre en cache
            print('✅ Conversation existante trouvée, conversation_id = $conversationId');
            return conversationId;
          }
        }
        
        print('📭 Aucune conversation existante, conversation_id = null');
        return null;
      } else {
        print('⚠️ Erreur lors de la vérification: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 Exception lors de la vérification des conversations: $e');
      return null;
    }
  }

  /// Envoie un message texte simple
  Future<Map<String, dynamic>> sendTextMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendTextMessage appelé');

    // Si conversationId n'est pas fourni, le déterminer selon la documentation
    if (conversationId == null) {
      conversationId = await _determineConversationId(
        userPhoneNumber: userPhoneNumber,
        matricule: matricule,
      );
    }

    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/envoyer/$userPhoneNumber',
    );

    // Selon la documentation: conversation_id doit être null s'il n'y a pas encore de conversation
    final body = {
      'content': content,
      'body': content,
      'subject': subject,
      'conversation_id': conversationId, // null si nouvelle conversation
      'code_ecole': codeEcole,
      'matricule': matricule,
      'sender_type': 'parent',
    };

    print('🌐 URL: $url');
    print('📦 Body: $body');

    try {
      print('📡 Envoi de la requête HTTP...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si c'est une nouvelle conversation, extraire et stocker le conversation_id
        if (conversationId == null) {
          final responseData = json.decode(response.body);
          if (responseData['data'] != null && responseData['data']['conversation_id'] != null) {
            _currentConversationId = responseData['data']['conversation_id'] as int?;
            print('🆕 Nouvelle conversation créée avec ID: $_currentConversationId');
          }
        }
        
        print('✅ Message texte envoyé avec succès');
        return {
          'success': true,
          'message': 'Message envoyé avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendTextMessage: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// Envoie un message avec une image
  Future<Map<String, dynamic>> sendImageMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    required File imageFile,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendImageMessage appelé');

    // Si conversationId n'est pas fourni, le déterminer selon la documentation
    if (conversationId == null) {
      conversationId = await _determineConversationId(
        userPhoneNumber: userPhoneNumber,
        matricule: matricule,
      );
    }

    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/envoyer/$userPhoneNumber',
    );

    try {
      final request = http.MultipartRequest('POST', url);

      request.fields['content'] = content;
      request.fields['body'] = content;
      request.fields['subject'] = subject;
      // Selon la documentation: conversation_id doit être null s'il n'y a pas encore de conversation
      request.fields['conversation_id'] = conversationId?.toString() ?? '';
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        imageBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      print('🌐 URL: $url');
      print('📦 Champs: ${request.fields}');
      print('📡 Envoi de la requête multipart...');

      final streamedResponse =
          await request.send().timeout(AppConfig.API_TIMEOUT);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si c'est une nouvelle conversation, extraire et stocker le conversation_id
        if (conversationId == null) {
          final responseData = json.decode(response.body);
          if (responseData['data'] != null && responseData['data']['conversation_id'] != null) {
            _currentConversationId = responseData['data']['conversation_id'] as int?;
            print('🆕 Nouvelle conversation créée avec ID: $_currentConversationId');
          }
        }
        
        print('✅ Message avec image envoyé avec succès');
        return {
          'success': true,
          'message': 'Message avec image envoyé avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendImageMessage: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// Envoie une note vocale
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    required File audioFile,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendVoiceMessage appelé');

    // Si conversationId n'est pas fourni, le déterminer selon la documentation
    if (conversationId == null) {
      conversationId = await _determineConversationId(
        userPhoneNumber: userPhoneNumber,
        matricule: matricule,
      );
    }

    final url = Uri.parse(
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/messages/envoyer/$userPhoneNumber',
    );

    try {
      final request = http.MultipartRequest('POST', url);

      request.fields['content'] = content;
      request.fields['body'] = content;
      request.fields['subject'] = subject;
      // Selon la documentation: conversation_id doit être null s'il n'y a pas encore de conversation
      request.fields['conversation_id'] = conversationId?.toString() ?? '';
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      final audioBytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        audioBytes,
        filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
      );
      request.files.add(multipartFile);

      print('🌐 URL: $url');
      print('📦 Champs: ${request.fields}');
      print('📡 Envoi de la requête multipart avec audio...');

      final streamedResponse =
          await request.send().timeout(AppConfig.API_TIMEOUT);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si c'est une nouvelle conversation, extraire et stocker le conversation_id
        if (conversationId == null) {
          final responseData = json.decode(response.body);
          if (responseData['data'] != null && responseData['data']['conversation_id'] != null) {
            _currentConversationId = responseData['data']['conversation_id'] as int?;
            print('🆕 Nouvelle conversation créée avec ID: $_currentConversationId');
          }
        }
        
        print('✅ Note vocale envoyée avec succès');
        return {
          'success': true,
          'message': 'Note vocale envoyée avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendVoiceMessage: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}