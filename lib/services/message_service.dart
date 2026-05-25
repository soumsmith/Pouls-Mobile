import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/conversation.dart';
import '../models/student_message.dart';
import 'http_service.dart';
import 'auth_service.dart';

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
      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId.toString();
      }
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      final extension = imageFile.path.split('.').last.toLowerCase();
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        imageBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.$extension',
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
      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId.toString();
      }
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      final audioBytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        audioBytes,
        filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
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

  /// Envoie un message avec un fichier générique (PDF, document, etc.)
  Future<Map<String, dynamic>> sendFileMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    required File file,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendFileMessage appelé');

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
      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId.toString();
      }
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      final extension = file.path.split('.').last.toLowerCase();
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        fileBytes,
        filename: 'document_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      request.files.add(multipartFile);

      print('🌐 URL: $url');
      print('📦 Champs: ${request.fields}');
      print('📡 Envoi de la requête multipart avec fichier...');

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
        
        print('✅ Fichier envoyé avec succès');
        return {
          'success': true,
          'message': 'Fichier envoyé avec succès',
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
      print('💥 Exception dans sendFileMessage: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// Récupère la conversation et les messages d'un élève (anciennement MessageApiService)
  Future<Map<String, dynamic>> getMessagesForStudent(
    String phoneNumber,
    String matricule, {
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      print('📨 Récupération des messages pour l\'élève $matricule du parent $phoneNumber');
      
      final response = await HttpService.get('/vie-ecoles/messages/$phoneNumber/eleve/$matricule?per_page=$perPage&page=$page');
      
      if (response['status'] == true && response['data'] != null) {
        final innerData = response['data'];
        if (innerData['status'] == 'success' && innerData['data'] != null) {
          final conversationData = innerData['data'];
          
          final hasConversation = conversationData['conversation'] != null;
          final conversationId = hasConversation ? conversationData['conversation']['id'] : null;
          
          print('📝 Conversation existante: $hasConversation');
          if (conversationId != null) {
            print('🆔 ID de conversation: $conversationId');
          }
          
          List<dynamic> messagesData = [];
          if (conversationData['messages'] != null && conversationData['messages']['data'] != null) {
            messagesData = conversationData['messages']['data'];
          }
          
          return {
            'success': true,
            'hasConversation': hasConversation,
            'conversationId': conversationId,
            'conversationData': conversationData['conversation'],
            'messages': messagesData,
          };
        }
      }
      
      print('📭 Aucune conversation existante');
      return {
        'success': true,
        'hasConversation': false,
        'conversationId': null,
        'conversationData': null,
        'messages': [],
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des messages: $e');
      throw Exception('Erreur lors du chargement des messages: $e');
    }
  }

  /// Marque des messages comme lus dans une conversation (anciennement MessageApiService)
  Future<bool> markMessagesAsRead({
    required String numeroParent,
    required int conversationId,
  }) async {
    try {
      print('📖 Marquage des messages comme lus pour la conversation $conversationId');
      
      final response = await HttpService.post(
        '/vie-ecoles/messages/marquer-comme-lu',
        body: {
          'numero_parent': numeroParent,
          'conversation_id': conversationId,
        },
      );
      
      if (response['status'] == true || response['success'] == true) {
        print('✅ Messages marqués comme lus avec succès');
        return true;
      } else {
        print('❌ Échec du marquage comme lu: ${response['message'] ?? 'Erreur inconnue'}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Crée une nouvelle conversation (anciennement MessageApiService)
  Future<Conversation?> createConversation({
    required int parentId,
    required int schoolId,
    required String studentId,
    required String subject,
    required String message,
  }) async {
    try {
      print('🆕 Création d\'une nouvelle conversation');
      
      final response = await HttpService.post(
        '/vie-ecoles/messages/create',
        body: {
          'parent_id': parentId,
          'school_id': schoolId,
          'student_id': studentId,
          'subject': subject,
          'message': message,
        },
      );
      
      if (response['status'] == 'success' && response['data'] != null) {
        final conversation = Conversation.fromJson(response['data'] as Map<String, dynamic>);
        print('✅ Conversation créée avec succès');
        return conversation;
      } else {
        throw Exception('Échec de la création de conversation');
      }
    } catch (e) {
      print('❌ Erreur lors de la création de conversation: $e');
      return null;
    }
  }

  /// Récupère les messages/notifications spécifiques à un élève (anciennement StudentMessageService)
  Future<List<StudentMessage>> getStudentNotifications(
    String phoneNumber,
    String matricule, {
    int perPage = 20,
    int page = 1,
  }) async {
    print('🔄 Début du chargement des messages pour l\'élève: $matricule');

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

        if ((data['status'] == true || data['status'] == 'success') &&
            data['data'] != null) {
          var innerData = data['data'];
          if (innerData is Map && innerData['data'] != null) {
            innerData = innerData['data'];
            if (innerData is Map &&
                innerData['messages'] != null &&
                innerData['messages']['data'] != null) {
              final List<dynamic> messagesData = innerData['messages']['data'];
              print(
                '⚠️ Format de réponse imbriqué détecté, mais StudentMessageService ne gère pas ce format',
              );
              print(
                '✅ ${messagesData.length} messages disponibles (format conversation)',
              );
              return [];
            }
          }

          if (innerData is List) {
            final List<dynamic> messagesData = innerData;
            final messages = messagesData
                .map((json) => StudentMessage.fromJson(json))
                .toList();
            print('📚 ${messages.length} messages parsés avec succès');
            return messages;
          }

          print('❌ Format de data non reconnu');
          return [];
        } else if (data['status'] == false && data['error'] != null) {
          print('❌ Erreur API: ${data['error']}');
          return [];
        } else {
          print('❌ Status false ou data null dans la réponse');
          return [];
        }
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        throw Exception(
          'Erreur lors du chargement des messages: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Exception dans getStudentNotifications: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }
}