import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ecole_detail.dart';
import '../config/app_config.dart';

/// Service pour gérer les données de l'école d'un élève
class EcoleEleveService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  // Cache pour stocker les données de l'école par élève
  static final Map<String, EcoleData> _ecoleCache = {};

  /// Récupère les paramètres de l'école pour un élève et les met en cache
  static Future<EcoleData> getEcoleParametresForEleve(String paramEcole) async {
    print('');
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    print('PARAMÈTRES DE L\'ÉCOLE POUR L\'ÉLÈVE');
    print('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
    print('Paramètre école: $paramEcole');

    // Vérifier si les données sont déjà en cache
    if (_ecoleCache.containsKey(paramEcole)) {
      print('Données trouvées en cache pour l\'école: $paramEcole');
      print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
      print('');
      return _ecoleCache[paramEcole]!;
    }

    final url = '$baseUrl/vie-ecoles/parametre/ecole?ecole=$paramEcole';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['data'] != null) {
          final ecoleData = EcoleData.fromJson(data['data']);

          // Mettre en cache les données
          _ecoleCache[paramEcole] = ecoleData;

          print(
            '✅ Paramètres de l\'école récupérés et mis en cache avec succès',
          );
          print('📊 Périodes d\'inscription:');
          print(
            '   - Préinscription: ${ecoleData.debutPreinscrit} au ${ecoleData.finPreinscrit}',
          );
          print(
            '   - Inscription: ${ecoleData.debutInscrit} au ${ecoleData.finInscrit}',
          );
          print(
            '   - Réservation: ${ecoleData.debutReservation} au ${ecoleData.finReservation}',
          );
          print('═══════════════════════════════════════════════════════════');
          print('');
          return ecoleData;
        } else {
          print('⚠️ Aucune donnée de paramètre trouvée dans la réponse');
          print('═══════════════════════════════════════════════════════════');
          print('');
          throw Exception('Aucune donnée de paramètre trouvée');
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print(
        '💥 Exception lors de la récupération des paramètres de l\'école: $e',
      );
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception(
        'Erreur lors de la récupération des paramètres de l\'école: $e',
      );
    }
  }

  /// Récupère les données de l'école depuis le cache
  static EcoleData? getEcoleDataFromCache(String paramEcole) {
    return _ecoleCache[paramEcole];
  }

  /// Vérifie si les inscriptions sont ouvertes
  static bool isInscriptionsOuvertes(EcoleData ecoleData) {
    final now = DateTime.now();
    final debutInscrit = DateTime.tryParse(ecoleData.debutInscrit ?? '');
    final finInscrit = DateTime.tryParse(ecoleData.finInscrit ?? '');

    if (debutInscrit != null && finInscrit != null) {
      return now.isAfter(debutInscrit) && now.isBefore(finInscrit);
    }
    return false;
  }

  /// Vérifie si les préinscriptions sont ouvertes
  static bool isPreinscriptionsOuvertes(EcoleData ecoleData) {
    final now = DateTime.now();
    final debutPreinscrit = DateTime.tryParse(ecoleData.debutPreinscrit ?? '');
    final finPreinscrit = DateTime.tryParse(ecoleData.finPreinscrit ?? '');

    if (debutPreinscrit != null && finPreinscrit != null) {
      return now.isAfter(debutPreinscrit) && now.isBefore(finPreinscrit);
    }
    return false;
  }

  /// Vérifie si les réservations sont ouvertes
  static bool isReservationsOuvertes(EcoleData ecoleData) {
    final now = DateTime.now();
    final debutReservation = DateTime.tryParse(
      ecoleData.debutReservation ?? '',
    );
    final finReservation = DateTime.tryParse(ecoleData.finReservation ?? '');

    if (debutReservation != null && finReservation != null) {
      return now.isAfter(debutReservation) && now.isBefore(finReservation);
    }
    return false;
  }

  /// Vide le cache (utile pour les tests ou forcer un rechargement)
  static void clearCache() {
    _ecoleCache.clear();
    print('🗑️ Cache des écoles vidé');
  }

  /// Retourne les statistiques d'inscription actuelles
  static Map<String, bool> getStatutsInscription(EcoleData ecoleData) {
    return {
      'preinscription': isPreinscriptionsOuvertes(ecoleData),
      'inscription': isInscriptionsOuvertes(ecoleData),
      'reservation': isReservationsOuvertes(ecoleData),
    };
  }

  /// Récupère les détails complets d'un élève
  static Future<Map<String, dynamic>> getEleveDetail(
    String matricule,
    String ecoleCode,
  ) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('👤 DÉTAILS DE L\'ÉLÈVE');
    print('═══════════════════════════════════════════════════════════');
    print('🎫 Matricule: $matricule');
    print('🏷️ Code école: $ecoleCode');

    final url = '$baseUrl/vie-ecoles/eleve/detail/$matricule?ecole=$ecoleCode';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['data'] != null) {
          final eleveData = data['data'] as Map<String, dynamic>;

          // Ajouter le code école aux données de l'élève
          eleveData['ecole'] = ecoleCode;
          eleveData['ecole_code'] = ecoleCode;

          print('✅ Détails de l\'élève récupérés avec succès');
          print('📊 Informations principales:');
          print('   - Nom: ${eleveData['nom']} ${eleveData['prenoms']}');
          print('   - Matricule: ${eleveData['matricule']}');
          print('   - Niveau: ${eleveData['niveau']}');
          print('   - Filière: ${eleveData['filiere']}');
          print('   - Sexe: ${eleveData['sexe']}');
          print('   - Date de naissance: ${eleveData['datenaissance']}');
          print('   - Code école ajouté: $ecoleCode');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return eleveData;
        } else {
          print('⚠️ Aucune donnée d\'élève trouvée dans la réponse');
          print('═══════════════════════════════════════════════════════════');
          print('');
          throw Exception('Aucune donnée d\'élève trouvée');
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des détails de l\'élève: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception(
        'Erreur lors de la récupération des détails de l\'élève: $e',
      );
    }
  }
}
