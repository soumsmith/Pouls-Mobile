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
  List<AstuceConseil> _allAstuces = [];
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

  Future<void> _loadAstuces({bool loadMore = false}) async {
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
      final response = await _astuceService.getAstucesConseils(page: _currentPage);
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
      astuces = astuces.where((a) =>
        a.title.toLowerCase().contains(q) ||
        a.content.toLowerCase().contains(q)
      ).toList();
    }
    return astuces;
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
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              CustomSliverAppBar(
                title: 'Astuces & Conseils',
                onBackTap: () => MainScreenWrapper.of(context).navigateToHome(),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
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
          child: Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        ),
      ];
    }
    
    if (_error != null) {
      final isNetworkError = _error!.contains('SocketException') || 
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
            title: isNetworkError ? 'Erreur de connexion' : 'Une erreur est survenue',
            message: errorMessage,
            onRetry: _loadAstuces,
            buttonIsLight: true,
            buttonWidth: 200,
          ),
        ),
      ];
    }
    
    final items = _filteredAstuces;
    
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
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppDimensions.getEcolesGridColumns(context),
            crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context) *
                (((AppDimensions.isTablet(context) ||
                            AppDimensions.isLargeTablet(context)) &&
                        AppDimensions.isLandscape(context))
                    ? 1.8
                    : 1.0),
            mainAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
            mainAxisExtent: AppDimensions.getEcoleCardHeight(context),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == items.length) {
                return _isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              final astuce = items[index];
              return ImageMenuCardExternalTitle(
                index: index,
                cardKey: astuce.id.toString(),
                title: astuce.title,
                subtitle: astuce.content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim(),
                imagePath: astuce.youtubeVideoId.isNotEmpty 
                    ? 'https://img.youtube.com/vi/${astuce.youtubeVideoId}/mqdefault.jpg' 
                    : ((astuce.image != null && astuce.image!.isNotEmpty) ? astuce.image : null),
                iconData: Icons.lightbulb_outline,
                color: Colors.orange,
                isDark: Theme.of(context).brightness == Brightness.dark,
                height: AppDimensions.getEcoleCardHeight(context),
                externalTitleSpacing: 4,
                titleMaxLines: 2,
                allowLineBreak: true,
                showPlayIcon: astuce.youtubeUrl != null && astuce.youtubeUrl!.isNotEmpty,
                onTap: () {
                  if (astuce.youtubeUrl != null && astuce.youtubeUrl!.isNotEmpty) {
                    final video = VisiteGuideeVideo(
                      id: astuce.id,
                      typeVideo: 'astuce',
                      youtubeUrl: astuce.youtubeUrl!,
                      title: astuce.title,
                      description: astuce.content,
                      code: astuce.codeecole,
                      slug: astuce.slug,
                    );
                    MainScreenWrapper.of(context).navigateToExtraScreen(
                      VisiteGuideeVideoFeedScreen(videos: [video]),
                    );
                  } else {
                    MainScreenWrapper.of(context).navigateToExtraScreen(
                      TipsAdviceDetailScreen(astuce: astuce),
                    );
                  }
                },
              );
            },
            childCount: items.length + (_hasMore ? 1 : 0),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: BottomSpacer()),
    ];
  }
}
