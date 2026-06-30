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
import '../widgets/custom_button.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/components/custom_error_state.dart';

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
    const int maxAttempts = 10; // 50 secondes de polling

    timer = Timer.periodic(const Duration(seconds: 5), (t) async {
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDimensions.getBottomSheetShadow(context),
        border: offer.isPopular
            ? Border.all(color: Colors.amber.shade400, width: 3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer.isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'LE PLUS POPULAIRE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${offer.price.toInt()} FCFA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Text(
                        ' / ${offer.duration}',
                        style: TextStyle(
                          fontSize: 16,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                ...offer.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: offer.isPopular
                                  ? Colors.amber.shade600
                                  : Colors.green),
                          const SizedBox(width: 12),
                          Expanded(child: Text(feature, style: TextStyle(color: textColor))),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                CustomButton(
                  text: offer.price == 0 ? 'Commencer' : "S'abonner",
                  onPressed: () => _subscribe(offer),
                  backgroundColor: offer.isPopular
                      ? Colors.amber.shade600
                      : Colors.indigo.shade600,
                  textColor: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
