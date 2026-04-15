import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paiement_historique.dart';

class PaiementHistoriqueService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api/vie-ecoles';

  /// Récupère l'historique des paiements d'un élève
  static Future<PaiementHistoriqueResponse> getHistoriquePaiements({
    required String matricule,
    required String ecoleCode,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/paiements-scolarite-eleve/$matricule?ecole=$ecoleCode',
      );

      print('URL de l\'API: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return PaiementHistoriqueResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique des paiements: $e');
      throw Exception('Impossible de récupérer l\'historique des paiements: $e');
    }
  }
}
