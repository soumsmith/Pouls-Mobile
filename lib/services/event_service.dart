import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/event.dart';
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

/// Service centralisé pour la gestion des événements
/// Fusion optimisée de event_service.dart et events_service.dart
class EventService {
  static String get baseUrl => '${AppConfig.VIE_ECOLES_API_BASE_URL}/ecoles';
  static Future<EventsResponse> getEvents({
    int page = 1,
    int perPage = 16,
    String? nomEtablissement,
    String? schoolCode,
    String? country,
    String? categorie,
    String? date,
    bool debug = false,
  }) async {
    try {
      String url = '${AppConfig.API_AFRICA_URL}/evenements-list?page=$page&per_page=$perPage';

      if (nomEtablissement != null && nomEtablissement.isNotEmpty) {
        url += '&nomEtablissement=${Uri.encodeComponent(nomEtablissement)}';
      }

      if (schoolCode != null && schoolCode.isNotEmpty) {
        url += '&ecole=${Uri.encodeComponent(schoolCode)}';
      }

      if (country != null) {
        url += '&country=${Uri.encodeComponent(country)}';
      }

      if (categorie != null) {
        url += '&categorie=${Uri.encodeComponent(categorie)}';
      }

      if (date != null) {
        url += '&date=${Uri.encodeComponent(date)}';
      }

      if (debug) {
        developer.log(
          '═══════════════════════════════════════════════════════════',
        );
        developer.log('📅 CHARGEMENT DES ÉVÉNEMENTS');
        developer.log('📄 Page: $page');
        developer.log('📊 Éléments par page: $perPage');
        if (nomEtablissement != null)
          developer.log('🏫 Établissement: $nomEtablissement');
        if (schoolCode != null) developer.log('🎓 Code école: $schoolCode');
        developer.log('🔗 URL: $url');
      }

      developer.log('[EventService] GET Request URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (debug) {
        developer.log('📥 Réponse reçue:');
        developer.log('   - Status Code: ${response.statusCode}');
        developer.log('   - Content-Type: ${response.headers['content-type']}');
        developer.log('   - Body length: ${response.body.length} caractères');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (debug) {
          developer.log('✅ Données reçues et parsées avec succès');
          developer.log(
            '═══════════════════════════════════════════════════════════',
          );
        }
        return EventsResponse.fromJson(data);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Erreur lors de la récupération des événements: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des événements');
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Récupère la liste complète des événements (première page par défaut)
  static Future<List<Event>> getEventsList({
    String? nomEtablissement,
    int page = 1,
    int perPage = 16,
  }) async {
    try {
      final response = await getEvents(
        nomEtablissement: nomEtablissement,
        page: page,
        perPage: perPage,
      );
      return response.data;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération de la liste des événements: $e',
      );
    }
  }

  /// Récupère les événements d'une école spécifique par son code
  static Future<List<Event>> getEventsBySchool(String schoolCode) async {
    try {
      final response = await getEvents(schoolCode: schoolCode);
      return response.data;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des événements de l\'école: $e',
      );
    }
  }

  /// Récupère les événements et les convertit en format UI
  static Future<List<Map<String, dynamic>>> getEventsForUI({
    int page = 1,
    int perPage = 16,
    String? nomEtablissement,
    String? schoolCode,
    String? country,
    String? categorie,
    String? date,
    bool debug = false,
  }) async {
    try {
      if (debug) {
        developer.log(
          '🔄 [EventService] Début de getEventsForUI - Page: $page, PerPage: $perPage',
        );
      }

      final eventsResponse = await getEvents(
        page: page,
        perPage: perPage,
        nomEtablissement: nomEtablissement,
        schoolCode: schoolCode,
        country: country,
        categorie: categorie,
        date: date,
        debug: debug,
      );

      if (debug) {
        developer.log(
          '📊 [EventService] ${eventsResponse.data.length} événements bruts reçus (Page ${eventsResponse.currentPage}/${eventsResponse.totalPages})',
        );
      }

      final uiEvents = eventsResponse.data.map((event) {
        try {
          return event.toUiMap();
        } catch (e) {
          developer.log(
            '❌ [EventService] Erreur conversion événement ${event.slug}: $e',
          );
          rethrow;
        }
      }).toList();

      if (debug) {
        developer.log(
          '✅ [EventService] ${uiEvents.length} événements convertis avec succès',
        );
      }

      return uiEvents;
    } catch (e) {
      developer.log('❌ [EventService] Erreur globale dans getEventsForUI: $e');
      throw Exception('Erreur lors de la conversion des événements: $e');
    }
  }

  /// Recherche des événements par terme
  static Future<List<Map<String, dynamic>>> searchEvents(
    String query, {
    String? nomEtablissement,
    String? schoolCode,
  }) async {
    try {
      final eventsResponse = await getEvents(
        nomEtablissement: nomEtablissement,
        schoolCode: schoolCode,
      );
      final allEvents = eventsResponse.data
          .map((event) => event.toUiMap())
          .toList();

      if (query.isEmpty) return allEvents;

      final searchQuery = query.toLowerCase();
      return allEvents.where((event) {
        return (event['title'] as String).toLowerCase().contains(searchQuery) ||
            (event['subtitle'] as String).toLowerCase().contains(searchQuery) ||
            (event['establishment'] as String).toLowerCase().contains(
              searchQuery,
            ) ||
            (event['type'] as String).toLowerCase().contains(searchQuery) ||
            (event['content'] as String).toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      developer.log('❌ Erreur lors de la recherche des événements: $e');
      throw Exception('Erreur lors de la recherche des événements: $e');
    }
  }

  /// Filtre les événements par statut
  static List<Map<String, dynamic>> filterEventsByStatus(
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
          final eventDate = event['date'] as String;
          return eventDate.contains('${today.day}') &&
              eventDate.contains(_getMonthName(today.month));
        }).toList();
      case 'cette semaine':
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));

        return events.where((event) {
          final eventDate = event['date'] as String;
          return eventDate.contains(weekStart.day.toString()) ||
              eventDate.contains(weekEnd.day.toString());
        }).toList();
      case 'tous':
      default:
        return events;
    }
  }

  /// Helper pour obtenir le nom du mois
  static String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }
}
