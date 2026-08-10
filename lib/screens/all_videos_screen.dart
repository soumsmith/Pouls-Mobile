import 'package:flutter/material.dart';
import 'dart:async';
import '../models/coulisse_excellence.dart';
import '../services/coulisse_excellence_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../config/app_colors.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/see_more_card.dart';
import 'coulisse_video_feed_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../services/ad_service.dart';
import '../models/ad_model.dart';
import '../utils/ad_injector.dart';
import '../widgets/ad_banner_card.dart';

class AllVideosScreen extends StatefulWidget {
  final String ecoleCode;
  const AllVideosScreen({Key? key, required this.ecoleCode}) : super(key: key);

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  final AdService _adService = AdService();
  List<CoulisseExcellence> _videos = [];
  List<CoulisseExcellence> _filteredVideos = [];
  List<AdModel> _ads = [];
  bool _isLoading = true;
  String? _error;

  // Variables pour la recherche
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  
  // Variables de pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _loadAds();
  }

  Future<void> _loadAds() async {
    final ads = await _adService.fetchAds(format: 'portrait');
    if (mounted) {
      setState(() {
        _ads = ads;
      });
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVideos({bool isRefresh = false}) async {
    setState(() {
      if (!isRefresh) _isLoading = true;
      _error = null;
    });
    try {
      final videos = await CoulisseExcellenceService.getAllCoulisseExcellenceVideos(page: 1, perPage: 20, ecoleCode: widget.ecoleCode);
      setState(() {
        _videos = videos;
        _filteredVideos = _getFilteredList(videos, _searchController.text);
        _hasMore = videos.length == 20;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final newVideos = await CoulisseExcellenceService.getAllCoulisseExcellenceVideos(page: nextPage, perPage: 20, ecoleCode: widget.ecoleCode);
      setState(() {
        if (newVideos.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage = nextPage;
          _videos.addAll(newVideos);
          _hasMore = newVideos.length == 20;
          _filteredVideos = _getFilteredList(_videos, _searchController.text);
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<CoulisseExcellence> _getFilteredList(List<CoulisseExcellence> list, String query) {
    if (query.isEmpty) return list;
    return list.where((video) {
      final titleMatch = video.titre.toLowerCase().contains(query.toLowerCase());
      final classMatch = video.classe != null && video.classe!.toLowerCase().contains(query.toLowerCase());
      return titleMatch || classMatch;
    }).toList();
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filteredVideos = _getFilteredList(_videos, query);
      });
    });
  }

  List<dynamic> get _mixedVideos {
    return AdInjector.injectAds<CoulisseExcellence>(_filteredVideos, _ads);
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
            onRefresh: () => _loadVideos(isRefresh: true),
            color: const Color(0xFF10B981),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _mainScrollController,
              slivers: [
                CustomSliverAppBar(
                  title: 'Coulisse de l\'Excellence',
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
                          _filteredVideos = _videos;
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
                    setState(() {
                      _searchController.clear();
                      _filteredVideos = _videos;
                    });
                  },
                  hintText: 'Rechercher une vidéo...',
                ),
              ),
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppDimensions.getEcolesGridColumns(context),
                      mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
                      crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context) *
                          (((AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) &&
                                  AppDimensions.isLandscape(context))
                              ? 1.8
                              : 1.0),
                      mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return const SkeletonBox();
                      },
                      childCount: 16,
                    ),
                  ),
                )
              else if (_error != null) 
                (() {
                  final isNetworkError = _error!.contains('SocketException') || 
                                         _error!.contains('ClientException') ||
                                         _error!.contains('Failed host lookup') ||
                                         _error!.contains('No address associated') ||
                                         _error!.contains('Connection refused') ||
                                         _error!.contains('Network is unreachable') ||
                                         _error!.contains('Software caused connection abort');
                                         
                  final errorMessage = isNetworkError 
                      ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.' 
                      : _error!;
                      
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline,
                            size: 64,
                            color: isNetworkError ? Colors.red : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isNetworkError ? 'Erreur de connexion' : 'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadVideos,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                })() else if (_mixedVideos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'Aucun résultat trouvé' : 'Aucune vidéo disponible',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching 
                              ? 'Essayez d\'autres mots clés'
                              : 'Les vidéos apparaîtront ici dès qu\'elles seront disponibles',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
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
                      crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context) *
                          (((AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) &&
                                  AppDimensions.isLandscape(context))
                              ? 1.8
                              : 1.0),
                      mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _mixedVideos.length && _hasMore) {
                          return SeeMoreCard(
                            cardColor: AppColors.screenCardThemed(context),
                            borderColor: const Color(0xFF10B981).withOpacity(0.3), // Green for videos
                            iconColor: const Color(0xFF10B981),
                            textColor: const Color(0xFF10B981),
                            subtitleColor: const Color(0xFF10B981).withOpacity(0.5),
                            title: _isLoadingMore ? 'Chargement...' : 'Voir plus',
                            subtitle: _isLoadingMore ? '' : 'de vidéos',
                            onTap: _isLoadingMore ? () {} : _loadMoreVideos,
                            icon: Icons.add,
                          );
                        }
                        if (index < _mixedVideos.length) {
                          final item = _mixedVideos[index];
                          if (item is AdGroup) {
                            return AdBannerCarousel(adGroup: item);
                          }
                          return _buildVideoCard(item as CoulisseExcellence);
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: _mixedVideos.length + (_hasMore ? 1 : 0),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: BottomSpacer(height: 125),
                ),
              ],
            ],
          ),
        ),
          const BottomFadeGradient(), // Gradient fade at bottom
        ],
      ),
    );
  }

  Widget _buildVideoCard(CoulisseExcellence video) {
    return ImageMenuCardExternalTitle(
      index: _filteredVideos.indexOf(video),
      cardKey: video.id.toString(),
      title: video.titre,
      subtitle: (video.classe != null && video.classe!.isNotEmpty) ? video.classe : null,
      imagePath: video.videoYoutube.isNotEmpty 
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      iconData: Icons.play_circle_outline,
      color: const Color(0xFF10B981), // Green color for videos
      height: AppDimensions.getEcoleCardHeight(context),
      imageFlex: 7.0,
      titleFontSize: AppDimensions.getScaledSize(context, 14.0),
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      showPlayIcon: true,
      onTap: () => _handleVideoAction(video),
    );
  }

  void _handleVideoAction(CoulisseExcellence video) {
    // Navigation vers l'écran de lecture de vidéo
    final videoIndex = _filteredVideos.indexWhere((v) => v.id == video.id);
    MainScreenWrapper.of(context).navigateToExtraScreen(
      CoulisseVideoFeedScreen(
        videos: _filteredVideos,
        initialIndex: videoIndex >= 0 ? videoIndex : 0,
        cameFromGrid: true,
      ),
    );
  }
}

// Écran de lecture de vidéo
class VideoPlayerScreen extends StatelessWidget {
  final CoulisseExcellence video;

  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          video.titre,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: 100,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lecteur vidéo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.titre,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
