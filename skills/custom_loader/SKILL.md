---
name: custom-loader
description: Guide pour comprendre et utiliser le composant CustomLoader et CustomLoaderOverlay, un indicateur de chargement global et réutilisable dans Flutter.
---

# 🚀 Guide du Composant : CustomLoader & Overlay

Ce guide ultra-simple vous explique comment fonctionne le composant `CustomLoader` et son outil associé `CustomLoaderOverlay`. Parfait pour les débutants !

## À quoi ça sert ? 🤔
Dans une application, quand on télécharge des données sur internet, on veut souvent empêcher l'utilisateur de cliquer partout et lui montrer une jolie animation pour le faire patienter.

Ce fichier nous offre **deux super-pouvoirs** :
1. **`CustomLoader`** : C'est le petit dessin animé (une vague de points) avec un texte en dessous (ex: "Chargement..."). On peut l'afficher de façon classique n'importe où dans notre interface.
2. **`CustomLoaderOverlay`** : C'est la version magique ! Avec une seule ligne de code, ça affiche un fond gris transparent par-dessus **TOUT** votre écran (ce qui empêche de cliquer sur quoi que ce soit en dessous) avec l'animation de chargement centrée.

---

## Étape 1 : Le Code du Composant (L'Implémentation)

Si vous devez réutiliser ce code dans un autre projet, voici son contenu complet. Il dépend du package `loading_animation_widget`. N'oubliez pas d'ajouter `loading_animation_widget: ^1.2.0` (ou version plus récente) dans votre fichier `pubspec.yaml` !

📁 **Chemin du fichier :** `lib/widgets/custom_loader.dart`

```dart
import 'package:flutter/material.dart';
// Ce package sert à afficher de très belles animations de chargement sans effort !
import 'package:loading_animation_widget/loading_animation_widget.dart';

// =====================================================================
// 1. L'OVERLAY : L'outil magique pour bloquer l'écran avec un chargement
// =====================================================================

/// Service pour afficher un loader au-dessus de TOUS les écrans (pour bloquer les clics)
class CustomLoaderOverlay {
  // Constructeur privé : on ne peut pas faire de "new CustomLoaderOverlay()", 
  // on utilise que les méthodes avec "static" (comme un outil global disponible partout).
  CustomLoaderOverlay._();

  // "OverlayEntry" est ce qui permet à Flutter de dessiner "par-dessus" l'écran actuel
  static OverlayEntry? _overlayEntry;

  /// 🎬 AFFICHE LE CHARGEMENT
  static void show(
    BuildContext context, {
    String message = 'Chargement...', // Le message texte par défaut
    Color? backgroundColor,
    Color loaderColor = const Color(0xFF1565C0), // Couleur bleue par défaut de l'animation
    double size = 56.0,
    bool showBackground = true,
  }) {
    // S'il y avait déjà un loader affiché à l'écran, on l'enlève pour éviter les bugs
    hide();

    // On récupère la couche supérieure (l'overlay) de l'application
    final overlay = Overlay.of(context);
    
    // On crée notre fond gris avec notre loader au milieu
    _overlayEntry = OverlayEntry(
      builder: (context) => _LoaderOverlayWidget(
        message: message,
        backgroundColor: backgroundColor,
        loaderColor: loaderColor,
        size: size,
        showBackground: showBackground,
        onDismiss: hide, // Que faire si on veut l'enlever
      ),
    );

    // Et BAM, on l'injecte par dessus tout le reste de l'écran !
    overlay.insert(_overlayEntry!);
  }

  /// 🛑 CACHE LE CHARGEMENT
  static void hide() {
    // Si l'overlay existe et est affiché
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove(); // On le retire physiquement de l'écran
      _overlayEntry = null;    // On nettoie la variable
    }
  }

  /// Permet de savoir si un chargement est actuellement visible à l'écran
  static bool get isVisible => _overlayEntry != null && _overlayEntry!.mounted;
}

// --- Widget interne (privé) qui gère l'animation de "fondu au noir" (Fade In) ---
class _LoaderOverlayWidget extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Color loaderColor;
  final double size;
  final bool showBackground;
  final VoidCallback onDismiss;

  const _LoaderOverlayWidget({
    required this.message,
    this.backgroundColor,
    required this.loaderColor,
    required this.size,
    required this.showBackground,
    required this.onDismiss,
  });

  @override
  State<_LoaderOverlayWidget> createState() => _LoaderOverlayWidgetState();
}

class _LoaderOverlayWidgetState extends State<_LoaderOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // On crée une petite animation rapide de 200 millisecondes...
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // ...qui va faire apparaître l'écran transparent progressivement (de 0.0 à 1.0)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );
    // On lance l'animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition applique l'effet d'apparition progressive
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        // Le fond noir/gris semi-transparent (black54) qui empêche de cliquer sur les boutons en dessous !
        color: Colors.black54, 
        child: Center(
          // Au centre exact de ce fond, on place notre composant visuel final (le CustomLoader)
          child: CustomLoader(
            message: widget.message,
            backgroundColor: widget.backgroundColor,
            loaderColor: widget.loaderColor,
            size: widget.size,
            showBackground: widget.showBackground,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 2. LE WIDGET VISUEL : L'animation elle-même (Les points et le texte)
// =====================================================================

/// C'est simplement le composant graphique : Les points qui dansent avec le texte
class CustomLoader extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color loaderColor;
  final double size;
  final bool showBackground;

  const CustomLoader({
    Key? key,
    required this.message,
    this.backgroundColor,
    required this.loaderColor,
    this.size = 56.0,
    this.showBackground = true, // Voulons-nous un joli petit carré blanc autour des points ?
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Le contenu : L'animation en haut, le texte en bas
    Widget content = Column(
      mainAxisSize: MainAxisSize.min, // La colonne prend juste la place stricte nécessaire
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // La fameuse animation (Staggered Dots Wave)
        LoadingAnimationWidget.staggeredDotsWave(color: loaderColor, size: size),
        
        // S'il y a un message texte, on l'ajoute
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999), // Gris clair très élégant
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none, // Empêche d'avoir des traits jaunes horribles sous le texte !
            ),
          ),
        ],
      ],
    );

    // Si on a désactivé le fond, on renvoie juste les points et le texte dans le vide
    if (!showBackground) {
      return content;
    }

    // Sinon (par défaut), on entoure l'animation d'un joli bloc (Container) avec coins arrondis
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          // S'il n'y a pas de couleur définie, on met du blanc à 90% d'opacité
          color: backgroundColor ?? Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}
```

---

## Étape 2 : Comment l'utiliser ? (L'Exemple Facile)

C'est ici que `CustomLoaderOverlay` brille ! 
Admettons que vous ayez un bouton "S'inscrire". Quand on clique dessus, vous parlez à votre base de données sur internet. Voici comment utiliser la magie :

📝 **Exemple d'utilisation dans un écran :**

```dart
import 'package:flutter/material.dart';
// N'oubliez pas l'import !
import '../widgets/custom_loader.dart';

class MonEcranLogin extends StatelessWidget {
  
  // Fonction appelée quand on clique sur notre fameux bouton "S'inscrire"
  void _boutonMagiqueAppuye(BuildContext context) async {
    
    // 1️⃣ ON AFFICHE LE CHARGEMENT PAR-DESSUS TOUT !
    // Bam ! L'utilisateur ne peut plus cliquer sur rien, un fond gris apparait !
    CustomLoaderOverlay.show(
      context, 
      message: "Vérification en cours...", // Votre texte personnalisé
      loaderColor: Colors.orange,          // Vous pouvez changer la couleur des points
    );

    // 2️⃣ ON FAIT NOTRE LONG TRAVAIL (ex: Parler à l'API)
    // Ici on simule une attente de 3 secondes avec Future.delayed
    await Future.delayed(const Duration(seconds: 3)); 

    // 3️⃣ ON CACHE LE CHARGEMENT !
    // ⚠️ Très important : N'oubliez jamais cette ligne, sinon l'écran reste bloqué à l'infini !
    CustomLoaderOverlay.hide();

    // 4️⃣ On passe à la page suivante ou on affiche un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tout s\'est bien passé !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exemple Loader")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _boutonMagiqueAppuye(context), // On lance notre fonction au clic
          child: const Text("Lancer une action"),
        ),
      ),
    );
  }
}
```

**Bravo 🎉 ! Vous savez maintenant gérer les "temps de chargement" de manière totalement professionnelle dans votre application !**
