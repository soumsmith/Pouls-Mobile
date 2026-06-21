---
name: custom-date-input
description: Implémentation et utilisation du champ de saisie de date avec formatage automatique (CustomDateInput).
tags: [flutter, widget, form, date-input, formatter]
---

# Custom Date Input Skill

Ce "skill" explique comment utiliser le composant `CustomDateInput` pour faciliter la saisie des dates par les utilisateurs. Ce composant intègre un formateur automatique intelligent (`DateInputFormatter`) qui ajoute automatiquement les barres obliques `/` pour obtenir un format `JJ/MM/AAAA`.

## 1. Fonctionnement Général

Le widget `CustomDateInput` encapsule un `CustomTextField` générique de l'application mais force :
- L'apparition du clavier numérique approprié (`TextInputType.datetime`).
- La possibilité d'utiliser le formateur fourni pour transformer une saisie brute (ex: `01022026`) en une date formatée (`01/02/2026`).

Le `DateInputFormatter` :
- Autorise uniquement les chiffres et les `/` (ou convertit les `-` en `/`).
- Limite la longueur maximale à 10 caractères.
- Limite intelligemment le jour à `31` et le mois à `12`.
- Limite intelligemment l'année pour empêcher de saisir une année dans le futur (ex: si l'année en cours est 2026, taper 2027 remplacera automatiquement par 2026).
- Gère correctement la suppression (Backspace) d'un caractère situé juste après un `/`.

## 2. Exemple d'utilisation basique

Voici comment intégrer le champ de saisie de date dans n'importe quel formulaire :

```dart
import '../widgets/components/custom_date_input.dart';
import 'package:flutter/material.dart';

class FormulaireDate extends StatefulWidget {
  @override
  _FormulaireDateState createState() => _FormulaireDateState();
}

class _FormulaireDateState extends State<FormulaireDate> {
  final TextEditingController _dateController = TextEditingController();
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return CustomDateInput(
      label: 'Date de naissance',
      hint: 'JJ/MM/AAAA',
      icon: Icons.calendar_today_outlined,
      controller: _dateController,
      required: true,
      hasError: _hasError,
      // Indispensable pour avoir l'auto-formatage :
      inputFormatters: [
        DateInputFormatter(),
      ],
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }
}
```

## 3. Paramètres Personnalisables

Le `CustomDateInput` accepte plusieurs paramètres pour l'adapter à vos différents écrans :

| Paramètre | Type | Description | Par défaut |
| :--- | :--- | :--- | :--- |
| `label` | `String` | Titre ou libellé au-dessus du champ. | **Requis** |
| `hint` | `String` | Texte grisé indicatif quand le champ est vide (ex: `JJ/MM/AAAA`). | **Requis** |
| `icon` | `IconData` | Icône affichée à gauche (ex: `Icons.event`). | **Requis** |
| `controller` | `TextEditingController` | Pour récupérer et définir la valeur tapée par l'utilisateur. | **Requis** |
| `iconColor` | `Color?` | La couleur de l'icône de gauche. | `AppColors.shopBlue` |
| `focusBorderColor`| `Color?` | La couleur de la bordure lorsque le champ est sélectionné. | `AppColors.shopBlue` |
| `hasError` | `bool` | Affiche le champ avec un style d'erreur rouge si mis à `true`. | `false` |
| `inputFormatters` | `List<TextInputFormatter>?` | Formateurs à appliquer (ex: `[DateInputFormatter()]`). | `null` |
| `required` | `bool` | Ajoute un astérisque rouge `*` à côté du label. | `false` |

## 4. Bonnes Pratiques
- **Validation** : Le formateur empêche de taper "45" pour un jour (il le remplace par "31"), mais il n'empêche pas de taper une date invalide mathématiquement comme le `30/02/2026`. Toujours vérifier la validité de la date côté logique métier (avec un `DateTime.tryParse()` après conversion) avant de soumettre le formulaire !
- **Suppression** : Ne retirez pas le paramètre `inputFormatters: [DateInputFormatter()]` à moins que vous ayez besoin d'un autre comportement précis, sinon l'utilisateur devra taper les barres obliques `/` manuellement.
- **Design System** : Par défaut, le champ utilise la couleur `AppColors.shopBlue`. Si vous l'utilisez sur un écran avec une autre dominante couleur (comme `AppColors.shopGreen`), n'hésitez pas à surcharger `iconColor` et `focusBorderColor`.
