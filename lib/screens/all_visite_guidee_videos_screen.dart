import 'package:flutter/material.dart';
import 'dart:async';
import '../models/video.dart';
import '../models/visite_guidee_video.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import 'visite_guidee_video_feed_screen.dart';

class AllVisiteGuideeVideosScreen extends StatefulWidget {
  final List<Video> videos;

  const AllVisiteGuideeVideosScreen({super.key, required this.videos});

  @override
  State<AllVisiteGuideeVideosScreen> createState() => _AllVisiteGuideeVideosScreenState();
}

class _AllVisiteGuideeVideosScreenState extends State<AllVisiteGuideeVideosScreen> {
  List<Video> _filteredVideos = [];

  // Variables pour la recherche
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _filteredVideos = widget.videos;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _filteredVideos = widget.videos;
        } else {
          _filteredVideos = widget.videos.where((video) {
            final titleMatch = video.title.toLowerCase().contains(query.toLowerCase());
            final descMatch = video.description != null && video.description.toLowerCase().contains(query.toLowerCase());
            return titleMatch || descMatch;
          }).toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomSliverAppBar(
                title: 'Visites guidées',
                pinned: true,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
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
                      _filteredVideos = widget.videos;
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
                              : 'Les vidéos de visite guidée apparaîtront ici dès qu\'elles seront disponibles.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildVideoCard(context, _filteredVideos[index]);
                    }, childCount: _filteredVideos.length),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120), // Large bottom margin
                ),
              ],
            ],
          ),
          const BottomFadeGradient(), // Gradient fade at bottom
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return ImageMenuCardExternalTitle(
      index: widget.videos.indexOf(video),
      cardKey: 'visite_${video.youtubeVideoId}_${widget.videos.indexOf(video)}',
      title: video.title,
      subtitle: video.createdAt.isNotEmpty
          ? video.createdAt
          : video.description,
      imagePath: video.youtubeVideoId.isNotEmpty
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      iconData: Icons.play_circle_outline,
      color: const Color(0xFF3B82F6),
      height: AppDimensions.getEcoleCardHeight(context),
      imageFlex: 7.0,
      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
      titleFontSize: AppDimensions.getScaledSize(context, 14.0),
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      onTap: () => _handleVideoAction(context, video),
    );
  }

  void _handleVideoAction(BuildContext context, Video video) {
    final initialIndex = widget.videos.indexOf(video);
    final visiteVideos = widget.videos
        .map(
          (v) => VisiteGuideeVideo(
            typeVideo: v.typevideo,
            youtubeUrl: v.youtubeUrl,
          ),
        )
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisiteGuideeVideoFeedScreen(
          videos: visiteVideos,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}
