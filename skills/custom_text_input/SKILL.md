---
name: custom-text-input
description: Implémentation et utilisation du champ de saisie de texte standard (CustomTextInput).
tags: [flutter, widget, form, text-input]
---

# Custom Text Input Skill

Ce "skill" explique l'utilisation de `CustomTextInput`, le composant de base recommandé pour la saisie de texte libre, d'emails ou de chiffres dans vos formulaires. Il encapsule intelligemment le `CustomTextField` pour garantir une uniformité visuelle (notamment via la palette `AppColors`).

## 1. Fonctionnement Général

Le widget `CustomTextInput` est une enveloppe (wrapper) légère qui :
- Force par défaut les couleurs sur `AppColors.shopBlue` pour l'icône et la bordure active (ce qui maintient une cohérence UI sans effort).
- Permet de gérer la saisie multiligne grâce au paramètre `maxLines`.
- Prend en charge la gestion du clavier (texte classique, email, numérique) via `keyboardType`.
- Permet le mode "lecture seule" (`readOnly`), idéal pour des champs informatifs ou cliquables (pour ouvrir un modal par exemple).

## 2. Exemple d'utilisation basique

Voici comment intégrer ce champ dans un formulaire :

```dart
import '../widgets/components/custom_text_input.dart';
import 'package:flutter/material.dart';

class FormulaireBasique extends StatefulWidget {
  @override
  _FormulaireBasiqueState createState() => _FormulaireBasiqueState();
}

class _FormulaireBasiqueState extends State<FormulaireBasique> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Saisie de texte classique
        CustomTextInput(
          label: 'Nom complet',
          hint: 'Entrez votre nom',
          icon: Icons.person_outline,
          controller: _nomController,
          required: true,
        ),
        const SizedBox(height: 16),
        // Saisie d'email
        CustomTextInput(
          label: 'Adresse e-mail',
          hint: 'exemple@mail.com',
          icon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
```

## 3. Paramètres Personnalisables

Voici la liste des paramètres disponibles pour ce widget :

| Paramètre | Type | Description | Par défaut |
| :--- | :--- | :--- | :--- |
| `label` | `String` | Libellé au-dessus du champ. | **Requis** |
| `hint` | `String` | Placeholder affiché quand le champ est vide. | **Requis** |
| `icon` | `IconData` | Icône affichée à l'intérieur à gauche. | **Requis** |
| `controller` | `TextEditingController` | Contrôleur du texte. | **Requis** |
| `iconColor` | `Color?` | Couleur de l'icône gauche. | `AppColors.shopBlue` |
| `focusBorderColor`| `Color?` | Couleur de la bordure quand le champ a le focus. | `AppColors.shopBlue` |
| `hasError` | `bool` | Affiche une bordure rouge d'erreur si `true`. | `false` |
| `required` | `bool` | Ajoute un `*` rouge à côté du label. | `false` |
| `keyboardType` | `TextInputType?` | Type de clavier (ex: `TextInputType.number`). | `TextInputType.text` |
| `inputFormatters` | `List<TextInputFormatter>?`| Règles de formatage (ex: tout en majuscule). | `null` |
| `readOnly` | `bool` | Empêche la saisie au clavier. | `false` |
| `maxLines` | `int` | Nombre de lignes visibles. Augmentez pour une zone de texte. | `1` |

## 4. Bonnes Pratiques
- **Textes longs (Zone de description)** : Si vous voulez que l'utilisateur tape un paragraphe (une description, des notes), mettez `maxLines: 4` (ou plus) et `keyboardType: TextInputType.multiline`.
- **Champs de sélection simulés** : Si vous voulez utiliser l'apparence d'un champ de texte pour faire un menu de sélection qui ouvre un `BottomSheet`, mettez `readOnly: true` et enveloppez le widget dans un `GestureDetector`.
- **Couleurs au thème** : Si le bleu (`shopBlue`) ne correspond pas à la section actuelle de l'application, pensez à surcharger `iconColor` et `focusBorderColor` avec une autre couleur de `AppColors`.
