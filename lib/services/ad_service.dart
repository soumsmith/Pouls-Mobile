import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ad_model.dart';

class AdService {
  static const String _apiUrl = 'https://api-africa.vie-ecoles.com/api/africa/publicites-list';

  Future<List<AdModel>> fetchAds() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        List<AdModel> allAds = jsonList.map((json) => AdModel.fromJson(json)).toList();
        
        // Filtrer les publicités actives
        return allAds.where((ad) => ad.isActive).toList();
      } else {
        throw Exception('Failed to load ads (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching ads: $e');
      return [];
    }
  }
}
