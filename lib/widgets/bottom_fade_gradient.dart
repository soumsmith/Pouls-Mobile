import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Un widget réutilisable qui affiche un dégradé de fondu en bas de l'écran
/// pour créer un effet de transition douce avec le fond de page
class BottomFadeGradient extends StatelessWidget {
  /// Hauteur du dégradé (par défaut: 60)
  final double height;
  
  /// Couleur de début du dégradé (par défaut: transparent)
  final Color startColor;
  
  /// Couleur de fin du dégradé (par défaut: couleur de surface de l'écran)
  final Color? endColor;

  const BottomFadeGradient({
    super.key,
    this.height = 60,
    this.startColor = const Color(0x00F8F8F8),
    this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    final finalEndColor = endColor ?? AppColors.screenSurface;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                startColor,
                finalEndColor,
                finalEndColor,
                finalEndColor,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
