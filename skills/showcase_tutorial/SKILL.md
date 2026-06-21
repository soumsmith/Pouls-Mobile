---
name: showcase-tutorial
description: Implémentation de tutoriels interactifs guidés dans les écrans Flutter à l'aide du package showcaseview.
---

# Showcase Tutorial Skill

Ce "skill" explique comment intégrer des tutoriels interactifs étape par étape dans des écrans Flutter avec le package `showcaseview`.

## 1. Structure Générale

Le package `showcaseview` permet de mettre en surbrillance des widgets un par un.

### Prérequis
- Avoir `showcaseview: ^5.1.0` (ou version récente) dans `pubspec.yaml`
- L'écran ou son parent DOIT être enveloppé dans un `ShowCaseWidget`.

> [!WARNING]
> Dans les versions récentes de `showcaseview` (> 5.0), `ShowCaseWidget` prend un argument `builder: (context) => Widget` (et non plus un `Builder()`).

## 2. Étapes d'intégration

### Étape 1 : Envelopper l'écran avec ShowCaseWidget
Si le tutoriel couvre la navigation globale (ex: `BottomNavBar`), enveloppez le widget racine (comme `MainScreenWrapper`). Sinon, enveloppez le `Scaffold` de l'écran cible.

```dart
import 'package:showcaseview/showcaseview.dart';

@override
Widget build(BuildContext context) {
  // Le ShowCaseWidget doit être défini avant d'appeler _checkAndStartTutorial
  return ShowCaseWidget(
    builder: (context) {
      // Exécuter l'appel au démarrage
      if (!_hasCheckedTutorial) {
        _hasCheckedTutorial = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndStartTutorial(context);
        });
      }
      
      return Scaffold(
        // Votre UI
      );
    },
  );
}
```

### Étape 2 : Définir les GlobalKeys
Créez des `GlobalKey` pour chaque widget à mettre en valeur.

```dart
class _MyScreenState extends State<MyScreen> {
  final GlobalKey _stepOne = GlobalKey();
  final GlobalKey _stepTwo = GlobalKey();
  bool _hasCheckedTutorial = false; // Empêche plusieurs exécutions
```

### Étape 3 : Envelopper les widgets cibles dans Showcase
Utilisez le widget `Showcase` pour cibler l'élément.

```dart
Showcase(
  key: _stepOne,
  description: 'Cliquez ici pour accéder à votre profil.',
  child: MonWidgetCible(),
)
```

### Étape 4 : Ajouter des boutons de navigation (Suivant / Fermer)
Depuis les versions récentes, le package propose nativement de rajouter des boutons d'action autour ou dans l'infobulle grâce à `tooltipActions` et `tooltipActionConfig`.

```dart
Showcase(
  key: _stepOne,
  description: 'Texte d\'aide',
  tooltipActionConfig: const TooltipActionConfig(
    position: TooltipActionPosition.outside, // Place les boutons en dehors
    alignment: MainAxisAlignment.end,
  ),
  tooltipActions: [
    const TooltipActionButton(
      type: TooltipDefaultActionType.skip, // Action Fermer
      name: 'Fermer',
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    const TooltipActionButton(
      type: TooltipDefaultActionType.next, // Action Suivant
      name: 'Suivant',
      backgroundColor: Colors.orange,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ],
  child: MonWidgetCible(),
)
```

### Étape 5 : Lancer le tutoriel
Vérifiez `SharedPreferences` pour jouer le tutoriel une seule fois.

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _checkAndStartTutorial(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool('hasSeenMyScreenTutorial') ?? false;

  if (!hasSeen) {
    await prefs.setBool('hasSeenMyScreenTutorial', true);
    // Lance le tutoriel avec l'ordre défini dans la liste
    ShowCaseWidget.of(context).startShowCase([_stepOne, _stepTwo]);
  }
}
```

## 3. Bonnes Pratiques
- **Persistance :** Utilisez toujours `SharedPreferences` avec une clé unique pour chaque écran (ex: `hasSeenHomeTutorial`, `hasSeenSettingsTutorial`).
- **Option de réinitialisation :** Pensez à ajouter un toggle/bouton dans les Paramètres pour permettre aux utilisateurs de revoir le tutoriel (`await prefs.setBool('hasSeenHomeTutorial', false);`).
- **Éléments globaux :** Pour mettre en surbrillance des éléments partagés (comme une barre de navigation en bas), définissez sa clé dans le wrapper parent et accédez-y depuis l'écran enfant via `MonWrapper.maybeOf(context)?.maCle`.

## 4. Affichage Conditionnel du Showcase
Si vous développez des composants réutilisables (comme une Card ou un Bouton) et que vous souhaitez pouvoir activer ou désactiver le Showcase via un paramètre, utilisez le widget `ConditionalShowcase` (situé dans `lib/widgets/conditional_showcase.dart`).

```dart
import '../widgets/conditional_showcase.dart';

ConditionalShowcase(
  showShowcase: true, // Mettez à false pour désactiver totalement le Showcase
  showcaseKey: _myKey,
  description: 'Voici mon widget.',
  child: MonWidgetCible(),
)
```
