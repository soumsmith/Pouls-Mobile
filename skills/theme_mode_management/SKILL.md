---
name: theme-mode-management
description: Implémentation robuste du mode Sombre / Clair (Dark/Light Mode) sans bugs dans une application Flutter.
---

# Theme Mode Management Skill

Ce "skill" explique la méthode recommandée pour implémenter, gérer et persister le mode Sombre (Dark Mode) et le mode Clair (Light Mode) de manière globale et sans bugs dans l'application.

L'application utilise déjà un fichier centralisé `AppColors` très complet. L'objectif est de lier ce design system avec l'état global de l'application.

## 1. Gestion de l'état (State Management & Persistance)

Pour que le changement de thème soit réactif et sauvegardé, il faut stocker le choix de l'utilisateur (Clair, Sombre, ou Système) avec `SharedPreferences` et utiliser un gestionnaire d'état (Provider, Riverpod, ou ValueNotifier) branché sur le `MaterialApp`.

### Exemple avec `ValueNotifier` (Approche la plus légère)

Créez un contrôleur global pour gérer le thème :

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._init();
  ThemeController._init();

  // Notifier écouté par MaterialApp
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    
    if (savedTheme == 'light') themeMode.value = ThemeMode.light;
    else if (savedTheme == 'dark') themeMode.value = ThemeMode.dark;
    else themeMode.value = ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    
    if (mode == ThemeMode.light) await prefs.setString('theme_mode', 'light');
    else if (mode == ThemeMode.dark) await prefs.setString('theme_mode', 'dark');
    else await prefs.remove('theme_mode'); // Retour au système
  }
}
```

## 2. Configuration du `MaterialApp`

Enveloppez votre `MaterialApp` avec un `ValueListenableBuilder` (ou `Consumer` si Provider/Riverpod) pour qu'il se reconstruise instantanément lors du changement de thème.

```dart
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeController.instance.themeMode,
    builder: (context, currentMode, child) {
      return MaterialApp(
        title: 'Mon Application',
        themeMode: currentMode, // <--- L'état central
        
        // --- THEME CLAIR ---
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.backgroundLight,
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            surface: AppColors.surfaceLight,
          ),
          // Configuration typographie, etc...
        ),
        
        // --- THEME SOMBRE ---
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceDark,
          ),
        ),
        
        home: const HomeScreen(),
      );
    },
  );
}
```

## 3. Bonnes Pratiques UI (Zéro Bugs de Couleurs)

### A. Ne JAMAIS coder de couleurs en dur dans l'UI
**❌ Mauvais :**
```dart
Container(color: Colors.white) // Bug : Restera blanc en mode sombre !
Text('Bonjour', style: TextStyle(color: Colors.black)) // Bug : Invisible en mode sombre !
```

**✅ Bon (Utilisation de `AppColors`) :**
Le fichier `AppColors` de votre projet contient des helpers dynamiques basés sur `isDarkMode(context)`. Utilisez-les toujours !
```dart
Container(color: AppColors.screenCardThemed(context))
Text('Bonjour', style: TextStyle(color: AppColors.screenTextPrimaryThemed(context)))
```

### B. Mettre à jour la barre de statut (System Chrome)
Quand le thème change, les icônes de batterie/heure en haut de l'écran (Status Bar) doivent s'adapter. Flutter le gère souvent seul via `AppBar`, mais si vous n'avez pas d'AppBar, forcez-le avec `AnnotatedRegion` :

```dart
import 'package:flutter/services.dart';

@override
Widget build(BuildContext context) {
  final isDark = AppColors.isDarkMode(context);
  
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: AppColors.screenBg(context),
      // ...
    ),
  );
}
```

### C. Gérer les ombres dynamiquement
Les ombres dures (`BoxShadow`) rendent souvent très mal en mode sombre. Réduisez leur opacité ou utilisez la couleur d'ombre configurée dans le fichier `AppColors` :

```dart
boxShadow: [
  BoxShadow(
    color: AppColors.screenShadowThemed(context), // Adapté au dark mode
    blurRadius: 10,
  ),
]
```

## 4. Résumé Anti-Bug
1. Le thème doit piloter `MaterialApp(themeMode: ...)` pour que `Theme.of(context).brightness` soit correct partout.
2. Tout widget de l'application doit dépendre de `context` pour ses couleurs (soit via `Theme.of(context)`, soit via `AppColors.method(context)`).
3. **Important :** N'utilisez pas les couleurs statiques de `AppColors` (`AppColors.pureWhite`, `AppColors.grey900`) directement dans vos designs finaux, préférez toujours les méthodes dynamiques (`AppColors.homeBg(context)` ou `AppColors.adaptiveColor(...)`).
