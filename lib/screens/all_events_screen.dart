import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import '../services/events_service.dart';

// ─── Design tokens (centralisés dans AppColors) ────────────────────────────────

// ─── Couleur par statut d'événement ──────────────────────────────────────────
Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'à venir':        return const Color(0xFF3B82F6);
    case "aujourd'hui":    return const Color(0xFF10B981);
    case 'cette semaine':  return const Color(0xFF8B5CF6);
    case 'passés':         return const Color(0xFF9CA3AF);
    default:               return AppColors.screenOrange;
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
  String  _selectedFilter   = 'Tous';
  bool    _isSearching      = false;
  final   _searchController = TextEditingController();
  final   _eventsService    = EventsService();
  List<Map<String, dynamic>> _allEvents = [];
  bool    _isLoading        = true;
  String? _error;

  // ── Animations ──────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  final List<String> _filters = [
    'Tous', 'À venir', "Aujourd'hui", 'Cette semaine', 'Passés',
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
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Données ──────────────────────────────────────────────
  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final events = await _eventsService.getEventsForUI();
      setState(() { _allEvents = events; _isLoading = false; });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    var events = _allEvents;
    if (_selectedFilter != 'Tous') {
      events = _eventsService.filterEventsByStatus(events, _selectedFilter);
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      events = events.where((e) =>
        (e['title']         as String).toLowerCase().contains(q) ||
        (e['subtitle']      as String).toLowerCase().contains(q) ||
        (e['establishment'] as String).toLowerCase().contains(q) ||
        (e['type']          as String).toLowerCase().contains(q) ||
        (e['content'] as String? ?? '').toLowerCase().contains(q),
      ).toList();
    }
    return events;
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.screenSurface,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.screenCard,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.screenCardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF1A1A1A)),
            ),
          ),

          const SizedBox(width: 12),

          // Titre
          const Expanded(
            child: Text(
              'Événements scolaires',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Bouton recherche
          GestureDetector(
            onTap: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            }),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.screenCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.screenCardShadow,
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                size: 20,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de recherche animée ────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearching ? 60 : 0,
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: _isSearching
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.screenSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.screenOrange.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.screenOrange.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un événement...',
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.screenOrange),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _searchController.clear()),
                          child: Icon(Icons.cancel_rounded,
                              size: 18, color: Colors.grey[400]),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            )
          : null,
    );
  }

  // ── Filtres ──────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: AppColors.screenCard,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f        = _filters[i];
            final selected = f == _selectedFilter;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 40),
              builder: (_, v, child) =>
                  Opacity(opacity: v, child: child),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.screenOrangeGradient : null,
                    color: selected ? null : AppColors.screenSurface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.screenOrange.withOpacity(0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Corps ────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    return _buildContent();
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
                  color: AppColors.screenOrange, strokeWidth: 2.5),
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
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadEcoles,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
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

  Widget _buildContent() {
    final items = _filteredEvents;

    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // ── En-tête résultats ────────────────────────
              SliverToBoxAdapter(
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
                          onTap: () =>
                              setState(() => _selectedFilter = 'Tous'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                                const Icon(Icons.close_rounded,
                                    size: 12, color: AppColors.screenOrange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── État vide ────────────────────────────────
              if (items.isEmpty)
                SliverFillRemaining(
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
                          child: const Icon(Icons.event_busy_rounded,
                              size: 40, color: AppColors.screenOrange),
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
                              fontSize: 13, color: Color(0xFF999999)),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedFilter = 'Tous';
                            _searchController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
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
                )
              else
                // ── Liste d'événements ───────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final event = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                                milliseconds: 300 + (i % 6) * 50),
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
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  useSafeArea: true,
                                  builder: (_) => _EventDetailSheet(
                                    event: event,
                                    allEvents: _allEvents,
                                    onEventUpdated: (updated) =>
                                        setState(() => _allEvents = updated),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Fondu bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F8F8F8), AppColors.screenSurface],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom sheet détail ──────────────────────────────────
  void _showEventDetailSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(
        event: event,
        allEvents: _allEvents,
        onEventUpdated: (updated) => setState(() => _allEvents = updated),
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
    final Color color      = event['color'] as Color;
    final String? imageUrl = event['image'] as String?;
    final bool isAvailable = event['available'] as bool? ?? true;
    final String title     = event['title'] as String? ?? '';
    final String subtitle  = event['subtitle'] as String?
        ?? event['establishment'] as String? ?? '';
    final String price     = event['price'] as String? ?? 'Gratuit';
    final String date      = event['date'] as String? ?? '';
    final String time      = event['time'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.screenCardShadow,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Vignette image (gauche) ───────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null
                        ? ImageHelper.buildNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: title,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.85),
                                  color.withOpacity(0.45),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                event['icon'] as IconData? ?? Icons.event_rounded,
                                size: 36,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),

                    // Badge COMPLET
                    if (!isAvailable)
                      Positioned(
                        top: 6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COMPLET',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Infos (droite) ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Ligne titre + bouton delete (icône poubelle)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône info/détail
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Sous-titre (établissement)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Prix + date + stepper
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Prix
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const Spacer(),

                      // Badge date
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Heure + disponibilité dot
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isAvailable) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Complet',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
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

// ─── Bottom sheet détail ──────────────────────────────────────────────────────
class _EventDetailSheet extends StatefulWidget {
  final Map<String, dynamic>         event;
  final List<Map<String, dynamic>>   allEvents;
  final void Function(List<Map<String, dynamic>>) onEventUpdated;

  const _EventDetailSheet({
    required this.event,
    required this.allEvents,
    required this.onEventUpdated,
  });

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  int _quantity = 1;

  String _total(String price, int qty) {
    if (price.toLowerCase().contains('gratuit')) return 'Gratuit';
    try {
      final v = double.parse(price.replaceAll('€', '').trim());
      return '${(v * qty).toStringAsFixed(2)} €';
    } catch (_) {
      return price;
    }
  }

  void _confirmPurchase() {
    final price = widget.event['price'].toString();
    final total = _total(price, _quantity);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity ticket(s) — ${widget.event['title']} · $total',
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    if (_quantity >= 5) {
      final updated = List<Map<String, dynamic>>.from(widget.allEvents);
      final idx = updated.indexWhere((e) => e['id'] == widget.event['id']);
      if (idx != -1) updated[idx]['available'] = false;
      widget.onEventUpdated(updated);
    }
    debugPrint(
        'Ticket: ${widget.event['title']} × $_quantity = $total');
  }

  @override
  Widget build(BuildContext context) {
    final event       = widget.event;
    final Color color = event['color'] as Color;
    final bool avail  = event['available'] as bool? ?? true;
    final String? img = event['image'] as String?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = MediaQuery.of(context).size.height * 0.90;
        return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Poignée ──────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Image ─────────────────────────────────────────
          if (img != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ImageHelper.buildNetworkImage(
                  imageUrl: img,
                  placeholder: event['title'] ?? 'Event',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.85),
                        color.withOpacity(0.45),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      event['icon'] as IconData? ?? Icons.event_rounded,
                      size: 60,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Titre + type ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event['type'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Méta-infos ───────────────────────────────
                _MetaRow(
                  icon: Icons.business_rounded,
                  color: color,
                  text: event['establishment'] as String? ?? '',
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  color: color,
                  text: event['date'] as String,
                  trailing: _MetaRow(
                    icon: Icons.schedule_rounded,
                    color: color,
                    text: event['time'] as String,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Achat / Complet ──────────────────────────
                if (avail) ...[
                  // Diviseur
                  Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  // Prix unitaire + quantité
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prix unitaire',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event['price'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.screenOrange,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Sélecteur quantité
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              onTap: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              onTap: () =>
                                  setState(() => _quantity++),
                              active: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Text(
                        _total(event['price'] as String, _quantity),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.screenOrange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bouton confirmer
                  GestureDetector(
                    onTap: _confirmPurchase,
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.screenOrangeGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.screenOrange.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Confirmer l\'achat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // État complet
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.event_busy_rounded,
                              size: 28,
                              color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Événement complet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cet événement n\'accepte plus\nde réservations',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Padding sécurité bas
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 24),
        ],
        ), // Column
      ),   // SingleChildScrollView
        );   // Container (return)
      },     // builder
    );       // LayoutBuilder
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData   icon;
  final Color      color;
  final String     text;
  final Widget?    trailing;

  const _MetaRow({
    required this.icon,
    required this.color,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData    icon;
  final VoidCallback? onTap;
  final bool        active;

  const _QtyButton({
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active && enabled
              ? AppColors.screenOrangeLight
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? (active ? AppColors.screenOrange : const Color(0xFF444444))
              : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}