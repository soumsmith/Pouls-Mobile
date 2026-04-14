import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/group_message.dart';
import '../config/app_config.dart';

/// Exception pour les erreurs de rate limiting
class RateLimitException implements Exception {
  final String message;
  final int retryAfter;

  RateLimitException(this.message, this.retryAfter);

  @override
  String toString() =>
      'RateLimitException: $message (retry after $retryAfter seconds)';
}

/// Classe pour gérer le cache des données
class _CachedData {
  final List<GroupMessage> data;
  final DateTime expiry;

  _CachedData(this.data, this.expiry);

  bool isExpired() => DateTime.now().isAfter(expiry);

  int timeToExpiry() {
    final difference = expiry.difference(DateTime.now());
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  }
}

/// Service pour gérer les messages de groupe (notifications)
class GroupMessageService {
  static String get baseUrl =>
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles';

  // Cache pour éviter les appels répétés
  static final Map<String, _CachedData> _cache = {};

  // Délai d'attente après un 429 (en secondes)
  static const int _defaultRetryDelay = 2;
  static const int _maxRetryDelay = 30;

  static Future<List<GroupMessage>> getGroupMessages(
    String matricule, {
    int page = 1,
    int perPage = 20,
  }) async {
    // Vérifier le cache d'abord
    final cacheKey = '${matricule}_${page}_${perPage}';
    final cachedData = _cache[cacheKey];

    if (cachedData != null && !cachedData.isExpired()) {
      print('📦 Utilisation des données en cache pour: $cacheKey');
      print('⏰ Cache expirera dans: ${cachedData.timeToExpiry()} secondes');
      return cachedData.data;
    }

    return await _fetchGroupMessagesWithRetry(
      matricule,
      page,
      perPage,
      cacheKey,
    );
  }

  static Future<List<GroupMessage>> _fetchGroupMessagesWithRetry(
    String matricule,
    int page,
    int perPage,
    String cacheKey,
  ) async {
    int retryCount = 0;
    int retryDelay = _defaultRetryDelay;

    while (retryCount < 3) {
      try {
        final result = await _attemptFetch(matricule, page, perPage);

        // Mettre en cache uniquement les résultats réussis
        if (result.isNotEmpty) {
          _cache[cacheKey] = _CachedData(
            result,
            DateTime.now().add(const Duration(minutes: 5)),
          );
          print('📦 Résultat mis en cache pour 5 minutes: $cacheKey');
        }

        return result;
      } on RateLimitException catch (e) {
        // Gérer spécifiquement les erreurs de rate limiting
        print('🚦 Rate limit atteint, attente de ${e.retryAfter} secondes...');
        await Future.delayed(Duration(seconds: e.retryAfter));

        retryCount++;
        if (retryCount >= 3) {
          print('❌ Nombre maximum de tentatives atteint pour le rate limiting');
          rethrow;
        }
      } catch (e) {
        retryCount++;
        print('⚠️ Tentative $retryCount/3 échouée: $e');

        if (retryCount >= 3) {
          print('❌ Nombre maximum de tentatives atteint');
          rethrow;
        }

        // Attendre avant de réessayer
        print('⏳ Attente de $retryDelay secondes avant de réessayer...');
        await Future.delayed(Duration(seconds: retryDelay));

        // Augmenter le délai pour la prochaine tentative (exponential backoff)
        retryDelay = (retryDelay * 2).clamp(_defaultRetryDelay, _maxRetryDelay);
      }
    }

    throw Exception('Échec après $retryCount tentatives');
  }

  static Future<List<GroupMessage>> _attemptFetch(
    String matricule,
    int page,
    int perPage,
  ) async {
    final url =
        '$baseUrl/liste-messages-groupe/$matricule?per_page=$perPage&page=$page';

    print('🔔 API GroupMessageService - Début de la requête');
    print('📡 URL: $url');
    print('📋 Paramètres: matricule=$matricule, page=$page, per_page=$perPage');
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');

    try {
      print('🚤 Envoi de la requête GET...');

      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      stopwatch.stop();

      print('📨 Réponse reçue - Status: ${response.statusCode}');
      print('⏱️ Durée: ${stopwatch.elapsedMilliseconds}ms');
      print('📏 Taille de la réponse: ${response.body.length} caractères');
      print('📋 Headers de la réponse:');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });

      if (response.statusCode == 200) {
        print('✅ Succès - Parsing du JSON...');
        final Map<String, dynamic> data = json.decode(response.body);

        print('📊 Structure de la réponse:');
        print('   success: ${data['success']}');
        print('   status: ${data['status']}'); // Ajout du log pour 'status'
        print('   message: ${data['message']}');
        print('   data présent: ${data['data'] != null}');
        print('   data type: ${data['data'].runtimeType}');

        // Vérifier si data est un Map et contient une liste 'data'
        if (data['data'] != null &&
            data['data'] is Map &&
            data['data']['data'] != null) {
          final List<dynamic> messagesData =
              data['data']['data']; // Accéder à la liste imbriquée
          print('📝 Nombre de messages bruts: ${messagesData.length}');

          final List<GroupMessage> messages = messagesData.map((json) {
            try {
              final message = GroupMessage.fromJson(json);
              print(
                '   ✅ Message parsé: ID=${message.id}, Titre="${message.titre}", Lu=${message.estLu}',
              );
              return message;
            } catch (e) {
              print('   ❌ Erreur parsing message: $e');
              print('   📄 Données brutes: $json');
              rethrow;
            }
          }).toList();

          print('✅ ${messages.length} messages récupérés avec succès');
          print('📊 Répartition des messages:');
          final lus = messages.where((m) => m.estLu).length;
          final nonLus = messages.where((m) => !m.estLu).length;
          print('   Messages lus: $lus');
          print('   Messages non lus: $nonLus');

          return messages;
        } else {
          print('⚠️ Réponse API invalide ou données manquantes');
          print('   success: ${data['success']}');
          print('   status: ${data['status']}');
          print('   message: ${data['message'] ?? 'Aucun message'}');
          print('   data null: ${data['data'] == null}');
          print('   data is Map: ${data['data'] is Map}');
          if (data['data'] is Map) {
            print('   data["data"] null: ${data['data']['data'] == null}');
            print('   data["data"] type: ${data['data']['data']?.runtimeType}');
          }
          return [];
        }
      } else if (response.statusCode == 429) {
        // Gérer le rate limiting
        print('🚦 Rate limit atteint (429)');

        // Extraire le retry-after des headers si disponible
        int retryAfter = _defaultRetryDelay;
        final retryAfterHeader = response.headers['retry-after'];
        if (retryAfterHeader != null) {
          retryAfter = int.tryParse(retryAfterHeader) ?? _defaultRetryDelay;
          print('⏱️ Retry-After header: $retryAfter secondes');
        }

        // Afficher les informations de rate limiting
        final rateLimitLimit = response.headers['x-ratelimit-limit'];
        final rateLimitRemaining = response.headers['x-ratelimit-remaining'];
        final rateLimitReset = response.headers['x-ratelimit-reset'];

        print('📊 Informations de rate limiting:');
        print('   Limite: $rateLimitLimit requêtes');
        print('   Restantes: $rateLimitRemaining requêtes');
        print('   Reset: $rateLimitReset');

        // Lever une exception avec le délai d'attente
        throw RateLimitException('Rate limit exceeded', retryAfter);
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('📄 Corps de la réponse:');
        print(response.body);

        // Essayer de parser l'erreur si c'est du JSON
        try {
          final errorData = json.decode(response.body);
          print('📊 Détails de l\'erreur:');
          print('   success: ${errorData['success']}');
          print('   status: ${errorData['status']}');
          print('   message: ${errorData['message']}');
          print('   errors: ${errorData['errors']}');
        } catch (e) {
          print('📄 La réponse n\'est pas du JSON valide');
        }

        return [];
      }
    } on SocketException catch (e) {
      print(' Erreur de connexion réseau: $e');
      print(' Type d\'erreur: ${e.runtimeType}');
      print(' Retour d\'une liste vide en attendant la reconnexion...');
      return [];
    } on TimeoutException catch (e) {
      print(' Erreur de timeout: $e');
      print(' Retour d\'une liste vide en attendant la reconnexion...');
      return [];
    } catch (e) {
      print(' Erreur générale lors de la récupération des messages: $e');
      print(' Type d\'erreur: ${e.runtimeType}');
      print(' Stack trace:');
      print(StackTrace.current);
      return [];
    } finally {
      print('🔔 API GroupMessageService - Fin de la requête');
      print('─' * 80);
    }
  }

  /// Marque un message comme lu
  static Future<bool> markMessageAsRead(
    String messageId,
    String matricule,
  ) async {
    final url =
        '$baseUrl/message-groupe/update-statut/$messageId/$matricule?statut=1';

    print('📝 API GroupMessageService - Début de la requête de marquage');
    print('📡 URL: $url');
    print(
      '📋 Paramètres: messageId=$messageId, matricule=$matricule, statut=1',
    );
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');

    try {
      print('🚤 Envoi de la requête PUT...');

      final stopwatch = Stopwatch()..start();
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      stopwatch.stop();

      print('� Réponse reçue - Status: ${response.statusCode}');
      print('⏱️ Durée: ${stopwatch.elapsedMilliseconds}ms');
      print('📏 Taille de la réponse: ${response.body.length} caractères');
      print('📋 Headers de la réponse:');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });

      if (response.statusCode == 200) {
        print('✅ Succès - Parsing du JSON...');
        final Map<String, dynamic> data = json.decode(response.body);

        print('📊 Structure de la réponse:');
        print('   success: ${data['success']}');
        print('   message: ${data['message']}');

        if (data['success'] == true) {
          print('✅ Message marqué comme lu avec succès');
          print('   Message ID: $messageId');
          print('   Matricule: $matricule');
          return true;
        } else {
          print('⚠️ Échec du marquage');
          print('   success: ${data['success']}');
          print('   message: ${data['message'] ?? 'Aucun message'}');
          print('   errors: ${data['errors']}');
          return false;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('📄 Corps de la réponse:');
        print(response.body);

        // Essayer de parser l'erreur si c'est du JSON
        try {
          final errorData = json.decode(response.body);
          print('📊 Détails de l\'erreur:');
          print('   success: ${errorData['success']}');
          print('   message: ${errorData['message']}');
          print('   errors: ${errorData['errors']}');
        } catch (e) {
          print('📄 La réponse n\'est pas du JSON valide');
        }

        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du marquage du message: $e');
      print('📍 Type d\'erreur: ${e.runtimeType}');
      print('📄 Stack trace:');
      print(StackTrace.current);
      return false;
    } finally {
      print('📝 API GroupMessageService - Fin de la requête de marquage');
      print('─' * 80);
    }
  }

  /// Marque un message comme non lu
  static Future<bool> markMessageAsUnread(
    String messageId,
    String matricule,
  ) async {
    final url =
        '$baseUrl/message-groupe/update-statut/$messageId/$matricule?statut=0';

    print(
      '📝 API GroupMessageService - Début de la requête de marquage (non lu)',
    );
    print('📡 URL: $url');
    print(
      '📋 Paramètres: messageId=$messageId, matricule=$matricule, statut=0',
    );
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');

    try {
      print('🚤 Envoi de la requête PUT...');

      final stopwatch = Stopwatch()..start();
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      stopwatch.stop();

      print('� Réponse reçue - Status: ${response.statusCode}');
      print('⏱️ Durée: ${stopwatch.elapsedMilliseconds}ms');
      print('📏 Taille de la réponse: ${response.body.length} caractères');
      print('📋 Headers de la réponse:');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });

      if (response.statusCode == 200) {
        print('✅ Succès - Parsing du JSON...');
        final Map<String, dynamic> data = json.decode(response.body);

        print('📊 Structure de la réponse:');
        print('   success: ${data['success']}');
        print('   message: ${data['message']}');

        if (data['success'] == true) {
          print('✅ Message marqué comme non lu avec succès');
          print('   Message ID: $messageId');
          print('   Matricule: $matricule');
          return true;
        } else {
          print('⚠️ Échec du marquage');
          print('   success: ${data['success']}');
          print('   message: ${data['message'] ?? 'Aucun message'}');
          print('   errors: ${data['errors']}');
          return false;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('📄 Corps de la réponse:');
        print(response.body);

        // Essayer de parser l'erreur si c'est du JSON
        try {
          final errorData = json.decode(response.body);
          print('📊 Détails de l\'erreur:');
          print('   success: ${errorData['success']}');
          print('   message: ${errorData['message']}');
          print('   errors: ${errorData['errors']}');
        } catch (e) {
          print('📄 La réponse n\'est pas du JSON valide');
        }

        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du marquage du message: $e');
      print('📍 Type d\'erreur: ${e.runtimeType}');
      print('📄 Stack trace:');
      print(StackTrace.current);
      return false;
    } finally {
      print(
        '📝 API GroupMessageService - Fin de la requête de marquage (non lu)',
      );
      print('─' * 80);
    }
  }
}
