import 'package:flutter/material.dart';
import '../models/subscription_offer.dart';
import '../services/subscription_service.dart';
import '../services/paiement_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../config/app_dimensions.dart';
import '../widgets/custom_button.dart';
import '../widgets/components/bottom_spacer.dart';

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
      final phone = user?.phone ?? '';

      final paiementResponse = await PaiementService().initierPaiementAbonnement(
        phone,
        offer.id,
        offer.price.toInt(),
      );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (paiementResponse.success && paiementResponse.url.isNotEmpty) {
        final launched = await PaiementService().lancerUrlPaiement(paiementResponse.url);
        if (launched) {
          // TODO: Implémenter le polling pour vérifier le statut du paiement,
          // de la même manière que pour l'inscription.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez finaliser votre paiement sur la page sécurisée.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
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
                Row(
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
