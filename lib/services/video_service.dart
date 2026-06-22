// services/video_service.dart
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'dart:developer' as developer;
import '../models/video.dart';
import '../config/app_config.dart';

class VideoService {
  static String get baseUrl =>
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/videos';

  static Future<List<Video>> getVideosByType(String type, {int page = 1, int perPage = 20}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'type_video': type,
        'page': page.toString(),
        'per_page': perPage.toString(),
      });
      developer.log('GET Request URL: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        // Filtrer par typevideo (sécurité côté client)
        final filteredVideos = data.where((item) {
          return item['typevideo'] == type;
        }).toList();

        return filteredVideos.map((json) {
          final video = Video.fromJson(json);
          print('📹 Video chargée - id: ${video.id}, code: "${video.code}", etablissement: "${video.etablissement}", title: "${video.title}"');
          return video;
        }).toList();
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }

  static Future<List<Video>> getAllVideos() async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'per_page': '1000',
      });
      developer.log('GET Request URL: $uri');
      final response = await http.get(uri);

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
