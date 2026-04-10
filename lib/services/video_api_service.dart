import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';

class VideoApiService {
  static const String baseUrl = 'https://api2.vie-ecoles.com';
  static const String videosEndpoint = '/api/vie-ecoles/videos';

  static Future<List<Video>> getVideos({String? ecole}) async {
    try {
      final Map<String, String> queryParams = {};
      if (ecole != null && ecole.isNotEmpty) {
        queryParams['ecole'] = ecole;
      }

      final uri = Uri.parse('$baseUrl$videosEndpoint').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> videosData = responseData['data'];
          return videosData.map((videoData) => Video.fromJson(videoData)).toList();
        } else {
          throw Exception('API returned status: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  static Future<List<Video>> getVideosForSchool(String ecole) async {
    return getVideos(ecole: ecole);
  }
}
