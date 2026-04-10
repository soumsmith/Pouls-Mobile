import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';

/// Widget réutilisable pour les en-têtes de section avec indicateur coloré
class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color? indicatorColor;
  final Color? accentColor; // Nouveau paramètre pour compatibilité
  final double? indicatorWidth;
  final double? indicatorHeight;
  final double? spacing;
  final EdgeInsets? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final double? letterSpacing;
  final bool showLeftIndicator; // Contrôle l'affichage du trait gauche
  final bool showBottomDivider; // Contrôle l'affichage de la ligne horizontale en bas
  final Color? dividerColor; // Couleur de la ligne de séparation
  final double? dividerHeight; // Hauteur de la ligne de séparation

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.isDark,
    this.indicatorColor,
    this.accentColor, // Priorité sur indicatorColor si fourni
    this.indicatorWidth,
    this.indicatorHeight,
    this.spacing,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.letterSpacing,
    this.showLeftIndicator = true, // Par défaut, on affiche le trait gauche
    this.showBottomDivider = false, // Par défaut, on n'affiche pas la ligne de séparation
    this.dividerColor,
    this.dividerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    
    // Utiliser accentColor en priorité, sinon indicatorColor, sinon la couleur par défaut
    final Color finalIndicatorColor = accentColor ?? 
                                   indicatorColor ?? 
                                   AppColors.screenOrange;

    return Column(
      children: [
        Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // Trait gauche conditionnel
              if (showLeftIndicator)
                Container(
                  width: indicatorWidth ?? 4,
                  height: indicatorHeight ?? 22,
                  decoration: BoxDecoration(
                    color: finalIndicatorColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              if (showLeftIndicator) SizedBox(width: spacing ?? 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize ?? textSizeService.getScaledFontSize(16),
                    fontWeight: fontWeight ?? FontWeight.w800,
                    color: textColor ?? (isDark ? Colors.white : AppColors.screenTextPrimary),
                    letterSpacing: letterSpacing ?? -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Ligne de séparation horizontale conditionnelle
        if (showBottomDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: dividerHeight ?? 1,
              color: dividerColor ?? (isDark ? Colors.grey[700] : Colors.grey[200]),
            ),
          ),
      ],
    );
  }
}
