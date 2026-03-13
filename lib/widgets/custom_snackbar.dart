import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String? actionText,
  }) {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Configuration des couleurs et icônes selon le type
      Color backgroundColor;
      Color textColor = Colors.white;
      IconData icon;
      
      switch (type) {
        case SnackBarType.success:
          backgroundColor = const Color(0xFF10B981); // Vert
          icon = Icons.check_circle_rounded;
          break;
        case SnackBarType.error:
          backgroundColor = const Color(0xFFEF4444); // Rouge
          icon = Icons.error_rounded;
          break;
        case SnackBarType.warning:
          backgroundColor = const Color(0xFFF59E0B); // Orange
          icon = Icons.warning_rounded;
          textColor = Colors.white;
          break;
        case SnackBarType.info:
          backgroundColor = const Color(0xFF3B82F6); // Bleu
          icon = Icons.info_rounded;
          break;
      }
      
      // Création du contenu personnalisé
      final content = Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onActionPressed != null && actionText != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                onActionPressed();
              },
              child: Text(
                actionText,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      );
      
      // Affichage de la SnackBar
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: content,
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
          // Animation personnalisée
          animation: CurvedAnimation(
            parent: const AlwaysStoppedAnimation(1.0),
            curve: Curves.elasticOut,
          ),
        ),
      );
    } catch (e) {
      // En cas d'erreur, afficher une SnackBar basique
      debugPrint('Erreur CustomSnackBar: $e');
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e2) {
        debugPrint('Erreur fallback SnackBar: $e2');
      }
    }
  }
  
  // Méthodes rapides pour chaque type
  static void success(BuildContext context, String message, {Duration? duration}) {
    show(context: context, message: message, type: SnackBarType.success, duration: duration ?? const Duration(seconds: 4));
  }
  
  static void error(BuildContext context, String message, {Duration? duration}) {
    show(context: context, message: message, type: SnackBarType.error, duration: duration ?? const Duration(seconds: 4));
  }
  
  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(context: context, message: message, type: SnackBarType.warning, duration: duration ?? const Duration(seconds: 4));
  }
  
  static void info(BuildContext context, String message, {Duration? duration}) {
    show(context: context, message: message, type: SnackBarType.info, duration: duration ?? const Duration(seconds: 4));
  }
  
  // Méthode avec action
  static void withAction({
    required BuildContext context,
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 6),
      onActionPressed: onActionPressed,
      actionText: actionText,
    );
  }
  
  // Masquer la SnackBar actuelle
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
  
  // Masquer toutes les SnackBars
  static void hideAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
