import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lieu_livraison.dart';
import '../config/app_config.dart';

class LieuLivraisonService {
  static String get _baseUrl =>
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<LieuLivraison>> getLieuxLivraison() async {
    try {
      print('🔄 Récupération des lieux de livraison...');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/liste-lieux-livraison'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      print('📡 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> lieuxData = data['data'];
          final List<LieuLivraison> lieux = lieuxData
              .map((json) => LieuLivraison.fromJson(json))
              .where((lieu) => lieu.status == 1) // Uniquement les lieux actifs
              .toList();

          print('✅ ${lieux.length} lieu(x) de livraison récupéré(s)');
          return lieux;
        } else {
          throw Exception(
            data['message'] ??
                'Erreur lors de la récupération des lieux de livraison',
          );
        }
      } else {
        throw Exception(
          'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des lieux de livraison: $e');
      throw Exception('Impossible de récupérer les lieux de livraison: $e');
    }
  }

  Future<LieuLivraison?> getLieuLivraisonById(int id) async {
    try {
      final lieux = await getLieuxLivraison();
      return lieux.firstWhere((lieu) => lieu.id == id);
    } catch (e) {
      print('❌ Erreur lors de la récupération du lieu $id: $e');
      return null;
    }
  }
}
