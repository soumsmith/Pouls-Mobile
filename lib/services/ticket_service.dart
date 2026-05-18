import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/ticket_category.dart';
import '../models/user_ticket.dart';

class TicketService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  /// Récupérer les catégories de tickets pour un événement
  static Future<List<TicketCategory>> getTicketCategories(
    String eventId, {
    String? fallbackSlug,
  }) async {
    try {
      // Essayer d'abord avec l'ID fourni
      final url = '$baseUrl/vie-ecoles/billetterie/categories/$eventId';
      developer.log('GET Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // L'API retourne directement un array, pas un objet wrapper
        final List<dynamic> data = json.decode(response.body);
        final categories = (data as List)
            .map((item) => TicketCategory.fromJson(item as Map<String, dynamic>))
            .toList();
        return categories;
      } else {
        throw Exception(
          'Erreur HTTP: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('Erreur lors de la récupération des catégories: $e');
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  /// Commander des tickets pour un événement
  /// tickets: Map<categoryId, quantity> ex: {"1": 2, "2": 1}
  static Future<Map<String, dynamic>> purchaseTicket({
    required String eventId,
    required Map<String, int> tickets,
    required String phoneNumber,
  }) async {
    try {
      final url = '$baseUrl/vie-ecoles/billetterie/participer/$eventId';
      developer.log('POST Request URL: $url');
      
      final body = {
        'telephone': phoneNumber,
        'tickets': tickets,
      };
      developer.log('Request Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Erreur HTTP: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('Erreur lors de la commande du ticket: $e');
      throw Exception('Erreur lors de la commande du ticket: $e');
    }
  }

  /// Récupérer les tickets achetés de l'utilisateur connecté par téléphone
  static Future<UserTicketsResponse> getUserTickets(String phoneNumber) async {
    try {
      final url = '$baseUrl/vie-ecoles/billetterie/ticket-commande/$phoneNumber';
      developer.log('GET Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      developer.log('Response Status: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return UserTicketsResponse.fromJson(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Erreur lors de la récupération des tickets utilisateur: $e');
      throw Exception('Erreur lors de la récupération des tickets utilisateur: $e');
    }
  }
}
