import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_colors.dart';
import '../models/annee_consultation.dart';
import '../models/bulletin_consultation.dart';
import '../services/consultation_api_service.dart';
import '../utils/notification_helper.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/custom_loader.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/bottom_sheets/reusable_bottom_sheet.dart';
import '../widgets/components/custom_error_state.dart';
import '../widgets/scroll_to_top_fab.dart';

/// Écran "Mes Notes", branché sur l'API de consultation
/// (api-pedagogie.pouls-scolaire.net, voir API-CONSULTATION-MOBILE.pdf §4).
///
/// `schoolId` est la référence opaque de l'établissement (résolue par
/// l'appelant via [ConsultationApiService.findSchoolIdByCode]) ; `classeRef`
/// est facultatif et ne joue que sur l'année courante (élève inscrit dans
/// deux classes, doc §4.5).
class NotesScreenJson extends StatefulWidget {
  final String matricule;
  final String schoolId;
  final String? classeRef;

  const NotesScreenJson({
    super.key,
    required this.matricule,
    required this.schoolId,
    this.classeRef,
  });

  @override
  State<NotesScreenJson> createState() => _NotesScreenJsonState();
}

class _NotesScreenJsonState extends State<NotesScreenJson>
    with SingleTickerProviderStateMixin {
  final ConsultationApiService _consultationApi = ConsultationApiService();

  List<AnneeConsultation> _annees = [];
  AnneeConsultation? _selectedAnnee;
  bool _isLoadingYears = false;

  // Un bulletin par période ayant des notes pour l'année sélectionnée
  // (doc §4.8) : changer de période n'a donc pas besoin d'un nouvel appel.
  List<BulletinConsultation> _bulletinsAnnee = [];
  BulletinConsultation? _selectedBulletin;
  bool _isLoading = true;

  String? _selectedSubject;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Carrousel auto-play
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // Cache d'affichage pour éviter un flash pendant un rechargement
  String _cachedNom = '';
  String _cachedPrenoms = '';

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _pageController = PageController(viewportFraction: 1.0);

    _loadYears();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  // ─── CHARGEMENT ───────────────────────────────────────────────────────────

  Future<void> _loadYears() async {
    setState(() => _isLoadingYears = true);
    try {
      final annees = await _consultationApi.getAnnees(widget.schoolId);
      if (!mounted) return;
      AnneeConsultation? current;
      if (annees.isNotEmpty) {
        current = annees.firstWhere(
          (a) => a.courante,
          orElse: () => annees.first,
        );
      }
      setState(() {
        _annees = annees;
        _selectedAnnee = current;
        _isLoadingYears = false;
      });
      if (current != null) {
        await _loadBulletinsForSelectedYear();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingYears = false;
        _isLoading = false;
      });
      _showError('lors du chargement des années scolaires: $e');
    }
  }

  Future<void> _loadBulletinsForSelectedYear() async {
    if (_selectedAnnee == null) return;
    setState(() {
      _isLoading = true;
      _selectedSubject = null;
    });
    try {
      final annee = _selectedAnnee!;
      var bulletins = await _consultationApi.getBulletins(
        widget.schoolId,
        widget.matricule,
        anneeRef: annee.ref,
        classeRef: widget.classeRef,
      );
      var effectiveAnnee = annee;

      // Repli sur la dernière année ayant des bulletins si l'année courante
      // (sélection par défaut, pas un choix explicite de l'utilisateur) n'en
      // a pas encore — cas fréquent en tout début d'année scolaire.
      if (bulletins.isEmpty && annee.courante) {
        for (final candidate in _annees) {
          if (candidate.ref == annee.ref) continue;
          final result = await _consultationApi.getBulletins(
            widget.schoolId,
            widget.matricule,
            anneeRef: candidate.ref,
            classeRef: widget.classeRef,
          );
          if (result.isNotEmpty) {
            bulletins = result;
            effectiveAnnee = candidate;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _bulletinsAnnee = bulletins;
        _selectedAnnee = effectiveAnnee;
        _selectedBulletin = bulletins.isEmpty ? null : bulletins.last;
        _isLoading = false;
        if (_selectedBulletin != null) {
          if (_selectedBulletin!.nom.isNotEmpty) _cachedNom = _selectedBulletin!.nom;
          if (_selectedBulletin!.prenoms.isNotEmpty) {
            _cachedPrenoms = _selectedBulletin!.prenoms;
          }
        }
      });
      if (_selectedBulletin != null) {
        _fadeController.forward(from: 0);
        _startAutoPlay();
      } else {
        _showInfo('Aucune note disponible pour cette année scolaire');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bulletinsAnnee = [];
        _selectedBulletin = null;
        _isLoading = false;
      });
      _showError('lors du chargement des bulletins: $e');
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_selectedBulletin != null) {
        setState(() => _currentPage = (_currentPage + 1) % 2);
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() => _autoPlayTimer?.cancel();

  void _showError(String msg) {
    if (!mounted) return;
    NotificationHelper.showError('Erreur $msg');
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    NotificationHelper.showInfo(msg);
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
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

  List<MatiereBulletin> _getFilteredMatieres() {
    final matieres = _selectedBulletin?.matieres ?? [];
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      return matieres.where((m) => m.libelle == _selectedSubject).toList();
    }
    return matieres;
  }

  List<String> get _availableSubjects {
    final matieres = _selectedBulletin?.matieres ?? [];
    if (matieres.isEmpty) return ['Toutes'];
    return ['Toutes', ...matieres.map((m) => m.libelle)];
  }

  /// Désambiguïse des libellés identiques (ex. deux années archivées
  /// distinctes — refs différentes, ex. H:297/H:226 — toutes deux libellées
  /// « Année 2024 - 2025 ») : sans ça, le dropdown les coche toutes les
  /// deux à la fois (comparaison par texte affiché) et il devient
  /// impossible de choisir la bonne.
  List<String> _dedupeLabels(List<String> labels) {
    final counts = <String, int>{};
    for (final l in labels) {
      counts[l] = (counts[l] ?? 0) + 1;
    }
    final seen = <String, int>{};
    return labels.map((l) {
      if ((counts[l] ?? 0) <= 1) return l;
      seen[l] = (seen[l] ?? 0) + 1;
      return '$l (${seen[l]})';
    }).toList();
  }

  List<String> get _availableYears =>
      _dedupeLabels(_annees.map((a) => a.libelle).toList());

  /// Libellé affiché pour [annee], cohérent avec [_availableYears] même en
  /// cas de doublon (même index dans les deux listes, qui partagent le
  /// même ordre).
  String _yearDisplayLabel(AnneeConsultation? annee) {
    if (annee == null) return 'Chargement...';
    final idx = _annees.indexWhere((a) => a.ref == annee.ref);
    if (idx < 0) return annee.libelle;
    return _availableYears[idx];
  }

  List<String> get _availablePeriods =>
      _bulletinsAnnee.map((b) => b.periodeLibelle).toList();

  void _showFiltersBottomSheet() {
    AnneeConsultation? tempAnnee = _selectedAnnee;
    String? tempSelectedSubject = _selectedSubject;
    BulletinConsultation? tempBulletin = _selectedBulletin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool isDark = AppColors.isDarkMode(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ReusableBottomSheet(
                title: 'Filtres',
                icon: Icons.tune,
                iconColor: AppColors.primary,
                initialChildSize: 0.75,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                content: Column(
                  children: [
                    const SizedBox(height: 16),
                    SearchableDropdown(
                      label: 'Année scolaire',
                      value: _yearDisplayLabel(tempAnnee),
                      items: _availableYears,
                      onChanged: (val) {
                        setSheetState(() {
                          final idx = _availableYears.indexOf(val);
                          final annee = idx >= 0 ? _annees[idx] : tempAnnee!;
                          tempAnnee = annee;
                          tempSelectedSubject = null;
                          tempBulletin = null;
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
                                tempSelectedSubject = val == 'Toutes'
                                    ? null
                                    : val;
                              });
                            },
                            isDarkMode: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SearchableDropdown(
                            label: 'Période',
                            value:
                                (tempBulletin ?? _selectedBulletin)
                                    ?.periodeLibelle ??
                                'Période',
                            items: _availablePeriods,
                            onChanged: (val) {
                              setSheetState(() {
                                tempBulletin = _bulletinsAnnee.firstWhere(
                                  (b) => b.periodeLibelle == val,
                                  orElse: () => _selectedBulletin!,
                                );
                              });
                            },
                            isDarkMode: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                fixedBottomWidget: Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDark),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        final yearChanged =
                            tempAnnee?.ref != _selectedAnnee?.ref;
                        final subjectChanged =
                            tempSelectedSubject != _selectedSubject;
                        final periodChanged =
                            tempBulletin != null &&
                            tempBulletin!.periodeRef !=
                                _selectedBulletin?.periodeRef;

                        if (yearChanged) {
                          setState(() => _selectedAnnee = tempAnnee);
                          _loadBulletinsForSelectedYear();
                        } else if (periodChanged) {
                          setState(() {
                            _selectedBulletin = tempBulletin;
                            _selectedSubject = tempSelectedSubject;
                          });
                          _fadeController.forward(from: 0);
                        } else if (subjectChanged) {
                          setState(
                            () => _selectedSubject = tempSelectedSubject,
                          );
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
                      child: const Center(
                        child: Text(
                          'Appliquer et fermer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
        floatingActionButton: ScrollToTopFab(scrollController: _scrollController),
        body: CustomScrollView(
          controller: _scrollController,
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
                    _showInfo('Actualisation des notes en cours...');
                    _loadBulletinsForSelectedYear();
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
            if (_isLoading || _isLoadingYears)
              SliverFillRemaining(child: _buildLoadingState())
            else
              ..._buildContentSlivers(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomLoader(
      message: 'Chargement des notes...',
      loaderColor: AppColors.screenOrange,
      backgroundColor: AppColors.screenBg(context),
      showBackground: false,
    );
  }

  // ─── CONTENT SLIVERS ────────────────────────────────────────────────────────
  List<Widget> _buildContentSlivers() {
    if (_selectedBulletin == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: _buildEmptyState(),
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
              if (_selectedBulletin!.estProvisoire) _buildProvisoireBanner(),
              _buildAverageCards(),
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

  Widget _buildProvisoireBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.screenOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.screenOrange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bulletin provisoire : le calcul officiel n\'a pas encore été '
              'lancé, ces moyennes peuvent encore changer.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.screenOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AVERAGE CARDS SECTION ───────────────────────────────────────────────────
  Widget _buildAverageCards() {
    if (_selectedBulletin == null) return const SizedBox.shrink();

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _stopAutoPlay();
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) _startAutoPlay();
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
    final bulletin = _selectedBulletin;
    final nom = bulletin?.nom.isNotEmpty == true ? bulletin!.nom : _cachedNom;
    final prenoms = bulletin?.prenoms.isNotEmpty == true
        ? bulletin!.prenoms
        : _cachedPrenoms;
    final matricule = widget.matricule;
    final anneeLibelle = bulletin?.anneeLibelle ?? _selectedAnnee?.libelle ?? '';
    final moyenneAnnuelle = bulletin?.moyenneAnnuelle;

    // Une carte par période disposant de notes (doc §4.8), triées telles que
    // renvoyées par l'API (ordre des périodes).
    List<Widget> averageCards = _bulletinsAnnee.map((b) {
      final isCurrent = b.periodeRef == bulletin?.periodeRef;
      final moy = b.moyenne ?? 0.0;
      return Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: _buildCompactAverageCard(
          b.periodeLibelle,
          moy.toStringAsFixed(1),
          isCurrent ? Icons.analytics_outlined : Icons.menu_book_outlined,
          _getAverageColor(moy),
        ),
      );
    }).toList();

    if (moyenneAnnuelle != null) {
      averageCards.insert(
        0,
        Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: _buildCompactAverageCardLight(
            'Moy. Annuelle',
            moyenneAnnuelle.toStringAsFixed(2),
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
                  style: const TextStyle(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge, color: Colors.white, size: 14),
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
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 14,
                            ),
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
          Container(height: 1, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
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
                style: const TextStyle(
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
    final matieres = _selectedBulletin?.matieres ?? [];

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
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
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
            child: matieres.isNotEmpty
                ? _buildNotesChart(matieres)
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

  Widget _buildNotesChart(List<MatiereBulletin> matieres) {
    final sortedMatieres = List<MatiereBulletin>.from(matieres)
      ..sort((a, b) => (b.moyenne ?? 0.0).compareTo(a.moyenne ?? 0.0));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: (sortedMatieres.length * 35.0).clamp(300.0, double.infinity),
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: 20,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).scaffoldBackgroundColor,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final matiere = sortedMatieres[group.x.toInt()];
                  return BarTooltipItem(
                    '${matiere.libelle}\n',
                    TextStyle(
                      color: AppColors.screenTextPrimaryThemed(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${(matiere.moyenne ?? 0.0).toStringAsFixed(2)}/20',
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
                    if (value.toInt() >= 0 && value.toInt() < sortedMatieres.length) {
                      final name = sortedMatieres[value.toInt()].libelle;
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
                              color: AppColors.screenTextSecondaryThemed(context),
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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: sortedMatieres.asMap().entries.map((entry) {
              final index = entry.key;
              final average = entry.value.moyenne ?? 0.0;

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
                    width: 15,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── NOTES SECTION ────────────────────────────────────────────────────────
  Widget _buildNotesSection(List<MatiereBulletin> matieres) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.customLightBlue, AppColors.customLightBlueDark],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
  Widget _buildSubjectCard(MatiereBulletin matiere, int index) {
    final avg = matiere.moyenne ?? 0.0;
    final isExpanded = _expandedSubjectId == matiere.libelle;
    final color = _getAverageColor(avg);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(
            () => _expandedSubjectId = isExpanded ? null : matiere.libelle,
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSubjectIcon(matiere.libelle),
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matiere.libelle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimaryThemed(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            matiere.professeur?.isNotEmpty == true
                                ? matiere.professeur!
                                : 'Coef. ${matiere.coefficient?.toStringAsFixed(1) ?? '1.0'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.screenTextSecondaryThemed(context),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Divider(color: AppColors.screenDividerThemed(context), height: 1),
                      const SizedBox(height: 14),
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
                              matiere.coefficient?.toStringAsFixed(1) ?? '1.0',
                              Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'Rang',
                              matiere.rang != null ? '${matiere.rang}e' : 'N/A',
                              Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBadge(
                              'Moyenne',
                              avg.toStringAsFixed(1),
                              AppColors.screenOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatBadge(
                        'Appréciation',
                        matiere.appreciation?.isNotEmpty == true
                            ? matiere.appreciation!
                            : 'N/A',
                        Colors.grey[600]!,
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

  String? _expandedSubjectId;

  // ─── STAT BADGE ───────────────────────────────────────────────────────────
  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      width: double.infinity,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    if (_annees.isEmpty) {
      return CustomErrorState(
        title: 'Informations indisponibles',
        message:
            'Les informations scolaires de cet élève ne sont pas complètes pour consulter ses notes.',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.screenOrange,
        onRetry: _loadYears,
        retryText: 'Actualiser',
        buttonIsLight: true,
        buttonWidth: 200,
      );
    }
    return CustomErrorState(
      title: 'Aucune note disponible',
      message: 'Modifiez les filtres pour afficher des résultats',
      icon: Icons.assignment_outlined,
      iconColor: AppColors.screenOrange,
    );
  }
}
