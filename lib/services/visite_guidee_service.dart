import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/visite_guidee_video.dart';

class VisiteGuideeService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/vie-ecoles';

  static Future<List<VisiteGuideeVideo>> getVideosByEcole(String ecoleCode) async {
    try {
      final url = '$baseUrl/videos?ecole=$ecoleCode';
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
        
        if (jsonData['status'] == true && jsonData['data'] != null) {
          final List<dynamic> videosData = jsonData['data'];
          print('Videos Data Length: ${videosData.length}');
          
          final videos = videosData.map((json) => VisiteGuideeVideo.fromJson(json)).toList();
          print('Videos processed: ${videos.length}');
          
          for (var video in videos) {
            print('Video: ${video.typeVideo} - ${video.youtubeUrl}');
          }
          
          return videos;
        } else {
          print('Status false or data null');
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
}
