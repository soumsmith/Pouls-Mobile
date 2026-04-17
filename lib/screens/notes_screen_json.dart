import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_colors.dart';
import '../services/notes_api_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/custom_loader.dart';
import '../widgets/snackbar.dart';
import '../widgets/subtle_retry_button.dart';
import '../widgets/custom_sliver_app_bar_fixed.dart';

class NotesScreenJson extends StatefulWidget {
  final String matricule;
  final String anneeId;
  final String classeId;
  final String anneeLibelle;

  const NotesScreenJson({
    super.key,
    required this.matricule,
    required this.anneeId,
    required this.classeId,
    required this.anneeLibelle,
  });

  @override
  State<NotesScreenJson> createState() => _NotesScreenJsonState();
}

class _NotesScreenJsonState extends State<NotesScreenJson>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _bulletinData;
  bool _isLoading = true;
  String? _expandedSubjectId;
  final NotesApiService _notesApiService = NotesApiService();

  String? _selectedSubject;
  String? _selectedTrimester;
  String? _selectedYear;

  String? _studentMatricule;
  String? _anneeId;
  String? _classeId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Variables pour le carrousel auto-play
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  
  // Variable pour l'état d'extension du filtre
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Initialiser le PageController pour le carrousel
    _pageController = PageController(viewportFraction: 1.0);
    
    _studentMatricule = widget.matricule;
    _anneeId = widget.anneeId;
    _classeId = widget.classeId;
    _selectedYear = widget.anneeLibelle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) _loadApiData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bulletinData != null) {
        setState(() {
          _currentPage = (_currentPage + 1) % 3;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  Future<void> _loadApiData() async {
    try {
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
          _selectedSubject = null;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
        
        // Démarrer l'auto-play du carrousel
        _startAutoPlay();

        // Notification de succès
        final matieres = apiData['details'] as List<dynamic>? ?? [];
        _showSuccess(
          'Notes chargées : ${matieres.length} matière${matieres.length > 1 ? 's' : ''}',
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Aucune note trouvée pour cette période');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Gestion spécifique des erreurs 400
      if (e.toString().contains('No result found for query')) {
        _showInfo('Aucune note disponible pour cette période scolaire');
      } else if (e.toString().contains('400')) {
        _showError('Requête invalide : vérifiez les paramètres');
      } else {
        _showError('Erreur lors du chargement: ${e.toString()}');
      }
    }
  }

  void _showError(String msg) {
    CartSnackBar.show(
      context,
      productName: 'Erreur',
      message: msg,
      backgroundColor: Colors.red[400] ?? Colors.red,
    );
  }

  void _showSuccess(String msg) {
    CartSnackBar.show(
      context,
      productName: 'Succès',
      message: msg,
      backgroundColor: AppColors.screenGreen,
    );
  }

  void _showInfo(String msg) {
    CartSnackBar.show(
      context,
      productName: 'Information',
      message: msg,
      backgroundColor: const Color(0xFF3B82F6),
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
      final sur = double.tryParse(n['noteSur']?.toString() ?? '20') ?? 20.0;
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
    if (s.contains('sport') || s.contains('eps'))
      return Icons.sports_soccer_outlined;
    if (s.contains('mus')) return Icons.music_note_outlined;
    if (s.contains('art')) return Icons.palette_outlined;
    if (s.contains('arab')) return Icons.translate_outlined;
    return Icons.school_outlined;
  }

  List<dynamic> _getFilteredMatieres() {
    if (_bulletinData == null) return [];
    List<dynamic> matieres = List.from(
      _bulletinData!['details'] as List<dynamic>,
    );
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      matieres = matieres
          .where((m) => m['matiereLibelle'] == _selectedSubject)
          .toList();
    }
    return matieres;
  }

  List<String> get _availableSubjects {
    if (_bulletinData == null) return ['Toutes'];
    final matieres = _bulletinData!['details'] as List<dynamic>;
    return ['Toutes', ...matieres.map((m) => m['matiereLibelle'] as String)];
  }

  List<String> get _availableTrimesters => [
    'Tous',
    'Premier Trimestre',
    'Deuxième Trimestre',
    'Troisième Trimestre',
  ];

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
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: CustomScrollView(
          slivers: [
            CustomSliverAppBarFixed(
              title: 'Mes Notes',
              isDark: false,
              pinned: true,
              floating: false,
              elevation: 0,
              actions: [
                AppBarIconButton(
                  icon: Icons.refresh_outlined,
                  isDark: false,
                  onTap: () {
                    setState(() => _isLoading = true);
                    _loadApiData();
                    _showInfo('Actualisation des notes en cours...');
                  },
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            if (_isLoading)
              SliverFillRemaining(child: _buildLoadingState())
            else
              ..._buildContentSlivers(),
          ],
        ),
      ),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return CustomLoader(
      message: 'Chargement des notes...',
      loaderColor: AppColors.screenOrange,
      backgroundColor: AppColors.screenSurface,
      showBackground: false,
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
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.screenTextPrimary,
                  ),
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
              SubtleRetryButton(
                onTap: () {
                  setState(() => _isLoading = true);
                  _loadApiData();
                  _showInfo('Actualisation des notes en cours...');
                },
                color: AppColors.screenOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CONTENT SLIVERS ────────────────────────────────────────────────────────
  List<Widget> _buildContentSlivers() {
    if (_bulletinData == null) {
      return [
        SliverFillRemaining(
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
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: AppColors.screenOrange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Impossible de charger les données.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SubtleRetryButtonWithText(
                    onTap: () {
                      setState(() => _isLoading = true);
                      _loadApiData();
                    },
                    color: AppColors.screenOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final matieres = _getFilteredMatieres();

    return [
      SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Student info banner
              //_buildStudentBanner(),
              // Average cards
              _buildAverageCards(),
              // Content
              Padding(
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
            ],
          ),
        ),
      ),
    ];
  }

  // ─── STUDENT BANNER ───────────────────────────────────────────────────────
  Widget _buildStudentBanner() {
    final prenoms = _bulletinData?['prenoms'] ?? '';
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
                prenoms.isNotEmpty ? prenoms[0].toUpperCase() : 'E',
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
                  '$prenoms $nom',
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _bulletinData?['anneeLibelle'] ?? _selectedYear ?? '',
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

  // ─── AVERAGE CARDS SECTION ───────────────────────────────────────────────────
  Widget _buildAverageCards() {
    if (_bulletinData == null) return const SizedBox.shrink();

    return Container(
      height: 245, // Increased height for combined slide
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                // Redémarrer l'auto-play quand l'utilisateur change manuellement
                _stopAutoPlay();
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _startAutoPlay();
                  }
                });
              },
              children: [
                _buildStudentInfoPage(),
                _buildChartPage(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == i
                  ? AppColors.primary
                  : AppColors.grey300,
            ),
          ),
      ],
    );
  }

  Widget _buildStudentInfoPage() {
    final nom = _bulletinData!['nom'] ?? '';
    final prenoms = _bulletinData!['prenoms'] ?? '';
    final matricule = _bulletinData!['matricule'] ?? '';
    final anneeLibelle = _bulletinData!['anneeLibelle'] ?? '';
    final moyFr = _bulletinData!['moyFr'] ?? 0.0;
    final moyGeneral = _bulletinData!['moyGeneral'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte d'informations de l'élève
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.screenOrange,
                  AppColors.screenOrangeDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.screenOrange.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.screenOrange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.screenOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.screenOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$prenoms $nom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Matricule: $matricule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      anneeLibelle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Séparateur
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                // Section des moyennes
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactAverageCard(
                        'Moyenne Française',
                        moyFr.toStringAsFixed(1),
                        Icons.menu_book_outlined,
                        _getAverageColor(moyFr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactAverageCard(
                        'Moyenne Générale',
                        moyGeneral.toStringAsFixed(1),
                        Icons.analytics_outlined,
                        _getAverageColor(moyGeneral),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAverageCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '/20',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPage() {
    final details = _bulletinData!['details'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Graphique des Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: details.isNotEmpty
                ? _buildNotesChart(details)
                : Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(
                        color: AppColors.screenTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesChart(List<dynamic> details) {
    // Trier les matières par moyenne pour un meilleur affichage
    final sortedDetails = List<Map<String, dynamic>>.from(
      details.map((item) => item as Map<String, dynamic>)
    )..sort((a, b) => (b['moyenne'] as double).compareTo(a['moyenne'] as double));

    // Prendre TOUTES les matières pour un affichage complet
    final allSubjects = sortedDetails;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: (allSubjects.length * 35.0).clamp(300.0, double.infinity), // Largeur dynamique ajustée
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween, // Alignement plus serré
            maxY: 20,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Theme.of(context).scaffoldBackgroundColor,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final subject = allSubjects[group.x.toInt()];
                  return BarTooltipItem(
                    '${subject['matiereLibelle']}\n',
                    TextStyle(
                      color: AppColors.screenTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${subject['moyenne'].toStringAsFixed(2)}/20',
                        style: TextStyle(
                          color: AppColors.screenTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < allSubjects.length) {
                      final subject = allSubjects[value.toInt()];
                      final name = subject['matiereLibelle'] as String;
                      // Abréger les noms longs
                      final displayName = name.length > 6 
                          ? '${name.substring(0, 4)}...' 
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: RotatedBox(
                          quarterTurns: 1, // Rotation verticale pour économiser l'espace
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: AppColors.screenTextSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: AppColors.screenTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: allSubjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;
              final average = (subject['moyenne'] as double);
              
              // Déterminer la couleur selon la moyenne
              Color barColor;
              if (average >= 16) {
                barColor = Colors.green;
              } else if (average >= 14) {
                barColor = Colors.blue;
              } else if (average >= 12) {
                barColor = Colors.orange;
              } else if (average >= 10) {
                barColor = Colors.deepOrange;
              } else {
                barColor = Colors.red;
              }

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: average,
                    color: barColor,
                    width: 15, // Largeur augmentée pour réduire l'espacement
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAverageCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      width: 160, // Increased width for better content fit
      margin: EdgeInsets.only(
        left: isFirst ? 0 : 0,
        right: isLast ? 0 : 0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Simplified border radius
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '/20',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Increased spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 22, // Slightly smaller font
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4), // Increased spacing
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTERS SECTION ──────────────────────────────────────────────────────
  Widget _buildFiltersSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFilterExpanded = !_isFilterExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          // boxShadow: const [
          //   BoxShadow(
          //     color: AppColors.screenShadow,
          //     blurRadius: 12,
          //     offset: Offset(0, 4),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            // Header avec design amélioré
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.screenOrange.withOpacity(0.1),
                    AppColors.screenOrange.withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Icône animée avec fond circulaire
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.screenOrange,
                          AppColors.screenOrangeDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.screenOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFilterExpanded ? Icons.filter_list : Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Texte avec style amélioré
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtres',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenOrange,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isFilterExpanded ? 'Réduire' : 'Étendre pour filtrer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.screenTextSecondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icône flèche animée
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.screenOrange.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.screenOrange,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Contenu du filtre avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterExpanded ? null : 0,
            child: _isFilterExpanded 
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.screenOrange,
                      size: 16,
                    ),
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
                  )
                : null,
          ),
        ],
      ),
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
              colors: [
                AppColors.customLightBlue,
                AppColors.customLightBlueDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 18,
                ),
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
                  horizontal: 10,
                  vertical: 5,
                ),
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.screenShadow,
            //     blurRadius: 12,
            //     offset: Offset(0, 4),
            //   ),
            // ],
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
    final notes = matiere['notes'] as List<dynamic>;
    final avg = matiere['moyenne'] ?? _calculateAverage(notes);
    final isExpanded = _expandedSubjectId == subjectName;
    final color = _getAverageColor(avg);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(
            () => _expandedSubjectId = isExpanded ? null : subjectName,
          ),
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
                      child: Icon(
                        _getSubjectIcon(subjectName),
                        color: color,
                        size: 20,
                      ),
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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
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
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.screenTextSecondary,
                        size: 20,
                      ),
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
                              'Coef',
                              '${matiere['coef'] ?? '1.0'}',
                              const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'Appréciation',
                              '${matiere['appreciation'] ?? 'N/A'}',
                              const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'Moyenne',
                              '${matiere['moyenne']?.toStringAsFixed(1) ?? avg.toStringAsFixed(1)}',
                              AppColors.screenOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      // Bouton marquer consulté
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Container(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 12, vertical: 8),
                      //     decoration: BoxDecoration(
                      //       color: AppColors.screenOrangeLight,
                      //       borderRadius: BorderRadius.circular(10),
                      //       border: Border.all(
                      //           color: AppColors.screenOrange.withOpacity(0.2)),
                      //     ),
                      //     child: const Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         Icon(Icons.visibility_outlined,
                      //             color: AppColors.screenOrange, size: 15),
                      //         SizedBox(width: 6),
                      //         Text(
                      //           'Marquer consulté',
                      //           style: TextStyle(
                      //             color: AppColors.screenOrange,
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
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
        final val = double.tryParse(note['note']?.toString() ?? '0') ?? 0.0;
        final sur =
            double.tryParse(note['noteSur']?.toString() ?? '20') ?? 20.0;
        final color = _getAverageColor((val / sur) * 20);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        // boxShadow: const [
        //   BoxShadow(
        //     color: AppColors.screenShadow,
        //     blurRadius: 12,
        //     offset: Offset(0, 4),
        //   ),
        // ],
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
            child: const Icon(
              Icons.assignment_outlined,
              size: 40,
              color: AppColors.screenOrange,
            ),
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
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      ),
    );
  }
}
