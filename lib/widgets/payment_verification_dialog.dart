import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Modal de vérification de paiement en ligne.
/// 
/// Affiche un design premium avec :
/// - Header gradient orange avec icône animée
/// - Infos de la transaction (élève, montant, école)
/// - Loader animé
/// - Badge sécurisé WicPay
class PaymentVerificationDialog {
  PaymentVerificationDialog._();

  /// Affiche le dialog de vérification de paiement.
  ///
  /// [context] - Le BuildContext
  /// [childName] - Le prénom de l'élève
  /// [montant] - Le montant en FCFA
  /// [establishment] - Le nom de l'école
  /// [serviceType] - Le type de service (ex: "scolarité", "réservation", "inscription")
  static Future<void> show({
    required BuildContext context,
    required String childName,
    required int montant,
    required String establishment,
    String serviceType = 'scolarité',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header avec gradient ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF7A3C), Color(0xFFFF9A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Paiement en cours',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vérification automatique',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Contenu ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        // Loader animé
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: const Color(0xFFFF7A3C),
                          size: 44,
                        ),
                        const SizedBox(height: 20),

                        // Infos de la transaction
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFEEEEEE),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.person_outline_rounded,
                                childName,
                                isDark,
                              ),
                              _buildDivider(isDark),
                              _buildInfoRow(
                                Icons.account_balance_wallet_outlined,
                                '$montant FCFA',
                                isDark,
                              ),
                              _buildDivider(isDark),
                              _buildInfoRow(
                                Icons.school_outlined,
                                establishment,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Message d'instruction
                        Text(
                          'Veuillez finaliser le paiement sur la page sécurisée. L\'application vérifie automatiquement le statut de votre transaction.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Badge sécurisé
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Transaction sécurisée via WicPay',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A3C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFFF7A3C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2D3748),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFEEEEEE),
      ),
    );
  }
}
