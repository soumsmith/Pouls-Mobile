import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';
import 'package:parents_responsable/config/app_dimensions.dart';
import 'package:parents_responsable/models/event.dart'; // Import du modèle
import 'package:parents_responsable/screens/event_detail_screen.dart'; // Import de l'écran de détail
import 'package:parents_responsable/services/event_service.dart';
import 'package:parents_responsable/services/text_size_service.dart';
import 'package:parents_responsable/widgets/bottom_sheets/bottom_sheet_header.dart';
import 'package:parents_responsable/widgets/custom_loader.dart';

class SchoolEventBottomSheet extends StatefulWidget {
  final String schoolCode;
  final String schoolName;

  const SchoolEventBottomSheet({
    super.key,
    required this.schoolCode,
    required this.schoolName,
  });

  @override
  State<SchoolEventBottomSheet> createState() => _SchoolEventBottomSheetState();
}

class _SchoolEventBottomSheetState extends State<SchoolEventBottomSheet> {
  final TextSizeService _textSizeService = TextSizeService();

  // On stocke les événements sous forme de modèles pour faciliter la navigation
  List<Map<String, dynamic>> _schoolEvents = [];
  bool _isLoadingEvents = false;
  bool _isLoadingMoreEvents = false;
  bool _hasMoreEvents = true;
  String? _eventsError;
  int _currentEventsPage = 1;
  late int _eventsPerPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eventsPerPage = AppDimensions.getEventsPerPage(context);
      _loadInitialEvents();
    });
  }

  Future<void> _loadInitialEvents() async {
    if (widget.schoolCode.isEmpty) return;

    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final events = await EventService.getEventsForUI(
        schoolCode: widget.schoolCode,
        page: 1,
        perPage: _eventsPerPage,
      );

      if (mounted) {
        setState(() {
          _schoolEvents = events;
          _isLoadingEvents = false;
          _hasMoreEvents = events.length >= _eventsPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eventsError = e.toString();
          _isLoadingEvents = false;
        });
      }
    }
  }

  Future<void> _loadMoreEvents() async {
    if (widget.schoolCode.isEmpty || !_hasMoreEvents || _isLoadingMoreEvents) return;

    setState(() {
      _isLoadingMoreEvents = true;
    });

    try {
      _currentEventsPage++;
      final newEvents = await EventService.getEventsForUI(
        schoolCode: widget.schoolCode,
        page: _currentEventsPage,
        perPage: _eventsPerPage,
      );

      if (mounted) {
        setState(() {
          _schoolEvents.addAll(newEvents);
          _isLoadingMoreEvents = false;
          _hasMoreEvents = newEvents.length >= _eventsPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreEvents = false;
          _currentEventsPage--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const themeColor = Color(0xFF8B5CF6);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHeader(
            icon: Icons.event_rounded,
            iconColor: themeColor,
            title: 'Événements scolaires',
            description: 'Calendrier des activités',
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: _buildEventsList(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(bool isDark) {
    if (_isLoadingEvents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CustomLoader(
            message: 'Chargement des événements...',
            loaderColor: AppColors.screenOrange,
            size: 50.0,
            showBackground: false,
          ),
        ),
      );
    }

    if (_eventsError != null) return _buildErrorState();
    if (_schoolEvents.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Derniers événements',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.screenTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Découvrez les activités de ${widget.schoolName}',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schoolEvents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildEventCard(_schoolEvents[i]),
        ),
        if (_hasMoreEvents) _buildLoadMoreButton(),
        if (_isLoadingMoreEvents)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> eventData) {
    final Color color = eventData['color'] as Color? ?? const Color(0xFF8B5CF6);
    final String? imageUrl = eventData['image'] as String?;
    final bool isAvailable = eventData['available'] as bool? ?? true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final Event? eventModel = eventData['event_object'] as Event?;
          late final Event eventToOpen;

          if (eventModel != null) {
            eventToOpen = eventModel;
          } else {
            try {
              eventToOpen = Event.fromJson(eventData);
            } catch (_) {
              return;
            }
          }

          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: eventToOpen),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppDimensions.getMainShadow(context),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade100,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.getEventCardPadding(context)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.getMediumCardBorderRadius(context)),
                  child: Container(
                    width: AppDimensions.getEventImageSize(context),
                    height: AppDimensions.getEventImageSize(context),
                    color: Colors.grey.withOpacity(0.1),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Icon(Icons.event_note, color: color, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventData['title'] ?? 'Événement',
                        style: TextStyle(
                          fontSize: AppDimensions.getEventTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.screenTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: color.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            eventData['date'] ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.grey.shade600
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            eventData['price'] ?? 'Gratuit',
                            style: TextStyle(
                              color: isAvailable ? color : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (!isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COMPLET',
                                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: GestureDetector(
          onTap: _loadMoreEvents,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
            ),
            child: const Text(
              'Voir plus d\'événements',
              style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucun événement', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Revenez plus tard pour les nouveautés.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Erreur de chargement'),
          TextButton(onPressed: _loadInitialEvents, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}