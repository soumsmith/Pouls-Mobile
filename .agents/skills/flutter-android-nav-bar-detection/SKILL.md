---
name: flutter-android-nav-bar-detection
description: >-
  Detects whether an Android device is using gesture navigation or the classic 3-button navigation, in order to adapt bottom UI elements (like removing rounded corners and margins for 3-button navigation).
---

# Flutter Android Navigation Bar Detection

## Overview
When designing custom bottom navigation bars or floating action buttons in Flutter, the UI can look out of place if the device uses Android's classic 3-button navigation (which is flat and takes up a large horizontal block at the bottom). In contrast, gesture navigation leaves a small bottom inset where rounded corners and floating margins look great.

This skill provides the standard heuristic pattern to detect 3-button navigation vs. gesture navigation and adjust the UI accordingly.

## Pattern / Snippet

To detect the navigation type, use `MediaQuery.of(context).viewPadding.bottom` (which gives the physical safe area inset at the bottom, unmodified by any `SafeArea` widget).

```dart
// 1. Récupérer le viewPadding du bas
final viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
final isAndroid = Theme.of(context).platform == TargetPlatform.android;

// 2. Détection de la navigation par 3 boutons (pas de swipe)
// La navigation par gestes (swipe) a un viewPaddingBottom généralement entre 15 et 35.
// >= 40 indique la barre classique à 3 boutons. 
// == 0 indique souvent l'absence d'edge-to-edge (donc 3 boutons sur de vieux appareils).
final isThreeButtonNav = isAndroid && (viewPaddingBottom == 0 || viewPaddingBottom >= 40);

// 3. Adapter l'interface en conséquence
final double horizontalMargin = isThreeButtonNav ? 0.0 : 16.0;
final BorderRadius navBorderRadius = isThreeButtonNav ? BorderRadius.zero : BorderRadius.circular(24.0);

// 4. Appliquer au conteneur
return Container(
  margin: EdgeInsets.fromLTRB(
    horizontalMargin, 
    12.0, 
    horizontalMargin, 
    MediaQuery.of(context).padding.bottom, // ou 0 si géré par ailleurs
  ),
  decoration: BoxDecoration(
    borderRadius: navBorderRadius,
    // ...
  ),
  // ...
);
```

## When to Use This Skill
- When implementing a custom `BottomNavigationBar`.
- When placing floating UI elements at the absolute bottom of the screen.
- When the user reports that a bottom element "floats awkwardly" or "looks bad with the 3 buttons" on Android.

## Common Mistakes
1. **Using `padding.bottom` inside a `SafeArea`**: If your widget is inside a `SafeArea`, `MediaQuery.of(context).padding.bottom` will be `0` because `SafeArea` consumes the padding. **Always use `viewPadding.bottom`** for this detection, as it represents the unconsumed physical safe area.
2. **Applying the heuristic to iOS**: iOS always uses the home indicator (gesture navigation), so its inset is around `34.0`. Ensure you check `isAndroid` before applying the 3-button fallback.
