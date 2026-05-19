import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/paiement_historique.dart';
import '../services/paiement_historique_service.dart';
import 'bottom_sheets/bottom_sheet_header.dart';

class PaiementHistoriqueBottomSheet {
  static void show({
    required BuildContext context,
    required String childName,
    required String matricule,
    required String ecoleCode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaiementHistoriqueSheetContent(
        childName: childName,
        matricule: matricule,
        ecoleCode: ecoleCode,
        isDark: isDark,
      ),
    );
  }

  static String _formatCurrency(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return '$str FCFA';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()} FCFA';
  }
}

class _PaiementHistoriqueSheetContent extends StatefulWidget {
  final String childName;
  final String matricule;
  final String ecoleCode;
  final bool isDark;

  const _PaiementHistoriqueSheetContent({
    required this.childName,
    required this.matricule,
    required this.ecoleCode,
    required this.isDark,
  });

  @override
  State<_PaiementHistoriqueSheetContent> createState() => _PaiementHistoriqueSheetContentState();
}

class _PaiementHistoriqueSheetContentState extends State<_PaiementHistoriqueSheetContent> {
  String? _expandedNumeroRecu;
  Future<PaiementHistoriqueResponse>? _historiqueFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _historiqueFuture = PaiementHistoriqueService.getHistoriquePaiements(
      matricule: widget.matricule,
      ecoleCode: widget.ecoleCode,
    );
  }

  void _retry() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Garantit que le Future n'est jamais nul, même après un Hot Reload sur un état existant
    _historiqueFuture ??= PaiementHistoriqueService.getHistoriquePaiements(
      matricule: widget.matricule,
      ecoleCode: widget.ecoleCode,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.history_rounded,
              iconColor: AppColors.screenOrange,
              title: 'Historique des paiements',
              description: widget.childName,
              onClose: () => Navigator.of(context).pop(),
            ),
            
            // Contenu
            Expanded(
              child: FutureBuilder<PaiementHistoriqueResponse>(
                future: _historiqueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.screenOrange),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Erreur de chargement',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                               ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.screenOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text(
                                'Réessayer',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.screenOrange.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: AppColors.screenOrange,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aucun paiement trouvé',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cet élève n\'a aucun paiement enregistré pour le moment.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final paiements = snapshot.data!.data;

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: paiements.length,
                    itemBuilder: (context, index) {
                      final paiement = paiements[index];
                      final isExpanded = _expandedNumeroRecu == paiement.numeroRecu;
                      return _PaymentCard(
                        paiement: paiement,
                        isDark: widget.isDark,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedNumeroRecu = null;
                            } else {
                              _expandedNumeroRecu = paiement.numeroRecu;
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaiementHistorique paiement;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.paiement,
    required this.isDark,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0);
    final detailBgColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC);

    // Mode icon selection
    IconData modeIcon;
    switch (paiement.modePaiement) {
      case 'ESP':
        modeIcon = Icons.payments_rounded;
        break;
      case 'CB':
        modeIcon = Icons.credit_card_rounded;
        break;
      case 'VIR':
        modeIcon = Icons.account_balance_rounded;
        break;
      case 'MOB':
        modeIcon = Icons.phone_android_rounded;
        break;
      default:
        modeIcon = Icons.wallet_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Orange left indicator bar
                Container(
                  width: 5,
                  color: AppColors.screenOrange,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Collapsed Header Row: Amount & Arrow Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                PaiementHistoriqueBottomSheet._formatCurrency(paiement.montant),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.screenOrange,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Expand/collapse indicator icon
                            Icon(
                              isExpanded 
                                  ? Icons.keyboard_arrow_up_rounded 
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.screenOrange,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Date & Time (always shown)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.screenOrange.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: AppColors.screenOrange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Le ${paiement.formattedDate} à ${paiement.formattedTime}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Expanded Area
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9),
                          ),
                          const SizedBox(height: 12),

                          // Receipt number badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.screenOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.screenOrange,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reçu N° ${paiement.numeroRecu}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.screenOrange,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Mode de paiement & Exercice
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: detailBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        modeIcon,
                                        size: 13,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          paiement.modePaiementLibelle,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: detailBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        size: 13,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          paiement.exercice,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Caissier row
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: detailBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 13,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                      children: [
                                        const TextSpan(text: 'Enregistré par : '),
                                        TextSpan(
                                          text: paiement.caissier,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.grey[200] : const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Montant en lettres section
                          if (paiement.montantLettres.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.spellcheck_rounded,
                                    size: 14,
                                    color: isDark ? Colors.grey[500] : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      paiement.montantLettres.toUpperCase(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
