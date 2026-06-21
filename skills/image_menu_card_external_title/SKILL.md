---
name: image-menu-card-external-title
description: Guide détaillé d'utilisation du composant ImageMenuCardExternalTitle (Cartes complexes avec images, textes externes et boutons).
tags: [flutter, widget, card, image, buttons, UI]
---

# Image Menu Card External Title Skill

Ce "skill" documente le widget `ImageMenuCardExternalTitle`, un composant UI extrêmement complet et polyvalent utilisé pour afficher des cartes illustrées. Contrairement à une carte standard où le texte est par-dessus l'image, ici le texte, les boutons et les autres informations sont disposés **en dessous** de l'image (à l'externe).

## 1. Fonctionnalités Principales

Ce composant est conçu pour répondre à presque tous les besoins d'affichage en grille ou en liste :
- **Gestion des Images intelligente** : Il gère les images réseau (`http`), les images locales (`assets/`), avec un fallback automatique vers une image par défaut ou une icône si l'image est manquante ou en erreur.
- **Titrage complet** : Support d'un sur-titre (`overtitle`), d'un titre principal (`title`), et d'un sous-titre (`subtitle`).
- **Éléments d'action** : Il permet d'ajouter un texte d'action cliquable, une localisation (avec icône pin), et/ou un bouton d'action complet (`buttonText` + `onButtonTap`).
- **Badge et Indicateurs** : Permet d'afficher un tag (badge) en haut à droite, ainsi qu'une icône `Play` au centre (utile si la carte représente une vidéo).
- **Design des Bordures** : Support exclusif d'un système de double bordure (`enableInnerBorder`, `enableOuterBorder`) très élégant.
- **Responsif et Animé** : Les polices s'adaptent toutes seules à la taille de l'écran (via `TextSizeService`) et la carte bénéficie d'une animation d'entrée progressive en fondu/glissement.

## 2. Exemples d'utilisation

### Exemple A : Carte Vidéo Simple (Youtube Style)
```dart
ImageMenuCardExternalTitle(
  index: 0,
  cardKey: 'video_card_1',
  title: 'Formation Flutter Avancée',
  subtitle: 'Il y a 2 jours',
  imagePath: 'https://mon-site.com/thumbnail.jpg',
  showPlayIcon: true, // Affiche l'icône lecture
  onTap: () {
    // Jouer la vidéo
  },
)
```

### Exemple B : Carte Produit / Événement (Avec Bouton et Tag)
```dart
ImageMenuCardExternalTitle(
  index: 1,
  cardKey: 'event_card',
  overtitle: 'SÉMINAIRE',
  title: 'Masterclass Design System',
  location: 'Paris, France', // Affiche une icône de localisation
  imagePath: 'assets/images/seminar.png',
  tag: 'NOUVEAU', // Badge en haut à droite de l'image
  color: AppColors.shopBlue, // Couleur dominante du badge/bouton
  buttonText: 'S\'inscrire',
  onButtonTap: () {
    // Action d'inscription
  },
  onTap: () {
    // Voir le détail de l'événement
  },
)
```

## 3. Paramètres Personnalisables

Voici la liste exhaustive des attributs que vous pouvez utiliser :

| Catégorie | Paramètre | Type | Description |
| :--- | :--- | :--- | :--- |
| **Bases** | `index` | `int` | **Requis**. Gère le délai de l'animation d'apparition (cascade). |
| | `cardKey` | `String` | **Requis**. Clé unique d'identification du widget. |
| | `onTap` | `VoidCallback` | **Requis**. Action au clic global sur la carte. |
| **Image** | `imagePath` | `String?` | URL réseau ou chemin Asset (ex: `assets/img.png`). |
| | `imageHeight` / `width` | `double?`| Définit la taille de l'image (hauteur et largeur de la carte). |
| | `showPlayIcon` | `bool` | Affiche une icône de lecture (Play) par-dessus l'image. |
| | `tag` | `String?` | Texte d'un badge placé en haut à droite de l'image. |
| **Titres**| `overtitle` | `String?` | Tout petit texte au-dessus du titre principal. |
| | `title` | `String?` | Le titre principal (Texte gras). |
| | `subtitle` | `String?` | Petit texte grisé sous le titre. |
| | `centerTitle` | `bool` | Centre tous les textes si `true`. Par défaut à gauche. |
| **Actions** | `location` | `String?` | Affiche une icône localisation + le texte spécifié. |
| | `buttonText` | `String?` | Si renseigné, affiche un bouton avec ce texte en bas à droite. |
| | `onButtonTap`| `VoidCallback?` | L'action appelée quand on clique **uniquement** sur le bouton. |
| **Design**| `enableInnerBorder` | `bool` | Ajoute une fine bordure intérieure autour de l'image. |
| | `enableOuterBorder` | `bool` | Ajoute une bordure externe (espacée) autour de l'image. |
| | `color` | `Color?` | La couleur dominante (utilise `AppColors.screenOrange` par défaut). |

## 4. Bonnes Pratiques

- **Bouton vs Carte** : Notez bien la différence entre `onTap` (action quand on clique sur la carte entière, généralement pour ouvrir une page de détail) et `onButtonTap` (action réservée au petit bouton d'action si vous l'activez avec `buttonText`).
- **Design Adaptatif** : N'utilisez pas de polices statiques pour redimensionner les textes. Le composant intègre le `TextSizeService` et change de taille automatiquement si l'application tourne sur Mobile ou sur Tablette.
- **Grilles (GridView)** : Ce composant est idéal pour être placé à l'intérieur d'un `GridView.builder` ou d'un `Wrap`. N'oubliez pas de passer l'`index` du builder directement au paramètre `index` de la carte pour bénéficier d'une magnifique animation d'apparition en cascade !
