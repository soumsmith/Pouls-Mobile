import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';

/// Widget de chargement centralisé et réutilisable pour toute l'application
class AppLoader extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const AppLoader({
    Key? key,
    this.message = 'Chargement...',
    this.backgroundColor,
    this.iconColor,
    this.size = 64.0,
    this.isDismissible = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final textSizeService = TextSizeService();
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon de chargement animé
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor ?? AppColors.primary,
                      (iconColor ?? AppColors.primary).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular((size ?? 64) / 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon principal
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: (size ?? 64) * 0.4,
                    ),
                    // Cercles de rotation pour l'animation
                    if (size != null && size! > 48) ...[
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message de chargement
              Text(
                message,
                style: TextStyle(
                  fontSize: textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimaryLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (isDismissible) ...[
                const SizedBox(height: 24),
                Text(
                  'Appuyez pour fermer',
                  style: TextStyle(
                    fontSize: textSizeService.getScaledFontSize(12),
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Variante simplifiée du loader pour les dialogues
class DialogLoader extends StatelessWidget {
  final String message;
  final Color? color;

  const DialogLoader({
    Key? key,
    this.message = 'Chargement...',
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: textSizeService.getScaledFontSize(14),
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loader inline pour les boutons et autres éléments
class InlineLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double? strokeWidth;

  const InlineLoader({
    Key? key,
    this.size = 20.0,
    this.color,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth!,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}
