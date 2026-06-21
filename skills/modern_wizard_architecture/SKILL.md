---
name: modern-wizard-architecture
description: Guide architectural pour construire un Wizard (formulaire multi-étapes) adaptatif, réactif et robuste avec Flutter.
tags: [flutter, wizard, stepper, architecture, pageview, form]
---

# Modern Wizard Architecture Skill

Ce "skill" documente le modèle architectural utilisé pour créer des écrans "Wizard" (ou tunnels de processus multi-étapes) comme on le voit dans l'écran d'inscription de ce projet (`inscription_screen.dart`).

Cette approche résout le problème classique des étapes conditionnelles : que se passe-t-il si un utilisateur coche une case qui doit afficher une étape supplémentaire ? L'architecture que nous utilisons permet de recalculer dynamiquement la liste des étapes tout en gardant une animation de transition fluide.

## 1. Concepts Clés

L'architecture repose sur **3 piliers fondamentaux** :

1. **La liste dynamique des identifiants (IDs) d'étapes** : Au lieu d'avoir un index figé (0, 1, 2), nous gérons une liste d'ID (ex: `['step1', 'step2', 'step4']`). Si l'étape 3 n'est pas requise, on ne l'inclut pas dans la liste générée.
2. **Le `PageView` contrôlé** : L'affichage réel des pages se fait via un `PageView` dont le défilement manuel (swipe) est désactivé (`NeverScrollableScrollPhysics`).
3. **Le Layout avec `Stack` et `BottomFadeGradient`** : Le contenu de la page est scrollable, mais les boutons "Suivant / Précédent" flottent toujours au-dessus du contenu en bas de l'écran, avec un effet de fondu pour ne pas couper le texte brutalement.

## 2. Structure du Code Modèle

Voici le squelette minimaliste pour créer un nouvel écran Wizard :

```dart
import 'package:flutter/material.dart';

// Définissez vos identifiants d'étapes en constantes
const String _kStepInfos = 'infos';
const String _kStepOptions = 'options';
const String _kStepPaiement = 'paiement';
const String _kStepRecap = 'recap';

class MyDynamicWizard extends StatefulWidget {
  @override
  _MyDynamicWizardState createState() => _MyDynamicWizardState();
}

class _MyDynamicWizardState extends State<MyDynamicWizard> {
  int _currentPageIndex = 0;
  late PageController _pageController;
  
  // Variable d'état qui contrôle si l'étape "Options" doit s'afficher
  bool _needsOptions = false; 

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  // 1. Le Générateur d'Étapes Dynamique
  // ===================================
  List<String> get _orderedStepIds {
    final steps = <String>[];
    steps.add(_kStepInfos);
    
    // Condition : On ajoute cette étape uniquement si _needsOptions est vrai
    if (_needsOptions) {
      steps.add(_kStepOptions);
    }
    
    steps.add(_kStepPaiement);
    steps.add(_kStepRecap);
    return steps;
  }

  // 2. Le Dispatcher de Widgets
  // ===================================
  Widget _buildStepById(String stepId) {
    switch (stepId) {
      case _kStepInfos:
        return _buildInfosStep();
      case _kStepOptions:
        return _buildOptionsStep();
      case _kStepPaiement:
        return _buildPaiementStep();
      case _kStepRecap:
        return _buildRecapStep();
      default:
        return const SizedBox();
    }
  }

  // 3. La Navigation
  // ===================================
  void _nextStep() {
    final steps = _orderedStepIds;
    if (_currentPageIndex < steps.length - 1) {
      setState(() => _currentPageIndex++);
      _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Fin du Wizard (Soumission finale)
    }
  }

  void _previousStep() {
    if (_currentPageIndex > 0) {
      setState(() => _currentPageIndex--);
      _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 4. L'Assemblage UI
  // ===================================
  @override
  Widget build(BuildContext context) {
    final steps = _orderedStepIds;

    return Scaffold(
      body: Stack(
        children: [
          // A. Le contenu principal
          CustomScrollView(
            slivers: [
              // (Mettez ici votre AppBar et Barre de progression)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: (_currentPageIndex + 1) / steps.length,
                  ),
                ),
              ),
              
              // B. Le conteneur du Wizard
              SliverFillRemaining(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Bloque le swipe au doigt
                  children: steps.map((id) => _buildStepById(id)).toList(),
                ),
              ),
            ],
          ),
          
          // C. Les boutons de navigation fixes en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white, // Ou effet de Blur
              child: Row(
                children: [
                  if (_currentPageIndex > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: const Text('Précédent'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(_currentPageIndex == steps.length - 1 ? 'Terminer' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Déclaration factice des étapes pour l'exemple)
  Widget _buildInfosStep() => Center(child: Text("Étape Infos"));
  Widget _buildOptionsStep() => Center(child: Text("Étape Options"));
  Widget _buildPaiementStep() => Center(child: Text("Étape Paiement"));
  Widget _buildRecapStep() => Center(child: Text("Étape Récapitulatif"));
}
```

## 3. Avantages de ce modèle

- **Immunité aux désynchronisations** : L'index `_currentPageIndex` est toujours aligné sur la liste retournée par `_orderedStepIds`.
- **Ajout/Suppression d'étapes "Live"** : Si l'utilisateur clique sur un switch "J'ai besoin de l'option X" à l'étape 1, le `setState` va recalculer `_orderedStepIds`, rajoutant magiquement la page "Options" au `PageView`. Les boutons Précédent/Suivant s'adapteront tout seuls.
- **Réutilisable** : Cette logique peut être extraite ou recréée facilement pour n'importe quel formulaire long (panier e-commerce, création de profil, onboarding complexe).
- **Adaptatif** : Parce qu'il utilise `CustomScrollView` et `SliverFillRemaining`, chaque étape peut avoir sa propre hauteur scrollable (en wrapant le contenu de l'étape dans un `SingleChildScrollView` avec un grand padding en bas pour ne pas cacher le contenu derrière les boutons flottants).
