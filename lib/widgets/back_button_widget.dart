import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Widget réutilisable pour les boutons de retour standardisés
class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({
    super.key,
    this.onPressed,
    this.color,
    this.useContainer = true,
  });

  final VoidCallback? onPressed;
  final Color? color;
  final bool useContainer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = color ?? AppColors.getTextColor(isDark);
    
    if (useContainer) {
      return IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          // decoration: BoxDecoration(
          //   color: AppColors.getSurfaceColor(isDark),
          //   borderRadius: BorderRadius.circular(10),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
          //       blurRadius: 4,
          //       offset: const Offset(0, 2),
          //     ),
          //   ],
          // ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: buttonColor,
            size: 20,
          ),
        ),
      );
    } else {
      return IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: buttonColor,
          size: 24,
        ),
      );
    }
  }
}
