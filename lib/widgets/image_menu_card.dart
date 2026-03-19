import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';

class ImageMenuCard extends StatelessWidget {
  final int index;
  final String cardKey;
  final String title;
  final String? imagePath;
  final IconData? iconData;
  final bool isDark;
  final IconData? icon;
  final Color? color;
  final String? location;
  final Color? backgroundColor;
  final Color? textColor;
  final String? actionText;
  final Color? actionTextColor;
  final String? subtitle;
  final VoidCallback onTap;

  const ImageMenuCard({
    super.key,
    required this.index,
    required this.cardKey,
    required this.title,
    this.imagePath,
    this.iconData,
    required this.isDark,
    this.icon,
    this.color,
    this.location,
    this.backgroundColor,
    this.textColor,
    this.actionText,
    this.actionTextColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(20 * (1 - v), 0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          height: 120, // Hauteur fixe pour éviter l'overflow
          margin: EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with overlay tag
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color:
                                color?.withOpacity(0.1) ??
                                AppColors.screenCard.withOpacity(0.1),
                            // Afficher l'image si disponible, sinon l'icône
                            child: _buildImageOrIcon(context),
                          ),
                          // Gradient overlay for better text visibility
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSectionTag(cardKey),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: textSizeService.getScaledFontSize(13),
                          fontWeight: FontWeight.w700,
                          color:
                              textColor ??
                              (isDark
                                  ? Colors.white
                                  : AppColors.screenTextPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (textColor ??
                                        (isDark
                                            ? Colors.white
                                            : AppColors.screenTextPrimary))
                                    .withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: textSizeService.getScaledFontSize(8),
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (actionText != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          actionText!,
                          style: TextStyle(
                            fontSize: textSizeService.getScaledFontSize(9),
                            fontWeight: FontWeight.w600,
                            color:
                                actionTextColor ??
                                color ??
                                AppColors.screenOrange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        if (location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color:
                                    textColor?.withOpacity(0.7) ??
                                    (isDark
                                        ? Colors.white70
                                        : AppColors.screenTextSecondary),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location!,
                                  style: TextStyle(
                                    fontSize: textSizeService.getScaledFontSize(
                                      10,
                                    ),
                                    color:
                                        textColor?.withOpacity(0.7) ??
                                        (isDark
                                            ? Colors.white70
                                            : AppColors.screenTextSecondary),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    );
  }

  // Méthode pour gérer l'affichage de l'image ou de l'icône
  Widget _buildImageOrIcon(BuildContext context) {
    // Priorité à l'image si elle est spécifiée et valide
    if (imagePath != null && imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Si l'image ne se charge pas, afficher l'icône de secours
          return Icon(
            icon ?? Icons.image,
            color: color ?? AppColors.screenOrange,
            size: 40,
          );
        },
      );
    }

    // Sinon, afficher l'icône si disponible
    if (iconData != null) {
      return Icon(iconData, color: color ?? AppColors.screenOrange, size: 40);
    }

    // Icône par défaut si aucun des deux n'est spécifié
    return Icon(
      icon ?? Icons.image,
      color: color ?? AppColors.screenOrange,
      size: 40,
    );
  }

  static String _getSectionTag(String key) {
    switch (key) {
      case 'informations':
        return 'École';
      case 'niveaux':
        return 'Primaire';
      case 'communication':
        return 'Info';
      case 'school_events':
        return 'Events';
      case 'consult_requests':
        return 'Demandes';
      case 'scolarite':
        return 'Frais';
      case 'voir_les_avis':
        return 'Avis';
      default:
        return 'Plus';
    }
  }
}
