import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_dimensions.dart';
import 'package:parents_responsable/config/app_colors.dart';
import 'package:parents_responsable/widgets/main_screen_wrapper.dart';
import 'package:parents_responsable/services/text_size_service.dart';

/// Widget SliverAppBar réutilisable avec personnalisation des actions
class CustomSliverAppBar extends StatelessWidget {
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

  const CustomSliverAppBar({
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
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      elevation: elevation ?? 0,
      surfaceTintColor: surfaceTintColor ?? Colors.transparent,
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1A1A1A) : AppColors.screenSurface),
      leading: leading ?? (automaticallyImplyLeading ? _buildDefaultLeading(context) : null),
      title: Text(
        title,
        style: titleTextStyle ??
            TextStyle(
              fontSize: textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.screenTextPrimary,
              letterSpacing: -0.5,
            ),
      ),
      actions: actions ?? _buildDefaultActions(),
    );
  }

  /// Bouton de retour par défaut
  Widget _buildDefaultLeading(BuildContext context) {
    return GestureDetector(
      onTap: onBackTap ?? () => _handleBackNavigation(context),
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

  /// Actions par défaut (favoris et partage)
  List<Widget> _buildDefaultActions() {
    return [
      _AppBarIconButton(
        icon: Icons.favorite_border,
        isDark: isDark,
        onTap: () {},
      ),
      _AppBarIconButton(
        icon: Icons.share,
        isDark: isDark,
        onTap: () {},
      ),
      const SizedBox(width: 4),
    ];
  }

  /// Gestion de la navigation de retour
  void _handleBackNavigation(BuildContext context) {
    if (MainScreenWrapper.maybeOf(context) != null) {
      MainScreenWrapper.of(context).navigateToHome();
    } else {
      Navigator.of(context).pop();
    }
  }
}

/// Widget pour les boutons d'action dans l'AppBar
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }
}

/// Classe d'aide pour créer des actions personnalisées
class AppBarAction {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  AppBarAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  Widget buildWidget(bool isDark) {
    Widget button = _AppBarIconButton(
      icon: icon,
      isDark: isDark,
      onTap: onTap,
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
