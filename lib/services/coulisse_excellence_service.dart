import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coulisse_excellence.dart';

class CoulisseExcellenceService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/ecoles';

  static Future<List<CoulisseExcellence>> getCoulisseExcellenceList(String ecoleId) async {
    try {
      final url = '$baseUrl/coulisseexcellencelist?ecole=$ecoleId';
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
        final List<dynamic> jsonData = json.decode(response.body);
        print('JSON Data Length: ${jsonData.length}');
        print('JSON Data: $jsonData');
        
        final videos = jsonData.map((json) => CoulisseExcellence.fromJson(json)).toList();
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
}
