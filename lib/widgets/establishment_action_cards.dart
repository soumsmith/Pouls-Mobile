import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import 'image_menu_card_external_title.dart';

// Modèle pour définir une action d'établissement
class EstablishmentAction {
  final String key;
  final String title;
  final String subtitle;
  final String? imagePath;
  final IconData? iconData;
  final Color color;
  final String actionText;
  final VoidCallback onTap;

  const EstablishmentAction({
    required this.key,
    required this.title,
    required this.subtitle,
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
      height: cardHeight ?? 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 24),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(action, index);
        },
      ),
    );
  }

  Widget _buildActionCard(EstablishmentAction action, int index) {
    if (useExternalTitle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageMenuCardExternalTitle(
            index: index,
            cardKey: action.key,
            title: action.title,
            //subtitle: action.subtitle,
            imagePath: action.imagePath,
            iconData: action.iconData,
            isDark: isDark,
            color: action.color,
            titleFontSize: 12,
            imageBorderRadius: 14,
            width: cardWidth ?? 80,
            height: cardHeight ?? 100,
            //actionText: action.actionText,
            backgroundColor: isDark
                ? action.color.withOpacity(0.15)
                : action.color.withOpacity(0.1),
            textColor: isDark ? action.color.withOpacity(0.75) : action.color,
            onTap: action.onTap,
          ),
          const SizedBox(width: 10),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ImageMenuCardExternalTitle(
          index: index,
          cardKey: action.key,
          title: action.title,
          subtitle: action.subtitle,
          imagePath: action.imagePath,
          iconData: action.iconData,
          isDark: isDark,
          color: action.color,
          titleFontSize: 12,
          imageBorderRadius: 15,
          width: cardWidth ?? 80,
          height: cardHeight ?? 100,
          externalTitleSpacing: 10.0,
          //actionText: action.actionText,
          backgroundColor: action.color.withOpacity(0.1),
          onTap: action.onTap,
        ),
      );
    }
  }
}

// Widget pour les cartes de communauté (layout différent)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth > 600 ? 2 : 1;

          Widget buildCard(EstablishmentAction action, int index) {
            return SchoolLifeItemCard(
              title: action.title,
              subtitle: action.subtitle,
              imagePath: action.imagePath,
              iconData: action.iconData,
              isDark: isDark,
              color: action.color,
              buttonText: action.actionText,
              onTap: action.onTap,
            );
          }

          // Mobile : Column pour éviter l'espace inutile du GridView
          if (crossAxisCount == 1) {
            return Column(
              children: actions
                  .asMap()
                  .entries
                  .map((entry) => buildCard(entry.value, entry.key))
                  .toList(),
            );
          }

          // Tablette/Desktop : GridView 2 colonnes
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 50,
              mainAxisSpacing: 0,
              childAspectRatio: 6,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) => buildCard(actions[index], index),
          );
        },
      ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildImageOrIcon(),
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
  Widget _buildImageOrIcon() {
    // Priorité à l'image si elle est spécifiée
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imagePath!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si l'image ne se charge pas, afficher l'icône de secours
            return Icon(
              iconData ?? Icons.image,
              color: color,
              size: 20,
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
        size: 20,
      );
    }

    // Icône par défaut si aucun des deux n'est spécifié
    return Icon(
      Icons.image,
      color: color,
      size: 20,
    );
  }
}
