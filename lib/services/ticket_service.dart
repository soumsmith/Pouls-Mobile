import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/ticket_category.dart';

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
        final Map<String, dynamic> data = json.decode(response.body);
        final categoriesResponse = TicketCategoriesResponse.fromJson(data);
        return categoriesResponse.data;
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

  /// Commander un ticket pour un événement
  static Future<Map<String, dynamic>> purchaseTicket({
    required String eventId,
    required String categoryId,
  }) async {
    try {
      final url = '$baseUrl/vie-ecoles/billetterie/participer/$eventId';
      developer.log('POST Request URL: $url');
      developer.log('Request Body: categoryId=$categoryId');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'category_id': categoryId}),
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
}
