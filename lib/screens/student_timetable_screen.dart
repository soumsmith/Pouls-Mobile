import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/student_timetable.dart';
import '../services/student_timetable_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';

// ─── Helpers couleurs / icônes ────────────────────────────────────────────────

const Map<String, Color> _subjectColors = {
  'SVT':   Color(0xFF4CAF82),
  'PC':    Color(0xFF5B8DEF),
  'FIQ':   Color(0xFFFF8C42),
  'HG':    Color(0xFFB06EE4),
  'MATH':  Color(0xFFE84B6A),
  'FR':    Color(0xFF00B4D8),
  'ANG':   Color(0xFFFFB627),
  'EPS':   Color(0xFF44BBA4),
  'INFO':  Color(0xFF7B2D8B),
  'PHILO': Color(0xFF8B7355),
};

Color _getSubjectColor(String subject) {
  final upper = subject.toUpperCase();
  for (final e in _subjectColors.entries) {
    if (upper.contains(e.key)) return e.value;
  }
  final hue = (subject.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, 0.52).toColor();
}

String _getSubjectIcon(String subject) {
  final upper = subject.toUpperCase();
  if (upper.contains('SVT'))   return '🌿';
  if (upper.contains('PC'))    return '⚗️';
  if (upper.contains('FIQ'))   return '📐';
  if (upper.contains('HG'))    return '🌍';
  if (upper.contains('MATH'))  return '∑';
  if (upper.contains('FR'))    return '📖';
  if (upper.contains('ANG'))   return '🇬🇧';
  if (upper.contains('EPS'))   return '⚽';
  if (upper.contains('INFO'))  return '💻';
  return '📚';
}

// ─── Constantes ───────────────────────────────────────────────────────────────

const List<String> _kDaysLong  = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
const List<String> _kDaysShort = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];

// ─── Screen principal ─────────────────────────────────────────────────────────

class StudentTimetableScreen extends StatefulWidget {
  final Child child;
  final String? ecoleCode;

  const StudentTimetableScreen({
    super.key,
    required this.child,
    this.ecoleCode,
  });

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with SingleTickerProviderStateMixin {

  List<StudentTimetableEntry> _entries = [];
  bool   _isLoading    = true;
  String? _errorMessage;

  final StudentTimetableService _timetableService = StudentTimetableService();

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // Source de vérité unique pour l'index sélectionné
  int _selectedIndex = 0;

  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();

    _selectedIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    _pageCtrl = PageController(initialPage: _selectedIndex);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    _loadTimetable();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTimetable() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final id      = widget.child.matricule ?? widget.child.id;
      final entries = await _timetableService.getTimetableEntriesForStudent(id);
      setState(() { _entries = entries; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // ── Appelé par le tap sur un jour ─────────────────────────────────────────
  void _onDayTapped(int index) {
    // 1. Met à jour l'état → déclenche rebuild complet du tree
    setState(() => _selectedIndex = index);
    // 2. Anime le PageView vers la page correspondante
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Appelé quand l'utilisateur swipe la page ──────────────────────────────
  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF12131A) : const Color(0xFFF5F6FA),
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
          const SizedBox(height: 16),
          Text('Chargement...', style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ));
    }

    if (_errorMessage != null) {
      return _StateView(
        isDark: isDark, icon: '⚠️',
        title: 'Erreur', subtitle: _errorMessage!,
        buttonLabel: 'Réessayer', onPressed: _loadTimetable,
      );
    }

    if (_entries.isEmpty) {
      return _StateView(
        isDark: isDark, icon: '📭',
        title: 'Aucun emploi du temps',
        subtitle: 'Aucun créneau trouvé pour ${widget.child.firstName}',
        buttonLabel: 'Actualiser', onPressed: _loadTimetable,
      );
    }

    return Column(
      children: [
        // ── Sélecteur de jours
        // IMPORTANT : on passe _selectedIndex directement en paramètre.
        // Comme ce widget est dans le build() du StatefulWidget parent,
        // il sera TOUJOURS rebuildu quand setState() est appelé.
        _DaySelector(
          selectedIndex: _selectedIndex,
          entries: _entries,
          isDark: isDark,
          onTap: _onDayTapped,
        ),

        // ── Pages des cours
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: _onPageChanged,
            itemCount: _kDaysLong.length,
            itemBuilder: (_, dayIndex) {
              final dayEntries = _entries
                  .where((e) => e.jourNumberValue == dayIndex + 1)
                  .toList();
              return _DayPage(
                dayName: _kDaysLong[dayIndex],
                entries: dayEntries,
                isDark: isDark,
                onRefresh: _loadTimetable,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── _DaySelector ─────────────────────────────────────────────────────────────
// StatefulWidget avec son propre ScrollController pour le scroll horizontal

class _DaySelector extends StatefulWidget {
  final int selectedIndex;
  final List<StudentTimetableEntry> entries;
  final bool isDark;
  final void Function(int) onTap;

  const _DaySelector({
    required this.selectedIndex,
    required this.entries,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<_DaySelector> {
  final ScrollController _scrollCtrl = ScrollController();

  // Largeur approximative d'un item pour auto-scroll
  static const double _itemWidth = 80.0;

  @override
  void didUpdateWidget(_DaySelector old) {
    super.didUpdateWidget(old);
    // Quand selectedIndex change, on scrolle pour rendre l'item visible
    if (old.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollCtrl.hasClients) return;
    final offset = (widget.selectedIndex * _itemWidth)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);

    return Container(
      color: widget.isDark ? const Color(0xFF1A1B25) : Colors.white,
      height: 72,
      child: ListView.builder(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: _kDaysShort.length,
        itemBuilder: (context, i) {
          final isSelected = i == widget.selectedIndex;
          final isToday    = i == todayIndex;
          final count      = widget.entries
              .where((e) => e.jourNumberValue == i + 1)
              .length;

          return GestureDetector(
            behavior: HitTestBehavior.opaque, // capture tous les taps
            onTap: () => widget.onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _kDaysShort[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.primary
                          : widget.isDark
                          ? Colors.white54
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count.clamp(0, 4), (_) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.primary.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── _DayPage ─────────────────────────────────────────────────────────────────

class _DayPage extends StatelessWidget {
  final String dayName;
  final List<StudentTimetableEntry> entries;
  final bool isDark;
  final Future<void> Function() onRefresh;

  const _DayPage({
    required this.dayName,
    required this.entries,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('☕', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text('Pas de cours ce $dayName', style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFFB0B7C3),
            fontSize: 15, fontStyle: FontStyle.italic,
          )),
        ],
      ));
    }

    final totalMin = entries.fold<int>(0, (acc, e) {
      try {
        final p1 = e.heureDebut.split(':').map(int.parse).toList();
        final p2 = e.heureFin.split(':').map(int.parse).toList();
        return acc + (p2[0] * 60 + p2[1]) - (p1[0] * 60 + p1[1]);
      } catch (_) { return acc; }
    });
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final dur = h > 0 ? '${h}h${m > 0 ? m.toString().padLeft(2,'0') : ''}' : '${m}min';

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayName, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                  letterSpacing: -0.3,
                )),
                const SizedBox(height: 2),
                Text('${entries.length} cours · $dur', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : const Color(0xFFB0B7C3),
                )),
              ],
            ),
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (context, i) => _CourseCard(course: entries[i], index: i, isDark: isDark),
              childCount: entries.length,
            )),
          ),
        ],
      ),
    );
  }
}

// ─── _CourseCard ──────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final StudentTimetableEntry course;
  final int index;
  final bool isDark;

  const _CourseCard({
    required this.course,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(course.matiere);
    final icon  = _getSubjectIcon(course.matiere);

    String t1 = '', t2 = '';
    try {
      final parts = course.formattedTime.split(' - ');
      t1 = parts[0].replaceAll(':00', '').trim();
      t2 = parts.length > 1 ? parts[1].replaceAll(':00', '').trim() : '';
    } catch (_) { t1 = course.formattedTime; }

    return TweenAnimationBuilder<double>(
      key: ValueKey('${course.matiere}_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 14 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barre colorée gauche
              Container(width: 4, decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              )),

              // Icône
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
              ),

              // Matière + entité
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(course.matiere, style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1D2E),
                      fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1,
                    )),
                    if (course.entite != null && course.entite!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(course.entite!, style: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFFB0B7C3),
                        fontSize: 11.5, fontWeight: FontWeight.w500,
                      )),
                    ],
                    if (course.observations != null && course.observations!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C42).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(course.observations!, style: const TextStyle(
                          color: Color(0xFFFF8C42), fontSize: 11, fontWeight: FontWeight.w500,
                        )),
                      ),
                    ],
                  ],
                ),
              )),

              // Horaires
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TimeChip(time: t1, color: color, isDark: isDark),
                    const SizedBox(height: 4),
                    Icon(Icons.arrow_downward_rounded, size: 10,
                        color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                    const SizedBox(height: 4),
                    _TimeChip(time: t2, color: color, isDark: isDark, isEnd: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _TimeChip ────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String time;
  final Color color;
  final bool isDark;
  final bool isEnd;

  const _TimeChip({
    required this.time,
    required this.color,
    required this.isDark,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnd
            ? (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6))
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(time, style: TextStyle(
        color: isEnd ? (isDark ? Colors.white38 : const Color(0xFF9CA3AF)) : color,
        fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3,
      )),
    );
  }
}

// ─── _StateView ───────────────────────────────────────────────────────────────

class _StateView extends StatelessWidget {
  final bool isDark;
  final String icon, title, subtitle, buttonLabel;
  final VoidCallback onPressed;

  const _StateView({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
            fontSize: 18, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFFB0B7C3),
            fontSize: 13, height: 1.5,
          )),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(buttonLabel, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ));
  }
}