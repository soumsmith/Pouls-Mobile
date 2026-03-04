import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/parent_suggestion.dart';
import '../services/parent_suggestion_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';

/// Écran de gestion des suggestions parents
class ParentSuggestionScreen extends StatefulWidget implements MainScreenChild {
  final String? parentId;
  final String? establishmentId;

  const ParentSuggestionScreen({
    super.key,
    this.parentId,
    this.establishmentId,
  });

  @override
  State<ParentSuggestionScreen> createState() => _ParentSuggestionScreenState();
}

class _ParentSuggestionScreenState extends State<ParentSuggestionScreen> 
    with TickerProviderStateMixin {
  List<ParentSuggestion> _suggestions = [];
  List<ParentSuggestion> _filteredSuggestions = [];
  SuggestionStats? _stats;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  bool _showFilters = false;
  
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final ParentSuggestionService _suggestionService = MockParentSuggestionService();
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  SuggestionCategory? _selectedCategory;
  SuggestionType? _selectedType;
  SuggestionPriority? _selectedPriority;
  SuggestionStatus? _selectedStatus;
  bool _isAnonymous = false;

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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });

    try {
      // Charger les suggestions
      final suggestions = widget.establishmentId != null
          ? await _suggestionService.getEstablishmentSuggestions(widget.establishmentId!)
          : await _suggestionService.getRecentSuggestions(50);
      
      // Charger les statistiques
      final stats = await _suggestionService.getSuggestionStats('30 jours', establishmentId: widget.establishmentId);
      
      setState(() {
        _suggestions = suggestions;
        _filteredSuggestions = suggestions;
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
      _filteredSuggestions = _suggestions.where((suggestion) {
        // Filtrer par catégorie
        if (_selectedCategory != null && suggestion.category != _selectedCategory) {
          return false;
        }
        
        // Filtrer par type
        if (_selectedType != null && suggestion.type != _selectedType) {
          return false;
        }
        
        // Filtrer par priorité
        if (_selectedPriority != null && suggestion.priority != _selectedPriority) {
          return false;
        }
        
        // Filtrer par statut
        if (_selectedStatus != null && suggestion.status != _selectedStatus) {
          return false;
        }
        
        // Filtrer par recherche
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          if (!suggestion.title.toLowerCase().contains(query) &&
              !suggestion.description.toLowerCase().contains(query) &&
              !suggestion.parentName.toLowerCase().contains(query)) {
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

  void _showCreateSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateSuggestionDialog(),
    );
  }

  Future<void> _createSuggestion() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null || _selectedType == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la catégorie, le type et la priorité'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final suggestion = ParentSuggestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: widget.parentId ?? 'parent_current',
        parentName: 'Parent Actuel',
        childId: 'child_current',
        childName: 'Enfant Actuel',
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        type: _selectedType!,
        priority: _selectedPriority!,
        status: SuggestionStatus.pending,
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
        establishmentId: widget.establishmentId,
        establishmentName: 'École Actuelle',
      );

      final success = await _suggestionService.createSuggestion(suggestion);
      
      if (success) {
        Navigator.of(context).pop();
        _loadData(); // Recharger les données
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Réinitialiser les contrôleurs
        _titleController.clear();
        _descriptionController.clear();
        _selectedCategory = null;
        _selectedType = null;
        _selectedPriority = null;
        _isAnonymous = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la suggestion'),
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

  Future<void> _voteSuggestion(String suggestionId, bool isUpvote) async {
    try {
      final success = isUpvote
          ? await _suggestionService.upvoteSuggestion(suggestionId, widget.parentId ?? 'parent_current')
          : await _suggestionService.downvoteSuggestion(suggestionId, widget.parentId ?? 'parent_current');
      
      if (success) {
        _loadData(); // Recharger les données
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du vote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = await _suggestionService.exportSuggestionsToCSV(
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
          'Suggestions Parents',
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
            Tab(text: 'Suggestions'),
            Tab(text: 'Statistiques'),
            Tab(text: 'Nouvelle'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSuggestionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuggestionsTab(),
          _buildStatsTab(),
          _buildCreateTab(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
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
          child: _filteredSuggestions.isEmpty 
              ? _buildEmptyState()
              : _buildSuggestionsList(),
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
          
          // Catégorie
          _buildFilterDropdown('Catégorie', SuggestionCategory.values, _selectedCategory, (value) {
            setState(() {
              _selectedCategory = value;
            });
            _applyFilters();
          }),
          
          const SizedBox(height: 12),
          
          // Type
          _buildFilterDropdown('Type', SuggestionType.values, _selectedType, (value) {
            setState(() {
              _selectedType = value;
            });
            _applyFilters();
          }),
          
          const SizedBox(height: 12),
          
          // Priorité
          _buildFilterDropdown('Priorité', SuggestionPriority.values, _selectedPriority, (value) {
            setState(() {
              _selectedPriority = value;
            });
            _applyFilters();
          }),
          
          const SizedBox(height: 12),
          
          // Statut
          _buildFilterDropdown('Statut', SuggestionStatus.values, _selectedStatus, (value) {
            setState(() {
              _selectedStatus = value;
            });
            _applyFilters();
          }),
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
                if (item is SuggestionCategory) displayName = item.displayName;
                else if (item is SuggestionType) displayName = item.displayName;
                else if (item is SuggestionPriority) displayName = item.displayName;
                else if (item is SuggestionStatus) displayName = item.displayName;
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

  Widget _buildSearchBar() {
    final isDark = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une suggestion...',
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

  Widget _buildSuggestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _filteredSuggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(ParentSuggestion suggestion) {
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
            // En-tête avec titre et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(suggestion.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(suggestion.status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    suggestion.status.displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(suggestion.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              suggestion.description,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Métadonnées
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(width: 6),
                Text(
                  suggestion.displayName,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(width: 6),
                Text(
                  suggestion.formattedCreatedAt,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Catégorie et priorité
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(suggestion.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.category.displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(suggestion.category),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.priority.displayName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(suggestion.priority),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Actions (votes)
            Row(
              children: [
                IconButton(
                  onPressed: () => _voteSuggestion(suggestion.id, true),
                  icon: Icon(
                    Icons.thumb_up,
                    size: 20,
                    color: Colors.green,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                Text(
                  '${suggestion.upvotes ?? 0}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _voteSuggestion(suggestion.id, false),
                  icon: Icon(
                    Icons.thumb_down,
                    size: 20,
                    color: Colors.red,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                Text(
                  '${suggestion.downvotes ?? 0}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                    'Taux d\'approbation',
                    '${_stats!.approvalRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    'Taux d\'implémentation',
                    '${_stats!.implementationRate.toStringAsFixed(1)}%',
                    Icons.build,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          
          // Suggestions par catégorie
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
                    'Suggestions par catégorie',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._stats!.suggestionsByCategory.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(entry.key),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key.displayName,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(14),
                                color: AppColors.getTextColor(isDark),
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDark),
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
          
          // Top suggestions
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
                    'Suggestions les plus populaires',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._stats!.topVotedSuggestions.take(5).map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion.title,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(13),
                                color: AppColors.getTextColor(isDark),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '+${suggestion.voteScore}',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
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

  Widget _buildCreateTab() {
    final isDark = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer une nouvelle suggestion',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 24),
          
          // Formulaire de création
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
                    'Titre de la suggestion',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Entrez un titre clair et concis...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
                    ),
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: AppColors.getTextColor(isDark),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre suggestion en détail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
                    ),
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: AppColors.getTextColor(isDark),
                    ),
                    maxLines: 5,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Catégorie
                  _buildFilterDropdown('Catégorie', SuggestionCategory.values, _selectedCategory, (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Type
                  _buildFilterDropdown('Type', SuggestionType.values, _selectedType, (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Priorité
                  _buildFilterDropdown('Priorité', SuggestionPriority.values, _selectedPriority, (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Option anonyme
                  Row(
                    children: [
                      Checkbox(
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Text(
                        'Publier anonymement',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de soumission
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Soumettre la suggestion',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSuggestionDialog() {
    final isDark = _themeService.isDarkMode;
    
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
              'Nouvelle Suggestion',
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
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(isDark),
                      ),
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFilterDropdown('Catégorie', SuggestionCategory.values, _selectedCategory, (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }),
                    
                    const SizedBox(height: 16),
                    
                    _buildFilterDropdown('Type', SuggestionType.values, _selectedType, (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    }),
                    
                    const SizedBox(height: 16),
                    
                    _buildFilterDropdown('Priorité', SuggestionPriority.values, _selectedPriority, (value) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          'Anonyme',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(14),
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                      ],
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
                    onPressed: _createSuggestion,
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
              Icons.lightbulb_outline,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune suggestion',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager vos idées !',
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

  Color _getStatusColor(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.pending:
        return Colors.orange;
      case SuggestionStatus.underReview:
        return Colors.blue;
      case SuggestionStatus.approved:
        return Colors.green;
      case SuggestionStatus.rejected:
        return Colors.red;
      case SuggestionStatus.implemented:
        return Colors.purple;
      case SuggestionStatus.closed:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.academic:
        return Colors.blue;
      case SuggestionCategory.infrastructure:
        return Colors.brown;
      case SuggestionCategory.security:
        return Colors.red;
      case SuggestionCategory.communication:
        return Colors.green;
      case SuggestionCategory.activities:
        return Colors.purple;
      case SuggestionCategory.nutrition:
        return Colors.orange;
      case SuggestionCategory.technology:
        return Colors.indigo;
      case SuggestionCategory.staff:
        return Colors.teal;
      case SuggestionCategory.finance:
        return Colors.amber;
      case SuggestionCategory.general:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.low:
        return Colors.green;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.urgent:
        return Colors.purple;
    }
  }
}
