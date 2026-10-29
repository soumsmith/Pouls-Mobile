import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ecole_histoire.dart';
import '../services/ecole_histoire_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../widgets/see_more_card.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/components/custom_error_state.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import 'ecole_histoire_detail_screen.dart';

const int _kHistoiresPerPage = 20;

/// Liste complète (toutes écoles) des "histoires" — point d'entrée "voir
/// plus" depuis la section accueil "Mémoire des écoles".
class AllHistoiresScreen extends StatefulWidget {
  const AllHistoiresScreen({super.key});

  @override
  State<AllHistoiresScreen> createState() => _AllHistoiresScreenState();
}

class _AllHistoiresScreenState extends State<AllHistoiresScreen> {
  List<EcoleHistoire> _histoires = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  final ScrollController _mainScrollController = ScrollController();

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _loadHistoires();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistoires({bool isRefresh = false}) async {
    setState(() {
      if (!isRefresh) _isLoading = true;
      _error = null;
    });
    try {
      final response = await EcoleHistoireService.getHistoires(
        page: 1,
        perPage: _kHistoiresPerPage,
        search: _searchController.text,
      );
      setState(() {
        _histoires = response.data;
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreHistoires() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await EcoleHistoireService.getHistoires(
        page: nextPage,
        perPage: _kHistoiresPerPage,
        search: _searchController.text,
      );
      setState(() {
        _histoires.addAll(response.data);
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _loadHistoires();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      floatingActionButton: ScrollToTopFab(scrollController: _mainScrollController, bottomSpacerHeight: 70),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadHistoires(isRefresh: true),
            color: kHistoireAccentColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _mainScrollController,
              slivers: [
                CustomSliverAppBar(
                  title: 'Mémoire des écoles',
                  pinned: true,
                  elevation: 0,
                  actions: [
                    AppBarIconButton(
                      icon: _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                            _loadHistoires();
                          }
                        });
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: SearchBarWidget(
                    isSearching: _isSearching,
                    searchController: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      _searchController.clear();
                      _loadHistoires();
                    },
                    hintText: 'Rechercher une histoire...',
                  ),
                ),
                if (_isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppDimensions.getEcolesGridColumns(context),
                        mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
                        crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                        mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const SkeletonBox(),
                        childCount: 12,
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: CustomErrorState(
                        title: 'Erreur de chargement',
                        message: _error!,
                        onRetry: _loadHistoires,
                        buttonIsLight: true,
                      ),
                    ),
                  )
                else if (_histoires.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching ? 'Aucun résultat trouvé' : 'Aucune histoire disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppDimensions.getEcolesGridColumns(context),
                        mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
                        crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                        mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _histoires.length && _hasMore) {
                            return SeeMoreCard(
                              cardColor: AppColors.screenCardThemed(context),
                              borderColor: kHistoireAccentColor.withOpacity(0.3),
                              iconColor: kHistoireAccentColor,
                              textColor: kHistoireAccentColor,
                              subtitleColor: kHistoireAccentColor.withOpacity(0.5),
                              title: _isLoadingMore ? 'Chargement...' : 'Voir plus',
                              subtitle: _isLoadingMore ? '' : 'd\'histoires',
                              onTap: _isLoadingMore ? () {} : _loadMoreHistoires,
                              icon: Icons.add,
                            );
                          }
                          if (index < _histoires.length) {
                            return _buildHistoireCard(_histoires[index]);
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: _histoires.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
                ],
              ],
            ),
          ),
          const BottomFadeGradient(),
        ],
      ),
    );
  }

  Widget _buildHistoireCard(EcoleHistoire histoire) {
    return ImageMenuCardExternalTitle(
      index: _histoires.indexOf(histoire),
      cardKey: histoire.id.toString(),
      title: histoire.title.isNotEmpty ? histoire.title : 'Mémoire de l\'école',
      subtitle: histoire.etablissement,
      overtitle: histoire.yearLabel.isNotEmpty ? histoire.yearLabel : null,
      overtitleColor: kHistoireAccentColor,
      imagePath: histoire.image,
      iconData: Icons.auto_stories_rounded,
      color: kHistoireAccentColor,
      height: AppDimensions.getEcoleCardHeight(context),
      titleFontSize: AppDimensions.getScaledSize(context, 14.0),
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      onTap: () => MainScreenWrapper.of(context).navigateToExtraScreen(
        EcoleHistoireDetailScreen(histoire: histoire),
      ),
    );
  }
}
