import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';
import 'image_menu_card_external_title.dart';

// Modèle pour définir une action d'établissement
class EstablishmentAction {
  final String key;
  final String title;
  final String subtitle;
  final String? overtitle;
  final String? imagePath;
  final IconData? iconData;
  final Color color;
  final String actionText;
  final VoidCallback onTap;

  const EstablishmentAction({
    required this.key,
    required this.title,
    required this.subtitle,
    this.overtitle,
    this.imagePath,
    this.iconData,
    required this.color,
    required this.actionText,
    required this.onTap,
  });
}

// Widget pour construire une section de cartes d'actions
class EstablishmentActionSection extends StatelessWidget {
  final String? sectionTitle;
  final List<EstablishmentAction> actions;
  final bool isDark;
  final bool useExternalTitle;
  final double? cardHeight;
  final double? cardWidth;

  const EstablishmentActionSection({
    super.key,
    this.sectionTitle,
    required this.actions,
    required this.isDark,
    this.useExternalTitle = false,
    this.cardHeight,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight != null ? cardHeight! + 20 : 130, // Padding for shadows/text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.getPaymentBannerCardSpacing(context) * 0.9,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(context, action, index);
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, EstablishmentAction action, int index) {
    final effectiveWidth = cardWidth ?? 80;
    
    if (useExternalTitle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageMenuCardExternalTitle(
            index: index,
            cardKey: action.key,
            title: action.title,
            imagePath: action.imagePath,
            iconData: action.iconData,
            isDark: isDark,
            color: action.color,
            titleFontSize: AppDimensions.getScaledSize(context, 11.0),
            imageBorderRadius: effectiveWidth / 2,
            width: effectiveWidth,
            height: null,
            titleMaxLines: 2,
            backgroundColor: isDark
                ? action.color.withOpacity(0.15)
                : action.color.withOpacity(0.1),
            textColor: isDark ? Colors.white : Colors.black,
            allowLineBreak: true,
            centerTitle: true,
            onTap: action.onTap,
          ),
          SizedBox(width: AppDimensions.getPaymentBannerCardSpacing(context)),
        ],
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(right: AppDimensions.getPaymentBannerCardSpacing(context)),
        child: ImageMenuCardExternalTitle(
          index: index,
          cardKey: action.key,
          title: action.title,
          subtitle: action.subtitle,
          imagePath: action.imagePath,
          iconData: action.iconData,
          isDark: isDark,
          color: action.color,
          titleFontSize: AppDimensions.getScaledSize(context, 11.0),
          imageBorderRadius: effectiveWidth / 2,
          width: effectiveWidth,
          height: null,
          externalTitleSpacing: 10.0,
          titleMaxLines: 2,
          backgroundColor: action.color.withOpacity(0.1),
          allowLineBreak: true,
          centerTitle: true,
          onTap: action.onTap,
        ),
      );
    }
  }
}

// Widget pour les cartes de communauté (layout différent - style Notes & Bulletins)
class EstablishmentCommunitySection extends StatelessWidget {
  final List<EstablishmentAction> actions;
  final bool isDark;

  const EstablishmentCommunitySection({
    super.key,
    required this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final cardWidth = actions.length == 1
            ? (screenWidth > 600 ? 340.0 : screenWidth - 32.0)
            : (screenWidth > 600 ? 340.0 : screenWidth * 0.75);
        final cardHeight = cardWidth * 0.55; 
        final containerHeight = cardHeight + 75.0;

        return SizedBox(
          height: containerHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final action = actions[index];
              return ImageMenuCardExternalTitle(
                index: index,
                cardKey: action.key,
                overtitle: action.overtitle ?? 'COMMUNAUTÉ',
                title: action.title,
                subtitle: action.subtitle,
                imagePath: action.imagePath,
                iconData: action.iconData,
                width: cardWidth,
                height: null,
                imageHeight: cardHeight,
                imageBorderRadius: 16.0,
                enableInnerBorder: true,
                enableOuterBorder: true,
                innerBorderWidth: 0.5,
                outerBorderWidth: 0.5,
                innerBorderColor: action.color.withOpacity(0.3),
                color: action.color,
                actionText: action.actionText,
                onTap: action.onTap,
              );
            },
          ),
        );
      },
    );
  }
}

// Widget réutilisable pour les cartes de communauté (design original conservé)
class SchoolLifeItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? iconData;
  final String? imagePath;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;
  final String buttonText;

  const SchoolLifeItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconData,
    this.imagePath,
    required this.isDark,
    required this.color,
    required this.onTap,
    this.buttonText = 'Obtenir',
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double imageSize = isTablet ? 64.0 : 75.0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          child: Row(
            children: [
              // Icon or Image
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildImageOrIcon(imageSize),
              ),
              const SizedBox(width: 12),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(12),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Button (now decorative)
              SizedBox(
                width: 90,
                child: TextButton(
                  onPressed: null, // Disable button click
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    textStyle: TextStyle(
                      fontSize: textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: color.withOpacity(0.3), width: 1),
                    ),
                    minimumSize: const Size(90, 32),
                  ),
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour gérer l'affichage de l'image ou de l'icône
  Widget _buildImageOrIcon(double size) {
    // Priorité à l'image si elle est spécifiée
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imagePath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si l'image ne se charge pas, afficher l'icône de secours
            return Icon(
              iconData ?? Icons.image,
              color: color,
              size: size / 2,
            );
          },
        ),
      );
    }

    // Sinon, afficher l'icône si disponible
    if (iconData != null) {
      return Icon(
        iconData,
        color: color,
        size: size / 2,
      );
    }

    // Icône par défaut si aucun des deux n'est spécifié
    return Icon(
      Icons.image,
      color: color,
      size: size / 2,
    );
  }
}
