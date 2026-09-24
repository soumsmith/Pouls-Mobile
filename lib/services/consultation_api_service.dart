import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../config/app_config.dart';
import '../models/etablissement_consultation.dart';
import '../models/annee_consultation.dart';
import '../models/periode_consultation.dart';
import '../models/eleve_consultation.dart';
import '../models/classe_consultation.dart';
import '../models/bulletin_consultation.dart';
import '../models/devoir_consultation.dart';
import '../models/progression_consultation.dart';
import '../utils/api_exception_handler.dart';
import 'pedagogie_auth_service.dart';

/// Service pour l'API de consultation (api-pedagogie.pouls-scolaire.net).
///
/// Couvre les 6 appels documentés : établissements, années, périodes, élèves,
/// bulletin et décision de fin d'année. Toutes les références (schoolId, ref
/// d'année/période/classe) sont des chaînes opaques : reçues depuis un appel,
/// repassées telles quelles au suivant, jamais interprétées ni composées.
class ConsultationApiService {
  // Singleton : chaque écran instanciait `ConsultationApiService()`
  // séparément, ce qui vidait `_etablissementsCache` à chaque nouvelle
  // instance et relançait l'appel legacy `/connecte/ecole` (résolution du
  // paramEcole, voir getEtablissements) à chaque écran ouvert au lieu d'une
  // seule fois par session — vérifié en conditions réelles (log répété à
  // chaque ouverture de bottom sheet). Partager l'instance rend le cache
  // mémoire réellement effectif.
  static final ConsultationApiService _instance =
      ConsultationApiService._internal();
  factory ConsultationApiService() => _instance;
  ConsultationApiService._internal();

  String get _baseUrl => '${AppConfig.PEDAGOGIE_API_BASE_URL}/v1';

  /// Cache mémoire des établissements (rarement modifiés) : évite de
  /// réinterroger l'API à chaque écran notes/bulletins ouvert.
  List<EtablissementConsultation>? _etablissementsCache;

  Future<Map<String, String>> _authHeaders({String accept = 'application/json'}) async {
    final token = await PedagogieAuthService().getValidToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': accept,
    };
  }

  /// Exécute [request] avec le jeton courant ; si la réponse est 401, force un
  /// renouvellement du jeton et retente une seule fois. [logLabel] identifie
  /// l'appel dans les logs (ex. "bulletins (liste)", "bulletin (notes)").
  /// [accept] doit correspondre au type de contenu attendu (l'API répond 406
  /// si l'en-tête Accept ne correspond pas — ex. "application/pdf" pour
  /// bulletin.pdf, "application/json" partout ailleurs).
  Future<http.Response> _getWithRetry(
    Uri uri,
    String logLabel, {
    String accept = 'application/json',
  }) async {
    _logRequest(logLabel, uri);
    var response = await http
        .get(uri, headers: await _authHeaders(accept: accept))
        .timeout(AppConfig.API_TIMEOUT);
    _logResponse(logLabel, response);
    if (response.statusCode == 401) {
      await PedagogieAuthService().forceRefresh();
      _logRequest('$logLabel (retry après 401)', uri);
      response = await http
          .get(uri, headers: await _authHeaders(accept: accept))
          .timeout(AppConfig.API_TIMEOUT);
      _logResponse(logLabel, response);
    }
    return response;
  }

  void _logRequest(String label, Uri uri) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🔌 API CONSULTATION — $label');
    print('🔗 URL: ${uri.replace(query: null)}');
    print('📋 Paramètres: ${uri.queryParameters}');
    print('⏱️  ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
  }

  /// Ré-indente `body` s'il s'agit de JSON valide ; sinon renvoie `body` tel
  /// quel (ex. corps d'erreur non-JSON).
  String _prettyBody(String body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json.decode(body));
    } catch (_) {
      return body;
    }
  }

  void _logResponse(String label, http.Response response) {
    final isError = response.statusCode != 200;
    if (isError) {
      print('❌ API CONSULTATION — $label → ${response.statusCode}');
      debugPrint('📦 Body: ${_prettyBody(response.body)}');
    } else {
      print('✅ API CONSULTATION — $label → ${response.statusCode}');
      debugPrint('📦 Body: ${_prettyBody(response.body)}');
    }
  }

  void _logException(String label, Object e) {
    print('💥 API CONSULTATION — $label a levé une exception: $e');
  }

  /// Lève une exception avec le message lisible renvoyé par l'API (doc §6) sur
  /// 400/401/403/404, ou une erreur générique sinon.
  Never _throwForStatus(String context, http.Response response) {
    String message = 'Erreur ${response.statusCode} lors de $context';
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      }
    } catch (_) {
      // Corps non-JSON : on garde le message générique.
    }
    throw Exception(message);
  }

  /// GET /consultation/etablissements
  ///
  /// Résultat mis en cache mémoire ; passer [forceRefresh] pour recharger.
  Future<List<EtablissementConsultation>> getEtablissements({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _etablissementsCache != null) {
      return _etablissementsCache!;
    }
    try {
      final uri = Uri.parse('$_baseUrl/consultation/etablissements');
      final response = await _getWithRetry(uri, 'établissements');
      if (response.statusCode != 200) _throwForStatus('les établissements', response);
      final List<dynamic> data = json.decode(response.body);
      final etablissements = data
          .map((e) => EtablissementConsultation.fromJson(e as Map<String, dynamic>))
          .toList();

      // paramecole n'existe pas dans cette API : résolu une seule fois ici
      // via GET /integrations/vie-ecoles/admin/schools (même hôte api-
      // pedagogie, même token), qui donne directement le `vieEcolesCode` par
      // `schoolId` — correspondance exacte, fiable, sans ambiguïté de
      // code/nom partagés. Remplace l'ancienne résolution via /connecte/ecole
      // (API legacy api-pro) qui, vérifié en conditions réelles, se trompait
      // ou ne trouvait rien pour la majorité des établissements. Best-effort :
      // en cas d'échec, paramEcole reste `null` sans faire échouer l'appel.
      try {
        final vieEcolesCodes = await _getVieEcolesCodes();
        for (final etab in etablissements) {
          etab.paramEcole = vieEcolesCodes[etab.schoolId];
        }
      } catch (e) {
        print('⚠️ Impossible de résoudre le paramEcole (vie-ecoles): $e');
      }

      print('✅ ${etablissements.length} établissement(s) trouvé(s)');
      for (var i = 0; i < etablissements.length; i++) {
        final e = etablissements[i];
        print(
          '   ${i + 1}. ${e.nom} (code: ${e.code}, schoolId: ${e.schoolId}, '
          'paramecole: ${e.paramEcole ?? "—"})',
        );
      }
      _etablissementsCache = etablissements;
      return etablissements;
    } catch (e) {
      _logException('établissements', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des établissements');
      rethrow;
    }
  }

  /// GET /integrations/vie-ecoles/admin/schools
  ///
  /// Retourne le `vieEcolesCode` (= paramEcole legacy) par `schoolId`. Champ
  /// `null` pour un établissement sans intégration vie-ecoles configurée
  /// (`configured: false` côté API).
  Future<Map<String, String?>> _getVieEcolesCodes() async {
    final uri = Uri.parse('$_baseUrl/integrations/vie-ecoles/admin/schools');
    final response = await _getWithRetry(uri, 'vie-ecoles (admin/schools)');
    if (response.statusCode != 200) {
      _throwForStatus('les codes vie-ecoles', response);
    }
    final List<dynamic> data = json.decode(response.body);
    final codes = <String, String?>{};
    for (final item in data) {
      final m = item as Map<String, dynamic>;
      final schoolId = m['schoolId'] as String?;
      if (schoolId == null) continue;
      final code = m['vieEcolesCode'] as String?;
      codes[schoolId] = (code != null && code.isNotEmpty) ? code : null;
    }
    return codes;
  }

  /// Retrouve le `schoolId` (référence opaque de l'API de consultation)
  /// correspondant au code d'établissement légataire (`Ecole.ecolecode`,
  /// lui-même issu de l'ancien `GET /connecte/ecole`).
  ///
  /// Le code legacy n'est pas fiable à lui seul : vérifié en conditions
  /// réelles, plusieurs établissements sans code assigné partagent la même
  /// valeur par défaut (ex. "12345678" porté à la fois par "COLLEGE PRIVE
  /// BKB" et par "ITAB", deux établissements sans rapport). Si [expectedName]
  /// est fourni, on exige en plus que le nom corresponde (comparaison
  /// insensible à la casse/aux espaces) parmi les établissements partageant
  /// ce code — sinon on refuse de choisir au hasard et on retourne `null`.
  Future<String?> findSchoolIdByCode(String code, {String? expectedName}) async {
    final etablissements = await getEtablissements();
    final candidates = etablissements.where((e) => e.code == code).toList();
    if (candidates.isEmpty) return null;

    if (expectedName != null) {
      // Toujours vérifier le nom quand on l'a, même s'il n'y a qu'un seul
      // candidat côté API de consultation : un code partagé côté legacy
      // (ex. "12345678") peut très bien ne correspondre à AUCUN des
      // établissements réels de l'API de consultation pour cette école
      // précise — un candidat unique n'est pas une preuve de correspondance.
      final normalizedExpected = _normalizeName(expectedName);
      for (final c in candidates) {
        if (_normalizeName(c.nom) == normalizedExpected) return c.schoolId;
      }
      return null;
    }

    // Pas de nom pour vérifier : ne faire confiance au code que s'il est
    // sans ambiguïté côté API de consultation.
    return candidates.length == 1 ? candidates.first.schoolId : null;
  }

  String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// GET /consultation/etablissements/{schoolId}/annees
  Future<List<AnneeConsultation>> getAnnees(String schoolId) async {
    try {
      final uri = Uri.parse('$_baseUrl/consultation/etablissements/$schoolId/annees');
      final response = await _getWithRetry(uri, 'années');
      if (response.statusCode != 200) _throwForStatus('les années scolaires', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => AnneeConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('années', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des années scolaires');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/annees/{annee}/periodes
  Future<List<PeriodeConsultation>> getPeriodes(String schoolId, String anneeRef) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/annees/$anneeRef/periodes',
      );
      final response = await _getWithRetry(uri, 'périodes');
      if (response.statusCode != 200) _throwForStatus('les périodes', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => PeriodeConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('périodes', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des périodes');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/annees/{annee}/eleves
  ///
  /// Un même matricule peut apparaître deux fois (élève inscrit dans deux
  /// classes) : ne jamais en élire une d'office côté appelant.
  Future<List<EleveConsultation>> getEleves(String schoolId, String anneeRef) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/annees/$anneeRef/eleves',
      );
      final response = await _getWithRetry(uri, 'élèves');
      if (response.statusCode != 200) _throwForStatus('la liste des élèves', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => EleveConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('élèves', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des élèves');
      rethrow;
    }
  }

  /// Télécharge les octets de la photo d'un élève depuis le chemin renvoyé
  /// par `EleveConsultation.urlPhoto` (chemin relatif, ex.
  /// "/api/v1/consultation/etablissements/{schoolId}/eleves/{matricule}/photo").
  /// Endpoint protégé par le même Bearer token que le reste de l'API — jamais
  /// une URL publique à passer telle quelle à Image.network. Retourne `null`
  /// si l'élève n'a pas de photo (404) ou en cas d'erreur (best-effort, ne
  /// lève jamais : appelée depuis une synchronisation en arrière-plan).
  Future<Uint8List?> getElevePhotoBytes(String urlPhotoPath) async {
    try {
      final origin = Uri.parse(AppConfig.PEDAGOGIE_API_BASE_URL);
      final uri = origin.replace(path: urlPhotoPath);
      // Accept: image/jpeg requis — l'API répond 406 sinon (même contrainte
      // que bulletin.pdf/application/pdf, voir _getWithRetry). Un 404 est le
      // cas normal d'un élève sans photo (doc recette du 15/09/2026) : pas
      // de log d'erreur pour ce cas, volontairement silencieux.
      final response = await http.get(
        uri,
        headers: await _authHeaders(accept: 'image/jpeg'),
      );
      if (response.statusCode == 401) {
        await PedagogieAuthService().forceRefresh();
        final retry = await http.get(
          uri,
          headers: await _authHeaders(accept: 'image/jpeg'),
        );
        if (retry.statusCode != 200) return null;
        return retry.bodyBytes;
      }
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (e) {
      _logException('photo élève', e);
      return null;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/classes
  ///
  /// L'entrée naturelle quand on ne connaît que le matricule (doc §4.7).
  /// Deux entrées signalent une double inscription ; `niveau` manque sur les
  /// années H: (archive), l'archive ne le porte pas à ce niveau de détail.
  Future<List<ClasseConsultation>> getClasses(
    String schoolId,
    String matricule, {
    required String anneeRef,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/classes',
      ).replace(queryParameters: {'annee': anneeRef});
      final response = await _getWithRetry(uri, 'classes');
      if (response.statusCode != 200) _throwForStatus('les classes', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ClasseConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('classes', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des classes');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/bulletin
  ///
  /// `classeRef` est facultatif et n'a d'effet que sur l'année courante : il
  /// tranche le cas d'un élève inscrit dans deux classes.
  Future<BulletinConsultation> getBulletin(
    String schoolId,
    String matricule, {
    required String anneeRef,
    required String periodeRef,
    String? classeRef,
    bool showNotification = true,
  }) async {
    try {
      final queryParams = {
        'annee': anneeRef,
        'periode': periodeRef,
        if (classeRef != null) 'classe': classeRef,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/bulletin',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(uri, 'bulletin (notes)');
      if (response.statusCode != 200) _throwForStatus('le bulletin', response);
      return BulletinConsultation.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      _logException('bulletin (notes)', e);
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération du bulletin',
        showNotification: showNotification,
      );
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/decision-fin-annee
  ///
  /// Lève une exception si l'année n'est pas close pour cet élève (404) — à
  /// traiter côté appelant comme un état vide, pas une erreur bloquante.
  Future<BulletinConsultation> getDecisionFinAnnee(
    String schoolId,
    String matricule, {
    required String anneeRef,
    String? classeRef,
  }) async {
    try {
      final queryParams = {
        'annee': anneeRef,
        if (classeRef != null) 'classe': classeRef,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/decision-fin-annee',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(uri, 'décision fin d\'année');
      if (response.statusCode != 200) _throwForStatus('la décision de fin d\'année', response);
      return BulletinConsultation.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } catch (e) {
      _logException('décision fin d\'année', e);
      ApiExceptionHandler.handle(
        e,
        context: 'la récupération de la décision de fin d\'année',
        showNotification: false,
      );
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/bulletins
  ///
  /// Un bulletin par période ayant réellement des notes, dans l'ordre des
  /// périodes (doc §4.8) — pas besoin de trier ni de dédupliquer côté appelant.
  Future<List<BulletinConsultation>> getBulletins(
    String schoolId,
    String matricule, {
    required String anneeRef,
    String? classeRef,
  }) async {
    try {
      final queryParams = {
        'annee': anneeRef,
        if (classeRef != null) 'classe': classeRef,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/bulletins',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(uri, 'bulletins (liste)');
      if (response.statusCode != 200) _throwForStatus('les bulletins', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => BulletinConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('bulletins (liste)', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des bulletins');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/bulletin.pdf
  ///
  /// Retourne les octets du PDF (`application/pdf`). Un `403` signale que
  /// l'établissement retient l'impression des bulletins (doc §4.9) — le
  /// message serveur remonte tel quel via `_throwForStatus`.
  Future<List<int>> getBulletinPdf(
    String schoolId,
    String matricule, {
    required String anneeRef,
    required String periodeRef,
    String? classeRef,
  }) async {
    try {
      final queryParams = {
        'annee': anneeRef,
        'periode': periodeRef,
        if (classeRef != null) 'classe': classeRef,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/bulletin.pdf',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(
        uri,
        'bulletin.pdf',
        accept: 'application/pdf',
      );
      if (response.statusCode != 200) _throwForStatus('le bulletin PDF', response);
      print('✅ API CONSULTATION — bulletin.pdf → ${response.bodyBytes.length} octets');
      return response.bodyBytes;
    } catch (e) {
      _logException('bulletin.pdf', e);
      ApiExceptionHandler.handle(e, context: 'le téléchargement du bulletin PDF');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/eleves/{matricule}/devoirs
  ///
  /// Triés par matière puis du plus récent au plus ancien (doc §4.11). Sans
  /// [depuis], les trente derniers jours. Un résultat vide signifie « rien
  /// d'enregistré dans le cahier de textes », pas forcément « aucun devoir » :
  /// ne pas l'afficher comme une absence de devoirs certaine. Réservé aux
  /// années P: — les années H: répondent 400 (cahier de textes non archivé).
  Future<List<DevoirConsultation>> getDevoirs(
    String schoolId,
    String matricule, {
    required String anneeRef,
    String? classeRef,
    String? matiere,
    String? depuis,
  }) async {
    try {
      final queryParams = {
        'annee': anneeRef,
        if (classeRef != null) 'classe': classeRef,
        if (matiere != null) 'matiere': matiere,
        if (depuis != null) 'depuis': depuis,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/eleves/$matricule/devoirs',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(uri, 'devoirs');
      if (response.statusCode != 200) _throwForStatus('les devoirs', response);
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => DevoirConsultation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _logException('devoirs', e);
      ApiExceptionHandler.handle(e, context: 'la récupération des devoirs');
      rethrow;
    }
  }

  /// GET /consultation/etablissements/{schoolId}/annees/{annee}/progressions
  ///
  /// Une ligne par couple classe-matière auquel une progression est
  /// affectée (doc §4.10) : une matière absente n'a pas de retard, elle n'a
  /// juste rien à dire. `chapitres` ne sera renseigné dans la réponse que si
  /// [classeRef] est fourni — sinon le détail multiplierait chaque ligne par
  /// la longueur du programme à l'échelle de l'établissement. Réservé aux
  /// années P: — les années H: répondent 400 (pas archivée).
  Future<List<ProgressionConsultation>> getProgressions(
    String schoolId, {
    required String anneeRef,
    String? classeRef,
    String? matiere,
  }) async {
    try {
      final queryParams = {
        if (classeRef != null) 'classe': classeRef,
        if (matiere != null) 'matiere': matiere,
      };
      final uri = Uri.parse(
        '$_baseUrl/consultation/etablissements/$schoolId/annees/$anneeRef/progressions',
      ).replace(queryParameters: queryParams);
      final response = await _getWithRetry(uri, 'progressions');
      if (response.statusCode != 200) {
        _throwForStatus('la progression du programme', response);
      }
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((e) => ProgressionConsultation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logException('progressions', e);
      ApiExceptionHandler.handle(e, context: 'la récupération de la progression');
      rethrow;
    }
  }
}
