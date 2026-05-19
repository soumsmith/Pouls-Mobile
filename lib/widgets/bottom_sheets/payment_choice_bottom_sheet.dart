import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'bottom_sheet_header.dart';

class PaymentChoiceBottomSheet extends StatelessWidget {
  final VoidCallback onOnlinePayment;
  final VoidCallback onCashPayment;

  const PaymentChoiceBottomSheet({
    super.key,
    required this.onOnlinePayment,
    required this.onCashPayment,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onOnlinePayment,
    required VoidCallback onCashPayment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PaymentChoiceBottomSheet(
          onOnlinePayment: onOnlinePayment,
          onCashPayment: onCashPayment,
        );
      },
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBg = isDark ? const Color(0xFF141414) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.shopBlue,
              title: 'Mode de paiement',
              description: 'Choisissez comment vous souhaitez payer votre inscription',
              onClose: () => Navigator.of(context).pop(),
              titleColor: isDark ? Colors.white : AppColors.screenTextPrimary,
              descriptionColor: isDark ? Colors.white70 : AppColors.screenTextSecondary,
              titleFontSize: 18,
              descriptionFontSize: 13,
              titleFontWeight: FontWeight.w800,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  _buildChoiceCard(
                    context,
                    title: 'Paiement en ligne',
                    description: 'Payer par Mobile Money (Wave, Orange, MTN...) ou carte bancaire.',
                    icon: Icons.phone_iphone_rounded,
                    onTap: onOnlinePayment,
                    color: const Color(0xFFFF7A3C),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceCard(
                    context,
                    title: 'Paiement à la caisse',
                    description: 'Payer physiquement à la caisse de l\'établissement scolaire.',
                    icon: Icons.storefront_rounded,
                    onTap: onCashPayment,
                    color: AppColors.shopBlue,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
