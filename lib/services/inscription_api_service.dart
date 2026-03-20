import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── CONSTANTES ───────────────────────────────────────────────────────────────

const String kBaseUrl = 'https://api2.vie-ecoles.com/api';

// ─── MODÈLES ──────────────────────────────────────────────────────────────────

class EcheanceScolarite {
  final int echId;
  final String uid;
  final String branche;
  final String statut;
  final String rubrique;
  final String pecheance;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final int ordre;
  final int rubriqueObligatoire;
  bool selectionnee;

  EcheanceScolarite({
    required this.echId,
    required this.uid,
    required this.branche,
    required this.statut,
    required this.rubrique,
    required this.pecheance,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.ordre,
    required this.rubriqueObligatoire,
    bool? selectionnee,
  }) : selectionnee = selectionnee ?? (rubriqueObligatoire == 1);

  factory EcheanceScolarite.fromJson(Map<String, dynamic> json) {
    return EcheanceScolarite(
      echId: json['ech_id'] ?? 0,
      uid: json['uid'],
      branche: json['branche'],
      statut: json['statut'],
      rubrique: json['rubrique'],
      pecheance: json['pecheance'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      ordre: json['ordre'],
      rubriqueObligatoire: json['rubrique_obligatoire'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ech_id': echId,
    'uid': uid,
    'branche': branche,
    'statut': statut,
    'rubrique': rubrique,
    'pecheance': pecheance,
    'montant': montant,
    'montant2': montant2,
    'datelimite': dateLimite,
    'libelle': libelle,
    'ordre': ordre,
    'rubrique_obligatoire': rubriqueObligatoire,
  };
}

class Service {
  final String iddetail;
  final String service;
  final String? zoneId;
  final String designation;
  final String description;
  final int prix;
  final int prix2;
  final String maitre;
  bool selectionnee;

  Service({
    required this.iddetail,
    required this.service,
    this.zoneId,
    required this.designation,
    required this.description,
    required this.prix,
    required this.prix2,
    required this.maitre,
    this.selectionnee = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      iddetail: json['iddetail'],
      service: json['service'],
      zoneId: json['zone_id'],
      designation: json['designation'],
      description: json['description'],
      prix: json['prix'],
      prix2: json['prix2'],
      maitre: json['maitre'],
    );
  }
}

class EcheanceService {
  final int idfrais;
  final String rubrique;
  final int montant;
  final int montant2;
  final String dateLimite;
  final String libelle;
  final String codeRubrique;
  bool selectionnee;

  EcheanceService({
    required this.idfrais,
    required this.rubrique,
    required this.montant,
    required this.montant2,
    required this.dateLimite,
    required this.libelle,
    required this.codeRubrique,
    this.selectionnee = true,
  });

  factory EcheanceService.fromJson(Map<String, dynamic> json) {
    return EcheanceService(
      idfrais: json['idfrais'],
      rubrique: json['rubrique'],
      montant: json['montant'],
      montant2: json['montant2'],
      dateLimite: json['datelimite'],
      libelle: json['libelle'],
      codeRubrique: json['coderubrique'],
    );
  }

  Map<String, dynamic> toJson() => {
    'idfrais': idfrais,
    'rubrique': rubrique,
    'montant': montant,
    'montant2': montant2,
    'datelimite': dateLimite,
    'libelle': libelle,
    'coderubrique': codeRubrique,
  };
}

class ZoneTransport {
  final String idzone;
  final String serviceId;
  final String code;
  final String zone;

  ZoneTransport({
    required this.idzone,
    required this.serviceId,
    required this.code,
    required this.zone,
  });

  factory ZoneTransport.fromJson(Map<String, dynamic> json) {
    return ZoneTransport(
      idzone: json['idzone'],
      serviceId: json['service_id'],
      code: json['code'],
      zone: json['zone'],
    );
  }
}

class ReservationStatus {
  final int sommeReservation;
  final bool status;

  ReservationStatus({required this.sommeReservation, required this.status});

  factory ReservationStatus.fromJson(Map<String, dynamic> json) {
    return ReservationStatus(
      sommeReservation: json['somme_reservation'],
      status: json['status'],
    );
  }
}

// ─── PAYLOAD D'INSCRIPTION ────────────────────────────────────────────────────

class InscriptionPayload {
  final List<Map<String, dynamic>> ids;
  final Map<String, dynamic> engagement;
  final String type;
  final int separationFlux;
  final int systemeEducatif;

  InscriptionPayload({
    required this.ids,
    this.engagement = const {},
    this.type = 'préinscription',
    this.separationFlux = 0,
    this.systemeEducatif = 1,
  });

  Map<String, dynamic> toJson() => {
    'ids': ids,
    'engagement': engagement,
    'type': type,
    'separation_flux': separationFlux,
    'systeme_educatif': systemeEducatif,
  };
}

// ─── SERVICE API ──────────────────────────────────────────────────────────────

/// Service centralisant tous les appels HTTP liés à l'inscription / préinscription.
/// À utiliser depuis [InscriptionWizardScreen] et tout autre écran qui en a besoin.
class InscriptionApiService {
  // ── En-têtes communs ────────────────────────────────────────────────────────

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Logger interne ──────────────────────────────────────────────────────────

  static void _logRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    print('🌐 [API] Requête $method');
    print('🔗 URL: $url');
    if (body != null) print('📤 Body: ${jsonEncode(body)}');
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');
  }

  static void _logResponse(String label, int statusCode, String body) {
    print('📊 [API] Réponse $label');
    print('📊 Status: $statusCode');
    print('📄 Body: $body');
    print('⏰ Heure: ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
  }

  // ── 1. Scolarité ────────────────────────────────────────────────────────────

  /// Récupère la liste des échéances de scolarité pour une branche donnée.
  ///
  /// [brancheId]       : identifiant de la branche (classe)
  /// [ecoleCode]       : code de l'école
  /// [systemeEducatif] : 1 = standard, 2 = arabe (ex: *annour*)
  static Future<List<EcheanceScolarite>> fetchScolarite({
    required String brancheId,
    required String ecoleCode,
    int systemeEducatif = 1,
  }) async {
    final url =
        '$kBaseUrl/preinscription/scolarite/branche/$brancheId'
        '?ecole=$ecoleCode&systeme_educatif=$systemeEducatif';

    _logRequest('GET', url);

    final response = await http.get(Uri.parse(url), headers: _headers);
    _logResponse('scolarité', response.statusCode, response.body);

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);

      print('📊 Réponse API scolarité:');
      print('   - Type: ${decodedData.runtimeType}');
      print(
        '   - Contenu: ${decodedData.toString().substring(0, decodedData.toString().length > 200 ? 200 : decodedData.toString().length)}...',
      );

      // Vérifier si la réponse est une liste directe ou un objet avec propriété 'data'
      if (decodedData is List) {
        // Cas 1: Réponse est une liste directe
        print('✅ Format: Liste directe détectée');
        final List<dynamic> data = decodedData;
        return data.map((e) => EcheanceScolarite.fromJson(e)).toList();
      } else if (decodedData is Map && decodedData['data'] != null) {
        // Cas 2: Réponse est un objet avec propriété 'data'
        print('✅ Format: Objet avec propriété data détecté');
        final List<dynamic> data = decodedData['data'];
        return data.map((e) => EcheanceScolarite.fromJson(e)).toList();
      } else {
        print('⚠️ Format de réponse inattendu: ${decodedData.runtimeType}');
        throw Exception('Format de réponse invalide pour la scolarité');
      }
    }

    throw Exception('Erreur chargement scolarité [${response.statusCode}]');
  }

  // ── 2. Réservation ──────────────────────────────────────────────────────────

  /// Vérifie le statut de réservation d'un élève.
  ///
  /// [matricule] : matricule de l'élève
  static Future<ReservationStatus> fetchReservation({
    required String matricule,
  }) async {
    final url = '$kBaseUrl/vie-ecoles/reservation/eleve/$matricule';

    _logRequest('GET', url);

    final response = await http.get(Uri.parse(url), headers: _headers);
    _logResponse('réservation', response.statusCode, response.body);

    // L'API peut renvoyer 500 avec un body valide
    if (response.statusCode == 200 || response.statusCode == 500) {
      return ReservationStatus.fromJson(jsonDecode(response.body));
    }

    // Valeur par défaut non bloquante
    return ReservationStatus(sommeReservation: 0, status: false);
  }

  // ── 3. Services ─────────────────────────────────────────────────────────────

  /// Récupère les services disponibles (cantine, transport, etc.) pour une école.
  ///
  /// [ecoleCode] : code de l'école
  static Future<List<Service>> fetchServices({
    required String ecoleCode,
  }) async {
    final url = '$kBaseUrl/preinscription/services?ecole=$ecoleCode';

    _logRequest('GET', url);

    final response = await http.get(Uri.parse(url), headers: _headers);
    _logResponse('services', response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Service.fromJson(e)).toList();
    }

    throw Exception('Erreur chargement services [${response.statusCode}]');
  }

  // ── 4. Échéances d'un service ───────────────────────────────────────────────

  /// Récupère l'échéancier d'un service spécifique.
  ///
  /// [serviceId] : identifiant du service (iddetail)
  /// [ecoleCode] : code de l'école
  static Future<List<EcheanceService>> fetchEcheancesService({
    required String serviceId,
    required String ecoleCode,
  }) async {
    final url =
        '$kBaseUrl/preinscription/service/echeances/$serviceId'
        '?ecole=$ecoleCode';

    _logRequest('GET', url);

    final response = await http.get(Uri.parse(url), headers: _headers);
    _logResponse('échéances service', response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => EcheanceService.fromJson(e)).toList();
    }

    throw Exception(
      'Erreur chargement échéances service [${response.statusCode}]',
    );
  }

  /// Récupère et fusionne les échéances de plusieurs services sélectionnés.
  ///
  /// [services]  : liste des services cochés par l'utilisateur
  /// [ecoleCode] : code de l'école
  static Future<List<EcheanceService>> fetchEcheancesForSelectedServices({
    required List<Service> services,
    required String ecoleCode,
  }) async {
    final selected = services.where((s) => s.selectionnee).toList();
    if (selected.isEmpty) return [];

    final allEcheances = <EcheanceService>[];
    for (final service in selected) {
      final echeances = await fetchEcheancesService(
        serviceId: service.iddetail,
        ecoleCode: ecoleCode,
      );
      allEcheances.addAll(echeances);
    }
    return allEcheances;
  }

  // ── 5. Zones de transport ───────────────────────────────────────────────────

  /// Récupère les zones de transport disponibles pour une école.
  ///
  /// [ecoleCode] : code de l'école
  static Future<List<ZoneTransport>> fetchZones({
    required String ecoleCode,
  }) async {
    final url = '$kBaseUrl/preinscription/service/zones?ecole=$ecoleCode';

    _logRequest('GET', url);

    final response = await http.get(Uri.parse(url), headers: _headers);
    _logResponse('zones', response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ZoneTransport.fromJson(e)).toList();
    }

    throw Exception('Erreur chargement zones [${response.statusCode}]');
  }

  // ── 6. Soumettre l'inscription ──────────────────────────────────────────────

  /// Soumet l'inscription / préinscription d'un élève.
  ///
  /// [matricule] : matricule de l'élève
  /// [ecoleCode] : code de l'école
  /// [payload]   : objet [InscriptionPayload] contenant tous les ids sélectionnés
  ///
  /// Renvoie `true` si la requête a réussi (200 ou 201), lance une [Exception] sinon.
  static Future<bool> submitInscription({
    required String matricule,
    required String ecoleCode,
    required InscriptionPayload payload,
  }) async {
    final url =
        '$kBaseUrl/vie-ecoles/inscription-eleve/$matricule'
        '?ecole=$ecoleCode';

    _logRequest('POST', url, body: payload.toJson());

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(payload.toJson()),
    );

    _logResponse('inscription', response.statusCode, response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    // Extraire le message d'erreur de l'API si disponible
    String errorMessage =
        'Erreur lors de l\'inscription [${response.statusCode}]';
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
    } catch (_) {}

    throw Exception(errorMessage);
  }
}
