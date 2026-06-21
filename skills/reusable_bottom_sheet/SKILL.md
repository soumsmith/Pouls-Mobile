---
name: reusable-adaptive-bottom-sheet
description: Guide pour créer et utiliser un BottomSheet réutilisable et adaptatif dans Flutter, avec en-tête personnalisable (icône, titre, sous-titre) et contenu dynamique.
tags: [flutter, ui, bottomsheet, reusable, adaptive, components]
---

# Reusable & Adaptive Bottom Sheet Skill

Ce "skill" vous guide dans la création et l'utilisation d'un **BottomSheet réutilisable et adaptatif**. Il est conçu pour s'adapter à la taille de son contenu, gérer le clavier virtuel, et être hautement personnalisable via des paramètres.

## 1. Création du Widget (Le Composant)

Créez un fichier `lib/widgets/bottom_sheets/reusable_bottom_sheet.dart` et insérez-y le code suivant :

```dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Pour l'effet de verre
import '../components/bottom_spacer.dart';

class ReusableBottomSheet extends StatelessWidget {
  final Widget content;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final double? imageBorderRadius;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onClose;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool useGlassEffect;
  final EdgeInsetsGeometry contentPadding;

  const ReusableBottomSheet({
    super.key,
    required this.content,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.imageBorderRadius,
    this.iconColor,
    this.iconBackgroundColor,
    this.onClose,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
    this.useGlassEffect = false,
    this.contentPadding = const EdgeInsets.all(16),
  });

  /// Méthode statique utilitaire pour afficher facilement le BottomSheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget content,
    required String title,
    String? subtitle,
    IconData? icon,
    String? imagePath,
    double? imageBorderRadius,
    Color? iconColor,
    Color? iconBackgroundColor,
    VoidCallback? onClose,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isDismissible = true,
    bool useGlassEffect = false,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(16),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled:
          true, // Permet au bottom sheet de prendre plus de place et gérer le clavier
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      builder: (context) => Padding(
        // padding bottom pour éviter que le clavier ne cache le contenu
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReusableBottomSheet(
          content: content,
          title: title,
          subtitle: subtitle,
          icon: icon,
          imagePath: imagePath,
          imageBorderRadius: imageBorderRadius,
          iconColor: iconColor,
          iconBackgroundColor: iconBackgroundColor,
          onClose: onClose,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          useGlassEffect: useGlassEffect,
          contentPadding: contentPadding,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation de DraggableScrollableSheet pour rendre le bottom sheet adaptatif
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand:
          false, // Important : permet au sheet de s'adapter au contenu si possible
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? Colors.grey[900]! : Colors.white;

        Widget contentContainer = Container(
          decoration: BoxDecoration(
            color: useGlassEffect ? bgColor.withOpacity(0.85) : bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(context),
              Divider(
                height: 1,
                thickness: 0.7,
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      content, // Le contenu dynamique passé en paramètre
                      const BottomSpacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (useGlassEffect) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: contentContainer,
            ),
          );
        }

        return contentContainer;
      },
    );
  }

  // Petit indicateur visuel en haut pour montrer que c'est glissable
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // L'en-tête dynamique
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightGrayBg = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône ou Image dynamique
          if (imagePath != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lightGrayBg,
                borderRadius: BorderRadius.circular(imageBorderRadius ?? 12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  (imageBorderRadius ?? 12.0) > 4
                      ? (imageBorderRadius ?? 12.0) - 4
                      : 4,
                ),
                child: Image.asset(
                  imagePath!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    iconBackgroundColor ??
                    Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
          const SizedBox(width: 20),
          // Textes (Titre et sous-titre)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Bouton de fermeture
          Container(
            decoration: BoxDecoration(
              color: lightGrayBg,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey[500],
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: () {
                if (onClose != null) {
                  onClose!();
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 2. Comment l'utiliser ?

N'importe où dans votre code, au clic d'un bouton par exemple, appelez simplement `ReusableBottomSheet.show(...)` :

```dart
ElevatedButton(
  onPressed: () {
    ReusableBottomSheet.show(
      context: context,
      title: 'Paramètres du compte',
      subtitle: 'Modifiez vos informations personnelles',
      icon: Icons.person_rounded, // L'icône passée en paramètre
      iconColor: Colors.blue, // Couleur personnalisée
      iconBackgroundColor: Colors.blue.withOpacity(0.1),
      initialChildSize: 0.6, // S'ouvre à 60% de l'écran par défaut
      minChildSize: 0.4, // Ne descend pas sous 40% (Optionnel)
      maxChildSize: 0.95, // Peut s'étirer jusqu'à 95% (Optionnel)
      useGlassEffect: true, // Active l'effet de verre !
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ajoutez ici n'importe quel widget pour le contenu !
          TextField(
            decoration: InputDecoration(labelText: 'Nom complet'),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(labelText: 'Email'),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Enregistrer'),
            ),
          )
        ],
      ),
    );
  },
  child: Text('Ouvrir les paramètres'),
);
```

## 3. Points Forts de cette Architecture
1. **`isScrollControlled: true`** : Indispensable pour que le BottomSheet puisse prendre plus de la moitié de l'écran et s'adapter lorsque le clavier apparait.
2. **`DraggableScrollableSheet`** : Permet à l'utilisateur de glisser le contenu vers le haut ou vers le bas de manière fluide. Gère automatiquement la hauteur grâce à `initialChildSize`, `minChildSize` et `maxChildSize`.
3. **`viewInsets.bottom`** : Le `Padding` dans la méthode `show` évite que le contenu ne soit masqué par le clavier de l'OS (très utile pour des formulaires dans un BottomSheet).
4. **Paramètres souples** : Vous passez un `Widget` pour le contenu, ce qui veut dire que ce composant peut afficher une liste, un formulaire, une image ou n'importe quoi d'autre.
5. **Design et UI affinés** : Le BottomSheet inclut nativement une bonne gestion des dépassements de texte (Ellipsis), un bouton de fermeture discret, et injecte automatiquement un espace (`BottomSpacer`) à la fin du scroll pour un confort visuel optimal.
