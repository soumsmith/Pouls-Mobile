import 'package:flutter/material.dart';

/// Bouton de réessai subtil et réutilisable avec couleur personnalisable
/// 
/// Usage :
/// ```dart
/// SubtleRetryButton(
///   onTap: () => _retryAction(),
///   color: AppColors.screenOrange, // Optionnel
///   size: 40, // Optionnel
/// )
/// ```
class SubtleRetryButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final double size;
  final double iconSize;
  final bool showShadow;

  const SubtleRetryButton({
    super.key,
    required this.onTap,
    this.color = const Color(0xFFFF7A3C),
    this.size = 40,
    this.iconSize = 18,
    this.showShadow = true,
  });

  /// Couleur de fond claire basée sur la couleur principale
  Color get _backgroundColor {
    return color.withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.refresh_outlined,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}

/// Variante du bouton de réessai avec un fond plein
class SubtleRetryButtonFilled extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final double size;
  final double iconSize;
  final bool showShadow;

  const SubtleRetryButtonFilled({
    super.key,
    required this.onTap,
    this.color = const Color(0xFFFF7A3C),
    this.size = 40,
    this.iconSize = 18,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.refresh_outlined,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Bouton de réessai textuel subtil
class SubtleRetryButtonWithText extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String text;
  final IconData icon;
  final bool showIcon;

  const SubtleRetryButtonWithText({
    super.key,
    required this.onTap,
    this.color = const Color(0xFFFF7A3C),
    this.text = 'Réessayer',
    this.icon = Icons.refresh_outlined,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
