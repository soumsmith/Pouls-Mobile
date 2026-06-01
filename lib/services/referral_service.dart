import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/referred_user.dart';
import '../config/app_config.dart';

class ReferralService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static Future<List<ReferredUser>> getReferredUsers(String phone) async {
    final url = Uri.parse('$baseUrl/vie-ecoles/info-parrainage/$phone?type=parents');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == true && decoded['data'] != null) {
          final comptesParraines = decoded['data']['comptes_parraines'] as List<dynamic>?;
          if (comptesParraines != null) {
            return comptesParraines
                .map((json) => ReferredUser.fromJson(json))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('Erreur dans getReferredUsers: $e');
      return [];
    }
  }
}
