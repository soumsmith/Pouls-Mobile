import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'package:flutter/material.dart';
import '../models/scolarite.dart';
import '../config/app_config.dart';

class ScolariteService {
  static String get baseUrl => AppConfig.VIE_ECOLES_API_BASE_URL;

  static Future<List<Scolarite>> getScolaritesByEcole(
    String ecoleCode, {
    required String code,
  }) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('💰 CHARGEMENT DES FRAIS DE SCOLARITÉ');
    print('═══════════════════════════════════════════════════════════');
    print('🏫 Code école: $ecoleCode');
    print('🎒 Niveau: $code');

    String url =
        '$baseUrl/vie-ecoles/scolarite-niveau/${Uri.encodeComponent(code)}?ecole=${Uri.encodeComponent(ecoleCode)}';
    print('🔗 URL: $url');
    print('📡 Envoi de la requête...');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Données de scolarité reçues et parsées avec succès');
        print('═══════════════════════════════════════════════════════════');
        print('');

        List<Scolarite> allScolarites = [];
        if (jsonList.isNotEmpty) {
          final dataMap = jsonList.first as Map<String, dynamic>;
          if (dataMap.containsKey('AFF')) {
            final affList = dataMap['AFF'] as List<dynamic>;
            allScolarites.addAll(
              affList.map(
                (item) => Scolarite.fromJson(item as Map<String, dynamic>),
              ),
            );
          }
          if (dataMap.containsKey('NAFF')) {
            final naffList = dataMap['NAFF'] as List<dynamic>;
            allScolarites.addAll(
              naffList.map(
                (item) => Scolarite.fromJson(item as Map<String, dynamic>),
              ),
            );
          }
        }
        return allScolarites;
      } else if (response.statusCode == 404) {
        print('ℹ️ Aucun frais de scolarité trouvé pour ce niveau (404)');
        print('═══════════════════════════════════════════════════════════');
        print('');
        return [];
      } else {
        String errorMessage =
            'Erreur lors du chargement des frais de scolarité';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}

        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 Exception lors de la récupération des frais de scolarité: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      if (e is Exception && !e.toString().contains('Erreur de connexion')) {
        rethrow;
      }
      throw Exception(
        'Veuillez vérifier votre connexion internet et réessayer.',
      );
    }
  }

  static List<Scolarite> filtrerEtTrierScolarites(List<Scolarite> scolarites) {
    // Filtrer pour exclure les statuts ECOLIER et exclure la branche '*'
    final filtres = scolarites
        .where((s) => s.shouldDisplay && s.branche != '*')
        .toList();

    // Trier par date limite (croissante)
    filtres.sort((a, b) {
      final dateA = a.dateLimiteParsed;
      final dateB = b.dateLimiteParsed;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    return filtres;
  }

  static Map<String, List<Scolarite>> grouperParBranche(
    List<Scolarite> scolarites,
  ) {
    final Map<String, List<Scolarite>> groupes = {};

    for (final scolarite in scolarites) {
      final branche = scolarite.branche ?? 'AUTRE';
      if (!groupes.containsKey(branche)) {
        groupes[branche] = [];
      }
      groupes[branche]!.add(scolarite);
    }

    return groupes;
  }

  static Map<String, List<Scolarite>> separerParRubrique(
    List<Scolarite> scolarites,
  ) {
    final Map<String, List<Scolarite>> separes = {};

    for (final scolarite in scolarites) {
      final rubrique = scolarite.rubrique ?? 'AUTRE';
      if (!separes.containsKey(rubrique)) {
        separes[rubrique] = [];
      }
      separes[rubrique]!.add(scolarite);
    }

    return separes;
  }

  static Map<String, List<Scolarite>> separerParStatut(
    List<Scolarite> scolarites,
  ) {
    final Map<String, List<Scolarite>> separes = {
      'AFF': [], // Montants affectés
      'NAFF': [], // Montants non affectés
      'ECOLIER': [], // Montants écolier
    };

    for (final scolarite in scolarites) {
      if (scolarite.isEcolier) {
        separes['ECOLIER']!.add(scolarite);
      } else if (scolarite.isAffecte) {
        separes['AFF']!.add(scolarite);
      } else if (scolarite.isNonAffecte) {
        separes['NAFF']!.add(scolarite);
      }
    }

    return separes;
  }

  static int calculerTotalMontant(List<Scolarite> scolarites) {
    int total = 0;
    for (final scolarite in scolarites) {
      total += scolarite.totalMontant ?? 0;
    }
    return total;
  }

  static Map<String, int> calculerTotauxParStatut(List<Scolarite> scolarites) {
    final scolaritesParStatut = separerParStatut(scolarites);

    return {
      'AFF': calculerTotalMontant(scolaritesParStatut['AFF'] ?? []),
      'NAFF': calculerTotalMontant(scolaritesParStatut['NAFF'] ?? []),
      'ECOLIER': calculerTotalMontant(scolaritesParStatut['ECOLIER'] ?? []),
      'total': calculerTotalMontant(scolarites),
    };
  }

  static String formaterMontant(int montant) {
    // Formater manuellement sans intl pour éviter la dépendance
    String montantStr = montant.toString();
    String resultat = '';

    int compteur = 0;
    for (int i = montantStr.length - 1; i >= 0; i--) {
      resultat = montantStr[i] + resultat;
      compteur++;

      if (compteur == 3 && i != 0) {
        resultat = ' ' + resultat;
        compteur = 0;
      }
    }

    return '$resultat FCFA';
  }

  static String getStatutLibelle(String? statut) {
    switch (statut) {
      case 'AFF':
        return 'Affecté';
      case 'NAFF':
        return 'Non Affecté';
      case 'ECOLIER':
        return 'Écolier';
      default:
        return statut ?? 'Inconnu';
    }
  }

  static Color getStatutColor(String? statut) {
    switch (statut) {
      case 'AFF':
        return const Color(0xFF3B82F6); // Bleu
      case 'NAFF':
        return const Color(0xFFEF4444); // Rouge
      case 'ECOLIER':
        return const Color(0xFF6B7280); // Gris
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }
}
