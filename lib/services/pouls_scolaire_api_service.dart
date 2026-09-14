import 'dart:async';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../config/app_config.dart';
import '../models/annee_scolaire.dart';
import '../models/eleve.dart';
import '../models/student_class_info.dart';
import '../utils/api_exception_handler.dart';
import 'school_service.dart';

/// Service pour interagir avec l'API Pouls Scolaire
class PoulsScolaireApiService {
  // Utiliser l'URL depuis AppConfig pour faciliter la configuration
  String get _baseUrl => AppConfig.POULS_SCOLAIRE_API_URL;

  /// Headers requis pour toutes les requêtes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Logger une requête API de manière standardisée
  void _logApiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? params,
    Object? body,
  }) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🔌 API REQUEST - ${method.toUpperCase()}');
    print('═══════════════════════════════════════════════════════════');
    print('🔗 URL: $_baseUrl$endpoint');
    if (params != null && params.isNotEmpty) {
      print('📋 Query Params: $params');
    }
    if (body != null) {
      print('📦 Body: $body');
    }
    print('⏱️  Timestamp: ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
  }

  /// Logger une réponse API de manière standardisée
  void _logApiResponse(
    int statusCode, {
    String? bodyPreview,
    int? bodyLength,
    bool isError = false,
  }) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    if (isError) {
      print('❌ API RESPONSE - ERROR $statusCode');
    } else {
      print('✅ API RESPONSE - SUCCESS $statusCode');
    }
    print('═══════════════════════════════════════════════════════════');
    print('📊 Status Code: $statusCode');
    if (bodyLength != null) {
      print('📄 Body Length: $bodyLength characters');
    }
    if (bodyPreview != null && bodyPreview.isNotEmpty) {
      print(
        '📝 Body Preview: ${bodyPreview.substring(0, bodyPreview.length > 200 ? 200 : bodyPreview.length)}',
      );
    }
    print('═══════════════════════════════════════════════════════════');
  }

  /// Logger une erreur API
  void _logApiError(String message, Object error) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('💥 API ERROR - $message');
    print('═══════════════════════════════════════════════════════════');
    print('❌ Error: $error');
    print('⏱️  Timestamp: ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  /// Récupère l'année scolaire ouverte pour une école
  ///
  Future<AnneeScolaire> getAnneeScolaireOuverte(int ecoleId) async {
    try {
      _logApiRequest(
        'GET',
        '/annee/list-ouverte-to-ecole-dto',
        params: {'ecole': ecoleId.toString()},
      );

      final uri = Uri.parse(
        '$_baseUrl/annee/list-ouverte-to-ecole-dto',
      ).replace(queryParameters: {'ecole': ecoleId.toString()});
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      _logApiResponse(response.statusCode, bodyLength: response.body.length);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print(
            '✅ Année scolaire ouverte récupérée: ${data['libelleAnneeOuverteCentrale'] ?? 'N/A'}',
          );
          return AnneeScolaire.fromJson(data);
        } catch (e) {
          _logApiError('Parsing JSON getAnneeScolaireOuverte', e);
          print('Réponse API: ${response.body}');
          throw Exception('Erreur lors du parsing de la réponse de l\'API: $e');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'année scolaire: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        ApiExceptionHandler.handle(
          e,
          context: 'la récupération de l\'année scolaire',
        );
        rethrow;
      }
      _logApiError('getAnneeScolaireOuverte', e);
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération de l\'année scolaire',
      );
      throw Exception(
        'Erreur lors de la récupération de l\'année scolaire: $e',
      );
    }
  }

  /// Récupère les élèves d'une école et d'une année
  ///
  /// Endpoint: GET /inscriptions/list-eleve-classe/{idEcole}/{idAnnee}
  Future<List<Eleve>> getElevesByEcoleAndAnnee(int idEcole, int idAnnee) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/inscriptions/list-eleve-classe/$idEcole/$idAnnee',
      );
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📚 CHARGEMENT DES ÉLÈVES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL complète de la ressource API:');
      print('   $uri');
      print('');
      print('📅 Identifiant de l\'année utilisé: $idAnnee');
      print('🏫 Identifiant de l\'école utilisé: $idEcole');
      print('═══════════════════════════════════════════════════════════');
      print('');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Réponse reçue: ${data.length} élèves récupérés');
        print('');

        // Chercher spécifiquement le matricule 25125794Q
        bool foundTargetMatricule = false;
        for (final eleveData in data) {
          final eleveJson = eleveData as Map<String, dynamic>;
          final matricule = eleveJson['matriculeEleve']?.toString() ?? '';
          if (matricule == '25125794Q' ||
              matricule.toUpperCase() == '25125794Q') {
            foundTargetMatricule = true;
            print('🎯 ÉLÈVE TROUVÉ - Matricule: 25125794Q');
            print('   📋 Tous les champs retournés par l\'API:');
            eleveJson.forEach((key, value) {
              print('      - $key: $value');
            });
            print('   🔍 Vérification des champs de classe:');
            print('      - classeid: ${eleveJson['classeid']}');
            print('      - classe: ${eleveJson['classe']}');
            print('      - brancheid: ${eleveJson['brancheid']}');
            print('      - brancheLibelle: ${eleveJson['brancheLibelle']}');
            print('   🖼️ Vérification du champ photo:');
            print('      - cheminphoto: ${eleveJson['cheminphoto']}');
            print('      - urlPhoto: ${eleveJson['urlPhoto']}');
            break;
          }
        }

        if (!foundTargetMatricule) {
          print('⚠️ Matricule 25125794Q non trouvé dans la liste des élèves');
        }

        // Logger les classeid des premiers élèves pour débogage
        if (data.isNotEmpty) {
          print('📋 Exemples de classeid des élèves:');
          for (int i = 0; i < (data.length > 3 ? 3 : data.length); i++) {
            final eleveJson = data[i] as Map<String, dynamic>;
            print(
              '   - Élève ${i + 1}: matricule=${eleveJson['matriculeEleve']}, classeid=${eleveJson['classeid']}, brancheid=${eleveJson['brancheid']}',
            );
          }
        }

        final eleves = data
            .map((json) => Eleve.fromJson(json as Map<String, dynamic>))
            .toList();

        // Vérifier l'élève avec le matricule 25125794Q après parsing
        try {
          final targetEleve = eleves.firstWhere(
            (e) =>
                e.matriculeEleve == '25125794Q' ||
                e.matriculeEleve.toUpperCase() == '25125794Q',
          );
          print(
            '🎯 ÉLÈVE APRÈS PARSING - Matricule: ${targetEleve.matriculeEleve}',
          );
          print('   - classeid final utilisé: ${targetEleve.classeid}');
          print('   - classe final utilisé: ${targetEleve.classe}');
        } catch (e) {
          // Élève non trouvé après parsing, déjà loggé avant
        }

        print('');
        print('═══════════════════════════════════════════════════════════');
        print('✅ FIN CHARGEMENT DES ÉLÈVES');
        print('═══════════════════════════════════════════════════════════');
        print('');

        return eleves;
      } else {
        throw Exception(
          'Erreur lors de la récupération des élèves: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des élèves: $e');
      ApiExceptionHandler.handle(e, context: 'la récupération des élèves');
      throw Exception('Erreur lors de la récupération des élèves: $e');
    }
  }

  /// Recherche un élève par son matricule dans une école et une année
  ///
  /// Retourne l'élève correspondant au matricule, ou null si non trouvé
  Future<Eleve?> findEleveByMatricule(
    int idEcole,
    int idAnnee,
    String matricule,
  ) async {
    try {
      print('🔍 ===== DÉBUT RECHERCHE ÉLÈVE =====');
      print('📝 Matricule recherché: $matricule');
      print('🏫 École ID: $idEcole');
      print('📅 Année ID: $idAnnee');
      print('🔗 Appel de getElevesByEcoleAndAnnee...');

      final eleves = await getElevesByEcoleAndAnnee(idEcole, idAnnee);
      print('📊 Nombre total d\'élèves récupérés: ${eleves.length}');

      print('🔎 Recherche du matricule "$matricule" dans la liste...');
      for (final eleve in eleves) {
        if (eleve.matriculeEleve.toLowerCase() == matricule.toLowerCase()) {
          print('✅ ===== ÉLÈVE TROUVÉ =====');
          print('   📝 Matricule: ${eleve.matriculeEleve}');
          print('   👤 Nom complet: ${eleve.fullName}');
          print('   📚 Classe ID (classeid): ${eleve.classeid}');
          print('   📚 Classe (libellé): ${eleve.classe}');
          print('   🆔 ID Élève Inscrit: ${eleve.idEleveInscrit}');
          print('   🆔 ID Inscription: ${eleve.inscriptionsidEleve}');
          print('   🖼️ URL Photo (cheminphoto): ${eleve.urlPhoto ?? "null"}');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return eleve;
        }
      }
      print('❌ Aucun élève trouvé avec le matricule: $matricule');
      print('🔍 Liste des matricules disponibles (premiers 10):');
      for (int i = 0; i < (eleves.length > 10 ? 10 : eleves.length); i++) {
        print('   - ${eleves[i].matriculeEleve}');
      }
      print('═══════════════════════════════════════════════════════════');
      print('');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la recherche de l\'élève: $e');
      // On ne lance pas ApiExceptionHandler ici car _searchEleve gère l'affichage de l'erreur dans l'UI
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la recherche de l\'élève: $e');
    }
  }

  /// Enregistre un token FCM pour recevoir les notifications
  ///
  /// Endpoint: POST /api/notifications/register-token
  /// Body: {
  ///   "token": string,
  ///   "userId": string,
  ///   "deviceType": "android" | "ios",
  ///   "matricules": string[]
  /// }
  ///
  /// Les matricules sont les identifiants des élèves pour lesquels ce token doit recevoir des notifications
  Future<bool> registerNotificationToken(
    String token,
    String userId, {
    String deviceType = 'android',
    List<String>? matricules,
  }) async {
    try {
      // Utiliser l'URL de base de l'API depuis AppConfig
      final baseUrl = AppConfig.API_BASE_URL;
      final uri = Uri.parse('$baseUrl/notifications/register-token');

      // Préparer le body avec les matricules (au moins un matricule requis)
      final body = {
        'token': token,
        'userId': userId,
        'deviceType': deviceType,
        'matricules': matricules ?? [],
      };

      print('📤 Enregistrement du token de notification');
      print('   URL: $uri');
      print('   UserId: $userId');
      print('   DeviceType: $deviceType');
      print('   Matricules: ${matricules?.length ?? 0}');

      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token de notification enregistré avec succès');
        final responseData = json.decode(response.body);
        if (responseData is Map &&
            responseData.containsKey('matriculesCount')) {
          print('   Matricules associés: ${responseData['matriculesCount']}');
        }
        return true;
      } else {
        print(
          '❌ Erreur lors de l\'enregistrement du token: ${response.statusCode}',
        );
        print('   Réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'enregistrement du token: $e');
      return false;
    }
  }

  /// Récupère les informations de la classe et de l'école pour un élève
  ///
  /// Endpoint: GET /classe-eleve/get-ecole-by-classe/{matricule}?annee={anneeId}&classe={classeId}
  Future<StudentClassInfo> getStudentClassInfo(
    String matricule,
    int anneeId,
    int classeId,
  ) async {
    try {
      _logApiRequest(
        'GET',
        '/classe-eleve/get-ecole-by-classe/$matricule',
        params: {'annee': anneeId.toString(), 'classe': classeId.toString()},
      );

      final uri =
          Uri.parse(
            '$_baseUrl/classe-eleve/get-ecole-by-classe/$matricule',
          ).replace(
            queryParameters: {
              'annee': anneeId.toString(),
              'classe': classeId.toString(),
            },
          );

      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🏫 CHARGEMENT DES INFOS CLASSE/ÉCOLE');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL complète:');
      print('   $uri');
      print('');
      print('📋 Paramètres utilisés:');
      print('   🎫 Matricule: $matricule');
      print('   📅 Année ID: $anneeId');
      print('   📚 Classe ID: $classeId');
      print('═══════════════════════════════════════════════════════════');
      print('');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      _logApiResponse(response.statusCode, bodyLength: response.body.length);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print('✅ Informations classe/école récupérées avec succès');
          print('   🏫 École: ${data['ecole']?['libelle']}');
          print('   📚 Classe: ${data['classe']?['libelle']}');
          print(
            '   👤 Élève: ${data['eleve']?['prenom']} ${data['eleve']?['nom']}',
          );
          print('   🏷️ ID Vie École: ${data['identifiantVieEcole']}');
          print('');

          final studentClassInfo = StudentClassInfo.fromJson(data);

          // Mettre à jour le SchoolService avec le nouvel identifiantVieEcole
          await _updateSchoolServiceWithVieEcoleId(studentClassInfo);

          return studentClassInfo;
        } catch (e) {
          print('❌ Erreur lors du parsing JSON: $e');
          print('❌ Contenu de la réponse: ${response.body}');
          throw Exception(
            'Erreur lors du parsing des informations classe/école: $e',
          );
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
          'Erreur lors de la récupération des informations classe/école: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logApiError('getStudentClassInfo', e);
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération des informations classe/école',
      );
      throw Exception(
        'Erreur lors de la récupération des informations classe/école: $e',
      );
    }
  }

  /// Met à jour le SchoolService avec les informations de l'école et l'ID Vie École
  Future<void> _updateSchoolServiceWithVieEcoleId(
    StudentClassInfo studentClassInfo,
  ) async {
    try {
      // Importer SchoolService ici pour éviter les dépendances circulaires
      final schoolService = SchoolService();

      // Créer les données de l'école au format attendu par SchoolService
      final schoolData = {
        'id': studentClassInfo.ecole.id,
        'libelle': studentClassInfo.ecole.libelle,
        'code': studentClassInfo.ecole.code,
        'identifiantVieEcole': studentClassInfo.identifiantVieEcole,
        // Ajouter d'autres champs si nécessaire
        'tel': null,
        'nomSignataire': null,
      };

      await schoolService.updateSchoolData(schoolData);
      print(
        '✅ SchoolService mis à jour avec le nouvel ID Vie École: ${studentClassInfo.identifiantVieEcole}',
      );
    } catch (e) {
      print('⚠️ Impossible de mettre à jour le SchoolService: $e');
      // Ne pas lancer d'exception pour ne pas bloquer le processus principal
    }
  }
}
