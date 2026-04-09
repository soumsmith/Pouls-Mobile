import 'package:flutter/material.dart';
import '../config/app_dimensions.dart';
import '../config/app_colors.dart';

/// Widget SliverAppBar réutilisable avec personnalisation des actions
/// Version adaptée pour la structure actuelle du projet
class CustomSliverAppBarFixed extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget>? actions;
  final VoidCallback? onBackTap;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final double? expandedHeight;
  final bool floating;
  final bool pinned;
  final double? elevation;
  final TextStyle? titleTextStyle;
  final bool? centerTitle;

  const CustomSliverAppBarFixed({
    super.key,
    required this.title,
    required this.isDark,
    this.actions,
    this.onBackTap,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.surfaceTintColor,
    this.expandedHeight = 0,
    this.floating = false,
    this.pinned = true,
    this.elevation = 0,
    this.titleTextStyle,
    this.centerTitle, // Permet de personnaliser cas par cas
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      elevation: elevation ?? 0,
      surfaceTintColor: surfaceTintColor ?? Colors.transparent,
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1A1A1A) : AppColors.screenSurface),
      leading: leading ?? (automaticallyImplyLeading ? _buildDefaultLeading(context) : null),
      centerTitle: AppDimensions.shouldCenterAppBarTitle(overrideValue: centerTitle),
      title: Text(
        title,
        style: titleTextStyle ??
            TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.screenTextPrimary,
              letterSpacing: -0.5,
            ),
      ),
      actions: actions,
    );
  }

  /// Bouton de retour par défaut
  Widget _buildDefaultLeading(BuildContext context) {
    return GestureDetector(
      onTap: onBackTap ?? () => Navigator.of(context).pop(),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenCard,
          borderRadius: BorderRadius.circular(AppDimensions.getSmallCardBorderRadius(context)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: isDark ? Colors.white : AppColors.screenTextPrimary,
        ),
      ),
    );
  }
}

/// Widget pour les boutons d'action dans l'AppBar
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String? tooltip;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : AppColors.screenCard,
          borderRadius: BorderRadius.circular(AppDimensions.getSmallCardBorderRadius(context)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : AppColors.screenTextPrimary,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
