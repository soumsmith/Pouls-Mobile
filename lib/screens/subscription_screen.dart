import 'package:flutter/material.dart';
import 'dart:async';
import '../models/subscription_offer.dart';
import '../services/subscription_service.dart';
import '../services/paiement_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/payment_verification_dialog.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../config/app_dimensions.dart';
import '../config/app_config.dart';
import '../widgets/custom_button.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/components/custom_error_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  List<SubscriptionOffer> _offers = [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final offers = await SubscriptionService.instance.getOffers();
    setState(() {
      _offers = offers;
      _isLoading = false;
    });
  }

  void _showPaymentVerificationLoader(String userId, SubscriptionOffer offer) {
    if (userId.isEmpty) return;

    Timer? timer;
    bool isChecking = false;

    PaymentVerificationDialog.show(
      context: context,
      childName: 'votre compte',
      montant: offer.price.toInt(),
      establishment: 'la plateforme',
      serviceType: 'abonnement',
    ).then((_) {
      timer?.cancel();
    });

    int attempts = 0;
    const int maxAttempts = AppConfig.PAYMENT_VERIFICATION_MAX_ATTEMPTS;

    timer = Timer.periodic(const Duration(seconds: AppConfig.PAYMENT_VERIFICATION_INTERVAL_SECONDS), (t) async {
      if (isChecking || !mounted) return;

      attempts++;
      if (attempts >= maxAttempts) {
        t.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le délai de vérification est dépassé. N\'hésitez pas à réessayer si votre compte n\'a pas été débité.'),
              backgroundColor: Colors.orange,
            ),
          );
          
          NotificationService().showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Vérification d\'abonnement en attente',
            body: 'Le délai de vérification de l\'abonnement \${offer.title} est dépassé. Si votre compte a été débité, votre abonnement s\'activera automatiquement.',
            payload: 'abonnement_timeout',
          );
        }
        return;
      }

      isChecking = true;

      try {
        final success = await PaiementService().checkSubscriptionPaymentStatus(userId);
        if (success && mounted) {
          t.cancel();
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paiement validé ! Abonnement \${offer.title} activé avec succès.'),
              backgroundColor: Colors.green,
            ),
          );
          
          NotificationService().showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Abonnement validé',
            body: 'Votre abonnement \${offer.title} a été activé avec succès !',
            payload: 'abonnement_success',
          );
        }
      } catch (e) {
        // Ignorer les erreurs
      } finally {
        isChecking = false;
      }
    });
  }

  Future<void> _subscribe(SubscriptionOffer offer) async {
    // Si l'offre est gratuite, on valide directement
    if (offer.price == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final success = await SubscriptionService.instance.subscribeToOffer(offer);
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abonnement ${offer.title} activé !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Pour une offre payante : Paiement en ligne
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = AuthService.instance.getCurrentUser();
      final userId = user?.id ?? '19421';

      // Récupérer la liste des enfants (élèves) du parent pour l'abonnement
      final children = await DatabaseService.instance.getChildrenByParent(userId);
      final eleveIds = children.map((c) => c.id).toList();

      final paiementResponse = await PaiementService().initierPaiementAbonnement(
        subscriptionPlanId: int.tryParse(offer.id) ?? 1,
        userId: userId,
        amountPaid: offer.price.toInt(),
        eleveIds: eleveIds,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (paiementResponse.success && paiementResponse.url.isNotEmpty) {
        final launched = await PaiementService().lancerUrlPaiement(paiementResponse.url);
        if (launched) {
          // Lancer le polling pour vérifier le statut du paiement
          _showPaymentVerificationLoader(userId, offer);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir la page de paiement.'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paiementResponse.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Passer Premium',
            isDark: isDark,
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          else if (_offers.isEmpty)
            SliverFillRemaining(
              child: CustomErrorState(
                title: 'Aucune offre',
                message: 'Aucun abonnement n\'est disponible pour le moment.',
                icon: Icons.card_membership,
                retryText: 'Rafraîchir',
                onRetry: _loadOffers,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final offer = _offers[index];
                    return _buildOfferCard(offer, isDark, context);
                  },
                  childCount: _offers.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: const BottomSpacer(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(SubscriptionOffer offer, bool isDark, BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDimensions.getBottomSheetShadow(context),
        border: offer.isPopular
            ? Border.all(color: Colors.amber.shade400, width: 2)
            : Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de la carte avec l'image ou le badge
          Stack(
            children: [
              if (offer.image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: offer.image!,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 110,
                      color: Colors.grey.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 110,
                      color: Colors.grey.withOpacity(0.1),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                )
              else
                Container(
                  height: 24, // Espace minimal si pas d'image
                  decoration: BoxDecoration(
                    color: offer.isPopular ? Colors.amber.shade400 : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                ),
                
              if (offer.isPopular)
                Positioned(
                  top: offer.image != null ? 12 : 0,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: const Text(
                      'POPULAIRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Section Prix
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (offer.isPromoActive)
                        Text(
                          '${offer.price.toInt()} ${offer.currency}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade400,
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              offer.activePrice == 0 ? 'Gratuit' : '${offer.activePrice.toInt()} ${offer.currency}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: offer.isPromoActive ? Colors.green.shade600 : textColor,
                              ),
                            ),
                            if (offer.activePrice > 0)
                              Text(
                                ' / ${offer.durationDays}j',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.family_restroom, size: 16, color: subtitleColor),
                          const SizedBox(width: 6),
                          Text(
                            'Jusqu\'à ${offer.maxStudents} enfant${offer.maxStudents > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Liste des modules
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Inclus dans ce forfait :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...offer.packageModules.map((module) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.nom, 
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (module.description != null && module.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    module.description!,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                CustomButton(
                  text: offer.activePrice == 0 ? 'Commencer' : "Sélectionner ce plan",
                  onPressed: () => _subscribe(offer),
                  backgroundColor: offer.isPopular
                      ? Colors.amber.shade600
                      : Colors.indigo.shade600,
                  textColor: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
