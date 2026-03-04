import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class EventsService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/ecoles';
  
  /// Récupère la liste des événements depuis l'API
  /// 
  /// Endpoint: GET /api/ecoles/evenements-list?page=1&per_page=20
  /// Endpoint: GET /api/ecoles/evenements-list?nomEtablissement={nomEtablissement}&page=1&per_page=20
  Future<EventsResponse> getEvents({
    int page = 1,
    int perPage = 20,
    String? nomEtablissement,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📅 CHARGEMENT DES ÉVÉNEMENTS');
    print('═══════════════════════════════════════════════════════════');
    print('📄 Page: $page');
    print('📊 Éléments par page: $perPage');
    if (nomEtablissement != null) {
      print('🏫 Établissement: $nomEtablissement');
    }
    
    String url = '$baseUrl/evenements-list?page=$page&per_page=$perPage';
    if (nomEtablissement != null && nomEtablissement.isNotEmpty) {
      url += '&nomEtablissement=${Uri.encodeComponent(nomEtablissement)}';
    }
    
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Données reçues et parsées avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return EventsResponse.fromJson(data);
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des événements: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Récupère les événements et les convertit en format UI
  Future<List<Map<String, dynamic>>> getEventsForUI({
    int page = 1,
    int perPage = 20,
    String? nomEtablissement,
  }) async {
    try {
      final eventsResponse = await getEvents(
        page: page, 
        perPage: perPage, 
        nomEtablissement: nomEtablissement
      );
      return eventsResponse.data.map((event) => event.toUiMap()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la conversion des événements: $e');
    }
  }

  /// Recherche des événements par terme
  Future<List<Map<String, dynamic>>> searchEvents(String query, {String? nomEtablissement}) async {
    try {
      final eventsResponse = await getEvents(nomEtablissement: nomEtablissement);
      final allEvents = eventsResponse.data.map((event) => event.toUiMap()).toList();
      
      if (query.isEmpty) return allEvents;
      
      final searchQuery = query.toLowerCase();
      return allEvents.where((event) {
        return (event['title'] as String).toLowerCase().contains(searchQuery) ||
               (event['subtitle'] as String).toLowerCase().contains(searchQuery) ||
               (event['establishment'] as String).toLowerCase().contains(searchQuery) ||
               (event['type'] as String).toLowerCase().contains(searchQuery) ||
               (event['content'] as String).toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des événements: $e');
    }
  }

  /// Filtre les événements par statut
  List<Map<String, dynamic>> filterEventsByStatus(
    List<Map<String, dynamic>> events,
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'à venir':
        return events.where((event) => event['available'] as bool).toList();
      case 'passés':
        return events.where((event) => !(event['available'] as bool)).toList();
      case "aujourd'hui":
        final today = DateTime.now();
        return events.where((event) {
          // Logique simplifiée pour la démo - à améliorer avec des dates réelles
          final eventDate = event['date'] as String;
          return eventDate.contains('${today.day}') && 
                 eventDate.contains(_getMonthName(today.month));
        }).toList();
      case 'cette semaine':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        
        return events.where((event) {
          // Logique simplifiée - à améliorer avec une meilleure gestion des dates
          final eventDate = event['date'] as String;
          return eventDate.contains(weekStart.day.toString()) ||
                 eventDate.contains(weekEnd.day.toString());
        }).toList();
      case 'tous':
      default:
        return events;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}
