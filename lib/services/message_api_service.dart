import '../models/conversation.dart';
import 'http_service.dart';
import 'auth_service.dart';

/// Service pour la gestion des messages via l'API vie-ecoles
class MessageApiService {
  static const String _baseUrl = '/vie-ecoles/messages';

  /// Récupère la liste des conversations/messages pour un parent
  /// 
  /// Endpoint: GET /vie-ecoles/messages/liste/{phoneNumber}
  /// Response: {
  ///   "status": "success",
  ///   "data": [Conversation...]
  /// }
  @deprecated
  Future<List<Conversation>> getMessagesForParent(String phoneNumber) async {
    try {
      print('📨 Récupération des messages pour: $phoneNumber');
      
      final response = await HttpService.get('$_baseUrl/liste/$phoneNumber');
      
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final conversations = data
            .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
            .toList();
        
        print('✅ ${conversations.length} conversations récupérées');
        return conversations;
      } else {
        throw Exception('Réponse invalide de l\'API');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des messages: $e');
      throw Exception('Impossible de charger les messages: $e');
    }
  }

  /// Récupère les messages d'un élève spécifique
  /// 
  /// Endpoint: GET /messages/{numero_parent}/eleve/{matricule}?per_page=20&page=1
  /// Response: {
  ///   "status": true,
  ///   "data": {
  ///     "status": "success",
  ///     "data": {
  ///       "conversation": {...},
  ///       "messages": {
  ///         "data": [...]
  ///       }
  ///     }
  ///   }
  /// }
  Future<Map<String, dynamic>> getMessagesForStudent(String phoneNumber, String matricule, {int perPage = 20, int page = 1}) async {
    try {
      print('📨 Récupération des messages pour l\'élève $matricule du parent $phoneNumber');
      
      final response = await HttpService.get('$_baseUrl/$phoneNumber/eleve/$matricule?per_page=$perPage&page=$page');
      
      // Selon la documentation: si success = true et contient un objet conversation
      if (response['status'] == true && response['data'] != null) {
        final innerData = response['data'];
        if (innerData['status'] == 'success' && innerData['data'] != null) {
          final conversationData = innerData['data'];
          
          // Vérifier s'il y a une conversation existante
          final hasConversation = conversationData['conversation'] != null;
          final conversationId = hasConversation ? conversationData['conversation']['id'] : null;
          
          print('📝 Conversation existante: $hasConversation');
          if (conversationId != null) {
            print('🆔 ID de conversation: $conversationId');
          }
          
          // Extraire les messages s'ils existent
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
      
      // Si la réponse est false ou ne contient pas d'objet conversation
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

  /// Récupère les messages pour l'utilisateur connecté
  Future<List<Conversation>> getCurrentUserMessages() async {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    // Cette méthode est obsolète, utilisez plutôt getMessagesForStudent
    // avec un matricule d'élève spécifique
    throw Exception(
      'Cette méthode est obsolète. Utilisez getMessagesForStudent(phoneNumber, matricule) '
      'avec le matricule de l\'élève souhaité.'
    );
  }

  /// Marque des messages comme lus dans une conversation
  /// 
  /// Endpoint: /vie-ecoles/messages/marquer-comme-lu
  /// Body: {
  ///   "numero_parent": "0707074647",
  ///   "conversation_id": 1
  /// }
  Future<bool> markMessagesAsRead({
    required String numeroParent,
    required int conversationId,
  }) async {
    try {
      print('📖 Marquage des messages comme lus pour la conversation $conversationId');
      
      final response = await HttpService.post(
        '$_baseUrl/marquer-comme-lu',
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

  /// Envoie un nouveau message dans une conversation
  /// 
  /// Endpoint: POST /vie-ecoles/messages/{conversationId}/send
  /// Body: {
  ///   "sender_type": "parent",
  ///   "sender_id": parentId,
  ///   "body": "message content",
  ///   "message_type": "text"
  /// }
  Future<bool> sendMessage({
    required int conversationId,
    required int parentId,
    required String body,
    String messageType = 'text',
  }) async {
    try {
      print('📤 Envoi d\'un message dans la conversation $conversationId');
      
      final response = await HttpService.post(
        '$_baseUrl/$conversationId/send',
        body: {
          'sender_type': 'parent',
          'sender_id': parentId,
          'body': body,
          'message_type': messageType,
        },
      );
      
      if (response['status'] == 'success') {
        print('✅ Message envoyé avec succès');
        return true;
      } else {
        throw Exception('Échec de l\'envoi du message');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      return false;
    }
  }

  /// Crée une nouvelle conversation
  /// 
  /// Endpoint: POST /vie-ecoles/messages/create
  /// Body: {
  ///   "parent_id": parentId,
  ///   "school_id": schoolId,
  ///   "student_id": studentId,
  ///   "subject": "sujet",
  ///   "message": "premier message"
  /// }
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
        '$_baseUrl/create',
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
}
