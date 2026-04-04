import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';

class ImageMenuCardExternalTitle extends StatelessWidget {
  final int index;
  final String cardKey;
  final String? title; // Titre affiché en dehors de la carte
  final String? subtitle; // Sous-titre affiché en dehors de la carte
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
  final String? tag;
  final double? width;
  final double? height;
  final double? externalTitleSpacing; // Espacement entre la carte et le titre externe
  final int titleMaxLines; // Nombre maximum de lignes pour le titre
  final String? buttonText; // Texte du bouton optionnel
  final Color? buttonColor; // Couleur de fond du bouton
  final Color? buttonTextColor; // Couleur du texte du bouton
  final VoidCallback? onButtonTap; // Action du bouton

  final VoidCallback onTap;

  const ImageMenuCardExternalTitle({
    super.key,
    required this.index,
    required this.cardKey,
    this.title, // Titre affiché en dehors de la carte
    this.subtitle, // Sous-titre affiché en dehors de la carte
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
    this.tag,
    this.width,
    this.height,
    this.externalTitleSpacing = 8.0, // Espacement par défaut
    this.titleMaxLines = 1, // Par défaut, le titre sur une seule ligne
    this.buttonText, // Bouton optionnel
    this.buttonColor,
    this.buttonTextColor,
    this.onButtonTap,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Carte principale (sans le titre à l'intérieur)
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: width ?? 100, //cardWidth,
              height: height ?? 100, // Hauteur par défaut si non spécifiée
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    (isDark ? const Color(0xFF1E1E1E) : AppColors.screenCard),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                  if (tag != null)
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
                          tag!,
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
          ),
          
          // Espacement entre la carte et le titre externe
          if (title?.isNotEmpty == true) 
            SizedBox(height: externalTitleSpacing),
          
          // Titre et sous-titre affichés en dehors de la carte
          if (title?.isNotEmpty == true) ...[
            Container(
              width: width ?? 100, // Même largeur que la carte
              margin: EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre principal
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w700,
                      color:
                          textColor ??
                          (isDark
                              ? Colors.white
                              : AppColors.screenTextPrimary),
                    ),
                    maxLines: titleMaxLines, // Utilise le paramètre configurable
                    overflow: TextOverflow.ellipsis, // Ajoute des points de suspension
                  ),
                  // Sous-titre
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(10),
                        fontWeight: FontWeight.w500,
                        color:
                            textColor?.withOpacity(0.7) ??
                            (isDark
                                ? Colors.white70
                                : AppColors.screenTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Texte d'action ou localisation
                  if (actionText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
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
                        ),
                        if (buttonText != null) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 22,
                            child: ElevatedButton(
                              onPressed: onButtonTap ?? () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor ?? color ?? AppColors.screenOrange,
                                foregroundColor: buttonTextColor ?? Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                buttonText!,
                                style: TextStyle(
                                  fontSize: textSizeService.getScaledFontSize(8),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    if (location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 10,
                                  color:
                                      textColor?.withOpacity(0.5) ??
                                      (isDark
                                          ? Colors.white54
                                          : AppColors.screenTextSecondary),
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    location!,
                                    style: TextStyle(
                                      fontSize: textSizeService
                                          .getScaledFontSize(9),
                                      color:
                                          textColor?.withOpacity(0.5) ??
                                          (isDark
                                              ? Colors.white54
                                              : AppColors.screenTextSecondary),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (buttonText != null) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 22,
                              child: ElevatedButton(
                                onPressed: onButtonTap ?? () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor ?? color ?? AppColors.screenOrange,
                                  foregroundColor: buttonTextColor ?? Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  buttonText!,
                                  style: TextStyle(
                                    fontSize: textSizeService.getScaledFontSize(8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                  
                  // Bouton optionnel seul (si ni actionText ni location)
                  if (buttonText != null && actionText == null && location == null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: onButtonTap ?? () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor ?? color ?? AppColors.screenOrange,
                          foregroundColor: buttonTextColor ?? Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          buttonText!,
                          style: TextStyle(
                            fontSize: textSizeService.getScaledFontSize(10),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Méthode pour gérer l'affichage de l'image ou de l'icône
  Widget _buildImageOrIcon(BuildContext context) {
    // Priorité aux images réseau si elles sont spécifiées
    if (imagePath != null && imagePath!.startsWith('http')) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Si l'image réseau ne se charge pas, afficher l'image par défaut
          return Image.asset(
            'assets/images/img-shcool-not-found.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Si même l'image par défaut ne se charge pas, afficher l'icône de secours
              return Icon(
                icon ?? Icons.image,
                color: color ?? AppColors.screenOrange,
                size: 40,
              );
            },
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          // Afficher un indicateur de chargement
          return Center(
            child: Icon(
              icon ?? Icons.image,
              color: color ?? AppColors.screenOrange.withOpacity(0.5),
              size: 40,
            ),
          );
        },
      );
    }
    
    // Priorité aux images locales si elles sont spécifiées et valides
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

    // Si aucune image n'est spécifiée, utiliser l'image par défaut
    if (imagePath == null) {
      return Image.asset(
        'assets/images/img-shcool-not-found.jpg',
        fit: BoxFit.cover,
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
}
