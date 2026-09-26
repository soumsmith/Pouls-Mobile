import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/echeance_notification.dart';
import '../config/app_config.dart';

/// Service pour gérer les notifications d'échéance
class EcheanceService {
  static String get baseUrl => '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles';

  // Cache par matricule pour éviter les appels répétés — un unique cache
  // statique partagé par tous les enfants affichait la notification
  // d'échéance du premier enfant consulté pour tous les autres tant que le
  // cache n'expirait pas (5 min), quel que soit le matricule demandé.
  static final Map<String, EcheanceNotification> _cache = {};
  static final Map<String, DateTime> _cacheExpiry = {};

  static Future<EcheanceNotification> getEcheanceNotification(String matricule) async {
    // Vérifier le cache d'abord
    final cached = _cache[matricule];
    final expiry = _cacheExpiry[matricule];
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
      print('📦 Utilisation des données d\'échéance en cache ($matricule)');
      return cached;
    }

    return await _fetchEcheanceNotification(matricule);
  }

  static Future<EcheanceNotification> _fetchEcheanceNotification(String matricule) async {
    final url = '$baseUrl/echeance-notification/$matricule';

    print('💰 API EcheanceService - Début de la requête');
    print('📡 URL: $url');
    print('📋 Paramètre: matricule=$matricule');
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');

    try {
      print('Envoi de la requête GET...');

      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print(' Timeout après 10 secondes');
          throw TimeoutException('Timeout de 10 secondes dépassé');
        },
      );
      stopwatch.stop();

      print(' Réponse reçue - Status: ${response.statusCode}');
      print(' Durée: ${stopwatch.elapsedMilliseconds}ms');
      print(' Taille de la réponse: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        print(' Succès - Parsing du JSON...');
        final Map<String, dynamic> data = json.decode(response.body);

        debugPrint(
          '📦 Body brut (matricule=$matricule): '
          '${const JsonEncoder.withIndent('  ').convert(data)}',
        );
        print(' Structure de la réponse:');
        print('   status: ${data['status']}');
        print('   message: ${data['message']}');
        print('   data (texte affiché au parent): ${data['data']}');

        final notification = EcheanceNotification.fromJson(data);

        // Mettre en cache le résultat pour 5 minutes, pour ce matricule
        _cache[matricule] = notification;
        _cacheExpiry[matricule] = DateTime.now().add(const Duration(minutes: 5));
        print(' Résultat mis en cache pour 5 minutes ($matricule)');

        print(' Notification d\'échéance récupérée avec succès');
        print('   Statut: ${notification.status ? 'Ir régulier' : 'Régulier'}');
        print('   Message: ${notification.message}');
        
        return notification;
      } else {
        print(' Erreur HTTP: ${response.statusCode}');
        print(' Corps de la réponse: ${response.body}');

        // Retourner une notification vide en cas d'erreur
        final emptyNotification = EcheanceNotification(
          data: '',
          status: false,
          message: 'Erreur HTTP ${response.statusCode}',
        );
        
        return emptyNotification;
      }
    } on SocketException catch (e) {
      print(' Erreur de connexion réseau: $e');
      print(' Type d\'erreur: ${e.runtimeType}');
      
      // En cas d'erreur de connexion, retourner une notification par défaut
      // mais ne pas la marquer comme une erreur fatale
      final defaultNotification = EcheanceNotification(
        data: 'Information non disponible temporairement',
        status: false,
        message: 'connexion_temporaire',
      );
      
      return defaultNotification;
    } on TimeoutException catch (e) {
      print(' Erreur de timeout: $e');
      
      final defaultNotification = EcheanceNotification(
        data: 'Information non disponible (timeout)',
        status: false,
        message: 'timeout',
      );
      
      return defaultNotification;
    } catch (e) {
      print(' Erreur générale lors de la récupération: $e');
      print(' Type d\'erreur: ${e.runtimeType}');

      // Retourner une notification vide en cas d'erreur
      final emptyNotification = EcheanceNotification(
        data: '',
        status: false,
        message: 'Erreur inconnue',
      );
      
      return emptyNotification;
    } finally {
      print('💰 API EcheanceService - Fin de la requête');
      print('─' * 80);
    }
  }

  /// Vide le cache des notifications d'échéance (tous matricules)
  static void clearCache() {
    _cache.clear();
    _cacheExpiry.clear();
    print('🗑️ Cache des notifications d\'échéance vidé');
  }
}
