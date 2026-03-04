# 🔄 StudentTimetableService - Mise à jour avec ID Vie École

## 📋 Description

Le `StudentTimetableService` a été modifié pour utiliser automatiquement l'**ID Vie École** stocké dans le `SchoolService` au lieu de nécessiter un `ecoleCode` en paramètre.

## 🎯 Changements apportés

### 🔄 Avant (ancienne version)
```dart
// Ancienne signature - nécessitait ecoleCode
Future<StudentTimetableResponse> getTimetableForStudent(String matricule, String ecoleCode) async {
  final url = Uri.parse('https://api2.vie-ecoles.com/api/vie-ecoles/emploi-du-temps-eleve/$matricule?ecole=$ecoleCode');
  // ...
}
```

### ✅ Après (nouvelle version)
```dart
// Nouvelle signature - utilise automatiquement l'ID Vie École
Future<StudentTimetableResponse> getTimetableForStudent(String matricule) async {
  final vieEcoleId = _schoolService.schoolVieEcoleId; // "hinneh"
  final url = Uri.parse('https://api2.vie-ecoles.com/api/vie-ecoles/emploi-du-temps-eleve/$matricule?ecole=$vieEcoleId');
  // ...
}
```

## 🚀 Nouvelles fonctionnalités

### 🏫 Intégration automatique avec SchoolService
- **Chargement automatique** : Le service utilise l'ID Vie École stocké
- **Validation** : Vérifie si les données de l'école sont disponibles
- **Logging amélioré** : Affiche le nom de l'école dans les logs

### 📊 Logging détaillé
```
🔄 Début du chargement de l'emploi du temps pour l'élève: 24047355B
🏫 École: Collège Privé Hînneh Biabou (ID Vie École: hinneh)
📡 Appel API: https://api2.vie-ecoles.com/api/vie-ecoles/emploi-du-temps-eleve/24047355B?ecole=hinneh
```

## 📱 Utilisation dans les écrans

### 🔄 Avant
```dart
class StudentTimetableScreen extends StatefulWidget {
  final String ecoleCode; // Devait être passé en paramètre
  
  // ...
  
  Future<void> _loadTimetable() async {
    final entries = await _timetableService.getTimetableEntriesForStudent(
      studentMatricule, 
      ecoleCode // Paramètre requis
    );
  }
}
```

### ✅ Après
```dart
class StudentTimetableScreen extends StatefulWidget {
  // Plus besoin du paramètre ecoleCode !
  
  // ...
  
  Future<void> _loadTimetable() async {
    final entries = await _timetableService.getTimetableEntriesForStudent(
      studentMatricule // Seulement le matricule !
    );
  }
}
```

## 🔧 Méthodes modifiées

Toutes les méthodes du service ont été mises à jour :

| Ancienne signature | Nouvelle signature |
|-------------------|-------------------|
| `getTimetableForStudent(matricule, ecoleCode)` | `getTimetableForStudent(matricule)` |
| `getTimetableEntriesForStudent(matricule, ecoleCode)` | `getTimetableEntriesForStudent(matricule)` |
| `hasCoursesToday(matricule, ecoleCode)` | `hasCoursesToday(matricule)` |
| `getTodayCourses(matricule, ecoleCode)` | `getTodayCourses(matricule)` |

## 🎯 Avantages

### ✅ **Simplification du code**
- Plus besoin de passer `ecoleCode` partout
- Moins de paramètres à gérer
- Code plus clair et maintenable

### 🏫 **Centralisation des données**
- Un seul point de vérité : `SchoolService`
- Mise à jour automatique si l'école change
- Cohérence garantie dans toute l'application

### 🔒 **Sécurité améliorée**
- Validation automatique de la disponibilité des données
- Messages d'erreur clairs si l'école n'est pas chargée
- Gestion centralisée des erreurs

### 📊 **Logging enrichi**
- Affichage du nom de l'école dans les logs
- Traçabilité améliorée des appels API
- Débogage facilité

## 🚨 Gestion d'erreur

Le service vérifie automatiquement si l'ID Vie École est disponible :

```dart
if (vieEcoleId == null) {
  print('❌ ID Vie École non disponible. Veuillez charger les données de l\'école d\'abord.');
  throw Exception('ID Vie École non disponible. Chargez les données de l\'école d\'abord.');
}
```

## 📋 Prérequis

Pour que le service fonctionne correctement :

1. **Charger les données de l'école** d'abord :
   ```dart
   final schoolService = SchoolService();
   await schoolService.loadSchoolData();
   ```

2. **Vérifier la disponibilité** :
   ```dart
   if (schoolService.isSchoolDataLoaded) {
     // Utiliser le service d'emploi du temps
   }
   ```

## 🔄 Migration guide

### Étape 1 : Mettre à jour les appels de service
```dart
// Ancien code
final entries = await _timetableService.getTimetableEntriesForStudent(matricule, ecoleCode);

// Nouveau code
final entries = await _timetableService.getTimetableEntriesForStudent(matricule);
```

### Étape 2 : Supprimer les paramètres ecoleCode
```dart
// Ancien widget
class MyScreen extends StatefulWidget {
  final String ecoleCode; // À supprimer
  
  // ...
}

// Nouveau widget
class MyScreen extends StatefulWidget {
  // Plus besoin de ecoleCode
  
  // ...
}
```

### Étape 3 : Ajouter le chargement des données de l'école
```dart
@override
void initState() {
  super.initState();
  _loadSchoolData(); // Ajouter cette ligne
  _loadTimetable();
}

Future<void> _loadSchoolData() async {
  final schoolService = SchoolService();
  await schoolService.loadSchoolData();
}
```

## 🎉 Résultat

Avec cette mise à jour :

- ✅ **Code plus simple** : Moins de paramètres à passer
- ✅ **Centralisation** : Toutes les données de l'école au même endroit
- ✅ **Cohérence** : Tous les services utilisent le même identifiant
- ✅ **Logging amélioré** : Plus de contexte dans les logs
- ✅ **Sécurité** : Validation automatique des données

L'API utilise maintenant automatiquement **"hinneh"** comme ID Vie École, extrait dynamiquement des données JSON de l'école ! 🚀
