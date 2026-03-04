import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/back_button_widget.dart';
import '../utils/image_helper.dart';
import '../services/events_service.dart';

/// Écran global de tous les événements de tous les établissements
class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  final EventsService _eventsService = EventsService();
  
  // États pour la gestion des données
  List<Map<String, dynamic>> _allEvents = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = ['Tous', 'À venir', 'Aujourd\'hui', 'Cette semaine', 'Passés'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _eventsService.getEventsForUI();
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    var events = _allEvents;
    
    // Apply filter
    if (_selectedFilter != 'Tous') {
      events = _eventsService.filterEventsByStatus(events, _selectedFilter);
    }
    
    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      events = events.where((event) => 
        (event['title'] as String).toLowerCase().contains(searchQuery) ||
        (event['subtitle'] as String).toLowerCase().contains(searchQuery) ||
        (event['establishment'] as String).toLowerCase().contains(searchQuery) ||
        (event['type'] as String).toLowerCase().contains(searchQuery) ||
        (event['content'] as String? ?? '').toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return events;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButtonWidget(),
        title: Center(
          child: Text(
            'Événements scolaires',
            style: AppTypography.appBarTitle.copyWith(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Slide Down Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearching ? 56 : 0,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: _isSearching ? 8 : 0,
            ),
            child: _isSearching
                ? CustomSearchBar(
                    hintText: 'Rechercher un événement...',
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    onClear: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                    autoFocus: true,
                  )
                : null,
          ),
          
          // Filter Tabs
          Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: !isSelected ? AppColors.getSurfaceColor(isDark) : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: Text(
                      filter,
                      style: AppTypography.overline.copyWith(
                        color: isSelected 
                          ? Colors.white 
                          : AppColors.getTextColor(isDark),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results Count or Loading/Error State
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _isLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chargement des événements...',
                        style: TextStyle(
                          fontSize: AppTypography.labelMedium,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : _error != null
                    ? Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erreur: $_error',
                              style: TextStyle(
                                fontSize: AppTypography.labelMedium,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadEvents,
                            icon: Icon(Icons.refresh, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text(
                            '${_filteredEvents.length} événement${_filteredEvents.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: AppTypography.labelMedium,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
          ),
          
          // Events Grid or Loading/Error State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Impossible de charger les événements',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadEvents,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun événement trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Essayez de modifier vos filtres ou votre recherche',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = 2;
                                if (constraints.maxWidth > 600) {
                                  crossAxisCount = 4;
                                }
                                
                                return GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: _filteredEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = _filteredEvents[index];
                                    return _buildEventCard(event);
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final Color color = event['color'] as Color;
    final String? imageUrl = event['image'] as String?;
    final bool isAvailable = event['available'] as bool;
    
    return GestureDetector(
      onTap: () {
        _showEventDetailSheet(event);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    imageUrl != null
                        ? ImageHelper.buildNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: event['title'] ?? 'Event',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.8),
                                  color.withOpacity(0.4),
                                ],
                              ),
                            ),
                            child: Icon(
                              event['icon'] as IconData,
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                    
                    // Date Badge overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event['date'] as String,
                          style: AppTypography.overline.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    // Availability Badge
                    if (!isAvailable)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'COMPLET',
                            style: AppTypography.overline.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      event['title'] as String,
                      style: TextStyle(
                        fontSize: AppTypography.titleSmall - 1,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    
                    // Subtitle (establishment)
                    Text(
                      event['subtitle'] as String,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall - 1,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event['time'] as String,
                              style: AppTypography.overline.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        
                        // Buy Button
                        GestureDetector(
                          onTap: () {
                            _showEventDetailSheet(event);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAvailable ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAvailable ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable ? Icons.shopping_cart : Icons.event_busy,
                                  size: 10,
                                  color: isAvailable ? color : Colors.grey,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  isAvailable ? 'Acheter' : 'Complet',
                                  style: AppTypography.overline.copyWith(
                                    color: isAvailable ? color : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetailSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailSheet(event: event),
    );
  }
}

class _EventDetailSheet extends StatefulWidget {
  final Map<String, dynamic> event;

  const _EventDetailSheet({required this.event});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  int quantity = 1;

  String _calculateTotal(String price, int qty) {
    if (price.toLowerCase().contains('gratuit')) {
      return 'Gratuit';
    }
    
    try {
      final cleanPrice = price.replaceAll('€', '').trim();
      final priceValue = double.parse(cleanPrice);
      final total = priceValue * qty;
      return '${total.toStringAsFixed(2)}€';
    } catch (e) {
      return price;
    }
  }

  void _confirmPurchase() {
    final price = widget.event['price'].toString();
    String totalPrice;
    
    if (price.toLowerCase().contains('gratuit')) {
      totalPrice = 'Gratuit';
    } else {
      try {
        final cleanPrice = price.replaceAll('€', '').trim();
        final priceValue = double.parse(cleanPrice);
        totalPrice = '${(priceValue * quantity).toStringAsFixed(2)}€';
      } catch (e) {
        totalPrice = price;
      }
    }
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Achat confirmé : $quantity ticket(s) pour ${widget.event['title']} - Total: $totalPrice'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Mettre à jour le statut de l'événement si complet
    if (quantity >= 5) { // Simuler une limite de stock
      final parentState = context.findAncestorStateOfType<_AllEventsScreenState>();
      if (parentState != null) {
        final eventIndex = parentState._allEvents.indexWhere((e) => e['id'] == widget.event['id']);
        if (eventIndex != -1) {
          parentState.setState(() {
            parentState._allEvents[eventIndex]['available'] = false;
          });
        }
      }
    }
    
    // TODO: Sauvegarder le ticket dans la base de données ou le stockage local
    _savePurchasedTicket(widget.event, quantity, totalPrice);
  }

  void _savePurchasedTicket(Map<String, dynamic> event, int quantity, String totalPrice) {
    // Logique pour sauvegarder le ticket acheté
    // Pour l'instant, nous allons juste afficher un message de debug
    debugPrint('Ticket sauvegardé: ${event['title']} - Quantité: $quantity - Total: $totalPrice');
    
    // Implémentation future:
    // 1. Sauvegarder dans SharedPreferences ou une base de données locale
    // 2. Ajouter à une liste globale de tickets achetés
    // 3. Synchroniser avec un serveur si nécessaire
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = widget.event['available'] as bool? ?? true;
    final color = widget.event['color'] as Color;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Event Image
          if (widget.event['image'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: ImageHelper.buildNetworkImage(
                  imageUrl: widget.event['image'] as String,
                  placeholder: widget.event['title'] ?? 'Event',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Type
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.event['title'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.event['type'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Event details
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.event['establishment'] as String,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.event['date'] as String,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.event['time'] as String,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Purchase Section
                if (isAvailable) ...[
                  Text(
                    'Acheter des tickets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Text(
                        'Prix unitaire: ${widget.event['price']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() => quantity--);
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.grey,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => quantity++);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: ${_calculateTotal(widget.event['price'].toString(), quantity)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Confirmer l\'achat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  // Event complet
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Événement complet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cet événement n\'accepte plus de réservations',
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
