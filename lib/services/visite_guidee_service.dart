import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../models/visite_guidee_video.dart';
import '../config/app_config.dart';

class VisiteGuideeService {
  static String get baseUrl => '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles';

  static Future<List<VisiteGuideeVideo>> getVideosByEcole(String ecoleCode) async {
    try {
      final url = '$baseUrl/videos?ecole=$ecoleCode&type_video=visiteguide&per_page=1000';
      print('=== API VISITES GUIDÉES ===');
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
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('Response Body: ${response.body}');
        
        if (jsonData['data'] != null) {
          final List<dynamic> videosData = jsonData['data'];
          print('Videos Data Length: ${videosData.length}');
          
          final videos = videosData.map((json) => VisiteGuideeVideo.fromJson(json)).toList();
          print('Videos processed: ${videos.length}');
          
          for (var video in videos) {
            print('Video: ${video.typeVideo} - ${video.youtubeUrl}');
          }
          
          return videos;
        } else {
          print('data is null');
          return [];
        }
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception dans getVideosByEcole: $e');
      throw Exception('Erreur lors de la récupération des vidéos: $e');
    }
  }

  static Future<List<VisiteGuideeVideo>> getAllVisiteGuideeVideos({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url =
          '$baseUrl/videos?type_video=visiteguide&per_page=$perPage&page=$page';
      print('=== API VISITES GUIDÉES (ALL) ===');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['data'] != null) {
          final List<dynamic> videosData = jsonData['data'];
          return videosData.map((json) => VisiteGuideeVideo.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception dans getAllVisiteGuideeVideos: $e');
      throw Exception('Erreur lors de la récupération des vidéos: $e');
    }
  }
}
