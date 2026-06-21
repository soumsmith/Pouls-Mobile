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
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/bottom_spacer.dart';

class NotesScreenJson extends StatefulWidget {
  final String matricule;
  final String anneeId;
  final String classeId;
  final String anneeLibelle;
  final String? ecoleId;

  const NotesScreenJson({
    super.key,
    required this.matricule,
    required this.anneeId,
    required this.classeId,
    required this.anneeLibelle,
    this.ecoleId,
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


  // Liste des années scolaires fetched depuis l'API
  List<dynamic> _schoolYears = [];
  List<String> _availableYears = [];
  bool _isLoadingYears = false;

  // Cache pour conserver les informations de l'élève même si un filtre ne retourne rien
  String _cachedNom = '';
  String _cachedPrenoms = '';
  String? _cachedPhotoUrl;

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

    _loadSchoolYears();
  }

  Future<void> _loadSchoolYears() async {
    final ecole = widget.ecoleId ?? '38';
    setState(() => _isLoadingYears = true);
    try {
      final years = await _notesApiService.getSchoolYears(ecoleId: ecole);
      if (!mounted) return;
      if (years != null && years.isNotEmpty) {
        setState(() {
          _schoolYears = years;
          _availableYears = years
              .map<String>(
                (y) =>
                    (y['customLibelle'] ?? y['libelle'] ?? 'Année').toString(),
              )
              .toList();
          _isLoadingYears = false;
        });

        // Tenter de matcher l'année courante pour avoir son libellé exact
        final currentYear = years.firstWhere(
          (y) => y['id'].toString() == _anneeId,
          orElse: () => null,
        );
        if (currentYear != null) {
          setState(() {
            _selectedYear =
                currentYear['customLibelle'] ??
                currentYear['libelle'] ??
                _selectedYear;
          });
        }
      } else {
        setState(() => _isLoadingYears = false);
      }
    } catch (e) {
      print('❌ Erreur _loadSchoolYears: $e');
      if (!mounted) return;
      setState(() => _isLoadingYears = false);
    }
  }

  void _onYearChanged(String label) {
    final year = _schoolYears.firstWhere(
      (y) => (y['customLibelle'] ?? y['libelle']) == label,
      orElse: () => null,
    );
    if (year != null && _anneeId != year['id'].toString()) {
      setState(() {
        _anneeId = year['id'].toString();
        _selectedYear = label;
        _isLoading = true;
      });
      _loadApiData();
    }
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
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_bulletinData != null) {
        setState(() {
          _currentPage = (_currentPage + 1) % 2;
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

      if (!mounted) return;

      if (apiData != null) {
        setState(() {
          _bulletinData = apiData;
          _selectedSubject = null;
          _isLoading = false;

          // Mettre à jour le cache si les données sont présentes
          if (apiData['nom'] != null && apiData['nom'].toString().isNotEmpty) {
             _cachedNom = apiData['nom'];
          }
          if (apiData['prenoms'] != null && apiData['prenoms'].toString().isNotEmpty) {
             _cachedPrenoms = apiData['prenoms'];
          }
          final newPhoto = apiData['photo']?.toString() ?? apiData['photoEleve']?.toString();
          if (newPhoto != null && newPhoto.isNotEmpty) {
             _cachedPhotoUrl = newPhoto;
          }
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
        setState(() {
          _bulletinData = null;
          _isLoading = false;
        });
        _showError('Aucune note trouvée pour cette période');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bulletinData = null;
        _isLoading = false;
      });

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
    if (!mounted) return;
    CartSnackBar.show(
      context,
      productName: 'Erreur',
      message: msg,
      backgroundColor: Colors.red[400] ?? Colors.red,
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    CartSnackBar.show(
      context,
      productName: 'Succès',
      message: msg,
      backgroundColor: AppColors.screenGreen,
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
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
    if (avg >= 12) return const Color(0xFF10B981); // Vert (Bien/Excellent)
    if (avg >= 10) return const Color(0xFFF59E0B); // Orange (Passable)
    return const Color(0xFFEF4444); // Rouge (Insuffisant)
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
    if (_bulletinData == null || _bulletinData!['details'] == null) return [];
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
    if (_bulletinData == null || _bulletinData!['details'] == null) return ['Toutes'];
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

  void _showFiltersBottomSheet() {
    // Variables temporaires pour retenir les choix avant de les valider
    String? tempSelectedYear = _selectedYear;
    String? tempAnneeId = _anneeId;
    String? tempSelectedSubject = _selectedSubject;
    String? tempSelectedTrimester = _selectedTrimester;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool isDark = AppColors.isDarkMode(context);
            return Container(
              // On force une hauteur minimale (50% de l'écran) pour qu'il soit plus grand
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(isDark),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // La colonne prend la place minimale, mais le Container force la taille
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Petite poignée (handle)
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.tune, color: AppColors.primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Filtres',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SearchableDropdown(
                        label: 'Année scolaire',
                        value: tempSelectedYear ?? 'Chargement...',
                        items: _availableYears,
                        onChanged: (val) {
                          setSheetState(() {
                            final year = _schoolYears.firstWhere(
                              (y) => (y['customLibelle'] ?? y['libelle']) == val,
                              orElse: () => null,
                            );
                            if (year != null) {
                              tempAnneeId = year['id'].toString();
                              tempSelectedYear = val;
                              // Optionnel: Réinitialiser la matière et le trimestre si l'année change
                              tempSelectedSubject = null;
                              tempSelectedTrimester = null;
                            }
                          });
                        },
                        isDarkMode: isDark,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SearchableDropdown(
                              label: 'Matière',
                              value: tempSelectedSubject ?? 'Toutes',
                              items: _availableSubjects,
                              onChanged: (val) {
                                setSheetState(() {
                                  tempSelectedSubject = val == 'Toutes' ? null : val;
                                });
                              },
                              isDarkMode: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SearchableDropdown(
                              label: 'Trimestre',
                              value: tempSelectedTrimester ?? 'Tous',
                              items: _availableTrimesters,
                              onChanged: (val) {
                                setSheetState(() {
                                  tempSelectedTrimester = val == 'Tous' ? null : val;
                                });
                              },
                              isDarkMode: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60), // Grand espace pour pousser le bouton vers le bas
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Ferme le bottom sheet
                          
                          // On vérifie si un filtre a changé
                          bool needApiCall = false;
                          bool needStateUpdate = false;
                          
                          // L'année ou le trimestre nécessitent de recharger l'API
                          if (_anneeId != tempAnneeId || _selectedTrimester != tempSelectedTrimester) {
                            needApiCall = true;
                          }
                          // N'importe quel changement nécessite de mettre à jour l'état
                          if (_anneeId != tempAnneeId || 
                              _selectedYear != tempSelectedYear ||
                              _selectedSubject != tempSelectedSubject ||
                              _selectedTrimester != tempSelectedTrimester) {
                            needStateUpdate = true;
                          }

                          if (needStateUpdate) {
                            setState(() {
                              _anneeId = tempAnneeId;
                              _selectedYear = tempSelectedYear;
                              _selectedSubject = tempSelectedSubject;
                              _selectedTrimester = tempSelectedTrimester;
                              if (needApiCall) _isLoading = true;
                            });
                            
                            // On déclenche l'API seulement maintenant !
                            if (needApiCall) {
                              _loadApiData();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Appliquer et fermer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.screenBg(context),
        body: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              title: 'Mes Notes',
              pinned: true,
              floating: false,
              elevation: 0,
              actions: [
                GestureDetector(
                  onTap: _showFiltersBottomSheet,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.screenCardThemed(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.screenShadowThemed(context),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLoading = true);
                    _loadApiData();
                    _showInfo('Actualisation des notes en cours...');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.screenCardThemed(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.screenShadowThemed(context),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh_outlined,
                      size: 20,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                  ),
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
      backgroundColor: AppColors.screenBg(context),
      showBackground: false,
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final matieres = _getFilteredMatieres();
    return Container(
      color: AppColors.screenBg(context),
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
                    color: AppColors.screenCardThemed(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimaryThemed(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_bulletinData != null)
                      Text(
                        '${matieres.length} matière${matieres.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.screenTextSecondaryThemed(context),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmptyState(),
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
      const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
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
        gradient: LinearGradient(
          colors: [const Color(0xFFFF7A3C), AppColors.screenOrange],
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
      height: 220, // Reduced height for slide cards
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
              children: [_buildStudentInfoPage(), _buildChartPage()],
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
        for (int i = 0; i < 2; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == i ? AppColors.primary : AppColors.grey300,
            ),
          ),
      ],
    );
  }

  Widget _buildStudentInfoPage() {
    // Utiliser les données du bulletin, sinon utiliser le cache, sinon utiliser les valeurs passées au widget
    final nom = (_bulletinData != null && _bulletinData!['nom'] != null) ? _bulletinData!['nom'] : _cachedNom;
    final prenoms = (_bulletinData != null && _bulletinData!['prenoms'] != null) ? _bulletinData!['prenoms'] : _cachedPrenoms;
    final matricule = (_bulletinData != null && _bulletinData!['matricule'] != null) ? _bulletinData!['matricule'] : widget.matricule;
    final anneeLibelle = (_bulletinData != null && _bulletinData!['anneeLibelle'] != null) ? _bulletinData!['anneeLibelle'] : (_selectedYear ?? widget.anneeLibelle);
    final photoUrl = (_bulletinData != null) ? (_bulletinData!['photo']?.toString() ?? _bulletinData!['photoEleve']?.toString()) ?? _cachedPhotoUrl : _cachedPhotoUrl;
    
    final moyGeneral = _bulletinData?['moyGeneral'] ?? 0.0;
    final libellePeriode = _bulletinData?['libellePeriode'] ?? '';
    final periodesMoyenne =
        _bulletinData?['periodesMoyenne'] as List<dynamic>? ?? [];
    final moyenneAnnuelleProjettee = _bulletinData?['moyenneAnnuelleProjettee'];

    // Regrouper toutes les moyennes et les trier
    List<Map<String, dynamic>> allPeriods = [];
    allPeriods.add({
      'libelle': libellePeriode.toString(),
      'moyenne': moyGeneral,
      'isCurrent': true,
    });

    for (var periode in periodesMoyenne) {
      allPeriods.add({
        'libelle': periode['periodeLibelle']?.toString() ?? '',
        'moyenne': periode['moyenne'],
        'isCurrent': false,
      });
    }

    int getSortKey(String libelle) {
      final lower = libelle.toLowerCase();
      if (lower.contains('premier') || lower.contains('1er')) return 1;
      if (lower.contains('deuxième') ||
          lower.contains('deuxieme') ||
          lower.contains('2ème') ||
          lower.contains('2nd'))
        return 2;
      if (lower.contains('troisième') ||
          lower.contains('troisieme') ||
          lower.contains('3ème'))
        return 3;
      if (lower.contains('quatrième') ||
          lower.contains('quatrieme') ||
          lower.contains('4ème'))
        return 4;
      return 99;
    }

    allPeriods.sort(
      (a, b) => getSortKey(a['libelle']).compareTo(getSortKey(b['libelle'])),
    );

    List<Widget> averageCards = [];
    for (var p in allPeriods) {
      final moy = p['moyenne'] ?? 0.0;
      final double parsedMoy = (moy is num)
          ? moy.toDouble()
          : (double.tryParse(moy.toString()) ?? 0.0);
      averageCards.add(
        Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: _buildCompactAverageCard(
            p['libelle'],
            parsedMoy.toStringAsFixed(1),
            p['isCurrent']
                ? Icons.analytics_outlined
                : Icons.menu_book_outlined,
            _getAverageColor(parsedMoy),
          ),
        ),
      );
    }

    if (moyenneAnnuelleProjettee != null) {
      final double parsedAnnuelle = (moyenneAnnuelleProjettee is num)
          ? moyenneAnnuelleProjettee.toDouble()
          : (double.tryParse(moyenneAnnuelleProjettee.toString()) ?? 0.0);
      averageCards.insert(
        0,
        Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: _buildCompactAverageCardLight(
            'Moy. Annuelle Proj.',
            parsedAnnuelle.toStringAsFixed(2),
            Icons.auto_graph_outlined,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.screenOrange, AppColors.screenOrangeDark],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photoUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prenoms.isNotEmpty ? prenoms[0].toUpperCase() : 'E',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          prenoms.isNotEmpty ? prenoms[0].toUpperCase() : 'E',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$prenoms $nom',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          // const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Matricule: $matricule',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                  // const SizedBox(width: 6),
                                  Text(
                                    anneeLibelle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Séparateur
                Container(height: 1, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                // Section des moyennes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: averageCards),
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
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
                child: Icon(icon, color: Colors.white, size: 12),
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

  Widget _buildCompactAverageCardLight(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.screenOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.screenOrange, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.screenOrange,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '/20',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenOrange.withOpacity(0.9),
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
              color: AppColors.screenOrange,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
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
                child: Icon(Icons.bar_chart, color: Colors.white, size: 16),
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
                        color: AppColors.screenTextSecondaryThemed(context),
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
    final sortedDetails =
        List<Map<String, dynamic>>.from(
          details.map((item) => item as Map<String, dynamic>),
        )..sort(
          (a, b) => (b['moyenne'] as double).compareTo(a['moyenne'] as double),
        );

    // Prendre TOUTES les matières pour un affichage complet
    final allSubjects = sortedDetails;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: (allSubjects.length * 35.0).clamp(
          300.0,
          double.infinity,
        ), // Largeur dynamique ajustée
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween, // Alignement plus serré
            maxY: 20,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).scaffoldBackgroundColor,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final subject = allSubjects[group.x.toInt()];
                  return BarTooltipItem(
                    '${subject['matiereLibelle']}\n',
                    TextStyle(
                      color: AppColors.screenTextPrimaryThemed(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${subject['moyenne'].toStringAsFixed(2)}/20',
                        style: TextStyle(
                          color: AppColors.screenTextSecondaryThemed(context),
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
                    if (value.toInt() >= 0 &&
                        value.toInt() < allSubjects.length) {
                      final subject = allSubjects[value.toInt()];
                      final name = subject['matiereLibelle'] as String;
                      // Abréger les noms longs
                      final displayName = name.length > 6
                          ? '${name.substring(0, 4)}...'
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: AppColors.screenTextSecondaryThemed(
                                context,
                              ),
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
                        color: AppColors.screenTextSecondaryThemed(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
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
      margin: EdgeInsets.only(left: isFirst ? 0 : 0, right: isLast ? 0 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Simplified border radius
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
                child: Icon(icon, color: color, size: 16),
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
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: AppColors.screenDividerThemed(context),
                        height: 1,
                      ),
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
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
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
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSubjectIcon(subjectName),
                        color: Colors.grey[600],
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimaryThemed(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${notes.length} évaluation${notes.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.screenTextSecondaryThemed(
                                context,
                              ),
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
                        color: AppColors.screenTextSecondaryThemed(context),
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
                      Divider(
                        color: AppColors.screenDividerThemed(context),
                        height: 1,
                      ),
                      const SizedBox(height: 14),

                      // Titre détail
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Détail des notes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
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
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Statistiques',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
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
                              Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'Appréciation',
                              '${matiere['appreciation'] ?? 'N/A'}',
                              Colors.grey[600]!,
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
            color: AppColors.screenCardThemed(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.screenDividerThemed(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'N°${i + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.screenTextSecondaryThemed(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${val.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              Text(
                '/${sur.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.screenTextSecondaryThemed(context),
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
          Text(
            'Aucune note disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Modifiez les filtres pour afficher des résultats',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondaryThemed(context),
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
