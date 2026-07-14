import 'package:flutter/material.dart';
import 'package:parents_responsable/services/astuce_conseil_service.dart';
import 'package:parents_responsable/services/auth_service.dart';
import 'package:parents_responsable/widgets/bottom_sheets/reusable_bottom_sheet.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/share_bottom_sheet.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../utils/html_helper.dart';
import '../models/video_comment.dart';
import '../models/video_rating.dart';
import '../services/theme_service.dart';
import '../services/interaction_api_service.dart';
import '../models/interaction.dart';
import '../models/visite_guidee_video.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/snackbar.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';
import '../config/app_dimensions.dart';
import '../widgets/components/custom_button.dart';
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../services/ecole_api_service.dart';
import 'establishment_detail_screen.dart';
import '../config/app_config.dart';
import '../services/ad_service.dart';
import '../models/ad_model.dart';
import '../utils/ad_injector.dart';
import '../widgets/ad_video_page.dart';

import 'all_visite_guidee_videos_screen.dart';
import 'tips_advice_screen.dart';
import '../models/video.dart';

class VisiteGuideeVideoFeedScreen extends StatefulWidget {
  final List<VisiteGuideeVideo> videos;
  final int initialIndex;
  final bool cameFromGrid;

  const VisiteGuideeVideoFeedScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
    this.cameFromGrid = false,
  });

  @override
  State<VisiteGuideeVideoFeedScreen> createState() =>
      _VisiteGuideeVideoFeedScreenState();
}

class _VisiteGuideeVideoFeedScreenState
    extends State<VisiteGuideeVideoFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<YoutubePlayerController?> _youtubeControllers = [];
  final Set<int> _likedVideoIds = <int>{};
  final Map<int, int> _videoCommentsCount = <int, int>{};
  final Map<int, int> _videoLikesCount = <int, int>{};

  final AdService _adService = AdService();
  List<AdModel> _ads = [];
  List<dynamic> _mixedVideos = [];
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadAdsAndInit();
  }

  Future<void> _loadAdsAndInit() async {
    _ads = await _adService.fetchAds();
    _mixedVideos = AdInjector.injectAds<VisiteGuideeVideo>(widget.videos, _ads);

    // adjust initial index to account for injected ads
    int newIndex = 0;
    int oldVideoCount = 0;
    for (int i = 0; i < _mixedVideos.length; i++) {
      if (_mixedVideos[i] is VisiteGuideeVideo) {
        if (oldVideoCount == widget.initialIndex) {
          newIndex = i;
          break;
        }
        oldVideoCount++;
      }
    }

    _currentIndex = newIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Initialisation lazy : créer une liste de null, seule la fenêtre active sera initialisée
    _youtubeControllers = List<YoutubePlayerController?>.filled(_mixedVideos.length, null);
    // Pré-initialiser uniquement la vidéo courante + les adjacentes (fenêtre de 3 max)
    _ensureControllerAt(_currentIndex, autoPlay: true);
    if (_currentIndex - 1 >= 0) _ensureControllerAt(_currentIndex - 1, autoPlay: false);
    if (_currentIndex + 1 < _mixedVideos.length) _ensureControllerAt(_currentIndex + 1, autoPlay: false);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
      if (_mixedVideos.isNotEmpty &&
          _mixedVideos[_currentIndex] is VisiteGuideeVideo) {
        // Optionnel : _fetchVideoInteractions
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _youtubeControllers) {
      if (controller != null) {
        controller.pause();
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Crée un contrôleur YouTube pour l'index donné s'il n'existe pas déjà.
  void _ensureControllerAt(int index, {required bool autoPlay}) {
    if (index < 0 || index >= _mixedVideos.length) return;
    // Déjà initialisé ou c'est une pub
    if (_youtubeControllers[index] != null) return;
    final item = _mixedVideos[index];
    if (item is AdGroup) return;

    final video = item as VisiteGuideeVideo;
    final videoId = video.youtubeVideoId.isEmpty
        ? video.youtubeUrl
        : video.youtubeVideoId;
    if (videoId.isEmpty) return;

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: autoPlay,
        mute: false,
        enableCaption: false,
        forceHD: false,
        loop: true,
        hideControls: true,
        hideThumbnail: true,
      ),
    );
    _youtubeControllers[index] = controller;
  }

  /// Met à jour la fenêtre glissante : garde uniquement les contrôleurs
  /// pour [centerIndex-1, centerIndex, centerIndex+1] et libère les autres.
  void _updateControllersWindow(int centerIndex) {
    final windowIndices = <int>{
      if (centerIndex - 1 >= 0) centerIndex - 1,
      centerIndex,
      if (centerIndex + 1 < _mixedVideos.length) centerIndex + 1,
    };

    // Libérer les contrôleurs hors fenêtre
    for (int i = 0; i < _youtubeControllers.length; i++) {
      if (!windowIndices.contains(i) && _youtubeControllers[i] != null) {
        _youtubeControllers[i]!.pause();
        _youtubeControllers[i]!.dispose();
        _youtubeControllers[i] = null;
      }
    }

    // Pré-initialiser les contrôleurs dans la fenêtre
    for (final i in windowIndices) {
      _ensureControllerAt(i, autoPlay: i == centerIndex);
    }
  }

  Future<void> _fetchVideoInteractions(VisiteGuideeVideo video) async {
    final videoId = video.id ?? video.typeVideo.hashCode;
    final astuceIdentifier = video.slug ?? video.id?.toString() ?? '';

    if (video.typeVideo == 'astuce' && astuceIdentifier.isNotEmpty) {
      try {
        final astuceService = AstuceConseilService();
        final likes = await astuceService.getLikes(astuceIdentifier);
        final comments = await astuceService.getComments(astuceIdentifier);

        final user = AuthService.instance.getCurrentUser();
        final hasLiked =
            user != null &&
            likes.any((like) => like['userid']?.toString() == user.id);

        if (mounted) {
          setState(() {
            if (hasLiked) {
              _likedVideoIds.add(videoId);
            } else {
              _likedVideoIds.remove(videoId);
            }
            _videoCommentsCount[videoId] = comments.length;
            _videoLikesCount[videoId] = likes.length;
          });
        }
      } catch (e) {
        print(
          '⚠️ Erreur lors de la récupération des interactions astuce pour la vidéo $videoId: $e',
        );
      }
      return;
    }

    final userId = InteractionApiService.getCurrentUserId();
    if (userId == null) return;

    try {
      final likes = await InteractionApiService.listInteractions(
        videoId: videoId,
        type: 'like',
      );

      final comments = await InteractionApiService.listInteractions(
        videoId: videoId,
        type: 'comment',
      );

      final hasLiked = likes.any((like) => like.userId == userId);

      if (mounted) {
        setState(() {
          if (hasLiked) {
            _likedVideoIds.add(videoId);
          } else {
            _likedVideoIds.remove(videoId);
          }
          _videoCommentsCount[videoId] = comments.length;
          _videoLikesCount[videoId] = likes.length;
        });
      }
    } catch (e) {
      print(
        '⚠️ Erreur lors de la récupération des interactions pour la vidéo $videoId: $e',
      );
    }
  }

  void _onPageChanged(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });

    // Pause de l'ancienne vidéo
    if (_youtubeControllers[previousIndex] != null) {
      _youtubeControllers[previousIndex]!.pause();
    }

    // Mettre à jour la fenêtre glissante (crée les adjacents, libère les éloignés)
    _updateControllersWindow(index);

    // Lecture instantanée de la vidéo active
    if (_youtubeControllers[index] != null) {
      _youtubeControllers[index]!.play();
    }

    if (_mixedVideos[index] is VisiteGuideeVideo) {
      _fetchVideoInteractions(_mixedVideos[index] as VisiteGuideeVideo);
    }
  }

  // Naviguer vers le détail de l'école
  Future<void> _navigateToEcole(String code) async {
    print('🏫 ═══════════════════════════════════════════');
    print('🏫 BOUTON ÉCOLE CLIQUÉ');
    print('🏫 ═══════════════════════════════════════════');
    print('🏫 Code école reçu: "$code"');
    print('🏫 Index courant: $_currentIndex');
    if (widget.videos.isNotEmpty && _currentIndex < widget.videos.length) {
      final video = widget.videos[_currentIndex];
      print(
        '🏫 Vidéo courante - id: ${video.id}, code: "${video.code}", etablissement: "${video.etablissement}", title: "${video.title}"',
      );
    }

    if (code.isEmpty) {
      print('🏫 ❌ Code école VIDE ! Navigation annulée.');
      CartSnackBar.showOverlay(
        context,
        productName: '',
        message: 'Le code de l\'école est manquant pour cette vidéo',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    try {
      print('🏫 📡 Appel API getEcoleParametres("$code")...');
      // Charger les détails de l'école via l'API des paramètres
      final ecoleData = await EcoleApiService.getEcoleParametres(code);
      print(
        '🏫 ✅ API OK - nom: "${ecoleData.nom}", ville: "${ecoleData.ville}", statut: "${ecoleData.statut}"',
      );

      // Créer un objet Ecole minimal avec les données récupérées
      final ecole = Ecole(
        pays: ecoleData.pays,
        ville: ecoleData.ville,
        adresse: ecoleData.adresse,
        parametreNom: ecoleData.nom,
        logo: ecoleData.logo ?? '',
        telephone: ecoleData.telephone,
        parametreCode: code,
        statut: ecoleData.statut,
        filiereNom: [],
        imagefond: ecoleData.imagefond,
        paramecole: code,
      );

      if (mounted) {
        print('🏫 🚀 Navigation vers EstablishmentDetailScreen...');
        MainScreenWrapper.of(context).navigateToEstablishmentDetail(ecole);
      }
    } catch (e) {
      print('🏫 ❌ ERREUR: $e');
      // La notification est déjà gérée par ApiExceptionHandler
      final errorStr = e.toString();
      if (errorStr.contains('Aucune école associée à cette vidéo') || errorStr.contains('404')) {
        if (mounted) {
          final wrapper = MainScreenWrapper.maybeOf(context);
          if (wrapper != null) {
            wrapper.updateCurrentIndex(2); // Index 2 correspond à l'onglet "Établissement"
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    }
  }

  // Afficher les options de partage
  void _shareVideo() {
    if (_mixedVideos.isEmpty) return;

    final item = _mixedVideos[_currentIndex];
    if (item is AdGroup) return;

    final currentVideo = item as VisiteGuideeVideo;

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    final videoId = currentVideo.youtubeVideoId.isEmpty
        ? currentVideo.youtubeUrl
        : currentVideo.youtubeVideoId;
    final String videoUrl = 'https://www.youtube.com/watch?v=$videoId';
    final String videoTitle = HtmlHelper.stripHtmlTags(currentVideo.title ?? 'Vidéo');
    final String videoDesc = HtmlHelper.stripHtmlTags(currentVideo.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        title: 'Partager la vidéo',
        itemTitle: videoTitle,
        shareText:
            '🎬 Regarde cette vidéo incroyable : $videoTitle\n\n$videoDesc\n\nRegardez la vidéo ici : $videoUrl\n\nTéléchargez l\'application ici : ${AppConfig.storeUrl}\n\n#PoulsMobile #Éducation',
      ),
    );
  }

  // Afficher les commentaires
  void _showComments() {
    if (_mixedVideos.isEmpty) return;

    final item = _mixedVideos[_currentIndex];
    if (item is! VisiteGuideeVideo) return;

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    ReusableBottomSheet.show(
      context: context,
      title: 'Commentaires',
      subtitle: 'Échangez sur cette vidéo',
      icon: Icons.comment_rounded,
      iconColor: const Color(0xFF0288D1),
      wrapWithScrollView: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      contentPadding: EdgeInsets.zero,
      content: _CommentsSheet(video: item),
    );
  }

  // Afficher la notation
  void _showRating() {
    if (_mixedVideos.isEmpty) return;

    final item = _mixedVideos[_currentIndex];
    if (item is! VisiteGuideeVideo) return;

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    ReusableBottomSheet.show(
      context: context,
      title: 'Noter la vidéo',
      icon: Icons.star_rounded,
      iconColor: Colors.orange,
      wrapWithScrollView: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      contentPadding: EdgeInsets.zero,
      content: _RatingSheet(video: item),
    );
  }

  Future<void> _toggleLike() async {
    if (_mixedVideos.isEmpty) return;

    final item = _mixedVideos[_currentIndex];
    if (item is! VisiteGuideeVideo) return;

    final videoId = item.id ?? item.typeVideo.hashCode;

    final userId = InteractionApiService.getCurrentUserId();
    if (userId == null) {
      CartSnackBar.showOverlay(
        context,
        productName: '',
        message: 'Vous devez être connecté pour aimer une vidéo',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      if (_likedVideoIds.contains(videoId)) {
        _likedVideoIds.remove(videoId);
        _videoLikesCount[videoId] = (_videoLikesCount[videoId] ?? 1) - 1;
      } else {
        _likedVideoIds.add(videoId);
        _videoLikesCount[videoId] = (_videoLikesCount[videoId] ?? 0) + 1;
      }
    });

    final type = _likedVideoIds.contains(videoId) ? 'like' : 'dislike';
    bool success = false;

    final astuceIdentifier = item.slug ?? item.id?.toString() ?? '';
    if (item.typeVideo == 'astuce' && astuceIdentifier.isNotEmpty) {
      final user = AuthService.instance.getCurrentUser();
      if (user != null) {
        success = await AstuceConseilService().likeArticle(
          astuceIdentifier,
          nom: user.fullName,
          userId: int.tryParse(user.id) ?? 0,
        );
      }
    } else {
      success = await InteractionApiService.toggleLike(
        videoId: videoId,
        userId: userId,
        type: type,
      );
    }

    if (!success) {
      // Revert if API failed
      if (mounted) {
        setState(() {
          if (type == 'like') {
            _likedVideoIds.remove(videoId);
            _videoLikesCount[videoId] = (_videoLikesCount[videoId] ?? 1) - 1;
          } else {
            _likedVideoIds.add(videoId);
            _videoLikesCount[videoId] = (_videoLikesCount[videoId] ?? 0) + 1;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isDarkMode = ThemeService().isDarkMode;

    // Handle empty videos list
    if (_mixedVideos.isEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          title: Text(
            'Visites Guidées',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              if (MainScreenWrapper.maybeOf(context) != null) {
                MainScreenWrapper.of(context).goBackToPreviousTab();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune vidéo disponible',
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // PageView pour les vidéos (défilement vertical)
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            allowImplicitScrolling: true,
            onPageChanged: _onPageChanged,
            itemCount: _mixedVideos.length,
            itemBuilder: (context, index) {
              final item = _mixedVideos[index];
              final isActive = index == _currentIndex;

              if (item is AdGroup) {
                return AdVideoCarouselPage(adGroup: item, isActive: isActive);
              }

              final video = item as VisiteGuideeVideo;
              final controller = _youtubeControllers[index];

              return _VideoPage(
                video: video,
                youtubeController: controller,
                isActive: isActive,
              );
            },
          ),

          // Indicateur de page supprimé

          // Boutons d'action latéraux
          if (_mixedVideos[_currentIndex] is VisiteGuideeVideo)
            Positioned(
              right: 16,
              bottom: 160,
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.school,
                    label: 'École',
                    onTap: () {
                      final item = _mixedVideos[_currentIndex];
                      if (item is VisiteGuideeVideo) {
                        _navigateToEcole(item.code);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon:
                        _mixedVideos[_currentIndex] is VisiteGuideeVideo &&
                            _likedVideoIds.contains(
                              (_mixedVideos[_currentIndex] as VisiteGuideeVideo)
                                      .id ??
                                  (_mixedVideos[_currentIndex]
                                          as VisiteGuideeVideo)
                                      .typeVideo
                                      .hashCode,
                            )
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label:
                        _mixedVideos[_currentIndex] is VisiteGuideeVideo &&
                            _videoLikesCount.containsKey(
                              (_mixedVideos[_currentIndex] as VisiteGuideeVideo)
                                      .id ??
                                  (_mixedVideos[_currentIndex]
                                          as VisiteGuideeVideo)
                                      .typeVideo
                                      .hashCode,
                            ) &&
                            _videoLikesCount[(_mixedVideos[_currentIndex]
                                            as VisiteGuideeVideo)
                                        .id ??
                                    (_mixedVideos[_currentIndex]
                                            as VisiteGuideeVideo)
                                        .typeVideo
                                        .hashCode]! >
                                0
                        ? '${_videoLikesCount[(_mixedVideos[_currentIndex] as VisiteGuideeVideo).id ?? (_mixedVideos[_currentIndex] as VisiteGuideeVideo).typeVideo.hashCode]}'
                        : 'J\'aime',
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.share,
                    label: 'Partager',
                    onTap: _shareVideo,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.comment,
                    label:
                        _mixedVideos[_currentIndex] is VisiteGuideeVideo &&
                            _videoCommentsCount.containsKey(
                              (_mixedVideos[_currentIndex] as VisiteGuideeVideo)
                                  .typeVideo
                                  .hashCode,
                            ) &&
                            _videoCommentsCount[(_mixedVideos[_currentIndex]
                                        as VisiteGuideeVideo)
                                    .typeVideo
                                    .hashCode]! >
                                0
                        ? '${_videoCommentsCount[(_mixedVideos[_currentIndex] as VisiteGuideeVideo).typeVideo.hashCode]}'
                        : 'Commenter',
                    onTap: _showComments,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.star,
                    label: 'Noter',
                    onTap: _showRating,
                  ),
                ],
              ),
            ),

          // CustomSliverAppBarFixed overlay (identique à coulisse_video_feed_screen.dart pour un effet ultra premium)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 56 + MediaQuery.paddingOf(context).top,
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  CustomSliverAppBar(
                    title: '',
                    isDark:
                        true, // Toujours style sombre au-dessus du lecteur pour un contraste premium suprême
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: true,
                    actions: [
                      AppBarIconButton(
                        icon: Icons.grid_view,
                        isDark: true,
                        onTap: () {
                          if (widget.cameFromGrid) {
                            final wrapper = MainScreenWrapper.maybeOf(context);
                            if (wrapper != null) {
                              wrapper.goBackToPreviousTab();
                            } else {
                              Navigator.of(context).pop();
                            }
                          } else {
                            if (_mixedVideos.isNotEmpty && _currentIndex < _mixedVideos.length) {
                              final item = _mixedVideos[_currentIndex];
                              if (item is VisiteGuideeVideo) {
                                if (item.typeVideo == 'astuce') {
                                  if (MainScreenWrapper.maybeOf(context) != null) {
                                    MainScreenWrapper.of(context).updateCurrentIndex(3);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TipsAdviceScreen(),
                                      ),
                                    );
                                  }
                                } else {
                                  final ecoleCode = item.code;
                                  final mappedVideos = widget.videos.map((v) => Video(
                                    id: v.id,
                                    typevideo: v.typeVideo,
                                    youtubeUrl: v.youtubeUrl,
                                    title: v.title ?? '',
                                    description: v.description ?? '',
                                    createdAt: '',
                                    code: v.code,
                                    etablissement: v.etablissement,
                                  )).toList();

                                  if (MainScreenWrapper.maybeOf(context) != null) {
                                    MainScreenWrapper.of(context).navigateToExtraScreen(
                                      AllVisiteGuideeVideosScreen(
                                        videos: mappedVideos,
                                        ecoleCode: '',
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AllVisiteGuideeVideosScreen(
                                          videos: mappedVideos,
                                          ecoleCode: '',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  final VisiteGuideeVideo video;
  final YoutubePlayerController? youtubeController;
  final bool isActive;

  const _VideoPage({
    required this.video,
    this.youtubeController,
    required this.isActive,
  });

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage>
    with SingleTickerProviderStateMixin {
  bool _showPlayPauseOverlay = false;
  bool _overlayIsPlayIcon = false;
  bool _isDescriptionExpanded = false;
  late AnimationController _overlayAnimationController;

  @override
  void initState() {
    super.initState();
    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _overlayAnimationController.dispose();
    super.dispose();
  }

  void _showDescriptionModal() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8), // Noir transparent
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        HtmlHelper.stripHtmlTags(
                          widget.video.displayDescription,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    if (widget.youtubeController != null) {
      final isPlaying = widget.youtubeController!.value.isPlaying;
      setState(() {
        if (isPlaying) {
          widget.youtubeController!.pause();
          _overlayIsPlayIcon = false; // Show pause icon
        } else {
          widget.youtubeController!.play();
          _overlayIsPlayIcon = true; // Show play icon
        }
        _showPlayPauseOverlay = true;
      });

      _overlayAnimationController.forward(from: 0.0).then((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _showPlayPauseOverlay = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Vidéo YouTube
        if (widget.youtubeController != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: YoutubePlayer(
              controller: widget.youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                if (widget.isActive) {
                  widget.youtubeController!.play();
                }
              },
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white54,
                size: 80,
              ),
            ),
          ),

        // Transient Play/Pause Overlay Icon
        if (_showPlayPauseOverlay)
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _overlayAnimationController,
                builder: (context, child) {
                  final scale =
                      1.0 + (1.0 - _overlayAnimationController.value) * 0.5;
                  final opacity = 1.0 - _overlayAnimationController.value;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _overlayIsPlayIcon ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // Informations superposées
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.only(
              left: 16,
              right: 88, // Espace pour ne pas chevaucher les boutons d'action
              bottom:
                  170, // Increased bottom padding to avoid progress bar overlap
              top: 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // School/Etablissement Logo & Name Row
                Row(
                  children: [
                    _SchoolLogo(
                      code: widget.video.code,
                      fallbackName: widget.video.etablissement,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.video.etablissement,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showDescriptionModal,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.video.displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HtmlHelper.stripHtmlTags(
                            widget.video.displayDescription,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Voir plus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Barre de progression et contrôles (style YouTube)
        if (widget.youtubeController != null)
          Positioned(
            bottom: 115, // Sous la description
            left: 0,
            right: 0,
            child: ValueListenableBuilder<YoutubePlayerValue>(
              valueListenable: widget.youtubeController!,
              builder: (context, value, child) {
                final duration = value.metaData.duration.inMilliseconds;
                final position = value.position.inMilliseconds;
                double progress = 0.0;
                if (duration > 0 && position > 0) {
                  progress = position / duration;
                }

                String formatDuration(int millis) {
                  final seconds = (millis / 1000).truncate();
                  final minutes = (seconds / 60).truncate();
                  final remainingSeconds = seconds % 60;
                  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
                }

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (value.isPlaying) {
                          widget.youtubeController!.pause();
                        } else {
                          widget.youtubeController!.play();
                        }
                      },
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.red,
                          trackShape: const RectangularSliderTrackShape(),
                        ),
                        child: Slider(
                          value: progress.isNaN
                              ? 0.0
                              : progress.clamp(0.0, 1.0),
                          onChanged: (newValue) {
                            if (duration > 0) {
                              widget.youtubeController!.seekTo(
                                Duration(
                                  milliseconds: (newValue * duration).round(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${formatDuration(position)} / ${formatDuration(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SchoolLogo extends StatefulWidget {
  final String code;
  final String fallbackName;

  const _SchoolLogo({required this.code, required this.fallbackName});

  @override
  State<_SchoolLogo> createState() => _SchoolLogoState();
}

class _SchoolLogoState extends State<_SchoolLogo> {
  late Future<EcoleDetail> _ecoleDetailFuture;

  @override
  void initState() {
    super.initState();
    if (widget.code.isNotEmpty) {
      _ecoleDetailFuture = EcoleApiService.getEcoleDetail(
        widget.code,
        showNotification: false,
      );
    } else {
      _ecoleDetailFuture = Future.error('Code école vide');
    }
  }

  @override
  void didUpdateWidget(covariant _SchoolLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      if (widget.code.isNotEmpty) {
        _ecoleDetailFuture = EcoleApiService.getEcoleDetail(
          widget.code,
          showNotification: false,
        );
      } else {
        _ecoleDetailFuture = Future.error('Code école vide');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EcoleDetail>(
      future: _ecoleDetailFuture,
      builder: (context, snapshot) {
        String? logoUrl;
        if (snapshot.hasData) {
          logoUrl = snapshot.data?.data.logo;
        }

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            backgroundImage:
                logoUrl != null &&
                    logoUrl.isNotEmpty &&
                    (logoUrl.startsWith('http://') ||
                        logoUrl.startsWith('https://'))
                ? NetworkImage(logoUrl)
                : null,
            child:
                logoUrl == null ||
                    logoUrl.isEmpty ||
                    (!logoUrl.startsWith('http://') &&
                        !logoUrl.startsWith('https://'))
                ? Text(
                    widget.fallbackName.isNotEmpty
                        ? widget.fallbackName[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final VisiteGuideeVideo video;

  const _CommentsSheet({required this.video});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Interaction> _comments = [];
  bool _isLoading = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = InteractionApiService.getCurrentUserId();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (_currentUserId == null) {
      print('⚠️ Utilisateur non connecté');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Interaction> comments = [];
    final astuceIdentifier =
        widget.video.slug ?? widget.video.id?.toString() ?? '';

    if (widget.video.typeVideo == 'astuce' && astuceIdentifier.isNotEmpty) {
      final apiComments = await AstuceConseilService().getComments(
        astuceIdentifier,
      );
      comments = apiComments
          .map(
            (c) => Interaction(
              id: c['id'] as int? ?? 0,
              videoId: widget.video.id ?? widget.video.typeVideo.hashCode,
              userId: _currentUserId!,
              type: 'comment',
              content: (c['content'] ?? c['contenu'])?.toString() ?? '',
              createdAt: c['created_at'] != null
                  ? DateTime.tryParse(c['created_at']) ?? DateTime.now()
                  : DateTime.now(),
              userName:
                  (c['author_name'] ?? c['nom'])?.toString() ?? 'Utilisateur',
            ),
          )
          .toList();
    } else {
      comments = await InteractionApiService.listInteractions(
        videoId: widget.video.id ?? widget.video.typeVideo.hashCode,
        type: 'comment',
      );
    }

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_currentUserId == null) {
      CartSnackBar.showOverlay(
        context,
        productName: '',
        message: 'Vous devez être connecté pour commenter',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      Interaction? newComment;
      final user = AuthService.instance.getCurrentUser();
      final astuceIdentifier =
          widget.video.slug ?? widget.video.id?.toString() ?? '';

      if (widget.video.typeVideo == 'astuce' &&
          astuceIdentifier.isNotEmpty &&
          user != null) {
        final content = _commentController.text.trim();
        final success = await AstuceConseilService().addComment(
          astuceIdentifier,
          nom: user.fullName,
          userId: int.tryParse(user.id) ?? 0,
          contenu: content,
        );
        if (success) {
          newComment = Interaction(
            id: DateTime.now().millisecondsSinceEpoch,
            videoId: widget.video.id ?? widget.video.typeVideo.hashCode,
            userId: _currentUserId!,
            type: 'comment',
            content: content,
            createdAt: DateTime.now(),
            userName: user.fullName,
          );
        }
      } else {
        newComment = await InteractionApiService.createInteraction(
          videoId: widget.video.id ?? widget.video.typeVideo.hashCode,
          userId: _currentUserId!,
          type: 'comment',
          content: _commentController.text.trim(),
        );
      }

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment!);
          _commentController.clear();
        });
      } else {
        await _loadComments();
        _commentController.clear();
        CartSnackBar.showOverlay(
          context,
          productName: '',
          message: 'Commentaire ajouté avec succès',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white54 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    final inputBorderColor = isDarkMode ? Colors.white24 : Colors.black12;

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDarkMode
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _CommentItem(
                      comment: comment,
                      currentUserId: _currentUserId,
                      onDelete: () => _deleteComment(comment.id),
                      onEdit: (newContent) =>
                          _editComment(comment.id, newContent),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 12
                : 24,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: inputBorderColor, width: 0.5),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: TextStyle(fontSize: 14, color: subtextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addComment,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteComment(int commentId) async {
    if (_currentUserId == null) return;

    setState(() {
      _comments.removeWhere((c) => c.id == commentId);
    });

    try {
      await InteractionApiService.deleteComment(
        commentId: commentId,
        userId: _currentUserId!,
      );
    } catch (e) {
      print('⚠️ Erreur lors de la suppression API: $e');
    }

    await _loadComments();
  }

  Future<void> _editComment(int commentId, String newContent) async {
    if (_currentUserId == null) return;

    setState(() {
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(content: newContent);
      }
    });

    try {
      await InteractionApiService.updateComment(
        commentId: commentId,
        userId: _currentUserId!,
        content: newContent,
      );
    } catch (e) {
      print('⚠️ Erreur lors de la modification API: $e');
    }

    await _loadComments();
  }
}

class _CommentItem extends StatelessWidget {
  final Interaction comment;
  final int? currentUserId;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const _CommentItem({
    required this.comment,
    this.currentUserId,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final isCurrentUser =
        currentUserId != null && comment.userId == currentUserId;
    final displayName = comment.userName ?? 'Utilisateur';

    final nameColor = isDarkMode ? Colors.white : Colors.black87;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;
    final timeColor = isDarkMode ? Colors.white54 : Colors.black45;
    final avatarBgColor = isDarkMode ? Colors.white24 : Colors.grey[300];
    final avatarTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarBgColor,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(color: avatarTextColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TextStyle(color: timeColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser) ...[
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: timeColor, size: 20),
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDarkMode ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Modifier',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              comment.content ?? '',
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }

  void _showEditDialog(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final controller = TextEditingController(text: comment.content ?? '');

    final dialogBgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white54 : Colors.black38;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          'Modifier le commentaire',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Votre commentaire...',
            hintStyle: TextStyle(color: hintColor),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                onEdit(controller.text.trim());
              }
            },
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final dialogBgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          'Supprimer le commentaire',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSheet extends StatefulWidget {
  final VisiteGuideeVideo video;

  const _RatingSheet({required this.video});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _currentRating = 0;
  bool _hasRated = false;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final videoId = widget.video.id ?? widget.video.typeVideo.hashCode;
    final astuceIdentifier =
        widget.video.slug ?? widget.video.id?.toString() ?? '';

    try {
      final ratings = await InteractionApiService.listInteractions(
        videoId: videoId,
        type: 'rating',
      );

      final user = AuthService.instance.getCurrentUser();
      final currentUserId = user != null ? int.tryParse(user.id) ?? 0 : 0;

      bool hasRated = false;
      int sumRatings = 0;
      int count = 0;

      for (var r in ratings) {
        if (r.userId == currentUserId) hasRated = true;
        final val = int.tryParse(r.content ?? '') ?? 0;
        if (val > 0 && val <= 5) {
          sumRatings += val;
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _totalRatings = count;
          _averageRating = count > 0 ? sumRatings / count : 0.0;
          _hasRated = hasRated;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur _loadRatings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final iconBgColor = isDarkMode ? Colors.white24 : Colors.grey[200];
    final playIconColor = isDarkMode ? Colors.white : Colors.black87;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Video info
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: iconBgColor,
                    ),
                    child: Icon(
                      Icons.play_circle,
                      color: playIconColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.displayTitle,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visite guidée',
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Current rating stats
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _averageRating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          Text(
                            '$_totalRatings évaluations',
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // User rating
              if (!_hasRated) ...[
                Text(
                  'Votre note :',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _currentRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _currentRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Center(
                  child: CustomButton(
                    text: 'Envoyer la note',
                    color: Colors.green,
                    onPressed: _currentRating > 0 ? _submitRating : null,
                    height: 48,
                    width: 300,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Merci pour votre évaluation !',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitRating() async {
    setState(() {
      _hasRated = true;
      // Mettre à jour les statistiques (simulation de l'UI en attendant que l'API réponde)
      _totalRatings++;
      _averageRating =
          ((_averageRating * (_totalRatings - 1)) + _currentRating) /
          _totalRatings;
    });

    final user = AuthService.instance.getCurrentUser();
    final userId = user != null ? int.tryParse(user.id) ?? 0 : 0;

    if (userId > 0) {
      try {
        final videoId = widget.video.id ?? widget.video.typeVideo.hashCode;

        await InteractionApiService.createInteraction(
          videoId: videoId,
          userId: userId,
          type: 'rating',
          content: _currentRating.toString(),
        );
      } catch (e) {
        print('❌ Erreur lors de l\'envoi de la note: $e');
      }
    }

    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
}
