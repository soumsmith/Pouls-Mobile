import 'package:flutter/material.dart';
import '../models/subscription_offer.dart';
import '../models/user.dart';
import 'auth_service.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._internal();
  factory SubscriptionService() => instance;
  SubscriptionService._internal();

  // Mock data pour les offres d'abonnement
  final List<SubscriptionOffer> _mockOffers = [
    SubscriptionOffer(
      id: 'sub_free',
      title: 'Basique',
      description: 'Pour découvrir l\'application',
      price: 0,
      duration: 'A vie',
      level: 'free',
      features: [
        'Accès au tableau de bord',
        'Visualisation des notes (limitée)',
        'Notifications de base',
      ],
    ),
    SubscriptionOffer(
      id: 'sub_premium',
      title: 'Premium',
      description: 'L\'expérience complète pour les parents exigeants',
      price: 4900,
      duration: '1 mois',
      level: 'premium',
      isPopular: true,
      features: [
        'Accès au tableau de bord',
        'Visualisation détaillée des notes et statistiques',
        'Toutes les notifications en temps réel',
        'Suivi de la cantine et du transport',
        'Messagerie directe avec les professeurs',
      ],
    ),
    SubscriptionOffer(
      id: 'sub_vip',
      title: 'VIP',
      description: 'Pour plusieurs enfants et un suivi exclusif',
      price: 12900,
      duration: '1 an',
      level: 'vip',
      features: [
        'Toutes les fonctionnalités Premium',
        "Jusqu'à 5 enfants inclus",
        'Support prioritaire 24/7',
        'Accès anticipé aux nouvelles fonctionnalités',
      ],
    ),
  ];

  Future<List<SubscriptionOffer>> getOffers() async {
    // Simuler un appel réseau
    await Future.delayed(const Duration(seconds: 1));
    return _mockOffers;
  }

  /// Vérifie si l'utilisateur courant a un certain niveau ou privilège
  bool hasPrivilege(String requiredLevel) {
    final user = AuthService.instance.getCurrentUser();
    if (user == null) return false;

    // Définir une hiérarchie simple: vip > premium > free
    int getLevelRank(String level) {
      switch (level.toLowerCase()) {
        case 'vip': return 3;
        case 'premium': return 2;
        case 'free': return 1;
        default: return 0;
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
