import '../services/school_service.dart';

/// Service pour gérer les détails de l'élève en utilisant les informations de l'école
class StudentDetailService {
  static final StudentDetailService _instance = StudentDetailService._internal();
  factory StudentDetailService() => _instance;
  StudentDetailService._internal();

  final SchoolService _schoolService = SchoolService();

  /// Génère les informations complètes de l'élève avec le contexte de l'école
  Map<String, dynamic> getStudentFullInfo(Map<String, dynamic> studentData) {
    final schoolData = _schoolService.getSchoolData();
    
    return {
      'student': studentData,
      'school': schoolData ?? {},
      'fullContext': {
        'studentName': '${studentData['prenom'] ?? ''} ${studentData['nom'] ?? ''}'.trim(),
        'schoolName': _schoolService.schoolName ?? 'École non définie',
        'schoolCode': _schoolService.schoolCode ?? 'N/A',
        'schoolPhone': _schoolService.schoolPhone ?? 'N/A',
        'schoolSignatory': _schoolService.schoolSignatoryName ?? 'N/A',
        'schoolId': _schoolService.schoolId ?? 0,
        'vieEcoleId': _schoolService.schoolVieEcoleId ?? 'N/A',
      }
    };
  }

  /// Génère l'en-tête pour un bulletin officiel
  String generateBulletinHeader(Map<String, dynamic> studentData) {
    return '''
${_schoolService.schoolName?.toUpperCase() ?? 'ÉCOLE'}
Code: ${_schoolService.schoolCode ?? 'N/A'} | Tel: ${_schoolService.schoolPhone ?? 'N/A'}
Année scolaire: ${studentData['annee']?['libelle'] ?? 'N/A'}
Classe: ${studentData['classe']?['libelle'] ?? 'N/A'} | Effectif: ${studentData['classe']?['effectif'] ?? 'N/A'}
Élève: ${studentData['eleve']?['prenom'] ?? ''} ${studentData['eleve']?['nom'] ?? ''}
Matricule: ${studentData['eleve']?['matricule'] ?? 'N/A'}
''';
  }

  /// Génère le pied de page pour un bulletin officiel
  String generateBulletinFooter() {
    return '''
Fait à ${_schoolService.schoolName ?? 'L\'établissement'}
Le ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}

${_schoolService.schoolSignatoryName ?? 'Le Directeur'}
${_schoolService.schoolSignatoryName != null ? 'Directeur' : ''}
''';
  }

  /// Vérifie si l'élève appartient à l'école actuelle
  bool isStudentFromCurrentSchool(Map<String, dynamic> studentData) {
    final studentSchoolId = studentData['classe']?['ecole']?['id'];
    return studentSchoolId == _schoolService.schoolId;
  }

  /// Génère un rapport complet de l'élève avec contexte
  Map<String, dynamic> generateStudentReport(Map<String, dynamic> bulletinData) {
    final studentInfo = getStudentFullInfo(bulletinData);
    final matieres = bulletinData['matieres'] as List<dynamic>? ?? [];
    
    // Calculer les statistiques
    int totalNotes = 0;
    double sommeMoyennes = 0.0;
    
    for (var matiere in matieres) {
      final notes = matiere['notes'] as List<dynamic>? ?? [];
      totalNotes += notes.length;
      
      if (notes.isNotEmpty) {
        double sommeNotes = 0.0;
        double totalSur = 0.0;
        
        for (var note in notes) {
          sommeNotes += note['note']?.toDouble() ?? 0.0;
          totalSur += note['sur']?.toDouble() ?? 20.0;
        }
        
        if (totalSur > 0) {
          sommeMoyennes += (sommeNotes / totalSur) * 20.0;
        }
      }
    }
    
    final moyenneGenerale = matieres.isNotEmpty ? sommeMoyennes / matieres.length : 0.0;
    
    return {
      ...studentInfo,
      'statistics': {
        'totalSubjects': matieres.length,
        'totalEvaluations': totalNotes,
        'generalAverage': moyenneGenerale.toStringAsFixed(2),
        'ranking': bulletinData['synthese']?['rang'] ?? 'N/A',
        'appreciation': bulletinData['synthese']?['appreciation'] ?? 'N/A',
      },
      'subjects': matieres.map((matiere) => {
        'name': matiere['libelle'] ?? 'Matière inconnue',
        'category': matiere['categorie'] ?? 'Non défini',
        'evaluations': (matiere['notes'] as List?)?.length ?? 0,
        'average': _calculateSubjectAverage(matiere['notes'] as List? ?? []),
        'details': matiere['notes'] ?? [],
      }).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  double _calculateSubjectAverage(List<dynamic> notes) {
    if (notes.isEmpty) return 0.0;
    
    double sommeNotes = 0.0;
    double totalSur = 0.0;
    
    for (var note in notes) {
      sommeNotes += note['note']?.toDouble() ?? 0.0;
      totalSur += note['sur']?.toDouble() ?? 20.0;
    }
    
    return totalSur > 0 ? (sommeNotes / totalSur) * 20.0 : 0.0;
  }

  /// Exporte les données de l'élève au format CSV
  String exportToCSV(Map<String, dynamic> bulletinData) {
    final report = generateStudentReport(bulletinData);
    final subjects = report['subjects'] as List<dynamic>;
    
    final csv = StringBuffer();
    
    // En-tête
    csv.writeln('École: ${_schoolService.schoolName}');
    csv.writeln('Élève: ${report['fullContext']['studentName']}');
    csv.writeln('Classe: ${bulletinData['classe']?['libelle'] ?? 'N/A'}');
    csv.writeln('Année: ${bulletinData['annee']?['libelle'] ?? 'N/A'}');
    csv.writeln('');
    
    // Tableau des matières
    csv.writeln('Matière;Catégorie;Évaluations;Moyenne');
    
    for (var subject in subjects) {
      csv.writeln('${subject['name']};${subject['category']};${subject['evaluations']};${subject['average'].toStringAsFixed(2)}');
    }
    
    csv.writeln('');
    csv.writeln('Statistiques générales');
    csv.writeln('Total matières: ${report['statistics']['totalSubjects']}');
    csv.writeln('Total évaluations: ${report['statistics']['totalEvaluations']}');
    csv.writeln('Moyenne générale: ${report['statistics']['generalAverage']}');
    csv.writeln('Rang: ${report['statistics']['ranking']}');
    csv.writeln('Appréciation: ${report['statistics']['appreciation']}');
    
    return csv.toString();
  }

  /// Pour le débogage - affiche le rapport complet
  void debugPrintStudentReport(Map<String, dynamic> bulletinData) {
    final report = generateStudentReport(bulletinData);
    
    print('═══════════════════════════════════════════════════════════');
    print('📊 RAPPORT COMPLET DE L\'ÉLÈVE');
    print('═══════════════════════════════════════════════════════════');
    print('École: ${report['fullContext']['schoolName']}');
    print('Élève: ${report['fullContext']['studentName']}');
    print('Classe: ${bulletinData['classe']?['libelle'] ?? 'N/A'}');
    print('');
    print('📈 Statistiques:');
    print('   Matières: ${report['statistics']['totalSubjects']}');
    print('   Évaluations: ${report['statistics']['totalEvaluations']}');
    print('   Moyenne: ${report['statistics']['generalAverage']}');
    print('   Rang: ${report['statistics']['ranking']}');
    print('   Appréciation: ${report['statistics']['appreciation']}');
    print('═══════════════════════════════════════════════════════════');
  }
}
