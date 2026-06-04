import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../services/event_service.dart';
import '../services/pays_service.dart';
import '../widgets/filter_row_widget.dart';
import '../models/event.dart';
import 'event_detail_screen.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/components/custom_date_input.dart';
import '../widgets/components/custom_text_input.dart';
import '../widgets/components/bottom_spacer.dart';

// ─── Design tokens (centralisés dans AppColors) ────────────────────────────────

// ─── Couleur par statut d'événement ──────────────────────────────────────────
Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'à venir':
      return const Color(0xFF3B82F6);
    case "aujourd'hui":
      return const Color(0xFF10B981);
    case 'cette semaine':
      return const Color(0xFF8B5CF6);
    case 'passés':
      return const Color(0xFF9CA3AF);
    default:
      return AppColors.screenOrange;
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────────
class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen>
    with TickerProviderStateMixin {
  // ── État ────────────────────────────────────────────────
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEvents = [];
  bool _isLoading = true;
  String? _error;
  
  // Nouveaux filtres API
  final _countryController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  bool _showAdvancedFilters = false;

  List<String> _countriesList = ['Tous'];
  Map<String, String> _paysMap = {'Tous': ''};
  Map<String, String> _paysReverseMap = {'': 'Tous'};
  bool _isLoadingPays = true;

  String? _getApiFormattedDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return dateStr;
    }
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      final day = parts[0];
      final month = parts[1];
      final year = parts[2];
      if (day.length == 2 && month.length == 2 && year.length == 4) {
        return '$year-$month-$day';
      }
    }
    return dateStr;
  }
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // ── Animations ──────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<String> _filters = [
    'Tous',
    'À venir',
    "Aujourd'hui",
    'Cette semaine',
    'Passés',
  ];

  // ── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadPays();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _countryController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Chargement des pays depuis l'API ────────────────────
  Future<void> _loadPays() async {
    try {
      final results = await Future.wait([
        PaysService.getPaysNames(),
        PaysService.getPaysMap(),
        PaysService.getPaysReverseMap(),
      ]);
      if (mounted) {
        setState(() {
          _countriesList = results[0] as List<String>;
          _paysMap = results[1] as Map<String, String>;
          _paysReverseMap = results[2] as Map<String, String>;
          _isLoadingPays = false;
        });
      }
    } catch (e) {
      // En cas d'erreur, garder la liste par défaut
      if (mounted) {
        setState(() => _isLoadingPays = false);
      }
    }
  }

  // ── Données ──────────────────────────────────────────────
  Future<void> _loadEvents({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await EventService.getEvents(
        page: _currentPage, 
        perPage: 16,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        categorie: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        date: _dateController.text.trim().isNotEmpty ? _getApiFormattedDate(_dateController.text.trim()) : null,
      );
      final newEvents = response.data.map((e) => e.toUiMap()).toList();
      
      setState(() {
        if (loadMore) {
          _allEvents.addAll(newEvents);
          _isLoadingMore = false;
        } else {
          _allEvents = newEvents;
          _isLoading = false;
        }
        _hasMore = response.currentPage < response.totalPages;
      });
      
      if (!loadMore) _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
          _currentPage--;
        } else {
          _error = e.toString();
          _isLoading = false;
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    var events = _allEvents;
    if (_selectedFilter != 'Tous') {
      events = EventService.filterEventsByStatus(events, _selectedFilter);
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      events = events
          .where(
            (e) =>
                (e['title'] as String).toLowerCase().contains(q) ||
                (e['subtitle'] as String).toLowerCase().contains(q) ||
                (e['establishment'] as String).toLowerCase().contains(q) ||
                (e['type'] as String).toLowerCase().contains(q) ||
                (e['content'] as String? ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.screenSurfaceThemed(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomSliverAppBar(
                title: 'Événements scolaires',
                isDark: Theme.of(context).brightness == Brightness.dark,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      color: _showAdvancedFilters ? AppColors.screenOrange : AppColors.screenTextPrimaryThemed(context),
                    ),
                    onPressed: () => setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    }),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                    onPressed: () => setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchController.clear();
                    }),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildAdvancedFilters(),
                    if (_showAdvancedFilters) const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterRow()),
              ..._buildBodySlivers(),
            ],
          ),
          // Fondu bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x00F8F8F8),
                      AppColors.screenSurfaceThemed(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildHeader() removed to use CustomSliverAppBar

  // ── Barre de recherche animée ────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearching ? 60 : 0,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: _isSearching
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.screenSurfaceThemed(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.screenBorder(context),
                ),
                boxShadow: AppColors.screenCardShadowThemed(context),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.screenTextPrimaryThemed(context)),
                decoration: InputDecoration(
                  hintText: 'Rechercher un événement...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.screenOrange,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _searchController.clear()),
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAdvancedFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showAdvancedFilters ? 165 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _showAdvancedFilters
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SearchableDropdown(
                          label: 'Pays',
                          value: _paysReverseMap[_countryController.text] ?? 'Tous',
                          items: _countriesList,
                          isDarkMode: Theme.of(context).brightness == Brightness.dark,
                          onChanged: (String val) {
                            setState(() {
                              _countryController.text = _paysMap[val] ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextInput(
                          label: 'Catégorie',
                          hint: 'Catégorie',
                          icon: Icons.category_rounded,
                          controller: _categoryController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomDateInput(
                          label: 'Date',
                          hint: 'JJ/MM/AAAA',
                          icon: Icons.calendar_today_rounded,
                          controller: _dateController,
                          iconColor: AppColors.screenOrange,
                          focusBorderColor: AppColors.screenOrange,
                          inputFormatters: [DateInputFormatter()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _loadEvents(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.screenOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Appliquer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ── Filtres ──────────────────────────────────────────────
  Widget _buildFilterRow() {
    return FilterRowWidget(
      filters: _filters,
      selectedFilter: _selectedFilter,
      onFilterSelected: (f) => setState(() => _selectedFilter = f),
    );
  }

  // ── Corps ────────────────────────────────────────────────
  List<Widget> _buildBodySlivers() {
    if (_isLoading) {
      return [
        SliverFillRemaining(
          child: _buildLoadingState(),
        )
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          child: _buildErrorState(),
        )
      ];
    }
    return _buildContentSlivers();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.screenOrangeLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                color: AppColors.screenOrange,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chargement des événements...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadEcoles,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.screenOrangeGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.screenOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Alias pour cohérence
  void _loadEcoles() => _loadEvents();

  List<Widget> _buildContentSlivers() {
    final items = _filteredEvents;

    return [
      // ── En-tête résultats ────────────────────────
      SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${items.length} ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenOrange,
                        ),
                      ),
                      const TextSpan(
                        text: 'événement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      TextSpan(
                        text: items.length > 1 ? 's' : '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFilter != 'Tous') ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 'Tous'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFilter,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.screenOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: AppColors.screenOrange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      // ── État vide ────────────────────────────────
      if (items.isEmpty)
        SliverFillRemaining(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      size: 40,
                      color: AppColors.screenOrange,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aucun événement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aucun résultat pour ce filtre',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedFilter = 'Tous';
                      _searchController.clear();
                      _countryController.clear();
                      _categoryController.clear();
                      _dateController.clear();
                      _loadEvents();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.screenOrangeGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.screenOrange.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Réinitialiser les filtres',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        // ── Liste d'événements ───────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              if (i == items.length) {
                return _buildLoadMoreButton();
              }
              final event = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (i % 6) * 50),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: _EventCard(
                      event: event,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(
                              event: Event.fromJson(event),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }, childCount: items.length + (_hasMore ? 1 : 0)),
          ),
        ),
        const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
    ];
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.screenOrange),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: GestureDetector(
          onTap: () => _loadEvents(loadMore: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.screenBorder(context)),
              boxShadow: AppColors.screenCardShadow,
            ),
            child: const Text(
              'Voir plus d\'événements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.screenOrange,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card événement (layout horizontal) ──────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = event['color'] as Color;
    final String? imageUrl = event['image'] as String?;
    final String title = event['title'] as String? ?? '';
    final String subtitle =
        event['subtitle'] as String? ?? event['establishment'] as String? ?? '';
    final String date = event['date'] as String? ?? '';
    final String status = event['statutevent'] as String? ?? 'en cours';
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.screenBorder(context) : const Color(0xFFF1F1F1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vignette image (gauche) ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null
                    ? ImageHelper.buildNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: title,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: color.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            event['icon'] as IconData? ?? Icons.event_rounded,
                            size: 32,
                            color: color,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // ── Infos (droite) ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ligne titre
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.screenTextPrimaryThemed(context),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Sous-titre (établissement)
                  Row(
                    children: [
                      Icon(Icons.business, size: 12, color: AppColors.screenTextSecondaryThemed(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Ligne Date et Statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Statut
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'terminé' 
                              ? Colors.grey.withOpacity(0.1) 
                              : const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: status.toLowerCase() == 'terminé' 
                                ? Colors.grey 
                                : const Color(0xFF22C55E),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
