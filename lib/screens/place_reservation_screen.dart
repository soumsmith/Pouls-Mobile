import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/place_reservation.dart';
import '../services/place_reservation_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';

/// Écran de gestion des réservations de places
class PlaceReservationScreen extends StatefulWidget implements MainScreenChild {
  final String? parentId;
  final String? establishmentId;

  const PlaceReservationScreen({
    super.key,
    this.parentId,
    this.establishmentId,
  });

  @override
  State<PlaceReservationScreen> createState() => _PlaceReservationScreenState();
}

class _PlaceReservationScreenState extends State<PlaceReservationScreen>
    with TickerProviderStateMixin {
  List<PlaceReservation> _reservations = [];
  List<PlaceReservation> _filteredReservations = [];
  List<PlaceAvailability> _availability = [];
  ReservationStats? _stats;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  bool _showFilters = false;
  
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final PlaceReservationService _reservationService = MockPlaceReservationService();
  
  final TextEditingController _searchController = TextEditingController();
  
  ReservationStatus? _selectedStatus;
  ReservationType? _selectedType;
  String? _selectedEstablishment;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });

    try {
      // Charger les réservations
      final reservations = widget.parentId != null
          ? await _reservationService.getParentReservations(widget.parentId!)
          : await _reservationService.getRecentReservations(50);
      
      // Charger les disponibilités
      final availability = await _reservationService.getPlaceAvailability(
        establishmentId: widget.establishmentId,
      );
      
      // Charger les statistiques
      final stats = await _reservationService.getReservationStats('30 jours', establishmentId: widget.establishmentId);
      
      setState(() {
        _reservations = reservations;
        _filteredReservations = reservations;
        _availability = availability;
        _stats = stats;
        _isLoading = false;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingStats = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14))),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReservations = _reservations.where((reservation) {
        // Filtrer par statut
        if (_selectedStatus != null && reservation.status != _selectedStatus) {
          return false;
        }
        
        // Filtrer par type
        if (_selectedType != null && reservation.type != _selectedType) {
          return false;
        }
        
        // Filtrer par établissement
        if (_selectedEstablishment != null && reservation.establishmentId != _selectedEstablishment) {
          return false;
        }
        
        // Filtrer par classe
        if (_selectedGrade != null && reservation.grade != _selectedGrade) {
          return false;
        }
        
        // Filtrer par recherche
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          if (!reservation.childName.toLowerCase().contains(query) &&
              !reservation.parentName.toLowerCase().contains(query) &&
              !reservation.establishmentName.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _showCreateReservationDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateReservationDialog(),
    );
  }

  Future<void> _submitReservation(String reservationId) async {
    try {
      final success = await _reservationService.submitReservation(reservationId);
      
      if (success) {
        _loadData(); // Recharger les données
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation soumise avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la soumission'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReservation(String reservationId) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison de l\'annulation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    if (result == true && reasonController.text.isNotEmpty) {
      try {
        final success = await _reservationService.cancelReservation(reservationId, reasonController.text);
        
        if (success) {
          _loadData(); // Recharger les données
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = await _reservationService.exportReservationsToCSV(
        establishmentId: widget.establishmentId,
      );
      
      await Clipboard.setData(ClipboardData(text: csvData));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Données exportées dans le presse-papiers',
              style: TextStyle(fontSize: _textSizeService.getScaledFontSize(14)),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Réservations de Places',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: AppColors.getTextColor(isDark),
            ),
            onPressed: _toggleFilters,
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: AppColors.getTextColor(isDark),
            ),
            onPressed: _exportToCSV,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.getTextColor(isDark, type: TextType.secondary),
          indicatorColor: AppColors.primary,
          labelStyle: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Réservations'),
            Tab(text: 'Disponibilités'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReservationDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsTab(),
          _buildAvailabilityTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildReservationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filtres animés
        AnimatedBuilder(
          animation: _filterAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _filterAnimation,
              child: _buildFiltersSection(),
            );
          },
        ),
        
        // Barre de recherche
        _buildSearchBar(),
        
        // Résultats
        Expanded(
          child: _filteredReservations.isEmpty 
              ? _buildEmptyState()
              : _buildReservationsList(),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 16),
          
          // Statut
          _buildFilterDropdown('Statut', ReservationStatus.values, _selectedStatus, (value) {
            setState(() {
              _selectedStatus = value;
            });
            _applyFilters();
          }),
          
          const SizedBox(height: 12),
          
          // Type
          _buildFilterDropdown('Type', ReservationType.values, _selectedType, (value) {
            setState(() {
              _selectedType = value;
            });
            _applyFilters();
          }),
          
          const SizedBox(height: 12),
          
          // Établissement
          _buildEstablishmentDropdown(),
          
          const SizedBox(height: 12),
          
          // Classe
          _buildGradeDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(String label, List<T> items, T? selectedItem, Function(T?) onChanged) {
    final isDark = _themeService.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selectedItem,
              onChanged: onChanged,
              isExpanded: true,
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
              items: items.map((item) {
                String displayName;
                if (item is ReservationStatus) displayName = item.displayName;
                else if (item is ReservationType) displayName = item.displayName;
                else displayName = item.toString();
                
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayName),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstablishmentDropdown() {
    final isDark = _themeService.isDarkMode;
    final establishments = [
      {'id': 'school1', 'name': 'École Primaire Jean Jaurès'},
      {'id': 'school2', 'name': 'Collège Victor Hugo'},
      {'id': 'school3', 'name': 'Lycée Marie Curie'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Établissement',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedEstablishment,
              onChanged: (value) {
                setState(() {
                  _selectedEstablishment = value;
                });
                _applyFilters();
              },
              isExpanded: true,
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
              hint: Text(
                'Tous les établissements',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
              ),
              items: establishments.map((establishment) {
                return DropdownMenuItem<String>(
                  value: establishment['id'],
                  child: Text(establishment['name']!),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDropdown() {
    final isDark = _themeService.isDarkMode;
    final grades = ['CP', 'CE1', 'CE2', 'CM1', 'CM2', '6ème', '5ème', '4ème', '3ème', 'Seconde', 'Première', 'Terminale'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classe',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGrade,
              onChanged: (value) {
                setState(() {
                  _selectedGrade = value;
                });
                _applyFilters();
              },
              isExpanded: true,
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
              hint: Text(
                'Toutes les classes',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
              ),
              items: grades.map((grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une réservation...',
          prefixIcon: Icon(Icons.search, color: AppColors.getTextColor(isDark, type: TextType.secondary)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.getSurfaceColor(isDark),
          hintStyle: TextStyle(
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
        ),
        style: TextStyle(
          color: AppColors.getTextColor(isDark),
          fontSize: _textSizeService.getScaledFontSize(14),
        ),
        onChanged: (value) => _applyFilters(),
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = _filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(PlaceReservation reservation) {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec enfant et statut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.childName,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                      Text(
                        '${reservation.establishmentName} - ${reservation.grade}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(reservation.status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    reservation.status.displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(reservation.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Type et année scolaire
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(reservation.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reservation.type.displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(reservation.type),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reservation.academicYear,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Dates importantes
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(width: 6),
                Text(
                  'Créée: ${reservation.formattedCreatedAt}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
                if (reservation.deadline != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: reservation.isOverdue ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Limite: ${reservation.formattedDeadline}',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      color: reservation.isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progression des documents
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Documents: ${reservation.submittedDocuments.length}/${reservation.requiredDocuments.length}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: AppColors.getTextColor(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reservation.documentsCompletionPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: reservation.areAllDocumentsSubmitted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: reservation.documentsCompletionPercentage / 100,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    reservation.areAllDocumentsSubmitted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Paiement
            Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 16,
                  color: reservation.isDepositPaid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  reservation.paymentStatus,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: reservation.isDepositPaid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (reservation.waitlistPosition != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Liste d\'attente: #${reservation.waitlistPosition}',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                if (reservation.status == ReservationStatus.draft)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitReservation(reservation.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Soumettre',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (reservation.status == ReservationStatus.draft) const SizedBox(width: 8),
                if (reservation.status == ReservationStatus.draft || reservation.status == ReservationStatus.submitted)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelReservation(reservation.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    if (_availability.isEmpty) {
      return _buildEmptyState();
    }

    final isDark = _themeService.isDarkMode;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availability.length,
      itemBuilder: (context, index) {
        final availability = _availability[index];
        return _buildAvailabilityCard(availability);
      },
    );
  }

  Widget _buildAvailabilityCard(PlaceAvailability availability) {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        availability.establishmentName,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                      Text(
                        '${availability.grade} - ${availability.academicYear}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAvailabilityStatusColor(availability.availabilityStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAvailabilityStatusColor(availability.availabilityStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    availability.availabilityStatus,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getAvailabilityStatusColor(availability.availabilityStatus),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Disponibilité
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Places disponibles',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
                      Text(
                        '${availability.availablePlaces}/${availability.totalPlaces}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(18),
                          fontWeight: FontWeight.w600,
                          color: availability.hasAvailablePlaces ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liste d\'attente',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
                      Text(
                        '${availability.waitlistCount}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(18),
                          fontWeight: FontWeight.w600,
                          color: availability.waitlistCount > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barre de progression
            LinearProgressIndicator(
              value: availability.availabilityPercentage / 100,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                availability.hasAvailablePlaces ? Colors.green : Colors.red,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Date limite
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: availability.isDeadlinePassed ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  'Date limite: ${availability.applicationDeadline.day}/${availability.applicationDeadline.month}/${availability.applicationDeadline.year}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: availability.isDeadlinePassed ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Frais
            Row(
              children: [
                Text(
                  'Frais: ${availability.reservationFee.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Acompte: ${availability.depositAmount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bouton d'action
            if (availability.isOpenForApplications && !availability.isDeadlinePassed && availability.hasAvailablePlaces)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showCreateReservationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Réserver une place',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return _buildEmptyState();
    }

    final isDark = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de résumé
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé de la période',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _stats!.summary,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Taux de confirmation',
                    '${_stats!.confirmationRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    'Taux de rejet',
                    '${_stats!.rejectionRate.toStringAsFixed(1)}%',
                    Icons.cancel,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          // Revenus
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenus',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Revenus totaux',
                    '${_stats!.totalRevenue.toStringAsFixed(0)} FCFA',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    'Revenus en attente',
                    '${_stats!.pendingRevenue.toStringAsFixed(0)} FCFA',
                    Icons.pending,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          // Réservations récentes
          Container(
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réservations récentes',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._stats!.recentReservations.take(5).map((reservation) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(reservation.status),
                            size: 16,
                            color: _getStatusColor(reservation.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${reservation.childName} - ${reservation.establishmentName}',
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(13),
                                color: AppColors.getTextColor(isDark),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            reservation.formattedCreatedAt,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(11),
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateReservationDialog() {
    final isDark = _themeService.isDarkMode;
    final childNameController = TextEditingController();
    final establishmentController = TextEditingController();
    final gradeController = TextEditingController();
    
    ReservationType selectedType = ReservationType.newAdmission;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle Réservation',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: childNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'enfant',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: establishmentController,
                      decoration: const InputDecoration(
                        labelText: 'Établissement',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Classe',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<ReservationType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de réservation',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        selectedType = value!;
                      },
                      items: ReservationType.values.map((type) {
                        return DropdownMenuItem<ReservationType>(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Logique de création simplifiée
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité de création à implémenter'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Créer',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final isDark = _themeService.isDarkMode;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(12),
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = _themeService.isDarkMode;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.event_seat,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune réservation',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer votre première réservation',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: AppColors.getTextColor(isDark, type: TextType.secondary).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.draft:
        return Colors.grey;
      case ReservationStatus.submitted:
        return Colors.blue;
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.underReview:
        return Colors.purple;
      case ReservationStatus.waitlist:
        return Colors.indigo;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.rejected:
        return Colors.red;
      case ReservationStatus.cancelled:
        return Colors.grey;
      case ReservationStatus.completed:
        return Colors.teal;
    }
  }

  Color _getTypeColor(ReservationType type) {
    switch (type) {
      case ReservationType.newAdmission:
        return Colors.blue;
      case ReservationType.reEnrollment:
        return Colors.green;
      case ReservationType.transfer:
        return Colors.orange;
      case ReservationType.siblingAdmission:
        return Colors.purple;
      case ReservationType.specialProgram:
        return Colors.red;
    }
  }

  Color _getAvailabilityStatusColor(String status) {
    switch (status) {
      case 'Disponible':
        return Colors.green;
      case 'Complet':
        return Colors.red;
      case 'Fermé':
        return Colors.grey;
      case 'Date limite dépassée':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.draft:
        return Icons.edit;
      case ReservationStatus.submitted:
        return Icons.send;
      case ReservationStatus.pending:
        return Icons.hourglass_empty;
      case ReservationStatus.underReview:
        return Icons.search;
      case ReservationStatus.waitlist:
        return Icons.people;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.rejected:
        return Icons.cancel;
      case ReservationStatus.cancelled:
        return Icons.not_interested;
      case ReservationStatus.completed:
        return Icons.done_all;
    }
  }
}
