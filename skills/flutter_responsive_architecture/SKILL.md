---
name: create-modern-responsive-flutter-app
description: Un prompt de départ (Skill) pour générer une architecture complète, responsive et production-ready pour une nouvelle application Flutter (Mobile & Tablette).
tags: [flutter, architecture, responsive, dark-mode, clean-architecture, design-system]
version: 2.0
---

# Générateur d'Application Flutter Responsive et Moderne

**Comment utiliser ce Skill ?**
Copiez-collez le "Prompt Principal" ci-dessous lors d'une nouvelle conversation pour démarrer un projet Flutter avec une architecture complète, moderne et évolutive. Des **prompts complémentaires** sont fournis en bas pour aller plus loin étape par étape.

---

## 📋 Prompt Principal (à copier-coller) :

> **Agis en tant qu'Architecte Flutter Senior et Expert UI/UX Mobile.**
>
> Je souhaite créer une toute nouvelle application Flutter moderne, élégante et parfaitement responsive (smartphones de toutes tailles + tablettes). Le projet doit être **immédiatement exécutable** (`flutter run` sans erreur) et prêt pour une mise en production.
>
> Génère l'architecture complète en respectant **strictement** les critères suivants :
>
> ---
>
> ### 🏗️ 1. Architecture des dossiers (Clean Architecture simplifiée)
>
> ```
> lib/
> ├── config/
> │   ├── themes/
> │   │   ├── app_theme.dart          # ThemeData light + dark
> │   │   ├── app_colors.dart         # Palette complète (light + dark)
> │   │   └── app_text_styles.dart    # Styles typographiques centralisés
> │   ├── app_dimensions.dart         # Breakpoints + tailles dynamiques
> │   └── app_constants.dart          # Constantes globales (durations, radii…)
> ├── core/
> │   ├── extensions/
> │   │   ├── context_extensions.dart # Ex: context.isTablet, context.w, context.h
> │   │   └── widget_extensions.dart  # Ex: widget.padded(), widget.centered()
> │   ├── utils/
> │   │   └── responsive_helper.dart  # Utilitaire de calcul responsive
> │   └── providers/
> │       └── theme_provider.dart     # Gestion état Dark/Light (Riverpod ou Provider)
> ├── widgets/
> │   ├── app_bar/
> │   │   └── custom_app_bar.dart
> │   ├── buttons/
> │   │   └── primary_button.dart
> │   ├── cards/
> │   │   └── adaptive_card.dart
> │   ├── drawer/
> │   │   └── custom_drawer.dart
> │   └── layouts/
> │       └── responsive_layout.dart  # Widget switcher Mobile/Tablette
> ├── screens/
> │   ├── onboarding/
> │   │   └── onboarding_screen.dart
> │   ├── home/
> │   │   ├── home_screen.dart
> │   │   └── widgets/               # Widgets spécifiques à home
> │   └── splash/
> │       └── splash_screen.dart
> └── main.dart
> ```
>
> ---
>
> ### 📐 2. Système Responsive Robuste
>
> **`app_dimensions.dart`** — Définit des breakpoints clairs et des helpers :
> - `isMobile(context)` → largeur < 600px
> - `isTablet(context)` → 600px ≤ largeur < 1024px
> - `isDesktop(context)` → largeur ≥ 1024px
> - `sp(double size)` → taille de police scalée (`size * textScaleFactor`)
> - `wp(double percent)` → pourcentage de la largeur écran
> - `hp(double percent)` → pourcentage de la hauteur écran
> - `adaptivePadding(context)` → padding 16px mobile, 24px tablette, 32px desktop
>
> **`responsive_layout.dart`** — Widget dédié au switch de layout :
> ```dart
> ResponsiveLayout(
>   mobile: MobileHomeLayout(),
>   tablet: TabletHomeLayout(),   // Optionnel
>   desktop: DesktopHomeLayout(), // Optionnel
> )
> ```
>
> **`context_extensions.dart`** — Extensions pratiques sur `BuildContext` :
> ```dart
> context.isTablet     // bool
> context.screenWidth  // double
> context.adaptivePad  // EdgeInsets
> context.theme        // ThemeData (shortcut)
> context.colors       // AppColors de la palette active
> ```
>
> ---
>
> ### 🎨 3. Design System & Thème Complet
>
> **`app_colors.dart`** — Deux palettes complètes, aucune couleur codée en dur dans l'UI :
> ```dart
> // Définir via ColorScheme, jamais Colors.white / Colors.black directement
> class AppColors {
>   // Primary, Secondary, Tertiary
>   // Background, Surface, SurfaceVariant
>   // OnPrimary, OnBackground, OnSurface
>   // Error, Success, Warning, Info
>   // Divider, Shadow, Overlay
> }
> ```
>
> **`app_text_styles.dart`** — Système typographique à 6 niveaux :
> ```dart
> // displayLarge, displayMedium (titres héros)
> // headlineLarge, headlineMedium (sous-titres sections)
> // bodyLarge, bodyMedium, bodySmall (texte courant)
> // labelLarge, labelSmall (boutons, badges)
> // → Toutes les tailles utilisent sp() pour le scaling
> ```
>
> **`app_theme.dart`** — Configuration `MaterialApp` complète :
> - `theme` (light) + `darkTheme` (dark) via `ThemeData.from(colorScheme: ...)`
> - Customisation de `AppBarTheme`, `CardTheme`, `ElevatedButtonTheme`, `InputDecorationTheme`, `SnackBarTheme`
> - `themeMode` piloté par `ThemeProvider` (sauvegardé en `SharedPreferences`)
>
> ---
>
> ### 🧩 4. Composants UI Inclus
>
> **`custom_app_bar.dart`** — AppBar responsive :
> - Titre + subtitle optionnel
> - Actions responsives (icônes sur mobile, boutons texte sur tablette)
> - Support `SliverAppBar` pour les scrolls longs
> - Switch thème Dark/Light intégré
>
> **`primary_button.dart`** — Bouton d'action principal :
> - États : normal, loading (CircularProgressIndicator), disabled, success
> - Style : bords très arrondis (`borderRadius: 14`), ombre douce, gradient optionnel
> - Largeur adaptative (pleine largeur mobile, taille fixe tablette)
>
> **`adaptive_card.dart`** — Carte de contenu générique :
> - Elevation dynamique (2 mobile, 4 tablette)
> - Clip + InkWell pour l'effet ripple
> - Slots : header, body, footer, leading image
>
> **`custom_drawer.dart`** — Navigation latérale :
> - En-tête avec avatar, nom utilisateur, rôle
> - Menus déroulants `ExpansionTile` pour sous-sections
> - Item actif mis en surbrillance
> - Bouton de déconnexion en bas
> - Largeur fixe sur tablette, pleine ouverture sur mobile
>
> ---
>
> ### 🚀 5. Onboarding & Navigation
>
> **`onboarding_screen.dart`** — Utilise `introduction_screen: ^4.0.0` :
> - 3 slides par défaut (personnalisables)
> - Illustrations SVG ou Lottie (placeholder commenté si assets manquants)
> - Bouton "Commencer" qui marque l'onboarding comme vu (`SharedPreferences`)
> - Skip button sur toutes les slides sauf la dernière
>
> **`splash_screen.dart`** — Écran de démarrage :
> - Logo animé (AnimationController + FadeTransition)
> - Vérifie si l'onboarding a déjà été vu → redirige vers Home ou Onboarding
> - Durée : 2 secondes puis navigation automatique
>
> **Navigation (`GoRouter` recommandé)** :
> ```dart
> // Routes : /splash → /onboarding (si première fois) → /home
> // Named routes avec paramètres typés
> // Redirect guard pour l'authentification (placeholder)
> ```
>
> ---
>
> ### 📦 6. `pubspec.yaml` complet
>
> Inclure ces dépendances (versions stables) :
> ```yaml
> dependencies:
>   flutter_riverpod: ^2.5.1      # Gestion d'état
>   go_router: ^14.0.0            # Navigation déclarative
>   introduction_screen: ^4.0.0   # Onboarding
>   shared_preferences: ^2.3.0    # Persistance locale (thème, onboarding)
>   flutter_svg: ^2.0.10          # Support SVG pour les illustrations
>   google_fonts: ^6.2.1          # Typographie premium
>   gap: ^3.0.1                   # Espacements sémantiques (Gap(16))
>
> dev_dependencies:
>   flutter_lints: ^4.0.0
>   build_runner: ^2.4.9
> ```
>
> ---
>
> ### ✅ 7. Règles Qualité & Bonnes Pratiques
>
> - **Zéro couleur statique dans l'UI** : toujours `Theme.of(context).colorScheme.X`
> - **Zéro `MediaQuery.of(context)` répété** : utiliser les extensions `context.X`
> - **`const` partout où possible** pour les performances
> - **Séparation UI / logique** : aucune logique métier dans les widgets
> - **Commentaires** sur chaque fichier expliquant son rôle
> - **`flutter analyze` sans warning** à la génération
>
> ---
>
> ### 📄 Fichiers à générer impérativement :
>
> 1. `pubspec.yaml`
> 2. `lib/main.dart`
> 3. `lib/config/app_colors.dart`
> 4. `lib/config/app_dimensions.dart`
> 5. `lib/config/themes/app_theme.dart`
> 6. `lib/config/themes/app_text_styles.dart`
> 7. `lib/core/extensions/context_extensions.dart`
> 8. `lib/core/providers/theme_provider.dart`
> 9. `lib/widgets/layouts/responsive_layout.dart`
> 10. `lib/widgets/app_bar/custom_app_bar.dart`
> 11. `lib/widgets/buttons/primary_button.dart`
> 12. `lib/widgets/cards/adaptive_card.dart`
> 13. `lib/widgets/drawer/custom_drawer.dart`
> 14. `lib/screens/splash/splash_screen.dart`
> 15. `lib/screens/onboarding/onboarding_screen.dart`
> 16. `lib/screens/home/home_screen.dart` (dashboard avec cartes de stats, AppBar, Drawer)
>
> **Résultat attendu** : `flutter run` sur Chrome, iOS Simulator et Android Emulator sans erreur, avec un dashboard magnifique qui s'adapte en temps réel à la rotation et au changement de taille d'écran.

---

## 🔧 Prompts Complémentaires (étapes suivantes)

### ➕ Ajouter une feature complète
> En continuant ce projet Flutter, ajoute une nouvelle feature **[NOM_FEATURE]** en respectant l'architecture existante :
> - Crée le dossier `lib/screens/[feature]/` avec son écran principal et ses sous-widgets
> - Ajoute le Provider/Notifier Riverpod dans `lib/core/providers/`
> - Enregistre la route dans le fichier GoRouter existant
> - Utilise les composants existants (`AdaptiveCard`, `PrimaryButton`, `CustomAppBar`)
> - Respecte le système de couleurs : aucune couleur codée en dur

### 🔐 Ajouter l'authentification
> Ajoute un système d'authentification complet à ce projet Flutter :
> - Écrans : `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`
> - `AuthProvider` (Riverpod) avec états : `loading`, `authenticated`, `unauthenticated`, `error`
> - Guard de navigation GoRouter : redirige vers `/login` si non authentifié
> - Formulaires avec validation inline (pas de popup)
> - Persistance du token via `SharedPreferences` ou `flutter_secure_storage`

### 🌐 Connecter une API REST
> Ajoute une couche service pour consommer une API REST dans ce projet Flutter :
> - Crée `lib/core/network/api_client.dart` avec `Dio` ou `http`
> - Intercepteur pour injecter le token d'auth dans les headers
> - Gestion des erreurs HTTP centralisée (401 → logout, 500 → snackbar)
> - Pattern Repository : `lib/data/repositories/[feature]_repository.dart`
> - Modèles avec `fromJson`/`toJson` dans `lib/data/models/`
> - `AsyncNotifier` Riverpod pour gérer les états loading/data/error dans l'UI

### 🧪 Ajouter les tests
> Génère les tests pour ce projet Flutter :
> - Tests unitaires pour tous les Providers/Notifiers Riverpod
> - Tests de widgets pour `PrimaryButton`, `AdaptiveCard`, `CustomAppBar`
> - Tests d'intégration pour le flow Onboarding → Home
> - Mocks des dépendances avec `mocktail`
> - Configuration `flutter_test` avec couverture minimale de 80%

### 📊 Ajouter des graphiques au dashboard
> Enrichis le `HomeScreen` avec des graphiques interactifs :
> - Utilise `fl_chart: ^0.68.0`
> - `LineChart` pour l'évolution temporelle
> - `BarChart` pour les comparaisons
> - `PieChart` pour les répartitions
> - Tous les graphiques s'adaptent responsive (plus grands sur tablette)
> - Couleurs issues de `AppColors` (compatibles Dark/Light mode)

---

## 💡 Conseils d'utilisation

| Situation | Action |
|-----------|--------|
| Nouveau projet from scratch | Copier le **Prompt Principal** complet |
| Ajouter un écran simple | Utiliser le prompt **"Ajouter une feature"** |
| Projet existant à migrer | Demander d'abord un audit, puis appliquer la structure par parties |
| Erreur de build après génération | Partager l'erreur complète + demander un fix ciblé |
| Adapter pour un domaine métier | Préciser le domaine dans le prompt (ex: "app de gestion RH") |

---

*Prompt enrichi — NKM Technologie | Architecture Flutter Production-Ready*