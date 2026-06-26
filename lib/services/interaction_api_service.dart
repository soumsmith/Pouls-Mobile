import '../models/interaction.dart';
import 'http_service.dart';
import 'auth_service.dart';

/// Service pour la gestion des interactions (commentaires, partages, notes) via l'API vie-ecoles
class InteractionApiService {
  // L'URL de base est gérée par HttpService qui utilise AppConfig

  /// Créer une nouvelle interaction (commentaire, partage, note)
  ///
  /// Endpoint: POST /vie-ecoles/interactions/store
  /// Body: {
  ///   "video_id": 1,
  ///   "user_id": 6,
  ///   "type": "comment",
  ///   "content": "Belle présentation. Nous sommes fière de toi"
  /// }
  static Future<Interaction?> createInteraction({
    required int videoId,
    required int userId,
    required String type,
    String? content,
  }) async {
    try {
      print(
        '💬 Création d\'une interaction: video=$videoId, user=$userId, type=$type',
      );

      final endpoint = '/videos/interaction/$videoId';
      final body = {
        'user_id': userId,
        'type': type,
        if (content != null) 'content': content,
      };

      print('🌐 POST URL: ${HttpService.baseUrl}$endpoint');
      print('📦 POST Data: $body');

      final response = await HttpService.post(
        endpoint,
        body: body,
      );

      print('💬 Réponse de l\'API: $response');

      // Gérer différents formats de réponse
      if (response['data'] != null) {
        final interaction = Interaction.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        print('✅ Interaction créée avec succès: ${interaction.id}');
        return interaction;
      } else if (response['status'] == 'success' || 
                 response['success'] == true ||
                 response['message'] == 'Interaction saved successfully') {
        // Si l'API retourne un message de succès mais pas de data, on retourne null
        // et on recharge la liste des commentaires
        print('✅ Interaction créée avec succès (message de confirmation)');
        return null;
      } else {
        final errorMsg = response['message'] ?? 'Erreur inconnue';
        print('❌ Échec de la création d\'interaction: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Erreur lors de la création d\'interaction: $e');
      rethrow;
    }
  }

  /// Lister les interactions d'une vidéo
  ///
  /// Endpoint: GET /vie-ecoles/interactions/list
  /// Query params: video_id=1, type=comment
  static Future<List<Interaction>> listInteractions({
    required int videoId,
    required String type,
  }) async {
    try {
      print('💬 Récupération des interactions: video=$videoId, type=$type');

      final endpoint = '/videos/interactions/$videoId?type=$type';

      final response = await HttpService.get(
        endpoint,
        showNotification: false,
      );

      print('💬 Réponse de l\'API: $response');

      if (response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final interactions = data
            .map((item) => Interaction.fromJson(item as Map<String, dynamic>))
            .toList();

        print('✅ ${interactions.length} interactions récupérées');
        return interactions;
      } else {
        print('❌ Échec de la récupération des interactions: pas de data');
        return [];
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des interactions: $e');
      return [];
    }
  }

  /// Supprimer un commentaire
  ///
  /// Endpoint: DELETE /vie-ecoles/interactions/comment/{id_comment}?user_id={idUser}
  static Future<bool> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    try {
      print('🗑️ Suppression du commentaire: id=$commentId, user=$userId');
      print('🌐 URL: ${HttpService.baseUrl}/vie-ecoles/interactions/comment/$commentId?user_id=$userId');

      try {
        final response = await HttpService.delete(
          '/vie-ecoles/interactions/comment/$commentId?user_id=$userId',
        );

        if (response['status'] == 'success' || response['success'] == true) {
          print('✅ Commentaire supprimé avec succès');
          return true;
        } else {
          // Some APIs return a message field on success
          final message = response['message']?.toString().toLowerCase() ?? '';
          if (message.contains('success') || message.contains('deleted') || message.contains('supprim')) {
            print('✅ Commentaire supprimé avec succès (message: ${response['message']})');
            return true;
          }
          print(
            '❌ Échec de la suppression du commentaire: ${response['message'] ?? 'Erreur inconnue'}',
          );
          return false;
        }
      } catch (httpError) {
        // HttpService may throw on non-JSON responses (e.g. plain text "deleted")
        // or on 204 No Content — treat as success if it's not a real network error
        final errorStr = httpError.toString().toLowerCase();
        if (errorStr.contains('204') || errorStr.contains('success') || errorStr.contains('deleted')) {
          print('✅ Commentaire supprimé avec succès (réponse non-JSON)');
          return true;
        }
        print('❌ Erreur HTTP lors de la suppression: $httpError');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression du commentaire: $e');
      return false;
    }
  }

  /// Modifier un commentaire
  ///
  /// Endpoint: POST /vie-ecoles/interactions/comment/update/{id_comment}
  /// Body: {
  ///   "user_id": 1,
  ///   "content": "Voici mon nouveau texte pour le commentaire !"
  /// }
  static Future<bool> updateComment({
    required int commentId,
    required int userId,
    required String content,
  }) async {
    try {
      print('✏️ Modification du commentaire: id=$commentId, user=$userId');
      print('🌐 URL: ${HttpService.baseUrl}/vie-ecoles/interactions/comment/update/$commentId');

      final response = await HttpService.post(
        '/vie-ecoles/interactions/comment/update/$commentId',
        body: {'user_id': userId, 'content': content},
      );

      if (response['status'] == 'success' || response['success'] == true) {
        print('✅ Commentaire modifié avec succès');
        return true;
      } else {
        print(
          '❌ Échec de la modification du commentaire: ${response['message'] ?? 'Erreur inconnue'}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la modification du commentaire: $e');
      return false;
    }
  }

  /// Aimer/Liker ou Disliker une vidéo
  ///
  /// Endpoint: POST /vie-ecoles/interactions/like
  /// Body: {
  ///   "video_id": 1,
  ///   "user_id": 6,
  ///   "type": "like" // ou "dislike"
  /// }
  static Future<bool> toggleLike({
    required int videoId,
    required int userId,
    required String type, // "like" ou "dislike"
  }) async {
    try {
      print('👍 Enregistrement interaction: video=$videoId, user=$userId');
      print('🌐 URL: ${HttpService.baseUrl}/videos/like/$videoId');

      final response = await HttpService.post(
        '/videos/like/$videoId',
        body: {
          'user_id': userId,
        },
      );

      print('👍 Réponse de l\'API: $response');

      final msg = response['message']?.toString().toLowerCase() ?? '';
      final isSuccess = response['status'] == 'success' ||
          response['success'] == true ||
          msg.contains('success') ||
          msg.contains('succè') ||
          msg.contains('succes') ||
          msg.contains('enregistré') ||
          response['data'] != null;

      if (isSuccess) {
        print('✅ Like/Dislike enregistré avec succès');
        return true;
      } else {
        print(
          "❌ Échec de l'enregistrement du Like/Dislike: ${response['message'] ?? 'Erreur inconnue'}",
        );
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement du Like/Dislike: $e');
      return false;
    }
  }

  /// Récupérer l'ID utilisateur de l'utilisateur connecté
  static int? getCurrentUserId() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      print('⚠️ Aucun utilisateur connecté');
      return null;
    }

    // L'ID utilisateur peut être une chaîne, on essaie de la convertir en int
    try {
      return int.parse(currentUser.id);
    } catch (e) {
      print(
        '⚠️ Impossible de convertir l\'ID utilisateur en int: ${currentUser.id}',
      );
      return null;
    }
  }
}
