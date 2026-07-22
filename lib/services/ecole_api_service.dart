import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../config/app_config.dart';
import '../utils/api_exception_handler.dart';

class EcoleApiService {
  static String get baseUrl =>
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/ecoles/list';

  /// Récupère la liste des écoles depuis l'API avec filtres optionnels
  static Future<List<Ecole>> getEcoles({
    int page = 1,
    int perPage = 50,
    String? pays,
    String? ville,
    String? quartier,
    String? nomEtablissement,
    String? categorie,
    String? codepays,
    String? statut,
    String? ordreEnseignement,
    String? programmesEnseignement,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 CHARGEMENT DES ÉCOLES (PAGE $page - $perPage ÉLÉMENTS/PAGE)');
    print('═══════════════════════════════════════════════════════════');

    // Construction des paramètres de requête
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    // Ajout des filtres s'ils sont fournis
    if (pays != null && pays.isNotEmpty) queryParams['pays'] = pays;
    if (ville != null && ville.isNotEmpty) queryParams['ville'] = ville;
    if (quartier != null && quartier.isNotEmpty)
      queryParams['quartier'] = quartier;
    if (nomEtablissement != null && nomEtablissement.isNotEmpty)
      queryParams['nomEtablissement'] = nomEtablissement;
    if (categorie != null && categorie.isNotEmpty)
      queryParams['categorie'] = categorie;
    if (codepays != null && codepays.isNotEmpty)
      queryParams['codepays'] = codepays;
    if (statut != null && statut.isNotEmpty)
      queryParams['statut'] = statut;
    if (ordreEnseignement != null && ordreEnseignement.isNotEmpty)
      queryParams['ordre_enseignement'] = ordreEnseignement;
    if (programmesEnseignement != null && programmesEnseignement.isNotEmpty)
      queryParams['programmes_enseignement'] = programmesEnseignement;

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('🔗 URL: $uri');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            uri,
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

        if (data['data'] != null && data['data'] is List) {
          final List<dynamic> ecolesData = data['data'];
          print('✅ ${ecolesData.length} école(s) récupérée(s)');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return ecolesData.map((json) => Ecole.fromJson(json)).toList();
        }
        print('⚠️ Aucune donnée d\'école trouvée dans la réponse');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return [];
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      ApiExceptionHandler.handle(e, context: 'la récupération des écoles (page)');
      throw Exception('Erreur lors de la récupération des écoles: $e');
    }
  }

  /// Récupère toutes les écoles sans pagination
  static Future<List<Ecole>> getAllEcoles() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 CHARGEMENT DE TOUTES LES ÉCOLES');
    print('═══════════════════════════════════════════════════════════');

    final url = baseUrl;
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

        if (data['data'] != null && data['data'] is List) {
          final List<dynamic> ecolesData = data['data'];
          print('✅ ${ecolesData.length} école(s) récupérée(s)');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return ecolesData.map((json) => Ecole.fromJson(json)).toList();
        }
        print('⚠️ Aucune donnée d\'école trouvée dans la réponse');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return [];
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      ApiExceptionHandler.handle(e, context: 'la récupération de toutes les écoles');
      throw Exception('Erreur lors de la récupération des écoles: $e');
    }
  }

  /// Cache en mémoire pour éviter les requêtes HTTP répétitives et les erreurs 429
  static final Map<String, EcoleDetail> _detailCache = {};

  /// Récupère les détails d'une école spécifique
  static Future<EcoleDetail> getEcoleDetail(String parametreCode, {bool showNotification = true}) async {
    if (_detailCache.containsKey(parametreCode)) {
      print('📥 [CACHE] Détails de l\'école récupérés depuis le cache pour: $parametreCode');
      return _detailCache[parametreCode]!;
    }

    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 DÉTAILS DE L\'ÉCOLE');
    print('═══════════════════════════════════════════════════════════');
    print('🏷️ Code paramètre: $parametreCode');

    final url =
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/ecoles/detail-ecole/$parametreCode';
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
        print('✅ Détails de l\'école récupérés avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');
        final detail = EcoleDetail.fromJson(data);
        _detailCache[parametreCode] = detail;
        return detail;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      ApiExceptionHandler.handle(e, context: 'la récupération des détails de l\'école', showNotification: showNotification);
      throw Exception(
        'Erreur lors de la récupération des détails de l\'école: $e',
      );
    }
  }

  /// Récupère les paramètres d'une école spécifique
  static Future<EcoleData> getEcoleParametres(String ecoleCode) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 PARAMÈTRES DE L\'ÉCOLE');
    print('═══════════════════════════════════════════════════════════');
    print('🏷️ Code école: $ecoleCode');

    final url =
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/parametre/ecole?ecole=$ecoleCode';
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
          print('✅ Paramètres de l\'école récupérés avec succès');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return EcoleData.fromJson(data['data']);
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
        if (response.statusCode == 404) {
          throw ApiException(
            message: 'Aucune école associée à cette vidéo',
            type: ApiErrorType.clientError,
          );
        }
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      final isNoSchoolError = e is ApiException && e.message == 'Aucune école associée à cette vidéo';
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération des paramètres de l\'école',
        showNotification: !isNoSchoolError,
      );
      throw Exception(
        'Erreur lors de la récupération des paramètres de l\'école: $e',
      );
    }
  }
}
