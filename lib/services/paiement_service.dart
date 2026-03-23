import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class PaiementResponse {
  final bool success;
  final String message;
  final String url;

  PaiementResponse({
    required this.success,
    required this.message,
    required this.url,
  });

  factory PaiementResponse.fromJson(Map<String, dynamic> json) {
    return PaiementResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class PaiementService {
  static String get baseUrl =>
      '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles';

  Future<PaiementResponse> initierPaiementEnLigne(
    String matricule,
    int montant,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/scolarite/paiement-en-ligne/$matricule?montant=$montant',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('💳 API Paiement - Status: ${response.statusCode}');
      print(
        '💳 API Paiement - URL: $baseUrl/scolarite/paiement-en-ligne/$matricule?montant=$montant',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final paiementResponse = PaiementResponse.fromJson(responseData);

        print('✅ Paiement initié: ${paiementResponse.success}');
        print('🔗 URL de paiement: ${paiementResponse.url}');

        return paiementResponse;
      } else {
        print(
          '❌ Erreur API Paiement: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Erreur lors de l\'initialisation du paiement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception lors de l\'initialisation du paiement: $e');
      throw Exception('Impossible d\'initialiser le paiement: $e');
    }
  }

  Future<bool> lancerUrlPaiement(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('🚀 Lancement URL de paiement: $launched');
        return launched;
      } else {
        print('❌ Impossible de lancer l\'URL: $url');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du lancement de l\'URL: $e');
      return false;
    }
  }
}
