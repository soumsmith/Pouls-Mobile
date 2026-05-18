import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/paiement_historique.dart';
import '../services/paiement_historique_service.dart';

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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151522) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header avec poignée premium
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Titre avec header enrichi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.screenOrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.screenOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historique des paiements',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            childName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton fermer premium
                    Material(
                      color: isDark ? const Color(0xFF242435) : Colors.grey[100],
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: isDark ? const Color(0xFF262639) : const Color(0xFFE2E8F0),
              ),
              
              // Contenu
              Expanded(
                child: FutureBuilder<PaiementHistoriqueResponse>(
                  future: PaiementHistoriqueService.getHistoriquePaiements(
                    matricule: matricule,
                    ecoleCode: ecoleCode,
                  ),
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
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  PaiementHistoriqueBottomSheet.show(
                                    context: context,
                                    childName: childName,
                                    matricule: matricule,
                                    ecoleCode: ecoleCode,
                                  );
                                },
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
                        return _buildPaymentCard(context, paiement, isDark);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPaymentCard(BuildContext context, PaiementHistorique paiement, bool isDark) {
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

    final cardBgColor = isDark ? const Color(0xFF1E1E2D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C3D) : const Color(0xFFE2E8F0);
    final detailBgColor = isDark ? const Color(0xFF26263A) : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Orange left indicator bar
              Container(
                width: 6,
                color: AppColors.screenOrange,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Amount & Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatCurrency(paiement.montant),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.screenOrange,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Premium Status badge chip for receipt
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.screenOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
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
                                  paiement.numeroRecu,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.screenOrange,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Beautiful separator
                      Container(
                        height: 1,
                        color: isDark ? const Color(0xFF2C2C3D) : const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(height: 14),

                      // Info row: Date & Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.screenOrange.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.screenOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Le ${paiement.formattedDate} à ${paiement.formattedTime}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Metadata Grid / chips
                      Row(
                        children: [
                          // Mode de paiement chip
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: detailBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    modeIcon,
                                    size: 14,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      paiement.modePaiementLibelle,
                                      style: TextStyle(
                                        fontSize: 12,
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
                          const SizedBox(width: 10),
                          // Exercice chip
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: detailBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 14,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      paiement.exercice,
                                      style: TextStyle(
                                        fontSize: 12,
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
                      const SizedBox(height: 10),

                      // Caissier row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: detailBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C29) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF26263B) : const Color(0xFFF1F5F9),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.spellcheck_rounded,
                                size: 15,
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
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
