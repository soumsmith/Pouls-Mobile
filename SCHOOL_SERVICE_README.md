# 🏫 Service de Gestion des Informations de l'École

## 📋 Description

Le `SchoolService` est un service singleton qui permet de gérer dynamiquement les informations de l'école à partir des données JSON. Il offre un accès centralisé aux informations de l'école pour toute l'application.

## 🚀 Fonctionnalités

### 📊 Chargement automatique
- Charge les données depuis `assets/services/jsonOptimise.json`
- Met en cache les données pour utilisation hors ligne
- Fallback vers le cache en cas d'erreur de chargement

### 🔧 Accès aux données
```dart
final schoolService = SchoolService();

// Informations de base
print(schoolService.schoolName);        // "Collège Privé Hînneh Biabou"
print(schoolService.schoolCode);        // "057955"
print(schoolService.schoolPhone);       // "0789353025"
print(schoolService.schoolSignatoryName); // "M.SANGARE"
print(schoolService.schoolVieEcoleId); // "hinneh"
print(schoolService.schoolId);          // 38
```

### 🔄 Mise à jour dynamique
```dart
// Mettre à jour les données de l'école
await schoolService.updateSchoolData(newSchoolData);

// Vérifier si les données sont chargées
if (schoolService.isSchoolDataLoaded) {
  // Utiliser les données
}
```

## 📱 Intégration dans les écrans

### 1. Écran de notes (`notes_screen_json.dart`)
```dart
class _NotesScreenJsonState extends State<NotesScreenJson> {
  final SchoolService _schoolService = SchoolService();
  
  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }
  
  Future<void> _loadJsonData() async {
    // Charger les données de l'école d'abord
    await _schoolService.loadSchoolData();
    // ... charger les autres données
  }
}
```

### 2. Écran de détail élève (`student_detail_screen.dart`)
```dart
class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final SchoolService _schoolService = SchoolService();
  final StudentDetailService _studentService = StudentDetailService();
  
  Widget _buildSchoolHeader(bool isDarkMode) {
    return Container(
      child: Text(_schoolService.schoolName ?? 'École non définie'),
    );
  }
}
```

## 🎯 StudentDetailService

Le `StudentDetailService` utilise le `SchoolService` pour fournir un contexte complet aux informations de l'élève :

### 📈 Génération de rapports
```dart
final studentService = StudentDetailService();
final report = studentService.generateStudentReport(bulletinData);

// Accès aux informations complètes
print(report['fullContext']['studentName']);  // "Fousseni Junior BAMBA"
print(report['fullContext']['schoolName']);   // "Collège Privé Hînneh Biabou"
print(report['statistics']['generalAverage']); // "12.78"
```

### 📄 Export et impression
```dart
// Export CSV
final csvData = studentService.exportToCSV(bulletinData);

// Génération d'en-tête de bulletin
final header = studentService.generateBulletinHeader(studentData);
final footer = studentService.generateBulletinFooter();
```

## 📁 Structure des données JSON

```json
{
  "bulletin": {
    "classe": {
      "ecole": {
        "id": 38,
        "libelle": "Collège Privé Hînneh Biabou",
        "tel": "0789353025",
        "nomSignataire": "M.SANGARE",
        "identifiantVieEcole": "hinneh",
        "code": "057955"
      }
    }
  }
}
```

## 🔧 Méthodes disponibles

### SchoolService
- `loadSchoolData()` - Charge les données depuis le JSON
- `updateSchoolData(Map<String, dynamic>)` - Met à jour manuellement
- `clearSchoolData()` - Réinitialise les données
- `getSchoolData()` - Retourne toutes les données
- `isSchool(String)` - Vérifie l'identifiant de l'école
- `debugPrintSchoolInfo()` - Affiche les infos pour débogage

### StudentDetailService
- `getStudentFullInfo(Map<String, dynamic>)` - Infos complètes élève + école
- `generateStudentReport(Map<String, dynamic>)` - Rapport complet
- `generateBulletinHeader(Map<String, dynamic>)` - En-tête bulletin
- `generateBulletinFooter()` - Pied de page bulletin
- `exportToCSV(Map<String, dynamic>)` - Export CSV
- `isStudentFromCurrentSchool(Map<String, dynamic>)` - Vérification

## 🎨 Utilisation dans l'UI

### Header d'école
```dart
Widget _buildSchoolHeader() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(_schoolService.schoolName ?? 'École non définie'),
        Text('Code: ${_schoolService.schoolCode ?? 'N/A'}'),
        Text('Tel: ${_schoolService.schoolPhone ?? 'N/A'}'),
      ],
    ),
  );
}
```

### Informations contextuelles
```dart
Widget _buildContextInfo() {
  return Row(
    children: [
      Icon(Icons.school, color: AppColors.primary),
      SizedBox(width: 8),
      Text('${_schoolService.schoolName} - ${student['classe']['libelle']}'),
    ],
  );
}
```

## 🔄 Cycle de vie

1. **Initialisation** : `SchoolService()` est un singleton
2. **Chargement** : `loadSchoolData()` au démarrage de l'app
3. **Cache** : Données sauvegardées dans `SharedPreferences`
4. **Utilisation** : Accès depuis n'importe quel écran
5. **Mise à jour** : `updateSchoolData()` si nécessaire

## 🐛 Débogage

```dart
// Afficher toutes les informations de l'école
schoolService.debugPrintSchoolInfo();

// Afficher le rapport complet d'un élève
studentService.debugPrintStudentReport(bulletinData);
```

## 📝 Bonnes pratiques

1. **Initialiser tôt** : Appeler `loadSchoolData()` au démarrage
2. **Vérifier le chargement** : Utiliser `isSchoolDataLoaded` avant l'accès
3. **Gérer les nulls** : Toujours vérifier les valeurs retournées
4. **Utiliser le cache** : Le service gère automatiquement le cache hors ligne
5. **Centraliser l'accès** : Passer toujours par le service, pas directement par JSON

## 🎯 Exemples d'utilisation

### Dans un écran existant
```dart
class SomeScreen extends StatefulWidget {
  @override
  _SomeScreenState createState() => _SomeScreenState();
}

class _SomeScreenState extends State<SomeScreen> {
  final SchoolService _schoolService = SchoolService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_schoolService.schoolName ?? 'Mon École'),
        subtitle: Text('Code: ${_schoolService.schoolCode ?? 'N/A'}'),
      ),
      body: Column(
        children: [
          if (_schoolService.isSchoolDataLoaded)
            Text('École: ${_schoolService.schoolName}')
          else
            CircularProgressIndicator(),
        ],
      ),
    );
  }
}
```

### Dans un service
```dart
class NotificationService {
  final SchoolService _schoolService = SchoolService();
  
  void sendParentNotification(Map<String, dynamic> studentData) {
    final schoolName = _schoolService.schoolName ?? 'École';
    final message = 'Nouveau bulletin disponible pour $schoolName';
    // Envoyer notification...
  }
}
```

---

## 🎉 Résultat

Avec ce système, vous avez maintenant :
- ✅ **Accès centralisé** aux informations de l'école
- ✅ **Cache automatique** pour utilisation hors ligne  
- ✅ **Contexte riche** pour les données des élèves
- ✅ **Réutilisation** dans toute l'application
- ✅ **Export et impression** avec contexte de l'école
- ✅ **Mise à jour dynamique** des informations
