import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:developer' as developer;
import '../models/ecole_histoire.dart';
import '../config/app_config.dart';

/// Service "Mémoire des écoles" : histoires/événements marquants d'un
/// établissement, avec deux portées — globale (toutes écoles, affichée sur
/// l'accueil) et spécifique à une école (affichée dans le détail
/// établissement).
class EcoleHistoireService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static String _withCommonParams(
    String url, {
    String? search,
    String? year,
    String? yearStart,
    String? yearEnd,
  }) {
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (year != null && year.trim().isNotEmpty) {
      url += '&year=${Uri.encodeComponent(year.trim())}';
    }
    if (yearStart != null && yearStart.trim().isNotEmpty) {
      url += '&year_start=${Uri.encodeComponent(yearStart.trim())}';
    }
    if (yearEnd != null && yearEnd.trim().isNotEmpty) {
      url += '&year_end=${Uri.encodeComponent(yearEnd.trim())}';
    }
    return url;
  }

  /// Liste globale de toutes les histoires sur la plateforme.
  ///
  /// Endpoint: GET /vie-ecoles/histoires?per_page=&page=&search=&year=&year_start=&year_end=
  static Future<EcoleHistoiresResponse> getHistoires({
    int page = 1,
    int perPage = 6,
    String? search,
    String? year,
    String? yearStart,
    String? yearEnd,
  }) async {
    var url = '$baseUrl/vie-ecoles/histoires?per_page=$perPage&page=$page';
    url = _withCommonParams(url, search: search, year: year, yearStart: yearStart, yearEnd: yearEnd);

    developer.log('[EcoleHistoireService] GET $url');

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EcoleHistoiresResponse.fromJson(data);
      }
      throw Exception('Erreur HTTP: ${response.statusCode}');
    } catch (e) {
      developer.log('[EcoleHistoireService] Erreur getHistoires: $e');
      throw Exception('Erreur lors de la récupération des histoires: $e');
    }
  }

  /// Liste des histoires spécifiques à une école.
  ///
  /// Endpoint: GET /ecoles/histoire/{codeecole}?typedecontenu=&title=&search=&per_page=&page=&year=&year_start=&year_end=
  static Future<EcoleHistoiresResponse> getHistoiresByEcole(
    String codeEcole, {
    int page = 1,
    int perPage = 6,
    String? typeDeContenu,
    String? title,
    String? search,
    String? year,
    String? yearStart,
    String? yearEnd,
  }) async {
    var url = '$baseUrl/ecoles/histoire/${Uri.encodeComponent(codeEcole)}?per_page=$perPage&page=$page';
    if (typeDeContenu != null && typeDeContenu.trim().isNotEmpty) {
      url += '&typedecontenu=${Uri.encodeComponent(typeDeContenu.trim())}';
    }
    if (title != null && title.trim().isNotEmpty) {
      url += '&title=${Uri.encodeComponent(title.trim())}';
    }
    url = _withCommonParams(url, search: search, year: year, yearStart: yearStart, yearEnd: yearEnd);

    developer.log('[EcoleHistoireService] GET $url');

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EcoleHistoiresResponse.fromJson(data);
      }
      throw Exception('Erreur HTTP: ${response.statusCode}');
    } catch (e) {
      developer.log('[EcoleHistoireService] Erreur getHistoiresByEcole: $e');
      throw Exception('Erreur lors de la récupération des histoires de l\'école: $e');
    }
  }
}
