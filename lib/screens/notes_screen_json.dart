import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../services/school_service.dart';
import '../services/notes_api_service.dart';
import '../widgets/searchable_dropdown.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

class NotesScreenJson extends StatefulWidget {
  const NotesScreenJson({super.key});

  @override
  State<NotesScreenJson> createState() => _NotesScreenJsonState();
}

class _NotesScreenJsonState extends State<NotesScreenJson>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _bulletinData;
  Map<String, dynamic>? _originalBulletinData;
  bool _isLoading = true;
  String? _expandedSubjectId;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final SchoolService _schoolService = SchoolService();
  final NotesApiService _notesApiService = NotesApiService();

  String? _selectedSubject;
  String? _selectedTrimester;
  String? _selectedYear;

  String? _studentMatricule;
  String? _anneeId;
  String? _classeId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _studentMatricule = '24294819Z';
    _anneeId = '226';
    _classeId = '27159';
    _selectedYear = 'Année 2025 - 2026';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeParameters();
    if (_isLoading) _loadApiData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeParameters() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _studentMatricule = args['matricule'] ?? '24294819Z';
      _anneeId = args['anneeId'] ?? '226';
      _classeId = args['classeId'] ?? '27159';
      _selectedYear = args['anneeLibelle'] ?? 'Année 2025 - 2026';
    }
  }

  Future<void> _loadApiData() async {
    try {
      await _schoolService.loadSchoolData();
      final periode = _getPeriodeNumberFromString(_selectedTrimester);
      final apiData = await _notesApiService.getNotesForStudent(
        matricule: _studentMatricule!,
        anneeId: _anneeId!,
        classeId: _classeId!,
        periode: periode,
      );

      if (apiData != null) {
        setState(() {
          _bulletinData = apiData;
          _originalBulletinData = apiData;
          _selectedSubject = null;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      } else {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement des notes. Veuillez réessayer.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  String _getPeriodeNumberFromString(String? trimestre) {
    if (trimestre == null || trimestre == 'Tous') return '1';
    if (trimestre.toLowerCase().contains('deux')) return '2';
    if (trimestre.toLowerCase().contains('trois')) return '3';
    return '1';
  }

  double _calculateAverage(List<dynamic> notes) {
    if (notes.isEmpty) return 0.0;
    double total = 0, totalSur = 0;
    for (var n in notes) {
      final note = double.tryParse(n['note']?.toString() ?? '0') ?? 0.0;
      final sur = double.tryParse(n['sur']?.toString() ?? '20') ?? 20.0;
      total += note;
      totalSur += sur;
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
    if (s.contains('math')) return Icons.calculate_outlined;
    if (s.contains('fran')) return Icons.menu_book_outlined;
    if (s.contains('histoir')) return Icons.public_outlined;
    if (s.contains('phys')) return Icons.science_outlined;
    if (s.contains('angl')) return Icons.language_outlined;
    if (s.contains('sport') || s.contains('eps')) return Icons.sports_soccer_outlined;
    if (s.contains('mus')) return Icons.music_note_outlined;
    if (s.contains('art')) return Icons.palette_outlined;
    if (s.contains('arab')) return Icons.translate_outlined;
    return Icons.school_outlined;
  }

  List<dynamic> _getFilteredMatieres() {
    if (_originalBulletinData == null) return [];
    List<dynamic> matieres =
        List.from(_originalBulletinData!['list'] as List<dynamic>);
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      matieres = matieres
          .where((m) => m['matiereLibelle'] == _selectedSubject)
          .toList();
    }
    return matieres;
  }

  List<String> get _availableSubjects {
    if (_originalBulletinData == null) return ['Toutes'];
    final matieres = _originalBulletinData!['list'] as List<dynamic>;
    return ['Toutes', ...matieres.map((m) => m['matiereLibelle'] as String)];
  }

  List<String> get _availableTrimesters =>
      ['Tous', 'Premier Trimestre', 'Deuxième Trimestre', 'Troisième Trimestre'];

  void _onSubjectChanged(String value) =>
      setState(() => _selectedSubject = value == 'Toutes' ? null : value);

  void _onTrimesterChanged(String value) {
    setState(() => _selectedTrimester = value == 'Tous' ? null : value);
    _loadApiData();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.screenOrange, strokeWidth: 2.5),
          ),
        ),
      ],
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final matieres = _getFilteredMatieres();
    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.screenShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.screenTextPrimary),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_bulletinData != null)
                      Text(
                        '${matieres.length} matière${matieres.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: () {
                  setState(() => _isLoading = true);
                  _loadApiData();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_outlined,
                      size: 18, color: AppColors.screenOrange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CONTENT ──────────────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_bulletinData == null) {
      return Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        size: 48, color: AppColors.screenOrange),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Erreur de chargement',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Impossible de charger les données.',
                    style: TextStyle(fontSize: 14, color: AppColors.screenTextSecondary),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: _buildOrangeButton(
                      label: 'Réessayer',
                      onTap: () {
                        setState(() => _isLoading = true);
                        _loadApiData();
                      },
                      trailing: const Icon(Icons.refresh_outlined,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final matieres = _getFilteredMatieres();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildAppBar(),
          // Student info banner
          _buildStudentBanner(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFiltersSection(),
                  const SizedBox(height: 16),
                  if (matieres.isNotEmpty)
                    _buildNotesSection(matieres)
                  else
                    _buildEmptyState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STUDENT BANNER ───────────────────────────────────────────────────────
  Widget _buildStudentBanner() {
    final prenom = _bulletinData?['prenom'] ?? '';
    final nom = _bulletinData?['nom'] ?? '';
    final matricule = _bulletinData?['matricule'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.screenOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                prenom.isNotEmpty ? prenom[0].toUpperCase() : 'E',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prenom $nom',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Matricule : $matricule',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedYear ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTERS SECTION ──────────────────────────────────────────────────────
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header filtre
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.screenOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.tune, color: AppColors.screenOrange, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.screenDivider, height: 1),
          const SizedBox(height: 14),

          // Année scolaire (read-only)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Année scolaire',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.screenOrange, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      _selectedYear ?? 'Chargement...',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Matière + Trimestre
          Row(
            children: [
              Expanded(
                child: SearchableDropdown(
                  label: 'Matière',
                  value: _selectedSubject ?? 'Toutes',
                  items: _availableSubjects,
                  onChanged: _onSubjectChanged,
                  isDarkMode: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchableDropdown(
                  label: 'Trimestre',
                  value: _selectedTrimester ?? 'Tous',
                  items: _availableTrimesters,
                  onChanged: _onTrimesterChanged,
                  isDarkMode: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── NOTES SECTION ────────────────────────────────────────────────────────
  Widget _buildNotesSection(List<dynamic> matieres) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header de section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.screenOrange.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Résultats par matière',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${matieres.length} matière${matieres.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cards matières
        Container(
          decoration: const BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.screenShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: matieres.asMap().entries.map((entry) {
              final isLast = entry.key == matieres.length - 1;
              return Column(
                children: [
                  _buildSubjectCard(entry.value, entry.key),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: AppColors.screenDivider, height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── SUBJECT CARD ─────────────────────────────────────────────────────────
  Widget _buildSubjectCard(Map<String, dynamic> matiere, int index) {
    final subjectName = matiere['matiereLibelle'] as String;
    final notes = matiere['notesEvaluation'] as List<dynamic>;
    final avg = _calculateAverage(notes);
    final isExpanded = _expandedSubjectId == subjectName;
    final color = _getAverageColor(avg);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() =>
              _expandedSubjectId = isExpanded ? null : subjectName),
          splashColor: AppColors.screenOrange.withOpacity(0.06),
          highlightColor: AppColors.screenOrange.withOpacity(0.04),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la matière
              Row(
                children: [
                  // Icône matière
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getSubjectIcon(subjectName),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Nom + nb évaluations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${notes.length} évaluation${notes.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.screenTextSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge moyenne
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: AppColors.screenTextSecondary, size: 20),
                  ),
                ],
              ),

              // Expanded detail
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.screenDivider, height: 1),
                    const SizedBox(height: 14),

                    // Titre détail
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Détail des notes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildNotesList(notes),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Statistiques',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatBadge(
                                'Coef', '1.0', const Color(0xFF3B82F6))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatBadge(
                                'Rang', '40', const Color(0xFF9C27B0))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatBadge(
                                'Effectif', '30', AppColors.screenOrange)),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // Bouton marquer consulté
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.screenOrangeLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.screenOrange.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined,
                                color: AppColors.screenOrange, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Marquer consulté',
                              style: TextStyle(
                                color: AppColors.screenOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ─── NOTES LIST ───────────────────────────────────────────────────────────
  Widget _buildNotesList(List<dynamic> notes) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: notes.asMap().entries.map((entry) {
        final i = entry.key;
        final note = entry.value;
        final val =
            double.tryParse(note['note']?.toString() ?? '0') ?? 0.0;
        final sur =
            double.tryParse(note['noteSur']?.toString() ?? '20') ?? 20.0;
        final color = _getAverageColor((val / sur) * 20);

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.screenSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.screenDivider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'N°${i + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.screenTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${val.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '/${sur.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.screenTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── STAT BADGE ───────────────────────────────────────────────────────────
  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.screenOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 40, color: AppColors.screenOrange),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune note disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Modifiez les filtres pour afficher des résultats',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
          ),
        ],
      ),
    );
  }

  // ─── ORANGE BUTTON (identique CartScreen) ─────────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}