import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import '../utils/image_helper.dart';
import '../models/astuce_conseil.dart';
import '../services/astuce_conseil_service.dart';
import 'tips_advice_detail_screen.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../widgets/components/custom_error_state.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../config/app_dimensions.dart';
import '../models/visite_guidee_video.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../services/ad_service.dart';
import '../models/ad_model.dart';
import '../utils/ad_injector.dart';
import '../widgets/ad_banner_card.dart';
import '../widgets/components/section_row.dart';

class TipsAdviceScreen extends StatefulWidget {
  const TipsAdviceScreen({super.key});

  @override
  State<TipsAdviceScreen> createState() => _TipsAdviceScreenState();
}

class _TipsAdviceScreenState extends State<TipsAdviceScreen>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _astuceService = AstuceConseilService();
  final AdService _adService = AdService();
  List<AstuceConseil> _allAstuces = [];
  List<AdModel> _ads = [];
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadAstuces();
    _loadAds();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadAstuces(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final ads = await _adService.fetchAds();
    if (mounted) {
      setState(() {
        _ads = ads;
      });
    }
  }

  Future<void> _loadAstuces({
    bool loadMore = false,
    bool isRefresh = false,
  }) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
      _currentPage++;
    } else {
      setState(() {
        if (!isRefresh) _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await _astuceService.getAstucesConseils(
        page: _currentPage,
      );
      final newAstuces = response.data;

      setState(() {
        if (loadMore) {
          _allAstuces.addAll(newAstuces);
          _isLoadingMore = false;
        } else {
          _allAstuces = newAstuces;
          _isLoading = false;
        }
        _hasMore = response.currentPage < response.lastPage;
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

  List<AstuceConseil> get _filteredAstuces {
    var astuces = _allAstuces;
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      astuces = astuces
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.content.toLowerCase().contains(q),
          )
          .toList();
    }
    return astuces;
  }

  List<dynamic> get _mixedArticles {
    final articles = _filteredAstuces
        .where((a) => a.youtubeUrl == null || a.youtubeUrl!.isEmpty)
        .toList();
    return AdInjector.injectAds(articles, _ads);
  }

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
      floatingActionButton: ScrollToTopFab(
        scrollController: _scrollController,
        bottomSpacerHeight: 90.0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _loadAstuces(isRefresh: true),
            color: Colors.orange,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              slivers: [
                CustomSliverAppBar(
                  title: 'Astuces & Conseils',
                  onBackTap: () =>
                      MainScreenWrapper.of(context).navigateToHome(),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: AppColors.screenTextPrimaryThemed(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                        if (_isSearching && _scrollController.hasClients) {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(child: _buildSearchBar()),
                ..._buildBodySlivers(),
              ],
            ),
          ),
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
                boxShadow: AppColors.screenCardShadow,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: AppColors.screenTextPrimaryThemed(context),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher une astuce...',
                  hintStyle: TextStyle(
                    color: AppColors.screenTextSecondaryThemed(context),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.screenTextSecondaryThemed(context),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: Colors.orange)),
        ),
      ];
    }

    if (_error != null) {
      final isNetworkError =
          _error!.contains('SocketException') ||
          _error!.contains('ClientException') ||
          _error!.contains('Failed host lookup') ||
          _error!.contains('Connection refused');

      final errorMessage = isNetworkError
          ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.'
          : 'Une erreur inattendue est survenue lors du chargement des astuces.';

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: CustomErrorState(
            title: isNetworkError
                ? 'Erreur de connexion'
                : 'Une erreur est survenue',
            message: errorMessage,
            onRetry: _loadAstuces,
            buttonIsLight: true,
            buttonWidth: 200,
          ),
        ),
      ];
    }

    final items = _filteredAstuces;
    final slivers = <Widget>[];
    final videos = items
        .where((a) => a.youtubeUrl != null && a.youtubeUrl!.isNotEmpty)
        .toList();
    final articles = items
        .where((a) => a.youtubeUrl == null || a.youtubeUrl!.isEmpty)
        .toList();

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune astuce trouvée',
                  style: TextStyle(
                    color: AppColors.screenTextSecondaryThemed(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      if (videos.isNotEmpty) _buildVideosSection(videos),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
      // if (videos.isNotEmpty && articles.isNotEmpty) _buildSeparator(),
      if (articles.isNotEmpty) ..._buildArticlesSection(articles),
      const SliverToBoxAdapter(child: BottomSpacer(height: 125)),
    ];
  }

  Widget _buildVideosSection(List<AstuceConseil> videos) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    // 2.5 cards visible: card1 + spacing (16) + card2 + spacing (16) + card3*0.5
    // Left padding of the list is 16, making total occupied horizontal space:
    // 16 (left padding) + cardWidth + 16 (spacing) + cardWidth + 16 (spacing) + cardWidth * 0.5 = screenWidth
    // => 2.5 * cardWidth + 48 = screenWidth
    // => cardWidth = (screenWidth - 48) / 2.5
    final double cardWidth = (screenWidth - 48) / 2.5;
    // Reduce height to 85% of standard school card height to match narrower width
    final double cardHeight = AppDimensions.getEcoleCardHeight(context) * 0.85;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionRow(title: 'Vidéos à la une'),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: videos.length > 3
                  ? videos.length + 1
                  : videos.length, // +1 for "Voir plus" button if > 3 videos
              itemBuilder: (context, index) {
                if (videos.length > 3 && index == videos.length) {
                  return _buildSeeMoreVideosButton(
                    videos,
                    cardWidth,
                    cardHeight,
                  );
                }

                final astuce = videos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: cardWidth,
                    child: ImageMenuCardExternalTitle(
                      index: index,
                      cardKey: 'video_${astuce.id}',
                      title: astuce.title,
                      subtitle: astuce.content
                          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
                          .trim(),
                      imagePath: astuce.youtubeVideoId.isNotEmpty
                          ? 'https://img.youtube.com/vi/${astuce.youtubeVideoId}/mqdefault.jpg'
                          : ((astuce.image != null && astuce.image!.isNotEmpty)
                                ? astuce.image
                                : null),
                      iconData: Icons.play_circle_fill,
                      color: Colors.orange,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      height: cardHeight,
                      width: cardWidth,
                      externalTitleSpacing: 4,
                      titleMaxLines: 2,
                      allowLineBreak: true,
                      showPlayIcon: true,
                      onTap: () {
                        final allVideos = videos
                            .map(
                              (a) => VisiteGuideeVideo(
                                id: a.id,
                                typeVideo: 'astuce',
                                youtubeUrl: a.youtubeUrl!,
                                title: a.title,
                                description: a.content,
                                code: a.codeecole,
                                slug: a.slug,
                              ),
                            )
                            .toList();
                        MainScreenWrapper.of(context).navigateToExtraScreen(
                          VisiteGuideeVideoFeedScreen(
                            videos: allVideos,
                            initialIndex: index,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreVideosButton(
    List<AstuceConseil> videos,
    double cardWidth,
    double cardHeight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: InkWell(
          onTap: () {
            final allVideos = videos
                .map(
                  (a) => VisiteGuideeVideo(
                    id: a.id,
                    typeVideo: 'astuce',
                    youtubeUrl: a.youtubeUrl!,
                    title: a.title,
                    description: a.content,
                    code: a.codeecole,
                    slug: a.slug,
                  ),
                )
                .toList();

            if (allVideos.isNotEmpty) {
              MainScreenWrapper.of(context).navigateToExtraScreen(
                VisiteGuideeVideoFeedScreen(videos: allVideos),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Voir plus\nde vidéos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColors.screenBorder(context),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.star_outline_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColors.screenBorder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildArticlesSection(List<dynamic> articles) {
    return [
      SliverToBoxAdapter(child: SectionRow(title: 'Articles récents')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == articles.length) {
              return _isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            final item = articles[index];
            if (item is AdGroup) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdBannerCarousel(adGroup: item),
              );
            }

            final astuce = item as AstuceConseil;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AstuceCard(
                astuce: astuce,
                onTap: () {
                  MainScreenWrapper.of(context).navigateToExtraScreen(
                    TipsAdviceDetailScreen(astuce: astuce),
                  );
                },
              ),
            );
          }, childCount: articles.length + (_hasMore ? 1 : 0)),
        ),
      ),
    ];
  }
}

class _AstuceCard extends StatelessWidget {
  final AstuceConseil astuce;
  final VoidCallback onTap;

  const _AstuceCard({required this.astuce, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uiData = astuce.toUiMap();
    final Color color = uiData['color'] as Color;
    final String? imageUrl = uiData['image'] as String?;
    final String title = astuce.title;
    final String subtitle = astuce.codeecole.isNotEmpty
        ? astuce.codeecole
        : 'Astuces & Conseils';
    final String date = uiData['date'] as String;
    final String type = uiData['type'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vignette image (gauche)
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
                                uiData['icon'] as IconData? ??
                                    Icons.lightbulb_outline,
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
            // Infos (droite)
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
                          horizontal: 6,
                          vertical: 3,
                        ),
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
                  // Sous-titre
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
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.screenTextSecondaryThemed(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.screenTextSecondaryThemed(context),
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
