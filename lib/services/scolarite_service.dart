import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/scolarite.dart';

class ScolariteService {
  static const String baseUrl = 'https://api2.vie-ecoles.com/api';

  static Future<ScolariteResponse> getScolaritesByEcole(String ecoleCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ecoles/scolarites/$ecoleCode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ScolariteResponse.fromJson(jsonData);
      } else {
        throw Exception('Erreur lors du chargement des frais de scolarité: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static List<Scolarite> filtrerEtTrierScolarites(List<Scolarite> scolarites) {
    // Filtrer pour exclure les statuts ECOLIER
    final filtres = scolarites.where((s) => s.shouldDisplay).toList();
    
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

  static Map<String, List<Scolarite>> grouperParBranche(List<Scolarite> scolarites) {
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

  static Map<String, List<Scolarite>> separerParRubrique(List<Scolarite> scolarites) {
    final Map<String, List<Scolarite>> separes = {
      'INS': [],  // Inscription
      'SCO': [],  // Scolarité
    };
    
    for (final scolarite in scolarites) {
      final rubrique = scolarite.rubrique ?? 'AUTRE';
      if (separes.containsKey(rubrique)) {
        separes[rubrique]!.add(scolarite);
      }
    }
    
    return separes;
  }

  static Map<String, List<Scolarite>> separerParStatut(List<Scolarite> scolarites) {
    final Map<String, List<Scolarite>> separes = {
      'AFF': [],  // Montants affectés
      'NAFF': [], // Montants non affectés
    };
    
    for (final scolarite in scolarites) {
      final statut = scolarite.statut ?? 'AUTRE';
      if (separes.containsKey(statut)) {
        separes[statut]!.add(scolarite);
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
