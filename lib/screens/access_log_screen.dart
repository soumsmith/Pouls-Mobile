import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/access_log.dart';
import '../services/access_log_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';

/// Écran d'affichage des logs d'accès d'un élève
class AccessLogScreen extends StatefulWidget implements MainScreenChild {
  final String childId;
  final String childName;

  const AccessLogScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AccessLogScreen> createState() => _AccessLogScreenState();
}

class _AccessLogScreenState extends State<AccessLogScreen> 
    with TickerProviderStateMixin {
  List<AccessLog> _accessLogs = [];
  List<AccessLog> _filteredLogs = [];
  AccessLogStats? _stats;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  String _selectedPeriod = '7 jours';
  AccessType? _selectedType;
  bool _showFilters = false;
  
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final AccessLogService _accessLogService = MockAccessLogService();
  
  final TextEditingController _searchController = TextEditingController();

  final List<String> _periods = ['Aujourd\'hui', '7 jours', '30 jours', '3 mois'];
  final List<AccessType> _accessTypes = AccessType.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      // Charger les logs selon la période sélectionnée
      final logs = await _getLogsForPeriod(_selectedPeriod);
      
      // Charger les statistiques
      final stats = await _accessLogService.getAccessLogStats(widget.childId, _selectedPeriod);
      
      setState(() {
        _accessLogs = logs;
        _filteredLogs = logs;
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

  Future<List<AccessLog>> _getLogsForPeriod(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'Aujourd\'hui':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case '7 jours':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 jours':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3 mois':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return await _accessLogService.getAccessLogsForChildInPeriod(
      widget.childId, 
      startDate, 
      endDate,
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _accessLogs.where((log) {
        // Filtrer par type
        if (_selectedType != null && log.accessType != _selectedType) {
          return false;
        }
        
        // Filtrer par recherche
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          if (!log.childName.toLowerCase().contains(query) &&
              !log.location!.toLowerCase().contains(query) &&
              !log.notes!.toLowerCase().contains(query)) {
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

  Future<void> _exportToCSV() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final csvData = await _accessLogService.exportAccessLogsToCSV(
        widget.childId,
        startDate,
        now,
      );
      
      // Copier dans le presse-papiers pour simplifier
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
          'Logs d\'Accès',
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
            Tab(text: 'Logs'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
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
          child: _filteredLogs.isEmpty 
              ? _buildEmptyState()
              : _buildLogsList(),
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
          
          // Période
          Text(
            'Période',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              fontWeight: FontWeight.w500,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _periods.map((period) {
              final isSelected = period == _selectedPeriod;
              return FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadData();
                },
                backgroundColor: AppColors.getSurfaceColor(isDark),
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.getTextColor(isDark),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Type d'accès
          Text(
            'Type d\'accès',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              fontWeight: FontWeight.w500,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _accessTypes.map((type) {
              final isSelected = type == _selectedType;
              return FilterChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                  _applyFilters();
                },
                backgroundColor: AppColors.getSurfaceColor(isDark),
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.getTextColor(isDark),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
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

  Widget _buildLogsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(AccessLog log) {
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
            // En-tête avec type et heure
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAccessTypeColor(log.accessType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getAccessTypeColor(log.accessType).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAccessTypeIcon(log.accessType),
                        size: 16,
                        color: _getAccessTypeColor(log.accessType),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        log.accessType.displayName,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                          color: _getAccessTypeColor(log.accessType),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  log.formattedTime,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations principales
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(width: 8),
                Text(
                  log.formattedDate,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
                if (log.location != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.location!,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            
            if (log.isLate) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.punctualityStatus,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.notes!,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(13),
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            if (log.verificationMethod != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Vérification: ${log.verificationMethod}',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
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
                  Column(
                    children: [
                      _buildStatItem(
                        'Présence',
                        '${_stats!.attendanceRate.toStringAsFixed(1)}%',
                        Icons.present_to_all,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Entrées totales',
                        '${_stats!.totalEntries}',
                        Icons.login,
                        AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Sorties totales',
                        '${_stats!.totalExits}',
                        Icons.logout,
                        AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Carte de ponctualité
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
                    'Ponctualité',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildStatItem(
                        'Retards',
                        _stats!.delaySummary,
                        Icons.access_time,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Sorties anticipées',
                        '${_stats!.earlyExits}',
                        Icons.exit_to_app,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Absences',
                        _stats!.absenceSummary,
                        Icons.event_busy,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Logs récents
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
                    'Activités récentes',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: _stats!.recentLogs.take(5).map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              _getAccessTypeIcon(log.accessType),
                              size: 16,
                              color: _getAccessTypeColor(log.accessType),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${log.accessType.displayName} - ${log.formattedDateTime}',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(13),
                                  color: AppColors.getTextColor(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              Icons.access_time,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun log d\'accès',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée d\'accès disponible pour cette période',
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

  Color _getAccessTypeColor(AccessType type) {
    switch (type) {
      case AccessType.entry:
        return Colors.green;
      case AccessType.exit:
        return Colors.blue;
      case AccessType.lateEntry:
        return Colors.orange;
      case AccessType.earlyExit:
        return Colors.purple;
      case AccessType.absent:
        return Colors.red;
      case AccessType.present:
        return Colors.teal;
    }
  }

  IconData _getAccessTypeIcon(AccessType type) {
    switch (type) {
      case AccessType.entry:
        return Icons.login;
      case AccessType.exit:
        return Icons.logout;
      case AccessType.lateEntry:
        return Icons.access_time;
      case AccessType.earlyExit:
        return Icons.exit_to_app;
      case AccessType.absent:
        return Icons.event_busy;
      case AccessType.present:
        return Icons.present_to_all;
    }
  }
}
