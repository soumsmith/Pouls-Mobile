import 'package:flutter/material.dart';
import 'dart:async';
import '../models/video.dart';
import '../models/visite_guidee_video.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/video_service.dart';
import '../widgets/see_more_card.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../widgets/main_screen_wrapper.dart';

class AllVisiteGuideeVideosScreen extends StatefulWidget {
  final List<Video> videos;
  final String ecoleCode;

  const AllVisiteGuideeVideosScreen({super.key, required this.videos, required this.ecoleCode});

  @override
  State<AllVisiteGuideeVideosScreen> createState() =>
      _AllVisiteGuideeVideosScreenState();
}

class _AllVisiteGuideeVideosScreenState
    extends State<AllVisiteGuideeVideosScreen> {
  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];

  // Variables de pagination
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // Variables pour la recherche
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _allVideos = widget.videos.toList();
    _filteredVideos = _allVideos;
    _hasMore = _allVideos.length >= 20;
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVideos() async {
    try {
      final newVideos = await VideoService.getVideosByType(
        'visiteguide',
        page: 1,
        perPage: 20,
        ecoleCode: widget.ecoleCode,
      );
      setState(() {
        _allVideos = newVideos;
        _filteredVideos = _getFilteredList(_allVideos, _searchController.text);
        _hasMore = newVideos.length == 20;
        _currentPage = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;

      // Log de l'URL de l'API
      final String apiUrl =
          '${VideoService.baseUrl}?type_video=visiteguide&page=$nextPage&per_page=20';
      print('🌐 [API LOG] Fetching videos from: $apiUrl');

      final newVideos = await VideoService.getVideosByType(
        'visiteguide',
        page: nextPage,
        perPage: 20,
        ecoleCode: widget.ecoleCode,
      );
      setState(() {
        final uniqueNewVideos = newVideos.where((v) => !_allVideos.contains(v)).toList();

        if (uniqueNewVideos.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage = nextPage;
          _allVideos.addAll(uniqueNewVideos);
          _hasMore = newVideos.length == 20; // S'il y a 20 éléments, on tente la page suivante, même si certains étaient des doublons
          _filteredVideos = _getFilteredList(
            _allVideos,
            _searchController.text,
          );
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

  List<Video> _getFilteredList(List<Video> list, String query) {
    if (query.isEmpty) return list;
    return list.where((video) {
      final titleMatch = video.title.toLowerCase().contains(
        query.toLowerCase(),
      );
      final descMatch =
          video.description != null &&
          video.description!.toLowerCase().contains(query.toLowerCase());
      return titleMatch || descMatch;
    }).toList();
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filteredVideos = _getFilteredList(_allVideos, query);
      });
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
            onRefresh: _refreshVideos,
            color: const Color(0xFF3B82F6),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _mainScrollController,
              slivers: [
                CustomSliverAppBar(
                  title: 'Visites guidées',
                pinned: true,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          _filteredVideos = widget.videos;
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
                      _filteredVideos = _allVideos;
                    });
                  },
                  hintText: 'Rechercher une visite...',
                ),
              ),
              if (_filteredVideos.isEmpty)
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
                          _isSearching
                              ? 'Aucun résultat trouvé'
                              : 'Aucune vidéo disponible',
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
                              : 'Les vidéos de visite guidée apparaîtront ici dès qu\'elles seront disponibles.',
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
                      crossAxisCount: AppDimensions.getEcolesGridColumns(
                        context,
                      ),
                      mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
                      crossAxisSpacing:
                          AppDimensions.getAdaptiveGridSpacing(context) *
                          (((AppDimensions.isTablet(context) ||
                                      AppDimensions.isLargeTablet(context)) &&
                                  AppDimensions.isLandscape(context))
                              ? 1.8
                              : 1.0),
                      mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(
                        context,
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == _filteredVideos.length && _hasMore) {
                        return SeeMoreCard(
                          cardColor: AppColors.screenCardThemed(context),
                          borderColor: const Color(
                            0xFF3B82F6,
                          ).withOpacity(0.3), // Blue
                          iconColor: const Color(0xFF3B82F6),
                          textColor: const Color(0xFF3B82F6),
                          subtitleColor: const Color(
                            0xFF3B82F6,
                          ).withOpacity(0.5),
                          title: _isLoadingMore ? 'Chargement...' : 'Voir plus',
                          subtitle: _isLoadingMore ? '' : 'de vidéos',
                          onTap: _isLoadingMore ? () {} : _loadMoreVideos,
                          icon: Icons.add,
                        );
                      }
                      if (index < _filteredVideos.length) {
                        return _buildVideoCard(context, _filteredVideos[index]);
                      }
                      return const SizedBox.shrink();
                    }, childCount: _filteredVideos.length + (_hasMore ? 1 : 0)),
                  ),
                ),
                const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
              ],
            ],
          ),
        ),
          const BottomFadeGradient(), // Gradient fade at bottom
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return ImageMenuCardExternalTitle(
      index: _filteredVideos.indexOf(video),
      cardKey: 'visite_${video.youtubeVideoId}_${_filteredVideos.indexOf(video)}',
      title: video.title,
      subtitle: video.etablissement.isNotEmpty
          ? video.etablissement
          : (video.createdAt.isNotEmpty ? video.createdAt : video.description),
      imagePath: video.youtubeVideoId.isNotEmpty
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      iconData: Icons.play_circle_outline,
      color: const Color(0xFF3B82F6),
      height: AppDimensions.getEcoleCardHeight(context),
      imageFlex: 7.0,
      titleFontSize: AppDimensions.getScaledSize(context, 14.0),
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      showPlayIcon: true,
      onTap: () => _handleVideoAction(context, video),
    );
  }

  void _handleVideoAction(BuildContext context, Video video) {
    final initialIndex = _filteredVideos.indexOf(video);
    final visiteVideos = _filteredVideos
        .map(
          (v) => VisiteGuideeVideo(
            id: v.id,
            typeVideo: v.typevideo,
            youtubeUrl: v.youtubeUrl,
            title: v.title,
            description: v.description,
            code: v.code,
            etablissement: v.etablissement,
          ),
        )
        .toList();

    MainScreenWrapper.of(context).navigateToExtraScreen(
      VisiteGuideeVideoFeedScreen(
        videos: visiteVideos,
        initialIndex: initialIndex >= 0 ? initialIndex : 0,
      ),
    );
  }
}
