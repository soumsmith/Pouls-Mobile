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

// --- VOS FICHIERS DE CONFIGURATION ---
// import 'package:parents_responsable/config/app_dimensions.dart';
// import 'package:parents_responsable/config/app_colors.dart';
// import 'package:parents_responsable/widgets/main_screen_wrapper.dart';
// import 'package:parents_responsable/services/text_size_service.dart';

/// 🎯 CustomSliverAppBar : Une barre supérieure magique pour vos listes (CustomScrollView)
class CustomSliverAppBar extends StatelessWidget {
  // Le texte affiché en haut
  final String title;
  // (Obsolète) Permettait de changer la couleur selon le mode sombre
  final bool isDark;
  // Les boutons à droite (ex: Partager, Favoris)
  final List<Widget>? actions;
  // Que faire quand on clique sur le bouton retour ? (Par défaut: on revient en arrière)
  final VoidCallback? onBackTap;
  // Le bouton tout à gauche (si on veut remplacer le bouton retour par défaut)
  final Widget? leading;
  // Doit-on afficher le bouton retour automatiquement ?
  final bool automaticallyImplyLeading;
  // Couleur de fond de la barre
  final Color? backgroundColor;
  // Couleur de l'effet de surface (Material 3)
  final Color? surfaceTintColor;
  // Hauteur de la barre quand elle est totalement dépliée
  final double? expandedHeight;
  // La barre réapparaît-elle dès qu'on commence à remonter le scroll ?
  final bool floating;
  // La barre reste-t-elle collée en haut quand on descend tout en bas ?
  final bool pinned;
  // L'ombre sous la barre
  final double? elevation;
  // Le style du texte du titre
  final TextStyle? titleTextStyle;
  // Un widget qui s'affiche derrière le titre quand la barre s'étire (ex: une grande image)
  final Widget? flexibleSpace;
  // La barre peut-elle s'étirer comme un élastique si on tire fort vers le bas ?
  final bool stretch;
  // Détermine si elle se comporte comme une SliverAppBar (true) ou une AppBar normale (false)
  final bool isSliver;

  // 🛠️ Le Constructeur : C'est ici qu'on définit toutes les options
  const CustomSliverAppBar({
    super.key,
    required this.title, // Le titre est obligatoire !
    this.isDark = false,
    this.actions,
    this.onBackTap,
    this.leading,
    this.automaticallyImplyLeading = true, // Par défaut, on met un bouton retour
    this.backgroundColor,
    this.surfaceTintColor,
    this.expandedHeight = 0, // Taille normale par défaut
    this.floating = false, // Par défaut, il faut remonter tout en haut pour la revoir
    this.pinned = true, // Par défaut, elle reste toujours visible (accrochée en haut)
    this.elevation = 0, // Pas d'ombre
    this.titleTextStyle,
    this.flexibleSpace,
    this.stretch = false,
    this.isSliver = true, // Par défaut, c'est bien une SliverAppBar
  });

  @override
  Widget build(BuildContext context) {
    // Service pour gérer la taille du texte dynamiquement selon les réglages du téléphone
    final textSizeService = TextSizeService();

    // On prépare le titre (s'il n'est pas vide)
    final titleWidget = title.isEmpty ? null : Text(
      title,
      style: titleTextStyle ??
          TextStyle(
            fontSize: textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.screenTextPrimaryThemed(context),
            letterSpacing: -0.5,
          ),
    );

    // On prépare le bouton de gauche et les couleurs
    final resolvedLeading = leading ?? (automaticallyImplyLeading ? _buildDefaultLeading(context) : null);
    final resolvedBgColor = backgroundColor ?? AppColors.screenSurfaceThemed(context);
    final resolvedSurfaceColor = surfaceTintColor ?? Colors.transparent;

    // MAGIE ICI : Si isSliver est faux, on renvoie une simple AppBar !
    if (!isSliver) {
      return AppBar(
        elevation: elevation ?? 0,
        surfaceTintColor: resolvedSurfaceColor,
        backgroundColor: resolvedBgColor,
        leading: resolvedLeading,
        title: titleWidget,
        actions: actions,
        flexibleSpace: flexibleSpace,
        centerTitle: false,
      );
    }

    // Sinon, on retourne le SliverAppBar natif de Flutter, dopé avec nos options !
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
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }

  // 🔙 Construit notre joli bouton retour encadré
  Widget _buildDefaultLeading(BuildContext context) {
    return GestureDetector(
      // Si on a cliqué, on exécute "onBackTap" (si fourni), sinon notre fonction par défaut
      onTap: onBackTap ?? () => _handleBackNavigation(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(AppDimensions.getSmallCardBorderRadius(context)),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: AppColors.screenTextPrimaryThemed(context),
        ),
      ),
    );
  }

  // 🧭 Navigation Intelligente
  void _handleBackNavigation(BuildContext context) {
    // Si on est dans un menu à onglets (MainScreenWrapper), on simule un retour pour l'onglet interne
    if (MainScreenWrapper.maybeOf(context) != null) {
      MainScreenWrapper.of(context).goBackToPreviousTab();
    } else {
      // Sinon on fait un vrai retour en arrière classique (on ferme l'écran)
      Navigator.of(context).pop();
    }
  }
}

// ---------------------------------------------------------
// 🟩 PETITS COMPOSANTS ANNEXES (Les boutons de la barre)
// ---------------------------------------------------------

/// 🔘 AppBarIconButton : Un bouton carré avec des coins arrondis pour mettre dans la barre
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark; 
  final VoidCallback onTap; // L'action au clic

  const AppBarIconButton({
    required this.icon,
    this.isDark = false,
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
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(AppDimensions.getSmallCardBorderRadius(context)),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.screenTextPrimaryThemed(context),
        ),
      ),
    );
  }
}

/// 💡 AppBarAction : Une petite classe outil pour construire le bouton "AppBarIconButton" avec une bulle d'aide (Tooltip)
class AppBarAction {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  AppBarAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  // Transforme la configuration en véritable Widget cliquable
  Widget buildWidget(bool isDark) {
    Widget button = AppBarIconButton(
      icon: icon,
      isDark: isDark,
      onTap: onTap,
    );

    // Si on a mis un texte d'aide (tooltip), on entoure le bouton avec ça.
    // Ainsi, en restant appuyé sur le bouton, le texte s'affiche !
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
```

---

## Étape 2 : Comment utiliser ce composant ? (Exemple Facile)

⚠️ **ATTENTION :** Une `SliverAppBar` est spéciale. Contrairement à une `AppBar` normale qui se met dans le paramètre `appBar:` d'un `Scaffold`, une SliverAppBar doit **toujours** être placée à l'intérieur d'un **`CustomScrollView`** (dans la liste `slivers:`). 

Voici un exemple simple pour l'intégrer dans un nouvel écran :

📝 **Exemple d'écran complet :**

```dart
import 'package:flutter/material.dart';
import '../widgets/custom_sliver_app_bar.dart'; // N'oubliez pas l'import !

class MonEcranExemple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // On utilise un CustomScrollView pour que la barre puisse réagir quand on fait glisser la page
      body: CustomScrollView(
        slivers: [
          
          // 1. NOTRE BARRE MAGIQUE !
          CustomSliverAppBar(
            title: "Mon Beau Titre", // Le seul paramètre obligatoire !
            pinned: true,            // TRUE = La barre reste collée en haut même si on descend
            floating: true,          // TRUE = Elle réapparait dès qu'on remonte le doigt
            actions: [
              // On peut ajouter nos jolis boutons personnalisés à droite
              AppBarIconButton(
                icon: Icons.search,
                onTap: () {
                  print("Recherche cliquée !");
                },
              ),
            ],
          ),

          // 2. LE CONTENU DE LA PAGE
          // Tout le reste de votre écran doit être enveloppé dans des widgets qui commencent par "Sliver..."
          SliverFillRemaining(
            child: Center(
              child: Text("Ici c'est le contenu de la page !"),
            ),
          ),

        ],
      ),
    );
  }
}
```

**Bravo 🎉 ! Vous maîtrisez maintenant l'utilisation du composant le plus stylé de votre projet !**
