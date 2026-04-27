import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class EventService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';
  
  static Future<EventsResponse> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ecoles/evenements-list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EventsResponse.fromJson(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }
  
  static Future<List<Event>> getEventsList() async {
    try {
      final response = await getEvents();
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la liste des événements: $e');
    }
  }
  
  static Future<List<Event>> getEventsBySchool(String schoolCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ecoles/evenements-list?ecole=$schoolCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final eventsResponse = EventsResponse.fromJson(data);
        return eventsResponse.data;
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements de l\'école: $e');
    }
  }
}
