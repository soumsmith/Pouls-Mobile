import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/matiere.dart';
import '../models/periode.dart';
import '../models/annee_scolaire.dart';
import '../models/note_api.dart';
import '../services/api_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../app.dart';
import '../widgets/custom_card.dart';
import '../widgets/searchable_dropdown.dart';

/// Écran d'affichage des notes
class NotesScreen extends StatefulWidget {
  final String childId;

  const NotesScreen({
    super.key,
    required this.childId,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<SubjectAverage> _allSubjectAverages = [];
  List<SubjectAverage> _filteredSubjectAverages = [];
  GlobalAverage? _globalAverage;
  bool _isLoading = true;
  bool _isLoadingNotes = false; // État séparé pour le chargement des notes
  String? _selectedSubject;
  String? _selectedTrimester;
  String? _selectedYear;
  String? _expandedSubjectId; // Pour gérer l'expansion des cards
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  // Données chargées depuis les API
  List<Matiere> _matieres = [];
  List<Periode> _periodes = [];
  List<String> _trimestersList = ['Tous']; // Cache pour éviter les recalculs
  AnneeScolaire? _anneeScolaire;
  
  // Informations de l'enfant
  int? _ecoleId;
  int? _classeId;
  String? _matricule;
  int? _anneeId;
  
  // Notes chargées depuis l'API
  Map<String, List<NoteApi>> _notesByMatiere = {}; // matiereId (string) -> liste de notes
  
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Charge les données initiales : informations de l'enfant, matières, périodes, année scolaire
  Future<void> _loadInitialData() async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('👁️  CLIC SUR "VOIR PLUS" - CHARGEMENT DE L\'ÉCRAN DES NOTES');
    print('═══════════════════════════════════════════════════════════');
    print('🆔 Child ID: ${widget.childId}');
    print('');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les informations de l'enfant depuis la base de données
      print('📂 Récupération des informations de l\'enfant depuis la base de données...');
      final childInfo = await DatabaseService.instance.getChildInfoById(widget.childId);
      
      if (childInfo == null) {
        throw Exception('Enfant non trouvé dans la base de données');
      }

      _ecoleId = childInfo['ecoleId'] as int?;
      _classeId = childInfo['classeId'] as int?;
      _matricule = childInfo['matricule'] as String?;

      

      print('✅ Informations de l\'élève récupérées depuis la base de données:');
      print('   🏫 École ID: $_ecoleId');
      print('   📚 Classe ID (classeid): $_classeId');
      print('   🎫 Matricule: $_matricule');

      if (_ecoleId == null || _classeId == null || _matricule == null) {
        throw Exception('Informations d\'école, de classe ou matricule manquantes pour cet enfant');
      }
      
      if (_classeId == 0 || _classeId == 1) {
        print('⚠️ ATTENTION: classeId semble incorrect: $_classeId');
        print('⚠️ Vérifiez que classeid est correctement sauvegardé dans la base de données');
        print('');
      }

      // Charger les périodes, année scolaire et matières de manière indépendante
      print('🔄 Chargement des périodes, année scolaire et matières...');
      print('   📚 Les matières seront chargées indépendamment des notes');
      print('');
      
      final results = await Future.wait([
        _poulsApiService.getAllPeriodes(),
        _poulsApiService.getAnneeScolaireOuverte(_ecoleId!),
        _poulsApiService.getMatieresByEcoleAndClasse(_ecoleId!, _classeId!),
      ]);

      final periodes = results[0] as List<Periode>;
      final anneeScolaire = results[1] as AnneeScolaire;
      final matieres = results[2] as List<Matiere>;

      // Calculer la liste des trimestres après avoir récupéré les périodes
      final trimestersList = <String>['Tous'];
      if (periodes.isNotEmpty) {
        final periodesSorted = List<Periode>.from(periodes);
        periodesSorted.sort((a, b) {
          final niveauCompare = a.niveau.compareTo(b.niveau);
          if (niveauCompare != 0) return niveauCompare;
          return a.libelle.compareTo(b.libelle);
        });
        for (final periode in periodesSorted) {
          trimestersList.add(periode.libelle);
        }
        print('📅 Périodes triées: ${periodesSorted.length}');
        for (final p in periodesSorted) {
          print('   - ID: ${p.id}, Libellé: ${p.libelle}, Niveau: ${p.niveau}');
        }
      }
      
      setState(() {
        _matieres = matieres; // Matières chargées indépendamment
        _periodes = periodes;
        _trimestersList = trimestersList;
        _anneeScolaire = anneeScolaire;
      });
      
      print('✅ Données chargées:');
      print('   📚 Matières: ${_matieres.length} (chargées indépendamment)');
      print('   📅 Périodes: ${_periodes.length}');
      print('   📆 Trimestres: ${_trimestersList.length}');
      print('   📆 Année scolaire: ${_anneeScolaire != null ? "Oui" : "Non"}');
      print('');
      
      // Récupérer l'ID de l'année scolaire ouverte et définir l'année par défaut
      if (_anneeScolaire != null && _anneeScolaire!.anneeEcoleList.isNotEmpty) {
        _anneeId = _anneeScolaire!.anneeOuverteCentraleId;
        
        // Trouver l'année ouverte et la sélectionner par défaut
        final anneeOuverte = _anneeScolaire!.anneeEcoleList.firstWhere(
          (a) => a.statut == 'OUVERTE',
          orElse: () => _anneeScolaire!.anneeEcoleList.first,
        );
        _selectedYear = anneeOuverte.anneeLibelle;
        print('📅 Année sélectionnée: $_selectedYear (ID: $_anneeId)');
      }

      // Initialiser les sélections par défaut
      _selectedSubject = null; // 'Toutes' sera affiché dans le dropdown
      if (_trimestersList.isNotEmpty) {
        _selectedTrimester = null; // 'Tous' sera affiché dans le dropdown
        print('📆 Trimestres disponibles: ${_trimestersList.length}');
        print('   Liste: ${_trimestersList.join(", ")}');
      } else {
        print('⚠️ Aucun trimestre disponible');
      }
      
      print('📚 Matières: ${_matieres.length} (chargées indépendamment)');
      print('');

      setState(() {
        _isLoading = false;
      });
      
      print('✅ État de chargement terminé (_isLoading = false)');
      print('');

      // Charger les notes maintenant que les données sont prêtes
      try {
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des notes: $e', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14))),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement initial: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14))),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadData({String? trimester, String? year}) async {
    if (_ecoleId == null || _classeId == null || _matricule == null || _anneeId == null) {
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('⚠️  IMPOSSIBLE DE CHARGER LES NOTES');
      print('═══════════════════════════════════════════════════════════');
      print('   - ecoleId: $_ecoleId');
      print('   - classeId: $_classeId');
      print('   - matricule: ${_matricule ?? "null"}');
      print('   - anneeId: $_anneeId');
      print('═══════════════════════════════════════════════════════════');
      print('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible de charger les notes: informations élève incomplètes',
              style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14)),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNotes = true;
      });
    }

    try {
      // Récupérer l'ID de la période sélectionnée (dynamique selon la sélection)
      // Par défaut, utiliser l'ID 1 si aucune période n'est sélectionnée
      int? periodeId;
      String periodeLibelle = '';
      if (trimester != null && trimester != 'Tous') {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == trimester,
          orElse: () => _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.first,
          ),
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } else if (_selectedTrimester != null && _selectedTrimester != 'Tous') {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == _selectedTrimester,
          orElse: () => _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.first,
          ),
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } else {
        // Par défaut, utiliser l'ID 1
        try {
          final defaultPeriode = _periodes.firstWhere(
            (p) => p.id == 1,
            orElse: () => _periodes.isNotEmpty ? _periodes.first : throw Exception('Aucune période disponible'),
          );
          periodeId = defaultPeriode.id;
          periodeLibelle = defaultPeriode.libelle;
        } catch (e) {
          // Si l'ID 1 n'existe pas, prendre la première période disponible
          if (_periodes.isNotEmpty) {
            periodeId = _periodes.first.id;
            periodeLibelle = _periodes.first.libelle;
          }
        }
      }

      if (periodeId == null) {
        throw Exception('Aucune période disponible');
      }
      
      print('');
      print('📆 Période sélectionnée pour charger les notes:');
      print('   - ID: $periodeId');
      print('   - Libellé: $periodeLibelle');
      print('');

      // Récupérer le libellé de la matière sélectionnée pour le filtrage côté client
      // On charge toutes les notes et on filtre côté client pour plus de simplicité
      String? selectedMatiereLibelle;
      if (_selectedSubject != null && _selectedSubject!.isNotEmpty && _selectedSubject != 'Toutes') {
        selectedMatiereLibelle = _selectedSubject;
        print('🔍 Filtrage par matière: $selectedMatiereLibelle');
      }

      // Charger toutes les notes depuis l'API (filtrage côté client)
      final notesResult = await _poulsApiService.getNotesByEleveMatricule(
        _anneeId!,
        _classeId!,
        periodeId,
        _matricule!,
      );

      final notes = notesResult.notes;
      
      print('📥 Notes reçues de l\'API:');
      print('   📝 Nombre de notes: ${notes.length}');
      print('   📊 Moyenne globale: ${notesResult.moyenneGlobale ?? "N/A"}');
      print('   🏆 Rang global: ${notesResult.rangGlobal ?? "N/A"}');
      if (notes.isEmpty) {
        print('⚠️ ATTENTION: Aucune note retournée par l\'API');
        print('   Vérifiez les paramètres:');
        print('      - Année ID: $_anneeId');
        print('      - Classe ID: $_classeId');
        print('      - Période ID: $periodeId');
        print('      - Matricule: $_matricule');
      }
      print('');

      // Organiser les notes par matière (utiliser les matières déjà chargées)
      final Map<String, List<NoteApi>> notesByMatiere = {};
      final Map<String, double?> moyennesParMatiere = {}; // Stocker les moyennes depuis l'API
      final Map<String, int?> rangsParMatiere = {}; // Stocker les rangs depuis l'API
      final Map<String, double?> coefsParMatiere = {}; // Stocker les coefficients depuis l'API
      
      print('📊 Organisation des notes par matière:');
      print('   📝 Nombre total de notes: ${notes.length}');
      
      for (final note in notes) {
        if (note.matiereLibelle != null && note.matiereLibelle!.isNotEmpty) {
          final matiereLibelle = note.matiereLibelle!;
          notesByMatiere.putIfAbsent(matiereLibelle, () => []).add(note);
          
          // Stocker la moyenne, le rang et le coefficient depuis l'API (ils sont identiques pour toutes les notes d'une matière)
          if (note.moyenne != null) {
            moyennesParMatiere[matiereLibelle] = note.moyenne;
          }
          if (note.rang != null) {
            rangsParMatiere[matiereLibelle] = note.rang;
          }
          if (note.coef != null) {
            coefsParMatiere[matiereLibelle] = note.coef;
          }
        }
      }
      
      print('   📚 Matières trouvées dans les notes: ${notesByMatiere.keys.length}');
      for (final libelle in notesByMatiere.keys) {
        print('      - $libelle: ${notesByMatiere[libelle]!.length} note(s)');
      }
      print('');

      // Trier les notes par date pour chaque matière
      for (final matiereId in notesByMatiere.keys) {
        notesByMatiere[matiereId]!.sort((a, b) {
          if (a.dateNote == null || b.dateNote == null) return 0;
          try {
            // Parser les dates pour une comparaison correcte
            final dateA = NoteApi.parseDate(a.dateNote);
            final dateB = NoteApi.parseDate(b.dateNote);
            if (dateA == null || dateB == null) {
              // Fallback: comparaison de strings si le parsing échoue
              return a.dateNote!.compareTo(b.dateNote!);
            }
            return dateA.compareTo(dateB);
          } catch (e) {
            // Fallback: comparaison de strings en cas d'erreur
            return a.dateNote!.compareTo(b.dateNote!);
          }
        });
      }

      // Convertir en SubjectAverage pour compatibilité
      // Utiliser les matières déjà chargées indépendamment
      final List<SubjectAverage> averages = [];
      print('🔄 Conversion en SubjectAverage:');
      print('   📚 Matières chargées indépendamment: ${_matieres.length}');
      
      for (final matiere in _matieres) {
        // Chercher les notes par libellé de matière
        final matiereNotes = notesByMatiere[matiere.libelle] ?? [];
        
        // Si une matière spécifique est sélectionnée, ignorer les autres
        if (selectedMatiereLibelle != null && matiere.libelle != selectedMatiereLibelle) {
          continue;
        }

        // Inclure la matière uniquement si elle a des notes
        if (matiereNotes.isNotEmpty) {
          // Utiliser la moyenne depuis l'API, sinon calculer
          double moyenne = moyennesParMatiere[matiere.libelle] ?? 0.0;
          if (moyenne == 0.0 && matiereNotes.isNotEmpty) {
            // Fallback: calculer si non disponible dans l'API
            final sum = matiereNotes.fold<double>(0.0, (sum, note) => sum + (note.note ?? 0.0));
            moyenne = sum / matiereNotes.length;
          }
          
          // Utiliser le coefficient depuis l'API, sinon depuis la matière
          double coef = coefsParMatiere[matiere.libelle] ?? 
                       (matiere.coef != null ? (matiere.coef as num).toDouble() : 1.0);
          
          // Utiliser le rang depuis l'API
          int? rang = rangsParMatiere[matiere.libelle];
          
          // Récupérer le matiereId depuis les notes pour la base de données
          int? dbMatiereId = matiere.id;
          if (matiereNotes.isNotEmpty && matiereNotes.first.matiereId != null) {
            dbMatiereId = matiereNotes.first.matiereId;
          }

          // Vérifier si la note a été consultée
          final viewed = await DatabaseService.instance.isNoteViewed(
            widget.childId,
            dbMatiereId ?? matiere.id,
            periodeId,
            _anneeId!,
          );

          print('   ✅ ${matiere.libelle}: ${matiereNotes.length} note(s), moyenne: $moyenne, rang: ${rang ?? "N/A"}');

          // Convertir les notes et numéroter selon les dates d'évaluation
          final notesList = matiereNotes.map((n) => n.toNote(widget.childId)).toList();
          
          // Trier les notes par date pour la numérotation
          notesList.sort((a, b) => a.date.compareTo(b.date));
          
          // Numéroter les notes selon leur ordre chronologique (N°1, N°2, etc.)
          for (int i = 0; i < notesList.length; i++) {
            notesList[i] = Note(
              id: notesList[i].id,
              childId: notesList[i].childId,
              subject: notesList[i].subject,
              grade: notesList[i].grade,
              coefficient: notesList[i].coefficient,
              date: notesList[i].date,
              assignmentNumber: 'N°${i + 1}', // Numérotation basée sur l'ordre chronologique
              average: notesList[i].average,
              rank: notesList[i].rank,
              totalStudents: notesList[i].totalStudents,
              mention: notesList[i].mention,
              noteSur: notesList[i].noteSur,
            );
          }

          averages.add(SubjectAverage(
            subject: matiere.libelle,
            notes: notesList,
            average: moyenne,
            coefficient: coef,
            weightedAverage: moyenne * coef,
            rank: rang,
            totalStudents: matiereNotes.isNotEmpty ? matiereNotes.first.effectif : null,
            viewed: viewed,
          ));
        }
      }
      
      print('   📊 Total de SubjectAverage créés: ${averages.length}');
      if (averages.isEmpty && notes.isNotEmpty) {
        print('⚠️ ATTENTION: Des notes ont été chargées mais aucun SubjectAverage n\'a été créé');
        print('   Cela peut indiquer un problème de correspondance entre les matières chargées et les notes');
      }
      print('');

      // Trier par moyenne pondérée décroissante
      averages.sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage));

      if (mounted) {
        setState(() {
          _notesByMatiere = notesByMatiere;
          _allSubjectAverages = averages;
          _filteredSubjectAverages = List.from(averages);
          _isLoadingNotes = false;
          _isLoading = false; // S'assurer que le chargement est terminé
        });
        print('✅ État mis à jour:');
        print('   📊 _allSubjectAverages: ${_allSubjectAverages.length}');
        print('   🔍 _filteredSubjectAverages: ${_filteredSubjectAverages.length}');
        print('   📚 _matieres: ${_matieres.length}');
        print('   ⏳ _isLoading: $_isLoading');
        print('   ⏳ _isLoadingNotes: $_isLoadingNotes');
        print('');
      }

      // Utiliser les moyennes globales depuis l'API
      if (mounted) {
        final globalMoyenne = notesResult.moyenneGlobale ?? 0.0;
        final globalRang = notesResult.rangGlobal ?? 0;

        setState(() {
          _globalAverage = GlobalAverage(
            trimesterAverage: globalMoyenne,
            trimesterRank: globalRang,
            trimesterMention: _getMention(globalMoyenne),
            annualAverage: 0.0, // Non disponible
            annualRank: 0,
            annualMention: '',
          );
        });
      }

      if (mounted) {
        _applyFilters();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des notes: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des notes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _getMention(double moyenne) {
    if (moyenne >= 16) return 'Très Bien';
    if (moyenne >= 14) return 'Bien';
    if (moyenne >= 12) return 'Assez Bien';
    if (moyenne >= 10) return 'Passable';
    return 'Insuffisant';
  }

  /// Récupère la liste des trimestres depuis les périodes (utilise le cache)
  List<String> get _trimesters => _trimestersList;

  /// Récupère la liste des années depuis l'année scolaire
  List<String> get _years {
    final list = ['Toutes'];
    if (_anneeScolaire != null) {
      for (final annee in _anneeScolaire!.anneeEcoleList) {
        list.add(annee.anneeLibelle);
      }
    }
    return list;
  }

  void _applyFilters() {
    setState(() {
      _filteredSubjectAverages = _allSubjectAverages.where((avg) {
        // Filtrer par matière si sélectionnée
        if (_selectedSubject != null && _selectedSubject!.isNotEmpty && _selectedSubject != 'Toutes') {
          return avg.subject == _selectedSubject;
        }
        return true;
      }).toList();
    });
  }

  void _onSubjectChanged(String value) {
    setState(() {
      _selectedSubject = value == 'Toutes' ? null : value;
    });
    // Recharger les données avec la nouvelle matière
    _loadData(trimester: _selectedTrimester, year: _selectedYear);
  }

  void _onTrimesterChanged(String? value) {
    setState(() {
      _selectedTrimester = value == 'Tous' ? null : value;
    });
    // Recharger les données avec le nouveau trimestre
    _loadData(trimester: _selectedTrimester, year: _selectedYear);
  }


  /// Marque une note comme consultée (Vue)
  Future<void> _markAsViewed(SubjectAverage subjectAvg) async {
    if (_ecoleId == null || _classeId == null || _anneeId == null) {
      print('⚠️ Impossible de marquer comme consulté: informations manquantes');
      return;
    }

    print('👁️  Marquage de la note comme consultée:');
    print('   📚 Matière: ${subjectAvg.subject}');

    // Trouver la matière correspondante
    Matiere? matiere;
    try {
      matiere = _matieres.firstWhere(
        (m) => m.libelle == subjectAvg.subject,
      );
      print('   🆔 Matière ID: ${matiere.id}');
    } catch (e) {
      print('❌ Matière non trouvée: ${subjectAvg.subject}');
      return;
    }

    // Récupérer l'ID de la période actuellement sélectionnée
    int? periodeId;
    String periodeLibelle = '';
    if (_selectedTrimester != null && _selectedTrimester != 'Tous') {
      try {
        final selectedPeriode = _periodes.firstWhere(
          (p) => p.libelle == _selectedTrimester,
        );
        periodeId = selectedPeriode.id;
        periodeLibelle = selectedPeriode.libelle;
      } catch (e) {
        print('⚠️ Période sélectionnée non trouvée, utilisation de la première');
        if (_periodes.isNotEmpty) {
          periodeId = _periodes.first.id;
          periodeLibelle = _periodes.first.libelle;
        }
      }
    } else if (_periodes.isNotEmpty) {
      periodeId = _periodes.first.id;
      periodeLibelle = _periodes.first.libelle;
    }

    if (periodeId == null) {
      print('❌ Aucune période disponible');
      return;
    }

    print('   📆 Période ID: $periodeId');
    print('   📆 Période: $periodeLibelle');
    print('   📅 Année ID: $_anneeId');

    // Marquer comme consulté dans la base de données
    try {
      await DatabaseService.instance.markNoteAsViewed(
        widget.childId,
        matiere.id,
        periodeId,
        _anneeId!,
      );
      print('✅ Note marquée comme consultée dans la base de données');
    } catch (e) {
      print('❌ Erreur lors du marquage: $e');
      return;
    }

    // Mettre à jour l'état
    setState(() {
      final index = _allSubjectAverages.indexWhere((a) => a.subject == subjectAvg.subject);
      if (index >= 0) {
        _allSubjectAverages[index] = SubjectAverage(
          subject: subjectAvg.subject,
          notes: subjectAvg.notes,
          average: subjectAvg.average,
          coefficient: subjectAvg.coefficient,
          weightedAverage: subjectAvg.weightedAverage,
          rank: subjectAvg.rank,
          totalStudents: subjectAvg.totalStudents,
          viewed: true,
        );
        _applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.getPureBackground(isDarkMode),
          body: _buildBody(),
        );
      },
    );
  }
  
  Widget _buildBody() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Section des filtres toujours visible
          _buildFiltersSection(),
          const SizedBox(height: 16),
          // Contenu principal
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_isLoadingNotes)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredSubjectAverages.isNotEmpty) ...[
            _buildNotesTable(),
            const SizedBox(height: 16),
          ] else if (_allSubjectAverages.isEmpty && !_isLoadingNotes) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune note disponible',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ChildId: ${widget.childId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _loadData(trimester: _selectedTrimester, year: _selectedYear),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text('Actualiser', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(12))),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucune matière ne correspond aux filtres sélectionnés',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Moyennes globales
          if (_globalAverage != null && !_isLoadingNotes) ...[
            const SizedBox(height: 16),
            _buildGlobalAverages(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.3)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune, 
                color: AppColors.primary, 
                size: 20
              ),
              const SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          // Affichage de l'année
          _buildReadOnlyField(
            label: 'Année scolaire',
            value: _selectedYear ?? 'Chargement...',
            isDarkMode: isDarkMode,
            textSizeService: _textSizeService,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'MATIÈRE',
                  value: _selectedSubject ?? 'Toutes',
                  items: ['Toutes', ..._matieres.map((m) => m.libelle)],
                  onChanged: _onSubjectChanged,
                  isDarkMode: isDarkMode,
                  isLoading: _isLoading || _matieres.isEmpty,
                  textSizeService: _textSizeService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'TRIMESTRE',
                  value: _selectedTrimester ?? 'Tous',
                  items: _trimesters,
                  onChanged: _onTrimesterChanged,
                  isDarkMode: isDarkMode,
                  isLoading: _isLoading || _trimesters.isEmpty,
                  textSizeService: _textSizeService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required bool isDarkMode,
    required TextSizeService textSizeService,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
        ),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          isDense: true,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: textSizeService.getScaledFontSize(14),
          ),
        ),
        readOnly: true,
        controller: TextEditingController(text: value),
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
          fontSize: textSizeService.getScaledFontSize(15),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required bool isDarkMode,
    bool isLoading = false,
    required TextSizeService textSizeService,
  }) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                fontSize: textSizeService.getScaledFontSize(11),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chargement...',
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                fontSize: textSizeService.getScaledFontSize(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SearchableDropdown(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildNotesTable() {
    final isDarkMode = _themeService.isDarkMode;
    
    if (_filteredSubjectAverages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message d'information intégré
          // Container(
          //   margin: const EdgeInsets.only(bottom: 16),
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     color: AppColors.getSurfaceColor(isDarkMode),
          //     borderRadius: BorderRadius.circular(16),
          //     boxShadow: [
          //       BoxShadow(
          //         color: isDarkMode 
          //             ? AppColors.black.withOpacity(0.3)
          //             : AppColors.shadowLight,
          //         blurRadius: 10,
          //         offset: const Offset(0, 2),
          //       ),
          //     ],
          //     border: Border.all(
          //       color: AppColors.primary.withOpacity(0.1),
          //       width: 1,
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         width: 40,
          //         height: 40,
          //         decoration: BoxDecoration(
          //           color: AppColors.primary.toSurface(),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: Icon(
          //           Icons.info_outline,
          //           color: AppColors.primary,
          //           size: 20,
          //         ),
          //       ),
          //       const SizedBox(width: 16),
          //       Expanded(
          //         child: Text(
          //           'Cher parents,\nMerci de vous impliquer régulièrement dans le suivi et l\'amélioration du résultat scolaire de votre enfant.',
          //           style: TextStyle(
          //             fontSize: 14,
          //             color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
          //             height: 1.5,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          
          // En-tête moderne
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Résultats par matière',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredSubjectAverages.length} matière${_filteredSubjectAverages.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Liste des matières en cards modernes
          ..._filteredSubjectAverages.asMap().entries.map((entry) {
            final index = entry.key;
            final avg = entry.value;
            return _buildModernSubjectCard(avg, index);
          }),
        ],
      ),
    );
  }

  Widget _buildModernSubjectCard(SubjectAverage avg, int index) {
    final notes = avg.notes;
    final isLast = index == _filteredSubjectAverages.length - 1;
    final isExpanded = _expandedSubjectId == avg.subject;
    final isDarkMode = _themeService.isDarkMode;
    
    // Couleur selon la moyenne
    Color averageColor = _getAverageColor(avg.average);
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedSubjectId = isExpanded ? null : avg.subject;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.02),
                blurRadius: isExpanded ? 8 : 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: averageColor.withOpacity(isExpanded ? 0.3 : 0.1),
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête compact
              Row(
                children: [
                  // Icône matière
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: averageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSubjectIcon(avg.subject),
                      color: averageColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info matière
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                avg.subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            // Icône d'expansion
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: averageColor,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${notes.length} évaluation${notes.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(12),
                            color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge moyenne
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: averageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: averageColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      avg.average.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: averageColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Section étendue (notes et statistiques)
              if (isExpanded) ...[
                const SizedBox(height: 12),
                // Séparateur
                Container(
                  height: 1,
                  color: (isDarkMode ? Colors.grey : Colors.grey).withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(height: 12),
                
                // Notes et statistiques
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Détail des notes
                    Text(
                      'Détail des notes',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        fontWeight: FontWeight.w600,
                        color: averageColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCompactNotesList(notes),
                    
                    // Statistiques sur une ligne
                    const SizedBox(height: 16),
                    Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        fontWeight: FontWeight.w600,
                        color: averageColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactStat('Coef', avg.coefficient.toStringAsFixed(1), Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactStat('Rang', avg.rank?.toString() ?? '-', Colors.purple),
                        ),
                        if (avg.totalStudents != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactStat('Effectif', avg.totalStudents.toString(), Colors.orange),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                // Bouton de consultation
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: avg.viewed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Consulté',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: _textSizeService.getScaledFontSize(12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _markAsViewed(avg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, color: Colors.orange[700], size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Marquer consulté',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: _textSizeService.getScaledFontSize(12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNotesList(List<Note> notes) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: notes.map((note) {
        final noteText = note.noteSur != null 
            ? '${note.grade.toStringAsFixed(1)}/${note.noteSur!.toStringAsFixed(0)}'
            : note.grade.toStringAsFixed(1);
            
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.assignmentNumber,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(9),
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                ),
              ),
              Text(
                noteText,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactStat(String label, String value, [Color? statColor]) {
    final isDarkMode = _themeService.isDarkMode;
    final color = statColor ?? (isDarkMode ? Colors.grey[600]! : Colors.grey[500]!);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Color _getAverageColor(double average) {
    if (average >= 16) return const Color(0xFF10B981); // Vert
    if (average >= 14) return const Color(0xFF3B82F6); // Bleu
    if (average >= 12) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }

  IconData _getSubjectIcon(String subject) {
    final lowerSubject = subject.toLowerCase();
    if (lowerSubject.contains('math')) return Icons.calculate;
    if (lowerSubject.contains('fran')) return Icons.menu_book;
    if (lowerSubject.contains('histoir')) return Icons.public;
    if (lowerSubject.contains('phys')) return Icons.science;
    if (lowerSubject.contains('angl')) return Icons.language;
    if (lowerSubject.contains('sport')) return Icons.sports_soccer;
    if (lowerSubject.contains('mus')) return Icons.music_note;
    if (lowerSubject.contains('art')) return Icons.palette;
    return Icons.school;
  }

  
  Widget _buildGlobalAverages() {
    if (_globalAverage == null) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            backgroundColor: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne Partielle Trimestrielle en Cours',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_globalAverage!.trimesterAverage.toStringAsFixed(2)} Rang ${_globalAverage!.trimesterRank}${_getOrdinalSuffix(_globalAverage!.trimesterRank)} ${_globalAverage!.trimesterMention}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_globalAverage!.trimesterAverage == 0.0)
                  Text(
                    'Aucune note disponible',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomCard(
            backgroundColor: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moyenne Partielle Annuelle',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _globalAverage!.annualAverage > 0
                      ? '${_globalAverage!.annualAverage.toStringAsFixed(2)} Rang ${_globalAverage!.annualRank}${_getOrdinalSuffix(_globalAverage!.annualRank)} ${_globalAverage!.annualMention}'
                      : 'Non disponible',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _globalAverage!.annualAverage > 0 ? null : Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }
}