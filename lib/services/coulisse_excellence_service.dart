import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:developer' as developer;
import '../models/coulisse_excellence.dart';
import '../config/app_config.dart';

class CoulisseExcellenceService {
  static String get baseUrl => '${AppConfig.VIE_ECOLES_API_BASE_URL}/ecoles';

  static Future<List<CoulisseExcellence>> getCoulisseExcellenceList(
    String ecoleId,
  ) async {
    try {
      final url = '$baseUrl/coulisseexcellencelist?ecole=$ecoleId&per_page=1000';
      print('=== API COULISSE EXCELLENCE ===');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> jsonData;
        
        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
          jsonData = decodedBody['data'];
        } else if (decodedBody is List) {
          jsonData = decodedBody;
        } else {
          throw Exception('Format de réponse inattendu');
        }
        
        print('JSON Data Length: ${jsonData.length}');
        print('JSON Data: $jsonData');

        final videos = jsonData
            .map((json) => CoulisseExcellence.fromJson(json))
            .toList();
        print('Videos processed: ${videos.length}');
        for (var video in videos) {
          print('Video: ${video.id} - ${video.titre} - ${video.videoYoutube}');
        }
        return videos;
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception dans getCoulisseExcellenceList: $e');
      throw Exception('Erreur lors de la récupération des vidéos: $e');
    }
  }

  static Future<List<CoulisseExcellence>>
  getAllCoulisseExcellenceVideos({int page = 1, int perPage = 20, String? ecoleCode}) async {
    try {
      var url = '$baseUrl/coulisseexcellencelist?per_page=$perPage&page=$page';
      if (ecoleCode != null && ecoleCode.isNotEmpty) {
        url += '&ecole=$ecoleCode';
      }
      developer.log('GET Request URL: $url');
      print('=== API COULISSE EXCELLENCE (ALL) ===');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> jsonData;
        
        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
          jsonData = decodedBody['data'];
        } else if (decodedBody is List) {
          jsonData = decodedBody;
        } else {
          throw Exception('Format de réponse inattendu');
        }
        
        print('JSON Data Length: ${jsonData.length}');

        final videos = jsonData
            .map((json) => CoulisseExcellence.fromJson(json))
            .toList();
        print('Videos processed: ${videos.length}');
        return videos;
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception dans getAllCoulisseExcellenceVideos: $e');
      throw Exception('Erreur lors de la récupération des vidéos: $e');
    }
  }
}
