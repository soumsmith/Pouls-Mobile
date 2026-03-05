import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';

/// Modèle pour une action dans la carte horizontale
class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  const ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });
}

/// Widget de carte d'action horizontale réutilisable
class HorizontalActionCard extends StatelessWidget {
  final List<ActionItem> actions;
  final double height;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? inactiveBorderColor;
  final TextStyle? labelTextStyle;

  const HorizontalActionCard({
    super.key,
    required this.actions,
    this.height = 48,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.borderRadius = 24,
    this.activeColor,
    this.inactiveColor,
    this.inactiveBorderColor,
    this.labelTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: height,
      margin: margin,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          final isActive = action.isActive;
          
          return _buildActionButton(context, action, isActive, isDark);
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ActionItem action, bool isActive, bool isDark) {
    // Déterminer les couleurs
    final Color backgroundColor = isActive 
        ? (action.activeColor ?? activeColor ?? AppColors.primary)
        : Colors.transparent;
    
    final Color foregroundColor = isActive
        ? Colors.white
        : (inactiveColor ?? AppColors.getTextColor(isDark));
    
    final Color borderColor = isActive
        ? backgroundColor
        : (inactiveBorderColor ?? AppColors.getTextColor(isDark).withOpacity(0.3));

    return GestureDetector(
      onTap: action.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (action.activeColor ?? activeColor ?? AppColors.primary).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: foregroundColor,
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: labelTextStyle ?? AppTypography.buttonText.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Version simplifiée pour les actions rapides d'établissement
class EstablishmentActionCard extends StatelessWidget {
  final VoidCallback? onIntegration;
  final VoidCallback? onRating;
  final VoidCallback? onSponsorship;
  final VoidCallback? onRecommend;
  final VoidCallback? onShare;
  final String? activeAction;

  const EstablishmentActionCard({
    super.key,
    this.onIntegration,
    this.onRating,
    this.onSponsorship,
    this.onRecommend,
    this.onShare,
    this.activeAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      ActionItem(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Intégration',
        onTap: onIntegration ?? () {},
        isActive: activeAction == 'integration',
        activeColor: AppColors.primary,
      ),
      ActionItem(
        icon: Icons.star_rate_rounded,
        label: 'Noter',
        onTap: onRating ?? () {},
        isActive: activeAction == 'rating',
        activeColor: AppColors.primary,
      ),
      ActionItem(
        icon: Icons.card_giftcard_rounded,
        label: 'Parrainer',
        onTap: onSponsorship ?? () {},
        isActive: activeAction == 'sponsorship',
        activeColor: AppColors.primary,
      ),
      ActionItem(
        icon: Icons.recommend_rounded,
        label: 'Recommander',
        onTap: onRecommend ?? () {},
        isActive: activeAction == 'recommend',
        activeColor: AppColors.primary,
      ),
      ActionItem(
        icon: Icons.share_rounded,
        label: 'Partager',
        onTap: onShare ?? () {},
        isActive: activeAction == 'share',
        activeColor: AppColors.primary,
      ),
    ];

    return HorizontalActionCard(
      actions: actions,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
