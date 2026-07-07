import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/event_rating_comment.dart';
import '../config/app_config.dart';

class EventRatingService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static String _parseError(http.Response response) {
    String errorMessage = 'Erreur HTTP ${response.statusCode}';
    try {
      final errorData = json.decode(response.body);
      if (errorData['message'] != null && errorData['message'].toString().isNotEmpty) {
        errorMessage = errorData['message'];
      } else if (errorData['exception'] != null) {
        errorMessage = 'Erreur serveur (${errorData['exception'].toString().split('\\').last})';
      }
    } catch (_) {
      if (response.statusCode == 404) {
        errorMessage = 'Service indisponible ou introuvable (404)';
      } else if (response.statusCode >= 500) {
        errorMessage = 'Erreur interne du serveur (${response.statusCode})';
      }
    }
    return errorMessage;
  }
  
  // Récupérer tous les commentaires et notations d'un événement
  static Future<List<EventRatingComment>> getEventComments(String eventSlug, {int page = 1}) async {
    try {
      final url = '$baseUrl/forums/$eventSlug/commentaires?per_page=50&page=$page';
      print('🌐 GET $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> commentsList = [];
        
        if (data['commentaire'] != null && data['commentaire']['data'] != null) {
          commentsList = data['commentaire']['data'];
        } else {
          commentsList = data['data'] ?? [];
        }

        return commentsList.map((item) {
          final mapItem = item as Map<String, dynamic>;
          final mapped = {
            'id': mapItem['id']?.toString() ?? '',
            'event_slug': eventSlug,
            'user_id': mapItem['userid']?.toString() ?? mapItem['user_id']?.toString() ?? '',
            'user_name': mapItem['author_name'] ?? mapItem['nom'] ?? mapItem['user_name'] ?? '',
            'user_avatar': mapItem['avatar'] ?? mapItem['user_avatar'] ?? '',
            'rating': mapItem['rating'] ?? 0,
            'comment': mapItem['contenu'] ?? mapItem['content'] ?? mapItem['comment'] ?? '',
            'created_at': mapItem['created_at'] ?? '',
          };
          return EventRatingComment.fromJson(mapped);
        }).toList();
      } else if (response.statusCode == 404) {
        // Le forum/événement n'existe pas ou n'a pas de commentaires
        return [];
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commentaires: $e');
    }
  }
  
  // Récupérer le résumé des notations d'un événement
  static Future<EventRatingSummary> getEventRatingSummary(String eventSlug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evenements/$eventSlug/rating-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EventRatingSummary.fromJson(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du résumé des notations: $e');
    }
  }
  
  // Ajouter un commentaire et une notation
  static Future<EventRatingComment> addComment({
    required String eventSlug,
    required String userId,
    required String userName,
    required String userAvatar,
    required int rating,
    required String comment,
  }) async {
    try {
      final commentData = {
        'nom': userName,
        'userid': int.tryParse(userId) ?? 0,
        'contenu': comment,
      };

      final url = Uri.parse('$baseUrl/forums/$eventSlug/commentaires');
      print('🌐 POST $url');
      print('📦 Payload: ${json.encode(commentData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(commentData),
      );

      print('📥 Response [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('id') || data.containsKey('created_at')) {
            return EventRatingComment.fromJson(data);
          }
        } catch (_) {}
        // Return dummy object if parsing fails (API typically returns just a success message)
        return EventRatingComment(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          eventSlug: eventSlug,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du commentaire: $e');
    }
  }
  
  // Mettre à jour un commentaire
  static Future<EventRatingComment> updateComment({
    required String commentId,
    required int rating,
    required String comment,
  }) async {
    try {
      final updateData = {
        'rating': rating,
        'comment': comment,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/evenements/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EventRatingComment.fromJson(data);
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du commentaire: $e');
    }
  }
  
  // Supprimer un commentaire
  static Future<bool> deleteComment(String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/evenements/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du commentaire: $e');
    }
  }
  
  // Vérifier si l'utilisateur a déjà commenté cet événement
  static Future<EventRatingComment?> getUserComment(String eventSlug, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evenements/$eventSlug/comments/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EventRatingComment.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // L'utilisateur n'a pas encore commenté
      } else {
        throw Exception(_parseError(response));
      }
    } catch (e) {
      throw Exception('Erreur lors de la vérification du commentaire utilisateur: $e');
    }
  }
}
