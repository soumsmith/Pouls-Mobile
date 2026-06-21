---
name: scroll-to-top-fab
description: Guide pour comprendre et utiliser le composant ScrollToTopFab, un bouton flottant intelligent pour remonter ou descendre en douceur dans une liste.
---

# 🚀 Guide du Composant : ScrollToTopFab

Ce guide ultra-simple vous explique ce qu'est le composant `ScrollToTopFab` et comment l'utiliser dans votre application. C'est le petit bouton magique indispensable pour toutes vos très longues listes !

## À quoi ça sert ? 🤔
Quand un utilisateur navigue dans une très longue page (comme un fil d'actualité ou un catalogue), ça peut être très fatiguant de devoir "scroller" (faire glisser le doigt) pendant de longues secondes juste pour revenir au menu tout en haut de l'écran.

Le **`ScrollToTopFab`** ("FAB" = Floating Action Button) est un bouton rond et flottant qui fait tout le travail :
- Il est **totalement invisible** quand l'utilisateur est déjà tout en haut.
- Il **apparaît automatiquement** (avec un joli effet d'animation) dès qu'on commence à descendre dans la page.
- Quand on clique dessus, il nous ramène **tout en haut** (ou tout en bas !) avec un magnifique effet de glissement fluide.

---

## Étape 1 : Le Code du Composant (L'Implémentation)

Voici comment ce petit bouton intelligent est construit en coulisse. L'astuce, c'est qu'il écoute en permanence le "ScrollController" (le chef d'orchestre de la liste) pour savoir s'il doit se cacher ou s'afficher.

📁 **Chemin du fichier :** `lib/widgets/scroll_to_top_fab.dart`

```dart
import 'package:flutter/material.dart';

// --- VOS FICHIERS DE CONFIGURATION ---
// import 'components/bottom_spacer.dart';
// import '../config/app_dimensions.dart';

/// Un petit bouton rond flottant qui permet de scroller automatiquement
class ScrollToTopFab extends StatefulWidget {
  // Le "cerveau" qui connaît la position exacte dans la liste et qui la contrôle
  final ScrollController scrollController;
  
  // À partir de combien de pixels de défilement le bouton doit-il apparaître ?
  final double showOffset;
  
  // Un espace vide optionnel en dessous du bouton pour ne pas être collé
  final double bottomSpacerHeight;
  
  // Si TRUE : ramène en HAUT. Si FALSE : ramène en BAS.
  final bool isScrollToTop;

  const ScrollToTopFab({
    Key? key,
    required this.scrollController, // Obligatoire !
    this.showOffset = 200.0,        // Par défaut, apparaît après avoir scrollé 200 pixels
    this.bottomSpacerHeight = 40.0,
    this.isScrollToTop = true,      // Par défaut, c'est pour remonter
  }) : super(key: key);

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  // Variable qui dit si on doit afficher le bouton (true) ou le cacher (false)
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    // Dès qu'on affiche l'écran, on demande au contrôleur de nous avertir chaque fois que la liste bouge !
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // ⚠️ Quand on quitte l'écran, on arrête d'écouter la liste pour économiser la batterie et la mémoire du téléphone.
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  // 👂 LA FONCTION MAGIQUE QUI ÉCOUTE LE DÉFILEMENT
  void _scrollListener() {
    // Vérifie que la liste est bien prête et attachée à l'écran
    if (widget.scrollController.hasClients) {
      
      if (widget.isScrollToTop) {
        // MODE "REMONTER" ⬆️
        // Si on a descendu de plus de 200 pixels ET que le bouton est caché... on l'affiche !
        if (widget.scrollController.offset >= widget.showOffset && !_showFab) {
          setState(() { _showFab = true; });
        } 
        // Si on est remonté en dessous des 200 pixels ET qu'il est affiché... on le cache !
        else if (widget.scrollController.offset < widget.showOffset && _showFab) {
          setState(() { _showFab = false; });
        }
      } else {
        // MODE "DESCENDRE" ⬇️ (Même logique, mais on regarde la fin de la page au lieu du début)
        final maxScroll = widget.scrollController.position.maxScrollExtent;
        if (widget.scrollController.offset < maxScroll - widget.showOffset && !_showFab) {
          setState(() { _showFab = true; });
        } else if (widget.scrollController.offset >= maxScroll - widget.showOffset && _showFab) {
          setState(() { _showFab = false; });
        }
      }
    }
  }

  // 🚀 L'ACTION AU CLIC : GLISSER EN DOUCEUR
  void _performAction() {
    if (widget.scrollController.hasClients) {
      // On calcule la destination : "0.0" pour tout en haut, ou la "taille maximale" pour tout en bas
      final target = widget.isScrollToTop ? 0.0 : widget.scrollController.position.maxScrollExtent;
      
      // Magie de Flutter : on anime le défilement !
      widget.scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500), // L'animation prend une demi-seconde
        curve: Curves.easeInOut, // Effet stylé : Le mouvement commence doucement et freine doucement à la fin
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pour adapter la couleur selon si le téléphone de l'utilisateur est en mode sombre ou clair
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min, // Prend juste la place nécessaire, sans s'étaler
      children: [
        
        // 💫 ANIMATION D'APPARITION : Fait "zoomer/dézoomer" le bouton quand il apparait/disparait
        AnimatedScale(
          scale: _showFab ? 1.0 : 0.0, // 1.0 = taille normale, 0.0 = complètement écrasé/invisible
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // On utilise votre ombre personnalisée de l'application
              boxShadow: AppDimensions.getBottomSheetShadow(context), 
            ),
            
            // LE VRAI BOUTON CLIQUABLE !
            child: FloatingActionButton(
              mini: true, // Un peu plus petit et mignon qu'un bouton flottant classique
              elevation: 0,
              highlightElevation: 0,
              onPressed: _performAction, // Lance la super animation calculée plus haut
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              foregroundColor: Theme.of(context).primaryColor, // Couleur de la petite flèche
              shape: const CircleBorder(),
              
              // Change le dessin de la flèche selon si on doit monter ou descendre
              child: Icon(widget.isScrollToTop ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            ),
          ),
        ),
        
        // Un espace vide pour ne pas que le bouton soit collé tout en bas de l'écran (si besoin)
        BottomSpacer(height: widget.bottomSpacerHeight),
      ],
    );
  }
}
```

---

## Étape 2 : Comment l'utiliser ? (L'Exemple Facile)

Pour l'utiliser, il y a **UNE RÈGLE D'OR** : Il vous faut une variable de type `ScrollController`. Vous devez brancher ce même contrôleur **à la fois** sur votre liste (`ListView`, `CustomScrollView`...) **et** sur notre petit bouton. C'est grâce à ça que le bouton et la liste "se parlent" !

📝 **Exemple d'utilisation dans un écran complet :**

```dart
import 'package:flutter/material.dart';
// N'oubliez pas votre composant
import '../widgets/scroll_to_top_fab.dart';

class MonEcranAvecListe extends StatefulWidget {
  @override
  _MonEcranAvecListeState createState() => _MonEcranAvecListeState();
}

class _MonEcranAvecListeState extends State<MonEcranAvecListe> {
  // 1️⃣ ON CRÉE LE CONTRÔLEUR ! C'est le chef d'orchestre du défilement.
  final ScrollController _monControleur = ScrollController();

  @override
  void dispose() {
    // ⚠️ On n'oublie jamais de détruire le contrôleur quand on quitte la page !
    _monControleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Une très longue liste")),
      
      // 2️⃣ LA LONGUE LISTE
      body: ListView.builder(
        controller: _monControleur, // ⚡ ON BRANCHE LE CONTRÔLEUR SUR LA LISTE
        itemCount: 100, // 100 éléments, c'est très long !
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Élément numéro \$index"),
          );
        },
      ),

      // 3️⃣ NOTRE PETIT BOUTON MAGIQUE
      // On le met très souvent dans l'emplacement dédié "floatingActionButton" du Scaffold
      floatingActionButton: ScrollToTopFab(
        scrollController: _monControleur, // ⚡ ON BRANCHE LE MÊME CONTRÔLEUR SUR LE BOUTON !
        showOffset: 300, // Le bouton apparaîtra seulement après avoir descendu de 300 pixels
        // isScrollToTop: true, // (Optionnel, c'est true par défaut)
      ),
      
      // On place le bouton correctement en bas à droite
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
```

**Bravo 🎉 ! Plus aucun de vos utilisateurs n'aura d'ampoules aux doigts à force de faire défiler vos pages !**
