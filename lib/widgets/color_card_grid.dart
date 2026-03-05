import 'package:flutter/material.dart';
import '../config/app_typography.dart';

/// Modèle pour une carte colorée carrée
class ColorCardItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? subtitleColor;
  final double? iconSize;
  final TextStyle? labelStyle;

  const ColorCardItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    required this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.subtitleColor,
    this.iconSize,
    this.labelStyle,
  });
}

/// Widget de cartes carrées colorées qui défilent horizontalement
class ColorCardGrid extends StatelessWidget {
  final List<ColorCardItem> cards;
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;
  final double cardWidth;
  final double cardHeight;

  const ColorCardGrid({
    super.key,
    required this.cards,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 16,
    this.cardWidth = 120,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight + 32, // hauteur fixe pour le conteneur
      padding: padding,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          return _buildColorCard(context, cards[index]);
        },
      ),
    );
  }

  Widget _buildColorCard(BuildContext context, ColorCardItem card) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: card.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: card.backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône principale
              Icon(
                card.icon,
                size: card.iconSize ?? 32,
                color: card.iconColor ?? Colors.white,
              ),
              const SizedBox(height: 8),
              // Texte du label
              Text(
                card.label,
                style: card.labelStyle ?? AppTypography.cardTitle.copyWith(
                  color: card.textColor ?? Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Sous-titre optionnel
              if (card.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  card.subtitle!,
                  style: TextStyle(
                    color: card.subtitleColor ?? Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Version spécifique pour les actions d'établissement avec couleurs prédéfinies
class EstablishmentActionGrid extends StatelessWidget {
  final VoidCallback? onIntegration;
  final VoidCallback? onRating;
  final VoidCallback? onSponsorship;
  final VoidCallback? onRecommend;
  final VoidCallback? onShare;

  const EstablishmentActionGrid({
    super.key,
    this.onIntegration,
    this.onRating,
    this.onSponsorship,
    this.onRecommend,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ColorCardItem(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Intégration',
        subtitle: 'Rejoindre',
        onTap: onIntegration ?? () {},
        backgroundColor: const Color(0xFF3B82F6), // Bleu
        textColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.8),
      ),
      ColorCardItem(
        icon: Icons.star_rate_rounded,
        label: 'Noter',
        subtitle: 'Évaluer',
        onTap: onRating ?? () {},
        backgroundColor: const Color(0xFF10B981), // Vert
        textColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.8),
      ),
      ColorCardItem(
        icon: Icons.card_giftcard_rounded,
        label: 'Parrainer',
        subtitle: 'Inviter',
        onTap: onSponsorship ?? () {},
        backgroundColor: const Color(0xFFF59E0B), // Orange
        textColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.8),
      ),
      ColorCardItem(
        icon: Icons.recommend_rounded,
        label: 'Recommander',
        subtitle: 'Suggérer',
        onTap: onRecommend ?? () {},
        backgroundColor: const Color(0xFF8B5CF6), // Violet
        textColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.8),
      ),
      ColorCardItem(
        icon: Icons.share_rounded,
        label: 'Partager',
        subtitle: 'Diffuser',
        onTap: onShare ?? () {},
        backgroundColor: const Color(0xFFEC4899), // Rose
        textColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.8),
      ),
    ];

    return ColorCardGrid(
      cards: cards,
      cardWidth: 110,
      cardHeight: 110,
      spacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
