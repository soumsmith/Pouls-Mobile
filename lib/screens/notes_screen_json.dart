import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../services/school_service.dart';
import '../widgets/searchable_dropdown.dart';

class NotesScreenJson extends StatefulWidget {
  const NotesScreenJson({super.key});

  @override
  State<NotesScreenJson> createState() => _NotesScreenJsonState();
}

class _NotesScreenJsonState extends State<NotesScreenJson> {
  Map<String, dynamic>? _bulletinData;
  Map<String, dynamic>? _originalBulletinData;
  bool _isLoading = true;
  String? _expandedSubjectId; // Aligné sur NotesScreen (une seule expanded à la fois)
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final SchoolService _schoolService = SchoolService();

  String? _selectedSubject;
  String? _selectedTrimester;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      // Charger les données de l'école d'abord
      await _schoolService.loadSchoolData();
      
      // Logger les informations de l'école dans la console
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🏫 INFORMATIONS DE L\'ÉCOLE CHARGÉES');
      print('═══════════════════════════════════════════════════════════');
      print('📛 Nom: ${_schoolService.schoolName ?? 'Non défini'}');
      print('🆔 ID: ${_schoolService.schoolId ?? 'Non défini'}');
      print('🔢 Code: ${_schoolService.schoolCode ?? 'Non défini'}');
      print('📞 Téléphone: ${_schoolService.schoolPhone ?? 'Non défini'}');
      print('✍️ Signataire: ${_schoolService.schoolSignatoryName ?? 'Non défini'}');
      print('🏷️ ID Vie École: ${_schoolService.schoolVieEcoleId ?? 'Non défini'}');
      print('✅ Données chargées: ${_schoolService.isSchoolDataLoaded ? 'Oui' : 'Non'}');
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      final String jsonString =
          await rootBundle.loadString('assets/services/jsonOptimise.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      setState(() {
        _originalBulletinData = data['bulletin'];
        _bulletinData = data['bulletin'];
        _selectedYear = _bulletinData!['annee']['libelle'] ?? 'Année 2025 - 2026';
        _selectedSubject = null;
        _selectedTrimester = null;
        _isLoading = false;
      });
      
      // Afficher les informations de l'élève aussi
      final eleve = _bulletinData!['eleve'];
      final classe = _bulletinData!['classe'];
      print('👤 INFORMATIONS DE L\'ÉLÈVE:');
      print('   📝 Nom complet: ${eleve['prenom']} ${eleve['nom']}');
      print('   🎫 Matricule: ${eleve['matricule']}');
      print('   📚 Classe: ${classe['libelle']}');
      print('   👥 Effectif: ${classe['effectif']}');
      print('');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      _loadTestData();
    }
  }

  void _loadTestData() {
    final Map<String, dynamic> testData = {
      "bulletin": {
        "eleve": {
          "nom": "BAMBA",
          "prenom": "Fousseni Junior",
        },
        "classe": {"libelle": "5EME A", "effectif": 46},
        "annee": {"libelle": "Année 2025 - 2026"},
        "periode": {"libelle": "Premier Trimestre"},
        "matieres": [
          {
            "id": 2027,
            "libelle": "EPS",
            "categorie": "Autres",
            "notes": [
              {"note": 16, "sur": 20, "type": "Devoir", "date": "2025-12-02"},
              {"note": 18, "sur": 20, "type": "Devoir", "date": "2025-11-25"},
              {"note": 14, "sur": 20, "type": "Devoir", "date": "2025-12-02"},
              {"note": 24, "sur": 40, "type": "Test lourd", "date": "2025-12-04"},
            ]
          },
          {
            "id": 2085,
            "libelle": "ARABE",
            "categorie": "Autres",
            "notes": [
              {"note": 7, "sur": 10, "type": "Interrogation", "date": "2025-12-03"},
              {"note": 10, "sur": 10, "type": "Interrogation", "date": "2025-12-03"},
              {"note": 10, "sur": 40, "type": "Devoir", "date": "2025-12-03"},
              {"note": 15, "sur": 20, "type": "Devoir", "date": "2025-12-03"},
              {"note": 29, "sur": 40, "type": "Test lourd", "date": "2025-11-27"},
            ]
          }
        ]
      }
    };
    setState(() {
      _originalBulletinData = testData['bulletin'];
      _bulletinData = testData['bulletin'];
      _selectedYear = _bulletinData!['annee']['libelle'] ?? 'Année 2025 - 2026';
      _selectedSubject = null;
      _selectedTrimester = null;
      _isLoading = false;
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _calculateAverage(List<dynamic> notes) {
    if (notes.isEmpty) return 0.0;
    double total = 0, totalSur = 0;
    for (var n in notes) {
      total += (n['note'] as num?)?.toDouble() ?? 0.0;
      totalSur += (n['sur'] as num?)?.toDouble() ?? 20.0;
    }
    return totalSur > 0 ? (total / totalSur) * 20.0 : 0.0;
  }

  Color _getAverageColor(double avg) {
    if (avg >= 16) return const Color(0xFF10B981);
    if (avg >= 14) return const Color(0xFF3B82F6);
    if (avg >= 12) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate;
    if (s.contains('fran')) return Icons.menu_book;
    if (s.contains('histoir')) return Icons.public;
    if (s.contains('phys')) return Icons.science;
    if (s.contains('angl')) return Icons.language;
    if (s.contains('sport') || s.contains('eps')) return Icons.sports_soccer;
    if (s.contains('mus')) return Icons.music_note;
    if (s.contains('art')) return Icons.palette;
    if (s.contains('arab')) return Icons.translate;
    return Icons.school;
  }

  List<dynamic> _getFilteredMatieres() {
    if (_originalBulletinData == null) return [];
    List<dynamic> matieres =
        List.from(_originalBulletinData!['matieres'] as List<dynamic>);
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      matieres = matieres
          .where((m) => m['libelle'] == _selectedSubject)
          .toList();
    }
    return matieres;
  }

  List<String> get _availableSubjects {
    if (_originalBulletinData == null) return ['Toutes'];
    final matieres = _originalBulletinData!['matieres'] as List<dynamic>;
    return ['Toutes', ...matieres.map((m) => m['libelle'] as String)];
  }

  List<String> get _availableTrimesters =>
      ['Tous', 'Premier Trimestre', 'Deuxième Trimestre', 'Troisième Trimestre'];

  void _onSubjectChanged(String value) {
    setState(() => _selectedSubject = value == 'Toutes' ? null : value);
  }

  void _onTrimesterChanged(String value) {
    setState(() => _selectedTrimester = value == 'Tous' ? null : value);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDarkMode),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes Notes',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: _textSizeService.getScaledFontSize(20),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadJsonData();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildContent() {
    if (_bulletinData == null) {
      return Center(
        child: Text(
          'Erreur lors du chargement des données',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(16),
            color: AppColors.getTextColor(_themeService.isDarkMode),
          ),
        ),
      );
    }

    final matieres = _getFilteredMatieres();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildFiltersSection(),
          const SizedBox(height: 16),
          if (matieres.isNotEmpty) ...[
            _buildNotesTable(matieres),
            const SizedBox(height: 16),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 48,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune note disponible',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filters section ────────────────────────────────────────────────────────

  Widget _buildFiltersSection() {
    final isDarkMode = _themeService.isDarkMode;
    return Container(
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
              Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            label: 'Année scolaire',
            value: _selectedYear ?? 'Chargement...',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchableDropdown(
                  label: 'MATIÈRE',
                  value: _selectedSubject ?? 'Toutes',
                  items: _availableSubjects,
                  onChanged: _onSubjectChanged,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SearchableDropdown(
                  label: 'TRIMESTRE',
                  value: _selectedTrimester ?? 'Tous',
                  items: _availableTrimesters,
                  onChanged: _onTrimesterChanged,
                  isDarkMode: isDarkMode,
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
        readOnly: true,
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          isDense: true,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: _textSizeService.getScaledFontSize(14),
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
          fontSize: _textSizeService.getScaledFontSize(15),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Notes table (header + cards) ───────────────────────────────────────────

  Widget _buildNotesTable(List<dynamic> matieres) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête dégradé — identique à NotesScreen
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${matieres.length} matière${matieres.length > 1 ? 's' : ''}',
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
        // Cards
        ...matieres.asMap().entries.map((entry) {
          return _buildModernSubjectCard(
              entry.value, entry.key, matieres.length);
        }),
      ],
    );
  }

  // ── Modern subject card — calqué sur NotesScreen ───────────────────────────

  Widget _buildModernSubjectCard(
      Map<String, dynamic> matiere, int index, int total) {
    final isDarkMode = _themeService.isDarkMode;
    final subjectName = matiere['libelle'] as String;
    final notes = matiere['notes'] as List<dynamic>;
    final avg = _calculateAverage(notes);
    final isExpanded = _expandedSubjectId == subjectName;
    final isLast = index == total - 1;
    final color = _getAverageColor(avg);

    return GestureDetector(
      onTap: () => setState(() =>
          _expandedSubjectId = isExpanded ? null : subjectName),
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
            color: color.withOpacity(isExpanded ? 0.3 : 0.1),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getSubjectIcon(subjectName),
                      color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subjectName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: color,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${notes.length} évaluation${notes.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: isDarkMode
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge moyenne
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            // ── Expanded content ──
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Détail des notes
                  Text(
                    'Détail des notes',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactNotesList(notes, isDarkMode),

                  // Statistiques
                  const SizedBox(height: 16),
                  Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStat(
                            'Coef', '1.0', Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactStat(
                            'Rang', '40', Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactStat(
                          'Effectif',
                          '${(_bulletinData!['classe']['effectif'] as int?) ?? '-'}',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bouton Marquer consulté
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            const Color(0xFFF59E0B).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility,
                            color: Colors.orange[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Marquer consulté',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize:
                                _textSizeService.getScaledFontSize(12),
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
    );
  }

  Widget _buildCompactNotesList(
      List<dynamic> notes, bool isDarkMode) {
    // Trier par date
    final sorted = List<Map<String, dynamic>>.from(notes)
      ..sort((a, b) =>
          (a['date'] as String).compareTo(b['date'] as String));

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: sorted.asMap().entries.map((entry) {
        final i = entry.key;
        final note = entry.value;
        final val = (note['note'] as num).toDouble();
        final sur = (note['sur'] as num).toDouble();
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'N°${i + 1}',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(9),
                  color: isDarkMode
                      ? Colors.grey[400]
                      : const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${val.toStringAsFixed(1)}/${sur.toInt()}',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.white
                      : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactStat(String label, String value,
      [Color? statColor]) {
    final isDarkMode = _themeService.isDarkMode;
    final color =
        statColor ?? (isDarkMode ? Colors.grey[600]! : Colors.grey[500]!);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
}