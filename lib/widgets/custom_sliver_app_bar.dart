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
  final Widget? flexibleSpace;
  final bool stretch;
  final bool isSliver; // Permet de choisir entre SliverAppBar et AppBar normal
  final Color textColor;
  final Color? actionButtonBackgroundColor;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.isDark = false, // Gardé pour compatibilité mais ne sera plus utilisé
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
    this.flexibleSpace,
    this.stretch = false,
    this.isSliver = true, // Par défaut, se comporte comme un SliverAppBar
    this.textColor = Colors.black,
    this.actionButtonBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    final titleWidget = title.isEmpty
        ? null
        : Text(
            title,
            style:
                titleTextStyle ??
                TextStyle(
                  fontSize: textSizeService.getScaledFontSize(18),
                  fontWeight: FontWeight.w700,
                  color: backgroundColor != null
                      ? textColor
                      : AppColors.screenTextPrimaryThemed(context),
                  letterSpacing: -0.5,
                ),
          );

    final resolvedLeading =
        leading ??
        (automaticallyImplyLeading ? _buildDefaultLeading(context) : null);
    final resolvedBgColor =
        backgroundColor ?? AppColors.screenSurfaceThemed(context);
    final resolvedSurfaceColor = surfaceTintColor ?? Colors.transparent;

    final List<Widget>? resolvedActions = actions != null && actions!.isNotEmpty
        ? [
            ...actions!,
            const SizedBox(
              width: 8,
            ), // Évite que les boutons collent trop au bord droit de l'écran
          ]
        : actions;

    if (!isSliver) {
      return AppBar(
        elevation: elevation ?? 0,
        surfaceTintColor: resolvedSurfaceColor,
        backgroundColor: resolvedBgColor,
        leading: resolvedLeading,
        title: titleWidget,
        actions: resolvedActions,
        flexibleSpace: flexibleSpace,
        centerTitle: false,
      );
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      stretch: stretch,
      elevation: elevation ?? 0,
      surfaceTintColor: resolvedSurfaceColor,
      backgroundColor: resolvedBgColor,
      leading: resolvedLeading,
      title: titleWidget,
      actions: resolvedActions,
      flexibleSpace: flexibleSpace,
    );
  }

  /// Bouton de retour par défaut
  Widget _buildDefaultLeading(BuildContext context) {
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkStyle = isDark || themeIsDark;
    final hasCustomBg = backgroundColor != null;

    return GestureDetector(
      onTap: onBackTap ?? () => _handleBackNavigation(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: actionButtonBackgroundColor != null
              ? actionButtonBackgroundColor!.withOpacity(0.25)
              : (hasCustomBg
                    ? textColor.withOpacity(0.15)
                    : (useDarkStyle
                          ? const Color(0xFF262626)
                          : AppColors.screenCardThemed(context))),
          borderRadius: BorderRadius.circular(
            AppDimensions.getButtonBorderRadius(context),
          ),
          boxShadow:
              (useDarkStyle ||
                  hasCustomBg ||
                  actionButtonBackgroundColor != null)
              ? null
              : AppDimensions.getSettingsCardShadow(context),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: hasCustomBg
              ? textColor
              : (useDarkStyle
                    ? Colors.white
                    : AppColors.screenTextPrimaryThemed(context)),
        ),
      ),
    );
  }

  /// Actions par défaut (favoris et partage)
  List<Widget> _buildDefaultActions() {
    return [
      AppBarIconButton(
        icon: Icons.favorite_border,
        isDark: isDark,
        onTap: () {},
      ),
      AppBarIconButton(icon: Icons.share, isDark: isDark, onTap: () {}),
      const SizedBox(width: 4),
    ];
  }

  /// Gestion de la navigation de retour
  void _handleBackNavigation(BuildContext context) {
    if (MainScreenWrapper.maybeOf(context) != null) {
      MainScreenWrapper.of(context).goBackToPreviousTab();
    } else {
      Navigator.of(context).pop();
    }
  }
}

/// Widget pour les boutons d'action dans l'AppBar
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark; // Gardé pour compatibilité mais ne sera plus utilisé
  final VoidCallback onTap;
  final Color? iconColor;
  final bool hasCustomBg;
  final Color? backgroundColor;

  const AppBarIconButton({
    super.key,
    required this.icon,
    this.isDark = false, // Gardé pour compatibilité mais ne sera plus utilisé
    required this.onTap,
    this.iconColor,
    this.hasCustomBg = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeIsDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkStyle = isDark || themeIsDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor != null
              ? backgroundColor!.withOpacity(0.15)
              : (hasCustomBg
                    ? (iconColor ?? Colors.black).withOpacity(0.15)
                    : (useDarkStyle
                          ? const Color(0xFF262626)
                          : AppColors.screenCardThemed(context))),
          borderRadius: BorderRadius.circular(
            AppDimensions.getButtonBorderRadius(context),
          ),
          boxShadow: (useDarkStyle || hasCustomBg || backgroundColor != null)
              ? null
              : AppDimensions.getSettingsCardShadow(context),
        ),
        child: Icon(
          icon,
          size: 18,
          color:
              iconColor ??
              (useDarkStyle
                  ? Colors.white
                  : AppColors.screenTextPrimaryThemed(context)),
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

  AppBarAction({required this.icon, required this.onTap, this.tooltip});

  Widget buildWidget(bool isDark) {
    Widget button = AppBarIconButton(icon: icon, isDark: isDark, onTap: onTap);

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
