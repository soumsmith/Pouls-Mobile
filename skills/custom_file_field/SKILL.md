---
name: custom-file-field
description: Implémentation et utilisation du champ permettant l'upload et la sélection de pièces jointes (CustomFileField).
tags: [flutter, widget, form, file-picker, upload]
---

# Custom File Field Skill

Ce "skill" explique comment utiliser le composant `CustomFileField` pour offrir aux utilisateurs une interface esthétique et uniforme pour ajouter des pièces jointes (images, PDF, documents) dans les formulaires.

## 1. Fonctionnement Général

Le widget `CustomFileField` n'ouvre pas *directement* la galerie ou l'explorateur de fichiers par lui-même. C'est un composant purement visuel (UI) qui expose une méthode `onTap`.
- Il affiche un état "vide" (bordure grise classique, texte du hint).
- Dès que vous lui passez un `fileName` (le nom du fichier sélectionné), il passe en état "sélectionné" (la bordure et l'icône de droite s'allument avec la couleur `AppColors.screenOrange`).
- Il intègre toujours une icône "cloud upload" à droite pour bien faire comprendre à l'utilisateur qu'il s'agit d'une zone de dépôt/sélection.

## 2. Exemple d'utilisation basique

Voici un exemple d'intégration utilisant la bibliothèque standard `file_picker` (que vous devez gérer dans votre contrôleur/état) branchée sur notre composant UI :

```dart
import '../widgets/custom_file_field.dart';
import 'package:flutter/material.dart';
// Note: Nécessite d'installer le package file_picker
import 'package:file_picker/file_picker.dart';

class FormulaireUpload extends StatefulWidget {
  @override
  _FormulaireUploadState createState() => _FormulaireUploadState();
}

class _FormulaireUploadState extends State<FormulaireUpload> {
  String? _selectedFileName;
  String? _selectedFilePath;

  Future<void> _pickFile() async {
    // Logique métier (ex: ouvrir le file picker)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc'],

      //type: FileType.any, // Permet de sélectionner tout type de fichier

    );

    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFileField(
      label: 'Pièce jointe (Optionnel)',
      hint: 'Sélectionner un fichier...',
      icon: Icons.attach_file,
      fileName: _selectedFileName, // Le composant changera de couleur si ce n'est pas null
      onTap: _pickFile, // Appelé quand l'utilisateur clique sur la zone
    );
  }
}
```

## 3. Paramètres Personnalisables

| Paramètre | Type | Description | Par défaut |
| :--- | :--- | :--- | :--- |
| `label` | `String` | Libellé au-dessus de la zone de clic. | **Requis** |
| `hint` | `String` | Texte grisé affiché quand aucun fichier n'est sélectionné. | **Requis** |
| `icon` | `IconData` | Icône affichée à l'intérieur à gauche. | **Requis** |
| `onTap` | `VoidCallback` | Fonction déclenchée au clic sur le composant (généralement pour ouvrir `FilePicker` ou `ImagePicker`). | **Requis** |
| `fileName`| `String?` | Nom du fichier sélectionné. **Si non null, le champ passe en mode "succès" (Orange)**. | `null` |

## 4. Bonnes Pratiques
- **Découplage UI / Logique** : Ne mettez jamais la logique d'upload d'API (requête HTTP multipart) dans ce composant. Laissez l'écran parent gérer le fichier physique (`File(path)`) et donnez seulement le `fileName` (String) à ce widget pour qu'il affiche le résultat.
- **Troncature automatique** : Si l'utilisateur upload un fichier avec un nom très long, le widget gère nativement le dépassement de texte avec `TextOverflow.ellipsis` (`...` à la fin).
- **Indicateur de succès visuel** : Le composant réagit visuellement (bordure orange plus épaisse) dès lors que la variable `fileName` n'est plus nulle. Assurez-vous donc de bien faire un `setState` pour lui passer la nouvelle valeur après la sélection.
