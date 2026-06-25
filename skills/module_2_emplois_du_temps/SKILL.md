---
name: module_2_emplois_du_temps
description: Règles pour la consultation des emplois du temps
---
# Spécifications Fonctionnelles - Module 2 : Consultation des emplois du temps

## Contexte
Permet la visualisation des emplois du temps pour tous les types d'utilisateurs.

## Emploi du temps d'une classe (Élèves & Parents)
- **Accès** : Restreint à la classe de l'élève concerné.
- **Affichage** : Par semaine, détaillant le créneau horaire, la matière, le nom du professeur et la salle de classe.

## Emploi du temps du professeur
- **Accès** : Le professeur voit son propre emploi du temps.
- **Affichage** : Par semaine, agrégé sur toutes les classes et établissements où il intervient. Détails : créneau horaire, classe concernée, matière et salle.

---

## Implémentation de Référence (Existante)

La fonctionnalité de consultation de l'emploi du temps pour une classe/un élève est déjà implémentée dans le projet. Pour pouvoir travailler sur ce module de manière indépendante, voici les éléments techniques complets existants :

### 1. Modèles de données (`lib/models/student_timetable.dart`)

L'emploi du temps est structuré autour d'un créneau (`StudentTimetableEntry`) et d'une réponse d'API (`StudentTimetableResponse`) qui gère le regroupement par jours.

```dart
class StudentTimetableEntry {
  final String id;
  final int jourNumber;
  final String jour; // Lundi, Mardi...
  final String heureDebut;
  final String heureFin;
  final String matiere;
  final String? professeur;
  final String? salle;
  // ... autres champs (typeCours, edtId, uid, entite, observations)

  // ... factory fromJson ...
  
  String get formattedTime => '$heureDebut - $heureFin';
}

class StudentTimetableResponse {
  final bool status;
  final List<StudentTimetableEntry> data;
  final String message;

  // ... factory fromJson ...

  /// Groupe les cours par jour et les trie chronologiquement
  Map<String, List<StudentTimetableEntry>> get coursesByDay {
    final Map<String, List<StudentTimetableEntry>> grouped = {};
    for (final entry in data) {
      if (!grouped.containsKey(entry.jour)) {
        grouped[entry.jour] = [];
      }
      grouped[entry.jour]!.add(entry);
    }
    // Tri chronologique des créneaux
    for (final dayEntries in grouped.values) {
      dayEntries.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
    }
    return grouped;
  }
}
```

### 2. Service d'Appel API (`lib/services/student_timetable_service.dart`)

Le service récupère les données via l'endpoint de l'école (Nécessite l'ID "Vie École").

```dart
class StudentTimetableService {
  final SchoolService _schoolService = SchoolService();

  Future<StudentTimetableResponse> getTimetableForStudent(String matricule) async {
    final vieEcoleId = _schoolService.schoolVieEcoleId;
    if (vieEcoleId == null) throw Exception('ID Vie École manquant');

    final url = Uri.parse(
      '\${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/emploi-du-temps-eleve/$matricule?ecole=$vieEcoleId',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return StudentTimetableResponse.fromJson(data);
    } else {
      throw Exception('Erreur HTTP \${response.statusCode}');
    }
  }
}
```

### 3. Logique d'Interface (`lib/screens/child_list_screen.dart`)

L'affichage est isolé dans un Modal (`ReusableBottomSheet`) et repose sur un `StatefulBuilder` pour mettre à jour la liste des cours de manière dynamique lors du changement de jour.

```dart
// === Variables d'état ===
StudentTimetableResponse? _timetableResponse;
bool _isLoadingTimetable = false;
bool _timetableHasError = false;
String? _selectedTimetableDay;
StateSetter? _timetableModalSetState; // setModalState isolé

// === 1. Ouverture du BottomSheet ===
void _showTimetableBottomSheet() {
  _selectedTimetableDay = "Lundi"; // (A déterminer selon date actuelle)
  
  ReusableBottomSheet.show(
    context: context,
    title: 'Emploi du temps',
    content: StatefulBuilder(
      builder: (context, setModalState) {
        _timetableModalSetState = setModalState;
        
        // Lance le chargement automatique initial
        if (_timetableResponse == null && !_isLoadingTimetable && !_timetableHasError) {
          _loadTimetableData(); // Met à jour l'état via _timetableModalSetState
        }

        return _buildDynamicTimetable(); 
      },
    ),
  );
}

// === 2. Construction de la vue ===
Widget _buildDynamicTimetable() {
  // Gestion des états
  if (_isLoadingTimetable) return const CustomLoader(message: 'Chargement...');
  if (_timetableHasError) return _buildErrorWidget(onRetry: _loadTimetableData);
  if (_timetableResponse == null || _timetableResponse!.data.isEmpty) return _buildEmptyWidget();

  final coursesByDay = _timetableResponse!.coursesByDay;
  final availableDays = coursesByDay.keys.toList();
  
  // Sécurisation du jour sélectionné
  if (_selectedTimetableDay == null || !availableDays.contains(_selectedTimetableDay)) {
    _selectedTimetableDay = availableDays.first;
  }

  return Column(
    children: [
      // Onglets Horizontaux des jours
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: availableDays.map((day) {
            final isSelected = day == _selectedTimetableDay;
            return GestureDetector(
              onTap: () {
                _timetableModalSetState?.call(() {
                  _selectedTimetableDay = day; // Met à jour le modal!
                });
              },
              child: Container(
                /* Design du bouton: Surligné si isSelected, normal sinon */
                child: Text(day),
              ),
            );
          }).toList(),
        ),
      ),
      
      // Liste des cours pour le jour actif
      ...coursesByDay[_selectedTimetableDay]!.map((course) {
        return Card(
          child: ListTile(
            title: Text(course.matiere),
            subtitle: Text('\${course.professeur} - Salle: \${course.salle}'),
            trailing: Text(course.formattedTime),
          ),
        );
      }).toList(),
    ],
  );
}
```
