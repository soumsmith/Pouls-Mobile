import 'package:flutter/material.dart';
import '../models/subscription_offer.dart';
import '../models/user.dart';
import 'auth_service.dart';
import '../config/app_config.dart';

import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._internal();
  factory SubscriptionService() => instance;
  SubscriptionService._internal();

  Future<List<SubscriptionOffer>> getOffers() async {
    try {
      final user = AuthService.instance.getCurrentUser();
      // On utilise l'ID de l'utilisateur connecté ou 19421 par défaut (selon la consigne)
      final userId = user?.id ?? '19421';

      final url = Uri.parse(
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/espace-parent/subscriptions/$userId',
      );

      print('================= RÉCUPÉRATION DES OFFRES =================');
      print('🌐 API GET - URL: $url');

      final response = await http.get(url);

      print('🌐 API GET - Status: ${response.statusCode}');
      print('🌐 API GET - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> plansJson = data['plans'] ?? [];
        final List<dynamic> modulesJson = data['accessible_modules'] ?? [];

        final List<String> modules = modulesJson
            .map((e) => e.toString())
            .toList();

        print('✅ ${plansJson.length} offres récupérées !');
        return plansJson
            .map((plan) => SubscriptionOffer.fromJson(plan))
            .toList();
      } else {
        print('❌ Erreur API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des offres: $e');
      return [];
    }
  }

  /// Vérifie si l'utilisateur courant a un certain niveau ou privilège
  bool hasPrivilege(String requiredLevel) {
    final user = AuthService.instance.getCurrentUser();
    if (user == null) return false;

    // Définir une hiérarchie simple: vip > premium > free
    int getLevelRank(String level) {
      switch (level.toLowerCase()) {
        case 'vip':
          return 3;
        case 'premium':
          return 2;
        case 'free':
          return 1;
        default:
          return 0;
      }
    }

    final userRank = getLevelRank(user.userLevel);
    final requiredRank = getLevelRank(requiredLevel);

    return userRank >= requiredRank;
  }

  /// Mettre à jour l'abonnement de l'utilisateur (Mock)
  Future<bool> subscribeToOffer(SubscriptionOffer offer) async {
    // Simuler un appel réseau / paiement
    await Future.delayed(const Duration(seconds: 2));

    final user = AuthService.instance.getCurrentUser();
    if (user != null) {
      // Mettre à jour le user en mémoire (Mock)
      final updatedUser = user.copyWith(userLevel: offer.level);
      // NOTE: Dans une vraie app, on mettrait aussi à jour AuthService._currentUser
      // Pour ce mock, on va passer par une méthode spécifique qu'on ajoutera à AuthService
      await AuthService.instance.updateUserSubscription(offer.level);
      return true;
    }
    return false;
  }
}
