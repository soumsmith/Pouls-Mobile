import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/ecole_api_service.dart';
import '../services/niveau_service.dart';
import '../services/scolarite_service.dart';
import '../services/integration_service.dart';
import '../services/blog_service.dart';
import '../services/events_service.dart';
import '../services/recommendation_service.dart';
import '../services/avis_service.dart';
import '../services/testimonial_service.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../widgets/gradient_submit_button.dart';
import '../widgets/app_loader.dart';
import '../models/niveau.dart';
import '../models/scolarite.dart';
import '../models/avis.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/back_button_widget.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import 'all_events_screen.dart';
import 'package:file_picker/file_picker.dart';

/// Écran des établissements
class EstablishmentScreen extends StatefulWidget implements MainScreenChild {
  const EstablishmentScreen({super.key});

  @override
  State<EstablishmentScreen> createState() => _EstablishmentScreenState();
}

class _EstablishmentScreenState extends State<EstablishmentScreen> {
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  final TextSizeService _textSizeService = TextSizeService();
  double _currentTextScale = 1.0;
  
  List<Ecole> _ecoles = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = ['Tous', 'Primaire', 'Collège', 'Lycée', 'Privé', 'Public'];

  @override
  void initState() {
    super.initState();
    _currentTextScale = _textSizeService.getScale();
    _textSizeService.addListener(_onTextSizeChanged);
    _loadEcoles();
  }

  Future<void> _loadEcoles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final ecoles = await EcoleApiService.getAllEcoles();
      
      setState(() {
        _ecoles = ecoles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Ecole> get _filteredItems {
    var items = _ecoles;
    
    // Apply filter
    if (_selectedFilter != 'Tous') {
      items = items.where((ecole) => ecole.typePrincipal == _selectedFilter).toList();
    }
    
    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      items = items.where((ecole) => 
        ecole.parametreNom.toLowerCase().contains(searchQuery) ||
        ecole.ville.toLowerCase().contains(searchQuery) ||
        ecole.adresse.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return items;
  }


  void _onTextSizeChanged() {
    setState(() {
      _currentTextScale = _textSizeService.getScale();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Appliquer l'échelle de texte à tout le widget
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_currentTextScale),
      ),
      child: Scaffold(
        backgroundColor: AppColors.getPureBackground(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.getPureAppBarBackground(isDark),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              // Retour direct à l'accueil
              MainScreenWrapper.of(context).navigateToHome();
            },
          ),
          title: Center(
            child: Text(
              'Établissements',
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
            IconButton(
              icon: Icon(Icons.filter_list, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                // TODO: Show advanced filters
              },
            ),
          ],
        ),
        floatingActionButton: null, // Remove FAB
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
                      hintText: 'Rechercher un établissement...',
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
            
            // Filter Tabs with Event Button
            Container(
              height: 37,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Filter Tabs
                  Expanded(
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
                              style: AppTypography.caption.copyWith(
                                color: isSelected 
                                  ? Colors.white 
                                  : AppColors.getTextColor(isDark),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: AppTypography.titleSmall,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Event Button with Badge
                  Stack(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AllEventsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event, size: 16),
                        label: const Text('Événements', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Badge pour le nombre d'événements
                      FutureBuilder(
                        future: EventsService().getEventsForUI(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final eventCount = snapshot.data!.length;
                            return Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                height: 16,
                                constraints: const BoxConstraints(minWidth: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    eventCount > 99 ? '99+' : '$eventCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Loading State
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            // Error State
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEcoles,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            // Content
            else ...[
              // Results Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${_filteredItems.length} établissements',
                      style: TextStyle(
                        fontSize: AppTypography.labelMedium,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Grid View
                // Grid View
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 600) {
                              crossAxisCount = 4;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 100), // ← marge en bas
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final ecole = _filteredItems[index];
                                return _buildEcoleCard(ecole);
                              },
                            );
                          },
                        ),
                      ),

                      // ← Effet nuage en bas
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
                                  AppColors.getPureBackground(isDark).withOpacity(0),
                                  AppColors.getPureBackground(isDark),
                                  AppColors.getPureBackground(isDark),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEcoleCard(Ecole ecole) {
    final Color color = _getTypeColor(ecole.typePrincipal);
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to establishment details
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EstablishmentDetailScreen(ecole: ecole),
          ),
        );
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
                    ImageHelper.buildNetworkImage(
                      imageUrl: ecole.displayImage,
                      placeholder: ecole.parametreNom ?? 'École',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Type Badge overlay
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
                          ecole.typePrincipal,
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
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        ecole.parametreNom ?? 'École sans nom',
                        style: TextStyle(
                          fontSize: AppTypography.titleSmall,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Subtitle
                      Text(
                        ecole.adresse,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // City indicator
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ecole.ville,
                              style: AppTypography.overline.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'primaire':
        return const Color(0xFF3B82F6);
      case 'collège':
        return const Color(0xFF8B5CF6);
      case 'lycée':
        return const Color(0xFF10B981);
      case 'privé':
        return const Color(0xFFF59E0B);
      case 'public':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  void dispose() {
    _textSizeService.removeListener(_onTextSizeChanged);
    _searchController.dispose();
    super.dispose();
  }
}

/// Écran de détail d'un établissement avec onglets
class EstablishmentDetailScreen extends StatefulWidget implements MainScreenChild {
  final Ecole ecole;
  
  const EstablishmentDetailScreen({super.key, required this.ecole});

  @override
  State<EstablishmentDetailScreen> createState() => _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends State<EstablishmentDetailScreen>
    with TickerProviderStateMixin implements MainScreenChild {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  EcoleDetail? _ecoleDetail;
  String? _expandedBranche; // Suivre la branche actuellement ouverte
  late Future<ScolariteResponse> _scolariteFuture; // Stocker le Future pour éviter les rechargements
  String _searchQuery = ''; // Requête de recherche pour filtrer les branches

  // Variables pour la communication et les événements
  List<Map<String, dynamic>> _blogs = [];
  List<Map<String, dynamic>> _schoolEvents = [];
  List<Map<String, dynamic>> _avis = [];
  bool _isLoadingBlogs = false;
  bool _isLoadingEvents = false;
  bool _isLoadingAvis = false;
  String? _blogsError;
  String? _eventsError;
  String? _avisError;
  final BlogService _blogService = BlogService();
  final EventsService _eventsService = EventsService();
  final AvisService _avisService = AvisService();

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'primaire':
        return const Color(0xFF3B82F6);
      case 'collège':
        return const Color(0xFF8B5CF6);
      case 'lycée':
        return const Color(0xFF10B981);
      case 'privé':
        return const Color(0xFFF59E0B);
      case 'public':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 6, vsync: this);
  _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  
  _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  ));
  _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
  ));
  
  _tabController.addListener(() {
    setState(() {});
  });
  
  _loadEcoleDetail();
  _loadBlogsEventsAndAvis();
  _animationController.forward();
  
  _scolariteFuture = ScolariteService.getScolaritesByEcole(widget.ecole.parametreCode);
}

  Future<void> _loadEcoleDetail() async {
    try {
      final detail = await EcoleApiService.getEcoleDetail(widget.ecole.parametreCode);
      
      setState(() {
        _ecoleDetail = detail;
      });
    } catch (e) {
      // En cas d'erreur, on garde _ecoleDetail à null pour utiliser les données de base
      print('Erreur lors du chargement des détails: $e');
    }
  }

  Future<void> _loadBlogsEventsAndAvis() async {
    final nomEtablissement = widget.ecole.parametreNom ?? '';
    final codeEcole = widget.ecole.parametreCode ?? '';
    
    if (nomEtablissement.isEmpty || codeEcole.isEmpty) return;
    
    // Charger les blogs
    setState(() {
      _isLoadingBlogs = true;
      _blogsError = null;
    });
    
    try {
      final blogs = await _blogService.getBlogsForUI(nomEtablissement);
      setState(() {
        _blogs = blogs;
        _isLoadingBlogs = false;
      });
    } catch (e) {
      setState(() {
        _blogsError = e.toString();
        _isLoadingBlogs = false;
      });
    }
    
    // Charger les événements
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });
    
    try {
      final events = await _eventsService.getEventsForUI(nomEtablissement: nomEtablissement);
      setState(() {
        _schoolEvents = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _eventsError = e.toString();
        _isLoadingEvents = false;
      });
    }
    
    // Charger les avis
    setState(() {
      _isLoadingAvis = true;
      _avisError = null;
    });
    
    try {
      final avis = await _avisService.getAvisForUI(codeEcole);
      setState(() {
        _avis = avis;
        _isLoadingAvis = false;
      });
    } catch (e) {
      setState(() {
        _avisError = e.toString();
        _isLoadingAvis = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    final Color color = _getTypeColor(widget.ecole.typePrincipal);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_themeService, _textSizeService]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.getPureBackground(isDarkMode),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(color),
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              _buildHeroImage(),
                              _buildEstablishmentInfo(color),
                              _buildActionButtons(color),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _CustomTabBarDelegate(
                    Container(
                      color: isDarkMode ? AppColors.pureBlack : AppColors.getSurfaceColor(isDarkMode),
                      child: _buildModernTabBar(),
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              color: isDarkMode ? AppColors.pureBlack : AppColors.getSurfaceColor(isDarkMode),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnifiedInfoTab(),
                    _buildCommunicationTab(),
                    _buildLevelsTab(),
                    _buildEventsTab(),
                    _buildScolariteTab(),
                    _buildNotesTab(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(Color color) {
    final theme = Theme.of(context);
    final isDarkMode = _themeService.isDarkMode;
    
    return SliverAppBar(
      expandedHeight: 20,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.getPureAppBarBackground(isDarkMode),
      elevation: 0,
      forceElevated: false,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Détails de l\'établissement',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: _textSizeService.getScaledFontSize(20),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.favorite_border, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Add to favorites
          },
        ),
        IconButton(
          icon: Icon(Icons.share, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Share establishment
          },
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
        onPressed: () {
          if (MainScreenWrapper.maybeOf(context) != null) {
            MainScreenWrapper.of(context).navigateToHome();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildHeroImage() {
    // Utiliser l'image du détail si disponible, sinon celle de l'école de base
    final imageUrl = _ecoleDetail?.image ?? widget.ecole.displayImage;
    
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ImageHelper.buildNetworkImage(
          imageUrl: imageUrl,
          placeholder: widget.ecole.parametreNom ?? 'École',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildEstablishmentInfo(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
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
              Expanded(
                child: Text(
                  widget.ecole.parametreNom ?? 'École',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(22),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  widget.ecole.typePrincipal,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: _textSizeService.getScaledFontSize(12),
                  ),
                ),
              ),
            ],
          ),
          
          // Slogan si disponible
          if (_ecoleDetail?.data.slogan != null && _ecoleDetail!.data.slogan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${_ecoleDetail!.data.slogan!}"',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.ecole.adresse ?? 'Adresse non disponible'}, ${widget.ecole.ville ?? 'Ville non disponible'}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          
          // Téléphone si disponible dans les détails
          if (_ecoleDetail?.data.telephone != null && _ecoleDetail!.data.telephone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _ecoleDetail!.data.telephone,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
          
          // Email si disponible dans les détails
          if (_ecoleDetail?.data.email != null && _ecoleDetail!.data.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ecoleDetail!.data.email!,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Bouton Demande d'intégration
            ElevatedButton.icon(
              onPressed: () {
                _showIntegrationBottomSheet();
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Intégration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Bouton Noter & commenter
            OutlinedButton.icon(
              onPressed: () {
                _showRatingBottomSheet();
              },
              icon: const Icon(Icons.star_rate_rounded, size: 16),
              label: const Text('Noter'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Bouton Parrainer
            OutlinedButton.icon(
              onPressed: () {
                _showSponsorshipBottomSheet();
              },
              icon: const Icon(Icons.card_giftcard_rounded, size: 16),
              label: const Text('Parrainer'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Bouton Recommander une école
            OutlinedButton.icon(
              onPressed: () {
                _showRecommendationBottomSheet();
              },
              icon: const Icon(Icons.recommend_rounded, size: 16),
              label: const Text('Recommander'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Bouton Partager
            OutlinedButton.icon(
              onPressed: () {
                _showShareBottomSheet();
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Partager'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    final isDarkMode = _themeService.isDarkMode;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_tabController, _textSizeService]),
      builder: (context, _) {
        return Container(
          height: 35,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 11.5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppColors.getSurfaceColor(isDarkMode)
                        : null,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTabIcon(index),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTabTitle(index),
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(14),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.info_rounded;
      case 1:
        return Icons.campaign_rounded;
      case 2:
        return Icons.school_rounded;
      case 3:
        return Icons.event_rounded;
      case 4:
        return Icons.account_balance_wallet_rounded;
      case 5:
        return Icons.star_rate_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Informations';
      case 1:
        return 'Communication';
      case 2:
        return 'Niveaux';
      case 3:
        return 'Event school';
      case 4:
        return 'Scolarité';
      case 5:
        return 'Notes';
      default:
        return '';
    }
  }

  void _showRecommendationBottomSheet() {
    // Pré-remplir avec les données de l'école actuelle
    _etablissementController.text = widget.ecole.parametreNom ?? '';
    _paysController.text = 'Côte d\'Ivoire';
    _villeController.text = 'Abidjan';
    _ordreController.text = 'Primaire, collège';
    _adresseEtablissementController.text = 'Adjamé';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar with improved design
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header with better spacing and design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommander une école',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aidez-nous à découvrir de nouveaux établissements',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(13),
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button with better design
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.grey600,
                        size: 20,
                      ),
                      iconSize: 20,
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ),
              
            const SizedBox(height: 8),
              
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.grey200,
            ),
              
            // Form content with better padding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Section Établissement with improved design
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Informations sur l\'établissement',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(16),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFormField('Nom de l\'établissement', 'Entrez le nom de l\'établissement', Icons.business_rounded, controller: _etablissementController),
                          const SizedBox(height: 12),
                          _buildFormField('Adresse', 'Adresse complète', Icons.location_on_rounded, controller: _adresseEtablissementController),
                          const SizedBox(height: 12),
                          _buildFormField('Ordre', 'Ex: Primaire, collège...', Icons.category_rounded, controller: _ordreController),
                          const SizedBox(height: 12),
                          _buildFormField('Ville', 'Ville de l\'établissement', Icons.location_city_rounded, controller: _villeController),
                          const SizedBox(height: 12),
                          _buildFormField('Pays', 'Pays de l\'établissement', Icons.public_rounded, controller: _paysController),
                        ],
                      ),
                    ),
                      
                    // Section Parent with improved design
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vos informations',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(16),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField('Nom', 'Votre nom', Icons.person_rounded, controller: _parentNomController),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField('Prénom', 'Votre prénom', Icons.person_outline_rounded, controller: _parentPrenomController),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFormField('Téléphone', 'Votre numéro de téléphone', Icons.phone_rounded, controller: _parentTelephoneController),
                          const SizedBox(height: 12),
                          _buildFormField('Email', 'Votre adresse email', Icons.email_rounded, controller: _recommandationEmailController),
                          const SizedBox(height: 12),
                          _buildFormField('Pays', 'Votre pays', Icons.public_rounded, controller: _parentPaysController),
                          const SizedBox(height: 12),
                          _buildFormField('Ville', 'Votre ville', Icons.location_city_rounded, controller: _parentVilleController),
                          const SizedBox(height: 12),
                          _buildFormField('Adresse', 'Votre adresse', Icons.home_rounded, controller: _parentAdresseController),
                        ],
                      ),
                    ),
                      
                    const SizedBox(height: 32),
                      
                    // Submit button with reduced width and improved design
                    Center(
                      child: RecommendationSubmitButton(
                        onPressed: () async {
                            // Logger le début du processus
                            developer.log('🎯 Début de la soumission de recommandation', name: 'RecommendationForm');
                            
                            // Afficher le loader centralisé
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AppLoader(
                                message: 'Envoi de la recommandation...',
                                backgroundColor: Colors.white,
                                iconColor: AppColors.primary,
                                size: 80.0,
                              ),
                            );
                            
                            // Validation basique
                            if (_etablissementController.text.isEmpty ||
                                _parentNomController.text.isEmpty ||
                                _parentPrenomController.text.isEmpty ||
                                _parentTelephoneController.text.isEmpty ||
                                _recommandationEmailController.text.isEmpty) {
                              developer.log('⚠️ Validation échouée - champs obligatoires manquants', name: 'RecommendationForm');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      const Expanded(child: Text('Veuillez remplir tous les champs obligatoires')),
                                    ],
                                  ),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                              return;
                            }
                            
                            developer.log('✅ Validation réussie - fermeture du formulaire', name: 'RecommendationForm');
                            
                            // Fermer le bottomsheet d'abord
                            Navigator.of(context).pop();
                            
                            // Afficher indicateur de chargement dans un nouveau contexte
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Envoi de votre recommandation...',
                                          style: TextStyle(
                                            fontSize: _textSizeService.getScaledFontSize(14),
                                            color: AppColors.textPrimaryLight,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                            
                            developer.log('📤 Appel de l\'API de recommandation', name: 'RecommendationForm');
                            
                            // Appeler l'API
                            final result = await RecommendationService.submitRecommendation(
                              etablissement: _etablissementController.text,
                              pays: _paysController.text,
                              ville: _villeController.text,
                              ordre: _ordreController.text,
                              adresseEtablissement: _adresseEtablissementController.text,
                              nomParent: _parentNomController.text,
                              prenomParent: _parentPrenomController.text,
                              telephone: _parentTelephoneController.text,
                              email: _recommandationEmailController.text,
                              paysParent: _parentPaysController.text,
                              villeParent: _parentVilleController.text,
                              adresseParent: _parentAdresseController.text,
                            );
                            
                            // Logger le résultat
                            developer.log('📊 Résultat de l\'API: ${result['success']}', name: 'RecommendationForm');
                            developer.log('📝 Message: ${result['message']}', name: 'RecommendationForm');
                            
                            // Fermer le dialogue de chargement
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            
                            // Afficher une notification détaillée
                            if (context.mounted) {
                              if (result['success'] == true) {
                                // Notification de succès
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Recommandation envoyée avec succès!',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              if (result['statusCode'] != null)
                                                Text(
                                                  'Code: ${result['statusCode']}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                ),
                                              if (result['message'] != null && result['message'] != 'Recommandation envoyée avec succès!')
                                                Text(
                                                  '${result['message']}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 5),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                                
                                // Vider les champs après succès
                                _parentNomController.clear();
                                _parentPrenomController.clear();
                                _parentTelephoneController.clear();
                                _recommandationEmailController.clear();
                                _parentPaysController.clear();
                                _parentVilleController.clear();
                                _parentAdresseController.clear();
                                
                                developer.log('🧹 Champs du formulaire vidés après succès', name: 'RecommendationForm');
                                
                                // Fermer le loader et afficher le dialogue de succès
                                Navigator.of(context).pop();
                                _showSuccessDialog('Recommandation envoyée avec succès!');
                              } else {
                                // Notification d'erreur
                                String errorMessage = result['message'] ?? 'Erreur inconnue';
                                String errorDetails = '';
                                
                                if (result['statusCode'] != null) {
                                  errorDetails = ' (Code: ${result['statusCode']})';
                                }
                                
                                if (result['error'] != null && result['error'].toString().length < 100) {
                                  errorDetails += ' - ${result['error']}';
                                }
                                
                                // Fermer le loader et afficher le dialogue d'erreur
                                Navigator.of(context).pop();
                                _showErrorDialog(
                                  'Échec de l\'envoi',
                                  'Une erreur est survenue lors de l\'envoi de votre recommandation.',
                                  details: errorMessage + errorDetails,
                                );
                                
                                developer.log('❌ Erreur affichée à l\'utilisateur: $errorMessage$errorDetails', name: 'RecommendationForm');
                              }
                            }
                          },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntegrationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.15),
                            _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: _getTypeColor(widget.ecole.typePrincipal),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demande d\'intégration',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(18),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.ecole.parametreNom ?? 'École',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(13),
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.grey600,
                          size: 20,
                        ),
                        iconSize: 20,
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.grey200,
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Section Informations élève
                      _buildSectionHeader('Informations de l\'élève'),

                      _buildFormField(
                        'Nom',
                        'Entrez le nom complet',
                        Icons.person_rounded,
                        controller: _studentNameController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Prénoms',
                        'Entrez les prénoms',
                        Icons.person_outline_rounded,
                        controller: _studentFirstNameController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Matricule',
                        'Entrez le matricule',
                        Icons.badge_rounded,
                        controller: _matriculeController,
                      ),

                      const SizedBox(height: 8),

                      _buildDropdownField(
                        'Sexe',
                        'Sélectionner le sexe',
                        Icons.person_rounded,
                        value: _selectedSexe,
                        items: ['M', 'F'],
                        onChanged: (value) {
                          setState(() {
                            _selectedSexe = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Date de naissance',
                        'AAAA-MM-JJ',
                        Icons.cake_rounded,
                        controller: _birthDateController,
                        keyboardType: TextInputType.datetime,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Lieu de naissance',
                        'Entrez le lieu de naissance',
                        Icons.location_on_rounded,
                        controller: _lieuNaissanceController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Nationalité',
                        'Entrez la nationalité',
                        Icons.flag_rounded,
                        controller: _nationaliteController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Adresse',
                        'Entrez l\'adresse complète',
                        Icons.home_rounded,
                        controller: _adresseController,
                      ),

                      const SizedBox(height: 16),

                      // Section Contacts
                      _buildSectionHeader('Contacts'),

                      _buildFormField(
                        'Contact 1',
                        'Entrez le numéro de téléphone principal',
                        Icons.phone_rounded,
                        controller: _contact1Controller,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Contact 2',
                        'Entrez le numéro de téléphone secondaire',
                        Icons.phone_android_rounded,
                        controller: _contact2Controller,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Section Parents
                      _buildSectionHeader('Informations des parents'),

                      _buildFormField(
                        'Nom du père',
                        'Entrez le nom complet du père',
                        Icons.person_rounded,
                        controller: _nomPereController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Nom de la mère',
                        'Entrez le nom complet de la mère',
                        Icons.person_outline_rounded,
                        controller: _nomMereController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Nom du tuteur',
                        'Entrez le nom du tuteur (optionnel)',
                        Icons.supervisor_account_rounded,
                        controller: _nomTuteurController,
                      ),

                      const SizedBox(height: 16),

                      // Section Scolarité antérieure
                      _buildSectionHeader('Scolarité antérieure'),

                      _buildFormField(
                        'Niveau antérieur',
                        'Ex: CP1, 6ème...',
                        Icons.school_rounded,
                        controller: _niveauAntController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'École antérieure',
                        'Entrez le nom de l\'école précédente',
                        Icons.account_balance_rounded,
                        controller: _ecoleAntController,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Moyenne antérieure',
                        'Ex: 12.5',
                        Icons.assessment_rounded,
                        controller: _moyenneAntController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Rang antérieur',
                        'Ex: 3',
                        Icons.format_list_numbered_rounded,
                        controller: _rangAntController,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Décision antérieure',
                        'Ex: Passage, Redoublement...',
                        Icons.gavel_rounded,
                        controller: _decisionAntController,
                      ),

                      const SizedBox(height: 16),

                      // Section Documents
                      _buildSectionHeader('Documents à fournir'),

                      _buildFileUploadField(
                        'Bulletin scolaire',
                        'Sélectionner le bulletin',
                        Icons.description_rounded,
                        fileName: _bulletinFile,
                        onTap: () => _pickFile('bulletin'),
                      ),

                      const SizedBox(height: 8),

                      _buildFileUploadField(
                        'Certificat de vaccination',
                        'Sélectionner le certificat',
                        Icons.medical_services_rounded,
                        fileName: _certificatVaccinationFile,
                        onTap: () => _pickFile('certificat_vaccination'),
                      ),

                      const SizedBox(height: 8),

                      _buildFileUploadField(
                        'Certificat de scolarité',
                        'Sélectionner le certificat',
                        Icons.school_rounded,
                        fileName: _certificatScolariteFile,
                        onTap: () => _pickFile('certificat_scolarite'),
                      ),

                      const SizedBox(height: 8),

                      _buildFileUploadField(
                        'Extrait de naissance',
                        'Sélectionner l\'extrait',
                        Icons.card_membership_rounded,
                        fileName: _extraitNaissanceFile,
                        onTap: () => _pickFile('extrait_naissance'),
                      ),

                      const SizedBox(height: 8),

                      _buildFileUploadField(
                        'CNI des parents',
                        'Sélectionner la CNI',
                        Icons.credit_card_rounded,
                        fileName: _cniParentFile,
                        onTap: () => _pickFile('cni_parent'),
                      ),

                      const SizedBox(height: 16),

                      // Section Détails de la demande
                      _buildSectionHeader('Détails de la demande'),

                      _buildFormField(
                        'Motif',
                        'Ex: Nouvelle inscription, Transfert...',
                        Icons.note_rounded,
                        controller: _motifController,
                      ),

                      const SizedBox(height: 8),

                      _buildDropdownField(
                        'Statut d\'affectation',
                        'Sélectionner le statut',
                        Icons.assignment_turned_in_rounded,
                        value: _selectedStatutAff,
                        items: ['Affecté', 'En attente', 'Refusé'],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatutAff = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 8),

                      _buildFormField(
                        'Filière',
                        'Ex: primaire, secondaire, technique...',
                        Icons.category_rounded,
                        controller: _filiereController,
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      Center(
                        child: GradientSubmitButton(
                          text: 'Envoyer la demande',
                          onPressed: () {
                            _submitIntegrationRequest();
                          },
                          type: SubmitButtonType.primary,
                          icon: Icons.send_rounded,
                          width: 220,
                        ),
                      ),
                    ],
                  ),
                ),
              ), // closes Expanded
            ],   // closes outer Column's children
          ),     // closes Column
        ),       // closes Container
      ),         // closes StatefulBuilder
    );           // closes showModalBottomSheet
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(13),
          fontWeight: FontWeight.bold,
          color: _getTypeColor(widget.ecole.typePrincipal),
        ),
      ),
    );
  }

  Future<void> _pickFile(String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String selectedFileName = result.files.single.name;
        setState(() {
          switch (fileType) {
            case 'bulletin':
              _bulletinFile = selectedFileName;
              break;
            case 'certificat_vaccination':
              _certificatVaccinationFile = selectedFileName;
              break;
            case 'certificat_scolarite':
              _certificatScolariteFile = selectedFileName;
              break;
            case 'extrait_naissance':
              _extraitNaissanceFile = selectedFileName;
              break;
            case 'cni_parent':
              _cniParentFile = selectedFileName;
              break;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné: $selectedFileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitIntegrationRequest() async {
    // Valider les champs obligatoires
    if (_studentNameController.text.isEmpty ||
        _studentFirstNameController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _contact1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Veuillez remplir tous les champs obligatoires'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Créer l'objet de demande selon le format de l'API
    final Map<String, dynamic> requestData = {
      'nom': _studentNameController.text,
      'prenoms': _studentFirstNameController.text,
      'matricule': _matriculeController.text.isNotEmpty ? _matriculeController.text : null,
      'sexe': _selectedSexe,
      'date_naissance': _birthDateController.text,
      'lieu_naissance': _lieuNaissanceController.text.isNotEmpty ? _lieuNaissanceController.text : null,
      'nationalite': _nationaliteController.text.isNotEmpty ? _nationaliteController.text : 'Ivoirienne',
      'adresse': _adresseController.text.isNotEmpty ? _adresseController.text : null,
      'contact_1': _contact1Controller.text,
      'contact_2': _contact2Controller.text.isNotEmpty ? _contact2Controller.text : null,
      'nom_pere': _nomPereController.text.isNotEmpty ? _nomPereController.text : null,
      'nom_mere': _nomMereController.text.isNotEmpty ? _nomMereController.text : null,
      'nom_tuteur': _nomTuteurController.text.isNotEmpty ? _nomTuteurController.text : null,
      'niveau_ant': _niveauAntController.text.isNotEmpty ? _niveauAntController.text : null,
      'ecole_ant': _ecoleAntController.text.isNotEmpty ? _ecoleAntController.text : null,
      'moyenne_ant': _moyenneAntController.text.isNotEmpty ? _moyenneAntController.text : null,
      'rang_ant': _rangAntController.text.isNotEmpty ? int.tryParse(_rangAntController.text) : null,
      'decision_ant': _decisionAntController.text.isNotEmpty ? _decisionAntController.text : null,
      'bulletin': _bulletinFile,
      'certificat_vaccination': _certificatVaccinationFile,
      'certificat_scolarite': _certificatScolariteFile,
      'extrait_naissance': _extraitNaissanceFile,
      'cni_parent': _cniParentFile,
      'motif': _motifController.text.isNotEmpty ? _motifController.text : 'Nouvelle inscription',
      'statut_aff': _selectedStatutAff,
      'filiere': _filiereController.text.isNotEmpty ? _filiereController.text : 'primaire',
    };

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(
        message: 'Envoi de la demande...',
        backgroundColor: Colors.white,
        iconColor: _getTypeColor(widget.ecole.typePrincipal),
        size: 80.0,
      ),
    );

    try {
      // Appeler l'API réelle
      final ecoleCode = widget.ecole.parametreCode ?? '';
      print('📤 Envoi de la demande d\'intégration pour l\'école: $ecoleCode');
      print('📋 Données envoyées: $requestData');
      
      final result = await IntegrationService.submitIntegrationRequest(ecoleCode, requestData);
      
      print('📥 Réponse de l\'API: $result');
      
      // Fermer le dialogue de chargement
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        print('✅ Demande d\'intégration envoyée avec succès: ${result['data']}');
        // Fermer le formulaire
        Navigator.of(context).pop();
        
        // Afficher le succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Demande d\'intégration envoyée avec succès!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Afficher les détails de la réponse
        final responseData = result['data'];
        if (responseData != null && responseData['demande_uid'] != null) {
          print('🆔 Numéro de suivi: ${responseData['demande_uid']}');
          _showSuccessDialog(responseData['demande_uid']);
        }
      } else {
        print('❌ Erreur lors de l\'envoi de la demande: ${result['error']}');
        
        // Gérer spécifiquement l'erreur 409 (demande déjà en cours)
        String errorMessage = result['error'] ?? 'Erreur inconnue';
        String title = 'Erreur lors de l\'envoi';
        String userMessage = 'Une erreur est survenue lors de l\'envoi de votre demande.';
        Color backgroundColor = AppColors.error;
        IconData icon = Icons.error_rounded;
        
        if (errorMessage.contains('409') || errorMessage.contains('déjà en cours')) {
          title = 'Demande déjà en cours';
          userMessage = 'Une demande est déjà en cours pour cet élève dans cette école.';
          backgroundColor = AppColors.warning;
          icon = Icons.info_rounded;
        } else if (errorMessage.contains('400')) {
          title = 'Données invalides';
          userMessage = 'Veuillez vérifier les informations saisies.';
        } else if (errorMessage.contains('500')) {
          title = 'Erreur serveur';
          userMessage = 'Le serveur rencontre des difficultés temporaires.';
        }
        
        // Afficher le dialogue d'erreur amélioré
        _showErrorDialog(title, userMessage, details: errorMessage);
      }
    } catch (e) {
      print('💥 Exception lors de l\'envoi de la demande: $e');
      // Fermer le dialogue de chargement en cas d'erreur
      Navigator.of(context).pop();
      
      // Afficher le dialogue d'erreur pour les exceptions
      _showErrorDialog(
        'Exception',
        'Une erreur inattendue est survenue lors de l\'envoi de votre demande.',
        details: e.toString(),
      );
    }
  }

  void _showErrorDialog(String title, String message, {String? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon d'erreur
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error,
                        AppColors.error.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Détails optionnels
                if (details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: AppColors.textSecondaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            details!,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(13),
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fermer le dialogue
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Fermer',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fermer le dialogue
                          // Optionnel: réessayer l'envoi
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Réessayer',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String demandeUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon de succès
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Demande envoyée avec succès !',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Votre demande d\'intégration a été soumise avec succès et est maintenant en cours de traitement.',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Numéro de suivi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Numéro de suivi',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        demandeUid,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Conservez ce numéro pour suivre l\'évolution de votre demande dans l\'application.',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(13),
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le dialogue
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'OK, j\'ai compris',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar with improved design
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header with better spacing and design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.15),
                          _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTypeColor(widget.ecole.typePrincipal).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.star_rate_rounded,
                      color: _getTypeColor(widget.ecole.typePrincipal),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noter et commenter',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.ecole.parametreNom ?? 'École',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(13),
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button with better design
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.grey600,
                        size: 20,
                      ),
                      iconSize: 20,
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.grey200,
            ),

            // Form content with better padding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Rating section with improved design
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.grade_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Votre note',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(16),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(5, (index) {
                                  final currentRating = int.tryParse(_ratingController.text) ?? 0;
                                  final isSelected = currentRating > index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _ratingController.text = (index + 1).toString();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? AppColors.warning.withOpacity(0.1) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: isSelected ? AppColors.warning : AppColors.grey400,
                                        size: 36,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Comment section with improved design
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextFormField(
                        controller: _commentController,
                        maxLines: 5,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Votre commentaire',
                          hintText: 'Partagez votre expérience...',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.comment_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button with reduced width and improved design
                    Center(
                      child: RatingSubmitButton(
                        onPressed: () async {
                          // Validation des champs
                          if (_ratingController.text.isEmpty || _commentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Veuillez remplir la note et le commentaire'),
                                  ],
                                ),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          // Récupérer l'utilisateur connecté
                          final currentUser = AuthService().getCurrentUser();
                          if (currentUser == null || currentUser.phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Utilisateur non connecté'),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          // Afficher un indicateur de chargement
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Container(
                              color: Colors.black54,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getTypeColor(widget.ecole.typePrincipal),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Envoi en cours...',
                                        style: TextStyle(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          try {
                            // Appel à l'API
                            final result = await TestimonialService.submitTestimonial(
                              codeecole: widget.ecole.parametreCode ?? '',
                              note: _ratingController.text,
                              contenu: _commentController.text,
                              userNumero: currentUser.phone,
                            );

                            // Fermer le dialogue de chargement
                            Navigator.of(context).pop();

                            if (result['success'] == true) {
                              // Fermer le bottom sheet
                              Navigator.of(context).pop();
                              
                              // Réinitialiser les champs
                              _ratingController.clear();
                              _commentController.clear();
                              
                              // Afficher le message de succès
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Témoignage envoyé avec succès!'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } else {
                              // Afficher le message d'erreur
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(result['message'] ?? 'Erreur lors de l\'envoi'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            // Fermer le dialogue de chargement
                            Navigator.of(context).pop();
                            
                            // Afficher l'erreur
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Erreur: $e'),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSponsorshipBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar with improved design
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header with better spacing and design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parrainer un ami',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invitez vos amis et bénéficiez d\'avantages',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(13),
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button with better design
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.grey600,
                        size: 20,
                      ),
                      iconSize: 20,
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.grey200,
            ),

            // Form content with better padding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Name field with improved design
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextFormField(
                        controller: _sponsorNameController,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Votre nom',
                          hintText: 'Entrez votre nom complet',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Your email field with improved design
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextFormField(
                        controller: _sponsorEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Votre email',
                          hintText: 'votre@email.com',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.email_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Friend email field with improved design
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextFormField(
                        controller: _recommenderEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email de l\'ami à parrainer',
                          hintText: 'ami@email.com',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Promo code field with improved design
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextFormField(
                        controller: _promoCodeController,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          color: AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Code promo (optionnel)',
                          hintText: 'Entrez un code promo si vous en avez',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textTertiaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.local_offer_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button with reduced width and improved design
                    Center(
                      child: SponsorshipSubmitButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Invitation de parrainage envoyée avec succès!'),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Text(
              'Partager l\'établissement',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ecole.parametreNom ?? 'École',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Share options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  'WhatsApp',
                  Icons.message_rounded,
                  Colors.green,
                  () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Partage via WhatsApp'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
                _buildShareOption(
                  'Facebook',
                  Icons.facebook_rounded,
                  Colors.blue,
                  () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Partage via Facebook'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
                _buildShareOption(
                  'Copier lien',
                  Icons.link_rounded,
                  AppColors.primary,
                  () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lien copié dans le presse-papiers!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildShareOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String hint, IconData icon, {
    TextEditingController? controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines ?? 1,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String hint, IconData icon, {
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(12),
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadField(String label, String hint, IconData icon, {
    String? fileName,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName ?? hint,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      color: fileName != null 
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(Icons.upload_file, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Form controllers for integration
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentFirstNameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _lieuNaissanceController = TextEditingController();
  final TextEditingController _nationaliteController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _contact1Controller = TextEditingController();
  final TextEditingController _contact2Controller = TextEditingController();
  final TextEditingController _nomPereController = TextEditingController();
  final TextEditingController _nomMereController = TextEditingController();
  final TextEditingController _nomTuteurController = TextEditingController();
  final TextEditingController _niveauAntController = TextEditingController();
  final TextEditingController _ecoleAntController = TextEditingController();
  final TextEditingController _moyenneAntController = TextEditingController();
  final TextEditingController _rangAntController = TextEditingController();
  final TextEditingController _decisionAntController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _filiereController = TextEditingController();
  final TextEditingController _requestedClassController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  
  // Variables for dropdowns and file uploads
  String _selectedSexe = 'M';
  String _selectedStatutAff = 'Affecté';
  
  // File upload variables
  String? _bulletinFile;
  String? _certificatVaccinationFile;
  String? _certificatScolariteFile;
  String? _extraitNaissanceFile;
  String? _cniParentFile;
  // Form controllers for recommendation
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController = TextEditingController();
  final TextEditingController _schoolTypeController = TextEditingController();
  final TextEditingController _schoolCityController = TextEditingController();
  final TextEditingController _recommenderNameController = TextEditingController();
  final TextEditingController _recommenderEmailController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  // New controllers for recommendation API
  final TextEditingController _parentNomController = TextEditingController();
  final TextEditingController _parentPrenomController = TextEditingController();
  final TextEditingController _parentTelephoneController = TextEditingController();
  final TextEditingController _recommandationEmailController = TextEditingController();
  final TextEditingController _parentPaysController = TextEditingController();
  final TextEditingController _parentVilleController = TextEditingController();
  final TextEditingController _parentAdresseController = TextEditingController();
  final TextEditingController _etablissementController = TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _ordreController = TextEditingController();
  final TextEditingController _adresseEtablissementController = TextEditingController();
  
  // New controllers for rating and sponsorship
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _sponsorNameController = TextEditingController();
  final TextEditingController _sponsorEmailController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();

  Widget _buildUnifiedInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Aperçu ───────────────────────────────────
          _buildOverviewSection(),
          
          const SizedBox(height: 16),
          
          // ── Section Contact ───────────────────────────────────
          _buildContactSection(),
          
          const SizedBox(height: 16),
          
          // ── Section Informations ───────────────────────────────
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Container(
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
        border: Border.all(
          color: _themeService.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      widget.ecole.parametreNom ?? 'Établissement',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats principales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Type',
                  widget.ecole.statut ?? 'Non spécifié',
                  Icons.category_rounded,
                  _getTypeColor(widget.ecole.statut ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Statut',
                  widget.ecole.statut ?? 'Non spécifié',
                  Icons.verified_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ecole.parametreNom ?? 'Aucune description disponible',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(9),
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _themeService.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.contact_phone_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Informations de contact',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contact info cards
          _buildContactInfoCard(
            'Adresse',
            '${widget.ecole.adresse ?? 'Adresse non disponible'}, ${widget.ecole.ville ?? 'Ville non disponible'}, ${widget.ecole.pays ?? 'Pays non disponible'}',
            Icons.location_on_rounded,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Téléphone depuis les détails si disponible
          if (_ecoleDetail?.data.telephone != null && _ecoleDetail!.data.telephone.isNotEmpty) ...[
            _buildContactInfoCard(
              'Téléphone',
              _ecoleDetail!.data.telephone,
              Icons.phone_rounded,
              Colors.green,
            ),
            const SizedBox(height: 12),
          ],
          
          // Email depuis les détails si disponible
          if (_ecoleDetail?.data.email != null && _ecoleDetail!.data.email!.isNotEmpty) ...[
            _buildContactInfoCard(
              'Email',
              _ecoleDetail!.data.email!,
              Icons.email_rounded,
              Colors.orange,
            ),
            const SizedBox(height: 12),
          ],
          
          // Site web si disponible
          if (_ecoleDetail?.data.site != null && _ecoleDetail!.data.site!.isNotEmpty) ...[
            _buildContactInfoCard(
              'Site web',
              _ecoleDetail!.data.site!,
              Icons.web_rounded,
              Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _themeService.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _themeService.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Détails administratifs',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Code établissement
          _buildInfoDetailCard(
            'Code établissement',
            widget.ecole.parametreCode ?? 'Non disponible',
            Icons.code_rounded,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Capacité
          _buildInfoDetailCard(
            'Capacité d\'accueil',
            '${_ecoleDetail?.data.effectif ?? 'Non spécifiée'} élèves',
            Icons.groups_rounded,
            Colors.orange,
          ),
          
          const SizedBox(height: 12),
          
          // Date de création
          _buildInfoDetailCard(
            'Date de création',
            _ecoleDetail?.data.annee ?? 'Non spécifiée',
            Icons.calendar_today_rounded,
            Colors.purple,
          ),
          
          const SizedBox(height: 12),
          
          // Directeur
          _buildInfoDetailCard(
            'Directeur/Directrice',
            _ecoleDetail?.data.nom ?? 'Non spécifié(e)',
            Icons.person_rounded,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _themeService.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section d'une filière ─────────────────────────────────
  Widget _buildFiliereSection(
    String filiere,
    List<String> sortedNiveauKeys,
    Map<String, List<Niveau>> niveauxMap,
  ) {
    final color = _getFiliereColor(filiere);
    final totalClasses = niveauxMap.values.fold(0, (s, l) => s + l.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _themeService.isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header filière ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getFiliereIcon(filiere), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFiliereLabel(filiere),
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '$totalClasses classe${totalClasses > 1 ? 's' : ''} · ${sortedNiveauKeys.length} niveau${sortedNiveauKeys.length > 1 ? 'x' : ''}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: color.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filiere,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Niveaux de cette filière ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedNiveauKeys.map((niveauLabel) {
                final classes = niveauxMap[niveauLabel]!
                  ..sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
                return _buildNiveauGroup(niveauLabel, classes, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauGroup(String niveauLabel, List<Niveau> classes, Color color) {
    // Si une seule classe et même nom que le niveau → affichage simple
    if (classes.length == 1) {
      return _buildSingleClassTile(classes.first, color);
    }

    // Plusieurs classes (séries) → affichage en groupe
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  niveauLabel,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${classes.length} séries',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(10),
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: classes.map((c) => _buildClassChip(c, color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleClassTile(Niveau niveau, Color color) {
    final isDark = _themeService.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.08)
            : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (niveau.nom ?? '?').substring(0, (niveau.nom?.length ?? 0).clamp(0, 2)),
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(11),
                  fontWeight: FontWeight.w800,
                  color: color,
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
                  niveau.nom ?? 'Classe',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                if (niveau.niveau != null && niveau.niveau!.isNotEmpty)
                  Text(
                    'Niveau : ${niveau.niveau}',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (niveau.code != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                niveau.code!,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(10),
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassChip(Niveau niveau, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            niveau.nom ?? '?',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(13),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (niveau.serie != null && niveau.serie!.isNotEmpty)
            Text(
              'Série ${niveau.serie}',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(10),
                color: color.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  // ── États vide / erreur ───────────────────────────────────
  Widget _buildNiveauEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun niveau disponible', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Cette école n\'a pas de niveaux configurés',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Erreur de chargement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => setState(() {}), child: const Text('Réessayer')),
        ],
      ),
    );
  }

  // ── Helpers filière ───────────────────────────────────────
  Color _getFiliereColor(String filiere) {
    switch (filiere.toUpperCase()) {
      case 'PRIMAIRE':
        return const Color(0xFF3B82F6);
      case 'GENERAL':
        return const Color(0xFF8B5CF6);
      case 'TECHNIQUE':
        return const Color(0xFF10B981);
      case 'PROFESSIONNEL':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getFiliereIcon(String filiere) {
    switch (filiere.toUpperCase()) {
      case 'PRIMAIRE':
        return Icons.child_care_rounded;
      case 'GENERAL':
        return Icons.menu_book_rounded;
      case 'TECHNIQUE':
        return Icons.precision_manufacturing_rounded;
      case 'PROFESSIONNEL':
        return Icons.work_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getFiliereLabel(String filiere) {
    switch (filiere.toUpperCase()) {
      case 'PRIMAIRE':
        return 'Enseignement Primaire';
      case 'GENERAL':
        return 'Enseignement Général';
      case 'TECHNIQUE':
        return 'Enseignement Technique';
      case 'PROFESSIONNEL':
        return 'Enseignement Professionnel';
      default:
        return filiere;
    }
  }


  Widget _buildLevelsTab() {
    final ecoleCode = widget.ecole.parametreCode ?? '';

    return FutureBuilder<List<Niveau>>(
      future: NiveauService.getNiveauxByEcole(ecoleCode),
      builder: (context, snapshot) {
        // ── Chargement ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Erreur ──
        if (snapshot.hasError) {
          return _buildNiveauError(snapshot.error.toString());
        }

        // ── Vide ──
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNiveauEmpty();
        }

        // ── Données : grouper par filière → par niveau ──
        final niveaux = snapshot.data!;
        final Map<String, Map<String, List<Niveau>>> grouped = {};

        for (final n in niveaux) {
          final filiere = (n.filiere?.isNotEmpty == true) ? n.filiere! : 'AUTRE';
          final niveauLabel = (n.niveau?.isNotEmpty == true) ? n.niveau! : n.nom ?? '?';
          grouped.putIfAbsent(filiere, () => {});
          grouped[filiere]!.putIfAbsent(niveauLabel, () => []);
          grouped[filiere]![niveauLabel]!.add(n);
        }

        // Trier les filières et les niveaux par ordre
        final sortedFilieres = grouped.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Text(
                'Niveaux d\'enseignement',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${niveaux.length} classe${niveaux.length > 1 ? 's' : ''} disponible${niveaux.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(13),
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),

              // Une section par filière
              ...sortedFilieres.map((filiere) {
                final niveauxMap = grouped[filiere]!;
                // Trier les niveaux par ordre (prendre le min ordre de la liste)
                final sortedNiveauKeys = niveauxMap.keys.toList()
                  ..sort((a, b) {
                    final oA = niveauxMap[a]!.map((e) => e.ordre ?? 99).reduce((x, y) => x < y ? x : y);
                    final oB = niveauxMap[b]!.map((e) => e.ordre ?? 99).reduce((x, y) => x < y ? x : y);
                    return oA.compareTo(oB);
                  });

                return _buildFiliereSection(filiere, sortedNiveauKeys, niveauxMap);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMontantSection({
    required String title,
    required List<Niveau> niveaux,
    required Color color,
    required bool isAffecte,
  }) {
    final niveauxParFiliere = NiveauService.grouperParFiliere(niveaux);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${niveaux.length} niveau${niveaux.length > 1 ? 'x' : ''}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Niveaux groupés par filière
        ...niveauxParFiliere.entries.map((entry) {
          final filiere = entry.key;
          final niveauxFiliere = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la filière
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  filiere,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              
              // Liste des niveaux de cette filière
              ...niveauxFiliere.map((niveau) => _buildNiveauCard(niveau, color)),
              
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNiveauCard(Niveau niveau, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.school_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          niveau.nom ?? 'Niveau sans nom',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (niveau.niveau != null && niveau.niveau!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Niveau: ${niveau.niveau}',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(12),
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
            if (niveau.serie != null && niveau.serie!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Série: ${niveau.serie}',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(12),
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Ordre: ${niveau.ordre ?? 0}',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to level details
        },
      ),
    );
  }

  Widget _buildLevelCard(
    String title,
    String classes,
    String ages,
    IconData icon,
    Color color,
    List<String> features,
  ) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : color.withOpacity(0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classes,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ages,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Programme et activités:',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 12),
          
          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to level details
              },
              icon: Icon(Icons.info_outline_rounded, size: 16),
              label: Text('En savoir plus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Événements scolaires',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Découvrez les événements de ${widget.ecole.parametreNom}',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          
          // Loading state
          if (_isLoadingEvents)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          // Error state
          else if (_eventsError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _eventsError!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBlogsEventsAndAvis,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          // Events list
          else if (_schoolEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun événement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun événement disponible pour le moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate crossAxisCount based on screen width
                int crossAxisCount = 2;
                if (constraints.maxWidth > 600) {
                  crossAxisCount = 4; // Tablet and larger
                }
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _schoolEvents.length,
                  itemBuilder: (context, index) {
                    final event = _schoolEvents[index];
                    return _buildEventCard(event);
                  },
                );
              },
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
        _showTicketPurchaseDialog(event);
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
                    // Use gradient background if no image, otherwise use network image
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
                              event['icon'] as IconData? ?? Icons.event,
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
                          event['date'] as String? ?? '',
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Complet',
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
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        event['title'] as String? ?? 'Sans titre',
                        style: TextStyle(
                          fontSize: AppTypography.titleSmall,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Subtitle (establishment)
                      Text(
                        event['establishment'] as String? ?? event['nomecole'] as String? ?? '',
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Location indicator (use establishment if location is null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['establishment'] as String? ?? 
                              event['nomecole'] as String? ?? 
                              event['location'] as String? ?? 
                              'Lieu à confirmer',
                              style: AppTypography.overline.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Price and availability
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event['price'] as String? ?? 'Gratuit',
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          isAvailable
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Acheter',
                                    style: AppTypography.overline.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Indisponible',
                                    style: AppTypography.overline.copyWith(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketPurchaseDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Achat de ticket - ${event['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${event['date']}'),
              Text('Heure: ${event['time']}'),
              Text('Lieu: ${event['location']}'),
              Text('Prix: ${event['price']}'),
              const SizedBox(height: 16),
              Text(
                'Combien de tickets souhaitez-vous acheter?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Decrease quantity
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Increase quantity
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Process ticket purchase
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Achat de ticket effectué avec succès!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer l\'achat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunicationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Communication et Actualités',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dernières communications de ${widget.ecole.parametreNom}',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          
          // Loading state
          if (_isLoadingBlogs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          // Error state
          else if (_blogsError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _blogsError!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBlogsEventsAndAvis,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          // Blogs list
          else if (_blogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune communication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune communication ou actualité disponible pour le moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._blogs.map((blog) => _buildBlogCard(blog)).toList(),
        ],
      ),
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final isDarkMode = _themeService.isDarkMode;
    final Color color = blog['color'] as Color;
    final String? imageUrl = blog['image'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ImageHelper.buildNetworkImage(
                imageUrl: imageUrl,
                placeholder: blog['title'] ?? 'Blog',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  blog['icon'] as IconData? ?? Icons.article,
                  size: 48,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        blog['type'] as String? ?? 'Actualité',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(10),
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      blog['date'] as String? ?? '',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(10),
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  blog['title'] as String? ?? 'Sans titre',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Content preview
                Text(
                  blog['content'] as String? ?? '',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Author and establishment
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      blog['auteur'] as String? ?? 'Administration',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      blog['establishment'] as String? ?? '',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildScolariteTab() {
    return FutureBuilder<ScolariteResponse>(
      future: _scolariteFuture, // ← utilise la variable stockée, pas d'appel inline
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _scolariteFuture = ScolariteService.getScolaritesByEcole(
                        widget.ecole.parametreCode ?? '',
                      );
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun frais de scolarité',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette école n\'a pas de frais de scolarité configurés',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final scolarites =
            ScolariteService.filtrerEtTrierScolarites(snapshot.data!.data);
        final scolaritesParBranche =
            ScolariteService.grouperParBranche(scolarites);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frais de scolarité',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Découvrez tous les frais de scolarité par branche et statut',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              // Champ de recherche
              Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(_themeService.isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _themeService.isDarkMode 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un niveau...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Afficher les branches filtrées
              ...scolaritesParBranche.entries
                  .where((entry) => _searchQuery.isEmpty || 
                      entry.key.toLowerCase().contains(_searchQuery))
                  .map((entry) => _buildBrancheSection(entry.key, entry.value))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrancheSection(String branche, List<Scolarite> scolarites) {
    final scolaritesParStatut =
        ScolariteService.separerParStatut(scolarites);
    final affectes = scolaritesParStatut['AFF'] ?? [];
    final nonAffectes = scolaritesParStatut['NAFF'] ?? [];
    final totaux = ScolariteService.calculerTotauxParStatut(scolarites);
    final isExpanded = _expandedBranche == branche;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _themeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: _themeService.isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header cliquable ──────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedBranche = isExpanded ? null : branche;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isExpanded ? Radius.zero : const Radius.circular(16),
                  bottomRight:
                      isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branche,
                              style: TextStyle(
                                fontSize:
                                    _textSizeService.getScaledFontSize(18),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${scolarites.length} frais',
                              style: TextStyle(
                                fontSize:
                                    _textSizeService.getScaledFontSize(12),
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Flèche animée
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Totaux résumé
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTotalItem(
                          'Affectés',
                          totaux['AFF'] ?? 0,
                          Colors.blue,
                          Icons.check_circle_rounded,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        _buildTotalItem(
                          'Non Affectés',
                          totaux['NAFF'] ?? 0,
                          Colors.red,
                          Icons.remove_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu dépliable avec AnimatedSize ───────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: ClipRect(
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (affectes.isNotEmpty) ...[
                            _buildStatutSection(
                              title: '🔵 Montants affectés',
                              scolarites: affectes,
                              color: Colors.blue,
                              isAffecte: true,
                              totalMontant: totaux['AFF'] ?? 0,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (nonAffectes.isNotEmpty) ...[
                            _buildStatutSection(
                              title: '🔴 Montants non affectés',
                              scolarites: nonAffectes,
                              color: Colors.red,
                              isAffecte: false,
                              totalMontant: totaux['NAFF'] ?? 0,
                            ),
                          ],
                        ],
                      ),
                    )
                  // SizedBox vide avec largeur fixe pour que AnimatedSize
                  // puisse calculer la transition correctement
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
      String label, int montant, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(10),
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ScolariteService.formaterMontant(montant),
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildStatutSection({
    required String title,
    required List<Scolarite> scolarites,
    required Color color,
    required bool isAffecte,
    required int totalMontant,
  }) {
    final scolaritesParRubrique =
        ScolariteService.separerParRubrique(scolarites);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section avec total
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${scolarites.length}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(10),
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ScolariteService.formaterMontant(totalMontant),
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(10),
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Liste des frais par rubrique
        ...scolaritesParRubrique.entries.map((entry) {
          final rubrique = entry.key;
          final fraisRubrique = entry.value;

          if (fraisRubrique.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  rubrique == 'INS' ? 'Inscription' : 'Scolarité',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.color
                        ?.withOpacity(0.8),
                  ),
                ),
              ),
              ...fraisRubrique
                  .map((s) => _buildScolariteCard(s, color))
                  .toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScolariteCard(Scolarite scolarite, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            scolarite.rubrique == 'INS'
                ? Icons.how_to_reg_rounded
                : Icons.menu_book_rounded,
            color: color,
            size: 16,
          ),
        ),
        title: Text(
          ScolariteService.formaterMontant(scolarite.totalMontant ?? 0),
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(13),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          'Date limite: ${scolarite.dateLimiteFormatee}',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(11),
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.6),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ScolariteService.getStatutLibelle(scolarite.statut),
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(10),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section d'une filière ─────────────────────────────────


  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Présentation si disponible
          if (_ecoleDetail?.data.presentation != null && _ecoleDetail!.data.presentation!.isNotEmpty) ...[
            _buildInfoCard(
              'Présentation',
              _ecoleDetail!.data.presentation!,
              Icons.info_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 20),
          ],
          
          // Informations générales
          _buildInfoCard(
            'Informations générales',
            '• Pays: ${widget.ecole.pays ?? 'N/A'}\n• Ville: ${widget.ecole.ville ?? 'N/A'}\n• Statut: ${widget.ecole.statut ?? 'N/A'}\n• Année scolaire: ${_ecoleDetail?.data.annee ?? 'N/A'}\n• Période: ${_ecoleDetail?.data.periode ?? 'N/A'}',
            Icons.business_rounded,
            AppColors.secondary,
          ),
          
          const SizedBox(height: 20),
          
          // Filières enseignées
          if (widget.ecole.filiereNom.isNotEmpty) ...[
            _buildInfoCard(
              'Filières enseignées',
              widget.ecole.filiereNom.join('\n• '),
              Icons.school_rounded,
              AppColors.success,
            ),
            const SizedBox(height: 20),
          ],
          
          // Informations client (effectif)
          if (_ecoleDetail?.client.effectif != null) ...[
            _buildInfoCard(
              'Effectif',
              '• Effectif total: ${_ecoleDetail!.client.effectif} élèves\n• Année: ${_ecoleDetail!.client.annee}',
              Icons.people_rounded,
              AppColors.warning,
            ),
            const SizedBox(height: 20),
          ],
          
          // Coordonnées GPS si disponibles
          if (_ecoleDetail?.data.longitude != null && _ecoleDetail?.data.latitude != null) ...[
            _buildInfoCard(
              'Localisation',
              '• Latitude: ${_ecoleDetail!.data.latitude}\n• Longitude: ${_ecoleDetail!.data.longitude}\n• Rayon de pointage: ${_ecoleDetail!.data.rayonPointage}m',
              Icons.location_on_rounded,
              AppColors.error,
            ),
            const SizedBox(height: 20),
          ],
          
          // Informations sur les réservations
          if (_ecoleDetail?.data.montantReservation != null && _ecoleDetail!.data.montantReservation > 0) ...[
            _buildInfoCard(
              'Réservations',
              '• Montant: ${_ecoleDetail!.data.montantReservation} FCFA\n• Période: ${_ecoleDetail!.data.debutReservation ?? 'N/A'} - ${_ecoleDetail!.data.finReservation ?? 'N/A'}',
              Icons.calendar_today_rounded,
              AppColors.info,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2)
                : color.withOpacity(0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes et Avis',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Avis des parents et élèves sur ${widget.ecole.parametreNom}',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          
          // Loading state
          if (_isLoadingAvis)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          // Error state
          else if (_avisError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _avisError!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBlogsEventsAndAvis,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          // Empty state
          else if (_avis.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_rate_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun avis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun avis ou note disponible pour le moment.\nSoyez le premier à donner votre avis !',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showRatingBottomSheet();
                      },
                      icon: const Icon(Icons.star_rate),
                      label: const Text('Donner mon avis'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._avis.map((avi) => _buildAvisCard(avi)).toList(),
        ],
      ),
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avi) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec avatar et info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar ou icône
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (avi['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    avi['icon'] as IconData,
                    color: avi['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              avi['auteur'] as String,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(16),
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (avi['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: avi['color'] as Color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avi['type'] as String,
                                  style: TextStyle(
                                    fontSize: _textSizeService.getScaledFontSize(12),
                                    fontWeight: FontWeight.w600,
                                    color: avi['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avi['date'] as String,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Photo si disponible
          if (avi['image'] != null && (avi['image'] as String).isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageHelper.buildNetworkImage(
                  imageUrl: avi['image'] as String,
                  placeholder: 'Photo de ${avi['auteur']}',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              avi['content'] as String,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CustomTabBarDelegate(this.child);

  @override
  double get minExtent => 58.0;

  @override
  double get maxExtent => 58.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_CustomTabBarDelegate oldDelegate) => false;
}