---
name: custom-sliver-app-bar
description: Guide pour comprendre et utiliser le composant CustomSliverAppBar, une barre de navigation dynamique et personnalisée pour les listes déroulantes (CustomScrollView).
---

# 🚀 Guide du Composant : CustomSliverAppBar

Ce guide vous explique de manière ultra-simple ce qu'est le composant `CustomSliverAppBar`, comment il fonctionne, et comment l'utiliser dans votre application. Parfait pour les débutants !

## À quoi ça sert ? 🤔
Dans Flutter, une `AppBar` normale reste fixe en haut de l'écran. 
Une **`SliverAppBar`** est une barre "magique" qui peut s'agrandir, rétrécir, ou disparaître quand on fait défiler l'écran (scroll). 

Le composant `CustomSliverAppBar` de votre projet est une version améliorée et réutilisable de cette barre.
Ses super-pouvoirs :
- **Bouton retour intelligent** : Il sait s'il doit fermer un onglet (`MainScreenWrapper`) ou revenir à l'écran précédent.
- **Design unifié** : Ses couleurs et ses ombres s'adaptent automatiquement au thème de votre application (grâce à `AppColors` et `AppDimensions`).
- **Facile à utiliser** : Vous n'avez qu'à lui donner un titre et il s'occupe de tout le design !

---

## Étape 1 : Le Code du Composant (L'Implémentation)

Si vous devez recréer ce composant ou comprendre comment il est fait sous le capot, voici son code exact. J'y ai ajouté des commentaires très simples en français.

📁 **Chemin du fichier :** `lib/widgets/custom_sliver_app_bar.dart`

```dart
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

```

---

## Étape 2 : Comment utiliser ce composant ? (Exemple Facile)

⚠️ **ATTENTION :** Une `SliverAppBar` est spéciale. Contrairement à une `AppBar` normale qui se met dans le paramètre `appBar:` d'un `Scaffold`, une SliverAppBar doit **toujours** être placée à l'intérieur d'un **`CustomScrollView`** (dans la liste `slivers:`).

Voici un exemple simple pour l'intégrer dans un nouvel écran :

```dart
import 'package:flutter/material.dart';
import 'package:parents_responsable/widgets/custom_sliver_app_bar.dart';

class MonEcran extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Mon Super Écran',
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            actionButtonBackgroundColor: Colors.white,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(title: Text('Élément $index')),
              childCount: 20,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Étape 3 : Boutons d'action personnalisés (Exemple Avancé)

Si vous avez besoin d'ajouter des boutons d'actions personnalisés à droite (ex: un bouton de filtre, ou de recherche), vous pouvez passer une liste de widgets dans le paramètre `actions:`.

Voici un exemple tiré de l'écran des établissements (`establishment_screen.dart`), où on crée un bouton personnalisé qui s'accorde parfaitement avec l'AppBar :

```dart
// 1. Créer une fonction pour générer le bouton
Widget _buildHeaderAction(BuildContext context, {
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: AppDimensions.getActionButtonSize(context),
      height: AppDimensions.getActionButtonSize(context),
      decoration: BoxDecoration(
        // Fond semi-transparent pour l'effet "verre" sur fond coloré
        color: AppColors.screenTextPrimaryThemed(context).withOpacity(0.15),
        borderRadius: BorderRadius.circular(
          AppDimensions.getButtonBorderRadius(context),
        ),
        boxShadow: null, // Pas d'ombre si fond transparent
      ),
      child: Icon(
        icon,
        size: 20,
        color: AppColors.screenTextPrimaryThemed(context),
      ),
    ),
  );
}

// 2. L'utiliser dans le composant CustomSliverAppBar
CustomSliverAppBar(
  title: 'Établissements',
  actions: [
    _buildHeaderAction(
      context,
      icon: Icons.search_rounded,
      onTap: () {
        print("Recherche cliquée");
      },
    ),
    const SizedBox(width: 8),
    _buildHeaderAction(
      context,
      icon: Icons.tune,
      onTap: () {
        print("Filtres cliqués");
      },
    ),
    const SizedBox(width: 4), // Marge finale à droite
  ],
)
```

**Bravo 🎉 ! Vous maîtrisez maintenant l'utilisation du composant le plus stylé de votre projet !**
