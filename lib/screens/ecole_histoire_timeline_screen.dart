import 'package:flutter/material.dart';
import 'dart:async';
import '../models/ecole_histoire.dart';
import '../services/ecole_histoire_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/components/custom_error_state.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/text_size_service.dart';
import '../utils/html_helper.dart';
import '../models/visite_guidee_video.dart';
import 'visite_guidee_video_feed_screen.dart';
import 'ecole_histoire_detail_screen.dart';

const int _kTimelinePerPage = 10;

/// Histoires (mémoires/événements marquants) spécifiques à un
/// établissement, affichées en timeline verticale — accessible depuis le
/// détail d'un établissement.
class EcoleHistoireTimelineScreen extends StatefulWidget {
  final String ecoleCode;
  final String ecoleNom;

  const EcoleHistoireTimelineScreen({
    super.key,
    required this.ecoleCode,
    required this.ecoleNom,
  });

  @override
  State<EcoleHistoireTimelineScreen> createState() => _EcoleHistoireTimelineScreenState();
}

class _EcoleHistoireTimelineScreenState extends State<EcoleHistoireTimelineScreen> {
  List<EcoleHistoire> _histoires = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _lastPage = 1;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  bool get _hasMore => _currentPage < _lastPage;

  @override
  void initState() {
    super.initState();
    _loadHistoires();
  }

  @override
  void dispose() {
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
      final response = await EcoleHistoireService.getHistoiresByEcole(
        widget.ecoleCode,
        page: 1,
        perPage: _kTimelinePerPage,
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
      final response = await EcoleHistoireService.getHistoiresByEcole(
        widget.ecoleCode,
        page: nextPage,
        perPage: _kTimelinePerPage,
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
      backgroundColor: AppColors.screenSurfaceThemed(context),
      body: RefreshIndicator(
        onRefresh: () => _loadHistoires(isRefresh: true),
        color: kHistoireAccentColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CustomSliverAppBar(
              title: 'Mémoire de l\'école',
              pinned: true,
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
                hintText: 'Rechercher dans l\'histoire de l\'école...',
              ),
            ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const SkeletonBox(height: 160, margin: EdgeInsets.only(bottom: 16)),
                    childCount: 4,
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
                        _isSearching
                            ? 'Aucun résultat trouvé'
                            : 'Aucune histoire disponible pour cette école',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _histoires.length) {
                        return _buildTimelineItem(
                          _histoires[index],
                          isLast: index == _histoires.length - 1 && !_hasMore,
                        );
                      }
                      // Bouton "charger plus"
                      return Padding(
                        padding: const EdgeInsets.only(left: 28, bottom: 24),
                        child: TextButton.icon(
                          onPressed: _isLoadingMore ? null : _loadMoreHistoires,
                          icon: _isLoadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(_isLoadingMore ? 'Chargement...' : 'Voir plus'),
                          style: TextButton.styleFrom(foregroundColor: kHistoireAccentColor),
                        ),
                      );
                    },
                    childCount: _histoires.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: BottomSpacer(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(EcoleHistoire histoire, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kHistoireAccentColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: kHistoireAccentColor.withOpacity(0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildHistoireCard(histoire),
            ),
          ),
        ],
      ),
    );
  }

  void _handleHistoireAction(EcoleHistoire histoire) {
    if (histoire.isVideo &&
        histoire.youtubeUrl != null &&
        histoire.youtubeUrl!.isNotEmpty) {
      final allVideoHistoires = _histoires
          .where(
            (h) =>
                h.isVideo &&
                h.youtubeUrl != null &&
                h.youtubeUrl!.isNotEmpty,
          )
          .toList();
      final allVideos = allVideoHistoires
          .map(
            (h) => VisiteGuideeVideo(
              id: h.id,
              typeVideo: 'histoire',
              youtubeUrl: h.youtubeUrl!,
              title: h.title,
              description: h.content,
              code: h.codeEcole,
              etablissement: h.etablissement.isNotEmpty
                  ? h.etablissement
                  : widget.ecoleNom,
            ),
          )
          .toList();
      final tappedIndex =
          allVideoHistoires.indexWhere((h) => h.id == histoire.id);
      MainScreenWrapper.of(context).navigateToExtraScreen(
        VisiteGuideeVideoFeedScreen(
          videos: allVideos,
          initialIndex: tappedIndex >= 0 ? tappedIndex : 0,
        ),
      );
    } else {
      MainScreenWrapper.of(context).navigateToExtraScreen(
        EcoleHistoireDetailScreen(histoire: histoire),
      );
    }
  }

  Widget _buildHistoireCard(EcoleHistoire histoire) {
    final textSizeService = TextSizeService();
    final excerpt = HtmlHelper.stripHtmlTags(histoire.content);
    final displayImage = histoire.displayImage;

    return GestureDetector(
      onTap: () => _handleHistoireAction(histoire),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayImage != null && displayImage.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kHistoireAccentColor.withOpacity(0.12),
                        child: const Icon(Icons.auto_stories_rounded, color: kHistoireAccentColor, size: 32),
                      ),
                    ),
                    if (histoire.isVideo)
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (histoire.yearLabel.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kHistoireAccentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        histoire.yearLabel,
                        style: TextStyle(
                          fontSize: textSizeService.getScaledFontSize(11),
                          fontWeight: FontWeight.w700,
                          color: kHistoireAccentColor,
                        ),
                      ),
                    ),
                  Text(
                    histoire.title.isNotEmpty ? histoire.title : 'Mémoire de l\'école',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: textSizeService.getScaledFontSize(15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(13),
                        height: 1.4,
                        color: AppColors.screenTextSecondaryThemed(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
