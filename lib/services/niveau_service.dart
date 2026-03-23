import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/niveau.dart';
import '../config/app_config.dart';

class NiveauService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static Future<List<Niveau>> getNiveauxByEcole(String ecoleCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ecoles/niveaux/$ecoleCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Niveau.fromJson(json)).toList();
      } else {
        throw Exception(
          'Erreur lors du chargement des niveaux: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static List<Niveau> trierNiveaux(List<Niveau> niveaux) {
    final sortedNiveaux = List<Niveau>.from(niveaux);
    sortedNiveaux.sort((a, b) {
      // D'abord trier par filière
      final filiereComparison = (a.filiere ?? '').compareTo(b.filiere ?? '');
      if (filiereComparison != 0) return filiereComparison;

      // Ensuite par ordre
      final ordreComparison = (a.ordre ?? 0).compareTo(b.ordre ?? 0);
      if (ordreComparison != 0) return ordreComparison;

      // Enfin par nom
      return (a.nom ?? '').compareTo(b.nom ?? '');
    });
    return sortedNiveaux;
  }

  static Map<String, List<Niveau>> grouperParFiliere(List<Niveau> niveaux) {
    final Map<String, List<Niveau>> groupes = {};

    for (final niveau in niveaux) {
      final filiere = niveau.filiere ?? 'AUTRE';
      if (!groupes.containsKey(filiere)) {
        groupes[filiere] = [];
      }
      groupes[filiere]!.add(niveau);
    }

    return groupes;
  }

  static Map<bool, List<Niveau>> separerParMontantAffecte(
    List<Niveau> niveaux,
  ) {
    final Map<bool, List<Niveau>> separes = {
      true: [], // Montants affectés
      false: [], // Montants non affectés
    };

    for (final niveau in niveaux) {
      final estAffecte = niveau.montantAffecte ?? false;
      separes[estAffecte]!.add(niveau);
    }

    return separes;
  }
}
