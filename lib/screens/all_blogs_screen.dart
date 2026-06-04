import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../utils/image_helper.dart';
import '../services/blog_service.dart';
import '../services/pays_service.dart';
import '../models/blog.dart';
import '../widgets/filter_row_widget.dart';
import 'blog_detail_screen.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/components/custom_date_input.dart';
import '../widgets/components/custom_text_input.dart';
import '../widgets/components/bottom_spacer.dart';

// ─── Design tokens (centralisés dans AppColors) ────────────────────────────────

// ─── Écran principal ──────────────────────────────────────────────────────────
class AllBlogsScreen extends StatefulWidget {
  const AllBlogsScreen({super.key});

  @override
  State<AllBlogsScreen> createState() => _AllBlogsScreenState();
}

class _AllBlogsScreenState extends State<AllBlogsScreen>
    with TickerProviderStateMixin {

  // ── État ────────────────────────────────────────────────
  String  _selectedFilter   = 'Tous';
  bool    _isSearching      = false;
  final   _searchController = TextEditingController();
  final   _blogService      = BlogService();
  List<Blog> _allBlogs = [];
  bool    _isLoading        = true;
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
  late Animation<double>   _fadeAnim;

  final List<String> _filters = [
    'Tous', 'Actualité', 'Communication', 'Événement', 'Information', 'Annonce',
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
    _loadBlogs();
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

  Future<void> _loadBlogs({bool loadMore = false}) async {
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
      final response = await BlogService.getBlogs(
        page: _currentPage, 
        perPage: 16,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        categorie: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        date: _dateController.text.trim().isNotEmpty ? _getApiFormattedDate(_dateController.text.trim()) : null,
      );
      final newBlogs = response.data;
      
      setState(() {
        if (loadMore) {
          _allBlogs.addAll(newBlogs);
          _isLoadingMore = false;
        } else {
          _allBlogs = newBlogs;
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

  List<Blog> get _filteredBlogs {
    var blogs = _allBlogs;
    if (_selectedFilter != 'Tous') {
      blogs = _blogService.filterBlogsByCategory(
        blogs.map((b) => b.toUiMap()).toList(),
        _selectedFilter,
      ).map((m) => _allBlogs.firstWhere((b) => b.slug == m['id'])).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      blogs = blogs.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.nomecole.toLowerCase().contains(q) ||
        b.content.toLowerCase().contains(q) ||
        (b.categories.join(' ').toLowerCase().contains(q)),
      ).toList();
    }
    return blogs;
  }

  // ── Build ────────────────────────────────────────────────
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
                title: 'Actualités',
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
                border: Border.all(color: AppColors.screenBorder(context)),
                boxShadow: AppColors.screenCardShadowThemed(context),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: AppColors.screenTextPrimaryThemed(context)),
                decoration: InputDecoration(
                  hintText: 'Rechercher une actualité...',
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
                        onPressed: () => _loadBlogs(),
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
                  color: AppColors.screenOrange, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chargement des actualités...',
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
              onTap: _loadBlogs,
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

  List<Widget> _buildContentSlivers() {
    final items = _filteredBlogs;

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
                        text: 'actualité',
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
                    child: const Icon(Icons.article_outlined,
                        size: 40, color: AppColors.screenOrange),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune actualité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun résultat pour ce filtre',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.screenTextSecondaryThemed(context)),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedFilter = 'Tous';
                      _searchController.clear();
                      _countryController.clear();
                      _categoryController.clear();
                      _dateController.clear();
                      _loadBlogs();
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
          ),
        )
      else
        // ── Liste de blogs ───────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i == items.length) {
                  return _buildLoadMoreButton();
                }
                final blog = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeTransition(
                    opacity: _fadeAnim,
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
                      child: _BlogCard(
                        blog: blog,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlogDetailScreen(blog: blog),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              childCount: items.length + (_hasMore ? 1 : 0),
            ),
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
          onTap: () => _loadBlogs(loadMore: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.screenBorder(context)),
              boxShadow: AppColors.screenCardShadowThemed(context),
            ),
            child: const Text(
              'Voir plus d\'actualités',
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

// ─── Card blog (layout horizontal) ─────────────────────────────────────────────
class _BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;

  const _BlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uiData = blog.toUiMap();
    final Color color      = uiData['color'] as Color;
    final String? imageUrl = blog.image;
    final String title     = blog.title;
    final String subtitle  = blog.nomecole;
    final String date      = uiData['date'] as String;
    final String type      = uiData['type'] as String;

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
              color: isDark ? const Color(0x1A000000) : const Color(0x08000000),
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
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null && imageUrl.isNotEmpty
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
                                uiData['icon'] as IconData? ?? Icons.article_rounded,
                                size: 36,
                                color: Colors.white.withOpacity(0.9),
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

                  // Ligne titre + badge catégorie
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimaryThemed(context),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge catégorie
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Sous-titre (établissement)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.screenTextSecondaryThemed(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
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
