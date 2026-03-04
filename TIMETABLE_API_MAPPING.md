# 🔄 StudentTimetableService - Mise à jour du mapping API

## 📋 Description

Le service d'emploi du temps a été mis à jour pour correspondre aux **vrais champs de l'API** retournés par `https://api2.vie-ecoles.com/api/vie-ecoles/emploi-du-temps-eleve/`.

## 🔍 Ancien vs Nouveau mapping

### ❌ Ancien modèle (incorrect)
```dart
// Attendait ces champs (inexistant dans l'API)
{
  "id": "123",
  "jour": "Lundi", 
  "heure_debut": "08:15",
  "heure_fin": "09:10",
  "matiere": "Mathématiques",
  "professeur": "M. Dupont",
  "salle": "S101",
  "type_cours": "CM"
}
```

### ✅ Nouveau modèle (correct)
```dart
// Champs réels retournés par l'API
{
  "edt_id": 627,
  "uid": "EDTdb6d070f-3ff9-4533-a506-9fe92501ebc6",
  "type": 1,
  "horaire_id": 2,
  "jour": 1,              // Numérique (1=Lundi, 2=Mardi...)
  "hdebut": "08:15:00",
  "hfin": "09:10:00", 
  "entite": "4EMEA-2025-2026",
  "valeur": "TICE",        // Nom de la matière
  "observations": ""
}
```

## 🎯 Changements dans StudentTimetableEntry

### 📝 Nouveaux champs ajoutés
```dart
class StudentTimetableEntry {
  final String id;              // edt_id
  final int jourNumber;          // jour (numérique)
  final String jour;             // Nom du jour (Lundi, Mardi...)
  final String heureDebut;        // hdebut
  final String heureFin;          // hfin
  final String matiere;           // valeur
  final String? professeur;       // Non fourni par l'API
  final String? salle;           // Non fourni par l'API
  final String? typeCours;       // Non fourni par l'API
  final String? edtId;           // edt_id
  final String? uid;             // uid
  final String? entite;          // entite
  final String? observations;     // observations
}
```

### 🔄 Méthodes mises à jour

#### fromJson()
```dart
factory StudentTimetableEntry.fromJson(Map<String, dynamic> json) {
  return StudentTimetableEntry(
    id: json['edt_id']?.toString() ?? '',        // ✅ edt_id
    jourNumber: json['jour'] as int? ?? 1,          // ✅ jour (numérique)
    jour: _getDayName(json['jour'] as int? ?? 1), // ✅ Conversion en nom
    heureDebut: json['hdebut']?.toString() ?? '',     // ✅ hdebut
    heureFin: json['hfin']?.toString() ?? '',         // ✅ hfin
    matiere: json['valeur']?.toString() ?? '',        // ✅ valeur
    professeur: json['professeur']?.toString(),        // ⚠️ Non fourni
    salle: json['salle']?.toString(),                // ⚠️ Non fourni
    typeCours: json['type_cours']?.toString(),        // ⚠️ Non fourni
    edtId: json['edt_id']?.toString(),
    uid: json['uid']?.toString(),
    entite: json['entite']?.toString(),
    observations: json['observations']?.toString(),
  );
}
```

#### _getDayName()
```dart
static String _getDayName(int jourNumber) {
  switch (jourNumber) {
    case 1: return 'Lundi';     // ✅ 1 = Lundi
    case 2: return 'Mardi';     // ✅ 2 = Mardi
    case 3: return 'Mercredi';  // ✅ 3 = Mercredi
    case 4: return 'Jeudi';     // ✅ 4 = Jeudi
    case 5: return 'Vendredi';  // ✅ 5 = Vendredi
    case 6: return 'Samedi';     // ✅ 6 = Samedi
    case 7: return 'Dimanche';   // ✅ 7 = Dimanche
    default: return 'Lundi';
  }
}
```

## 📊 Exemples de données reçues

### 🎓 Exemple concret
```json
{
  "edt_id": 627,
  "uid": "EDTdb6d070f-3ff9-4533-a506-9fe92501ebc6",
  "type": 1,
  "horaire_id": 2,
  "jour": 1,                    // Lundi
  "hdebut": "08:15:00",
  "hfin": "09:10:00",
  "entite": "4EMEA-2025-2026",
  "valeur": "TICE",             // Matière : TICE
  "observations": ""
}
```

### 📚 Matières disponibles
D'après les données de l'API :
- **TICE** (Technologies de l'Information et de la Communication)
- **FR** (Français)
- **ARABE** (Arabe)
- **EDHC** (Éducation à la Citoyenneté et aux Droits Humains)
- **ALL** (Allemand)
- **ANG** (Anglais)
- **MATH** (Mathématiques)
- **MEMO** (Mémoire)
- **SVT** (Sciences de la Vie et de la Terre)
- **PC** (Physique-Chimie)
- **FIQ** (Français Islamique)
- **HG** (Histoire-Géographie)
- **ARTS-VIS** (Arts Visuels)
- **AL-AQIDAH** (Arabe - Éducation Islamique)
- **AS-SIRAH** (Arabe - Éducation Islamique)

## 🔧 Logging amélioré

Le service affiche maintenant les vrais champs :
```
🔍 Premier créneau (pour débogage):
   edt_id: 627 (int)
   uid: EDTdb6d070f-3ff9-4533-a506-9fe92501ebc6 (String)
   type: 1 (int)
   horaire_id: 2 (int)
   jour: 1 (int)
   hdebut: 08:15:00 (String)
   hfin: 09:10:00 (String)
   entite: 4EMEA-2025-2026 (String)
   valeur: TICE (String)
   observations:  (String)
```

## 🎯 Avantages des changements

### ✅ **Correspondance exacte avec l'API**
- Plus d'erreurs de parsing
- Mapping correct des champs
- Gestion des types appropriés

### 📅 **Gestion des jours améliorée**
- Jour numérique (1-7) directement utilisable
- Conversion automatique en nom de jour
- Support complet de la semaine

### 🏫 **Intégration avec SchoolService**
- Utilisation automatique de l'ID Vie École
- Plus besoin de passer le code école
- Centralisation des données

### 🔍 **Débogage facilité**
- Logging détaillé des vrais champs
- Types affichés pour chaque valeur
- Identification rapide des problèmes

## 🚀 Résultat

L'emploi du temps utilise maintenant :
- ✅ **Vrais champs API** : `edt_id`, `jour`, `hdebut`, `hfin`, `valeur`
- ✅ **ID Vie École** : `hinneh` au lieu du code école
- ✅ **Mapping correct** : Conversion numérique → nom des jours
- ✅ **Logging détaillé** : Affiche les vrais champs reçus

Plus d'erreurs `type 'int' is not a subtype of type 'String?'` ! 🎉
