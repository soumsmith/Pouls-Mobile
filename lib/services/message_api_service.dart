import '../models/conversation.dart';
import 'http_service.dart';
import 'auth_service.dart';

/// Service pour la gestion des messages via l'API vie-ecoles
class MessageApiService {
  static const String _baseUrl = '/api/vie-ecoles/messages';

  /// Récupère la liste des conversations/messages pour un parent
  /// 
  /// Endpoint: GET /api/vie-ecoles/messages/liste/{phoneNumber}
  /// Response: {
  ///   "status": "success",
  ///   "data": [Conversation...]
  /// }
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

  /// Récupère les messages pour l'utilisateur connecté
  Future<List<Conversation>> getCurrentUserMessages() async {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    return getMessagesForParent(currentUser.phone);
  }

  /// Marque une conversation comme lue
  /// 
  /// Endpoint: POST /api/vie-ecoles/messages/{conversationId}/read
  /// Body: { "parent_id": parentId }
  Future<bool> markConversationAsRead(int conversationId, int parentId) async {
    try {
      print('📖 Marquage de la conversation $conversationId comme lue');
      
      final response = await HttpService.post(
        '$_baseUrl/$conversationId/read',
        body: {
          'parent_id': parentId,
        },
      );
      
      if (response['status'] == 'success') {
        print('✅ Conversation marquée comme lue');
        return true;
      } else {
        throw Exception('Échec du marquage comme lu');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Envoie un nouveau message dans une conversation
  /// 
  /// Endpoint: POST /api/vie-ecoles/messages/{conversationId}/send
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
  /// Endpoint: POST /api/vie-ecoles/messages/create
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
