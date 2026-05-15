// services/video_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';

class VideoService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/vie-ecoles/videos';

  static Future<List<Video>> getVideosByType(String type) async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        
        // Filtrer par typevideo
        final filteredVideos = data.where((item) {
          return item['typevideo'] == type;
        }).toList();
        
        return filteredVideos.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }

  static Future<List<Video>> getAllVideos() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        
        return data.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }
}