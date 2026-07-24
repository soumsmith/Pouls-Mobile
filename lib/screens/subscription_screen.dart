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
import '../widgets/scroll_to_top_fab.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  List<SubscriptionOffer> _offers = [];
  
  final ScrollController _scrollController = ScrollController();
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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

    timer = Timer.periodic(
      const Duration(seconds: AppConfig.PAYMENT_VERIFICATION_INTERVAL_SECONDS),
      (t) async {
        if (isChecking || !mounted) return;

        attempts++;
        if (attempts >= maxAttempts) {
          t.cancel();
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Le délai de vérification est dépassé. N\'hésitez pas à réessayer si votre compte n\'a pas été débité.',
                ),
                backgroundColor: Colors.orange,
              ),
            );

            NotificationService().showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: 'Vérification d\'abonnement en attente',
              body:
                  'Le délai de vérification de l\'abonnement ${offer.title} est dépassé. Si votre compte a été débité, votre abonnement s\'activera automatiquement.',
              payload: 'abonnement_timeout',
            );
          }
          return;
        }

        isChecking = true;

        try {
          final success = await PaiementService()
              .checkSubscriptionPaymentStatus(userId);
          if (success && mounted) {
            t.cancel();
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Paiement validé ! Abonnement ${offer.title} activé avec succès.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Ignorer les erreurs
        } finally {
          isChecking = false;
        }
      },
    );
  }

  Future<void> _subscribe(SubscriptionOffer offer) async {
    // Si l'offre est gratuite, on valide directement
    if (offer.price == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final success = await SubscriptionService.instance.subscribeToOffer(
        offer,
      );
      if (!mounted) return;
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abonnement ${offer.title} activé !'),
            backgroundColor: Colors.green,
          ),
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
      final children = await DatabaseService.instance.getChildrenByParent(
        userId,
      );
      final eleveIds = children.map((c) => c.id).toList();

      final paiementResponse = await PaiementService()
          .initierPaiementAbonnement(
            subscriptionPlanId: int.tryParse(offer.id) ?? 1,
            userId: userId,
            amountPaid: offer.price.toInt(),
            eleveIds: eleveIds,
          );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (paiementResponse.success && paiementResponse.url.isNotEmpty) {
        final launched = await PaiementService().lancerUrlPaiement(
          paiementResponse.url,
        );
        if (launched) {
          // Lancer le polling pour vérifier le statut du paiement
          _showPaymentVerificationLoader(userId, offer);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir la page de paiement.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paiementResponse.message),
            backgroundColor: Colors.red,
          ),
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

    final filteredOffers = _offers.where((offer) {
      final query = _searchQuery.toLowerCase();
      return offer.title.toLowerCase().contains(query) ||
          offer.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      floatingActionButton: ScrollToTopFab(
        scrollController: _scrollController,
        bottomSpacerHeight: 70,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CustomSliverAppBar(title: 'Passer Premium', isDark: isDark),
          
          // --- Barre de recherche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Rechercher une offre...',
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: isDark ? Colors.white54 : Colors.black54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          else if (filteredOffers.isEmpty)
            SliverFillRemaining(
              child: CustomErrorState(
                title: _searchQuery.isNotEmpty ? 'Aucune offre trouvée' : 'Aucune offre',
                message: _searchQuery.isNotEmpty 
                    ? 'Aucun abonnement ne correspond à votre recherche.'
                    : 'Aucun abonnement n\'est disponible pour le moment.',
                icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.card_membership,
                retryText: 'Rafraîchir',
                onRetry: _loadOffers,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: MediaQuery.of(context).size.width > 600
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisExtent: 560,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildOfferCard(filteredOffers[index], isDark, context, isGrid: true);
                        },
                        childCount: filteredOffers.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildOfferCard(filteredOffers[index], isDark, context);
                        },
                        childCount: filteredOffers.length,
                      ),
                    ),
            ),
          SliverToBoxAdapter(child: const BottomSpacer()),
        ],
      ),
    );
  }

  Widget _buildOfferCard(
    SubscriptionOffer offer,
    bool isDark,
    BuildContext context, {
    bool isGrid = false,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final primaryColor = offer.isPopular ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
    final gradient = offer.isPopular 
        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
        : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]);

    return Container(
      margin: isGrid 
          ? EdgeInsets.zero 
          : const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : primaryColor).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: offer.isPopular
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          width: offer.isPopular ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image et Badge
            Stack(
              children: [
                if (offer.image != null)
                  CachedNetworkImage(
                    imageUrl: offer.image!,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 90,
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 90,
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
                      child: Icon(Icons.image_not_supported, size: 24, color: subtitleColor),
                    ),
                  )
                else
                  Container(
                    height: 6,
                    decoration: BoxDecoration(gradient: gradient),
                  ),

                if (offer.isPopular)
                  Positioned(
                    top: offer.image != null ? 8 : 0,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'POPULAIRE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (isGrid)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _buildCardContent(offer, isDark, textColor, subtitleColor, primaryColor, context, isGrid: isGrid),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _buildCardContent(offer, isDark, textColor, subtitleColor, primaryColor, context, isGrid: isGrid),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(
    SubscriptionOffer offer,
    bool isDark,
    Color textColor,
    Color subtitleColor,
    Color primaryColor,
    BuildContext context, {
    bool isGrid = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  // En-tête (Titre + Prix)
                  if (isGrid) ...[
                    // Sur tablette en grille, on empile verticalement
                    Text(
                      offer.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description,
                      style: TextStyle(color: subtitleColor, fontSize: 12, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          if (offer.isPromoActive)
                            Text(
                              '${offer.price.toInt()} ${offer.currency}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade400,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                offer.activePrice == 0 ? 'Gratuit' : '${offer.activePrice.toInt()}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: offer.isPromoActive ? const Color(0xFF10B981) : primaryColor,
                                ),
                              ),
                              if (offer.activePrice > 0)
                                Text(
                                  ' ${offer.currency}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: offer.isPromoActive ? const Color(0xFF10B981) : primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          if (offer.activePrice > 0)
                            Text(
                              '/ ${offer.durationDays}j',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else
                    // Sur mobile, on affiche côte à côte
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                offer.description,
                                style: TextStyle(color: subtitleColor, fontSize: 12, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              if (offer.isPromoActive)
                                Text(
                                  '${offer.price.toInt()} ${offer.currency}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade400,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    offer.activePrice == 0 ? 'Gratuit' : '${offer.activePrice.toInt()}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: offer.isPromoActive ? const Color(0xFF10B981) : primaryColor,
                                    ),
                                  ),
                                  if (offer.activePrice > 0)
                                    Text(
                                      ' ${offer.currency}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: offer.isPromoActive ? const Color(0xFF10B981) : primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                              if (offer.activePrice > 0)
                                Text(
                                  '/ ${offer.durationDays}j',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Enfants
                  Row(
                    children: [
                      Icon(Icons.family_restroom, size: 16, color: primaryColor.withOpacity(0.8)),
                      const SizedBox(width: 6),
                      Text(
                        'Jusqu\'à ${offer.maxStudents} enfant${offer.maxStudents > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),

                  // Liste des modules
                  Text(
                    'Inclus :',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...offer.packageModules.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.nom,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (module.description != null && module.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    module.description!,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                         if (isGrid) const Spacer() else const SizedBox(height: 16),
                  
                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _subscribe(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark 
                            ? Colors.white.withOpacity(0.08) 
                            : const Color(0xFFF2F4F7),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        offer.activePrice == 0 ? 'Commencer gratuitement' : "Sélectionner ce plan",
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
    );
  }
}
