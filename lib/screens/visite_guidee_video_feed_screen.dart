import 'package:flutter/material.dart';
import 'package:parents_responsable/widgets/bottom_sheets/reusable_bottom_sheet.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/share_bottom_sheet.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../widgets/main_screen_wrapper.dart';
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

class VisiteGuideeVideoFeedScreen extends StatefulWidget {
  final List<VisiteGuideeVideo> videos;
  final int initialIndex;

  const VisiteGuideeVideoFeedScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeControllers();
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

  void _initializeControllers() {
    // Créer les contrôleurs YouTube pour chaque vidéo
    final controllers = <YoutubePlayerController?>[];
    for (var video in widget.videos) {
      final videoId = video.youtubeVideoId;
      print('Traitement vidéo: ${video.typeVideo} - VideoID: $videoId');
      if (videoId.isNotEmpty) {
        final isInitialVideo =
            widget.videos.indexOf(video) == widget.initialIndex;
        final controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: isInitialVideo,
            mute: false,
            enableCaption: false,
            forceHD: false,
            loop: true, // Loopper la vidéo comme sur TikTok / YouTube Shorts
            hideControls: true, // Masquer les contrôles natifs
          ),
        );
        // Ajouter un écouteur pour rafraîchir le bouton Play/Pause en direct
        controller.addListener(() {
          if (mounted) {
            final activeIndex = widget.videos.indexOf(video);
            if (activeIndex == _currentIndex) {
              setState(() {});
            }
          }
        });
        controllers.add(controller);
      } else {
        print('VideoID vide pour vidéo ${video.typeVideo}');
        controllers.add(null);
      }
    }

    setState(() {
      _youtubeControllers = controllers;
    });
  }

  Future<void> _fetchVideoInteractions(int videoId) async {
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
    setState(() {
      _currentIndex = index;
    });

    // Lecture instantanée de la vidéo active dès le swipe
    if (_youtubeControllers[index] != null) {
      _youtubeControllers[index]!.play();
    }

    // Pause immédiate de toutes les autres vidéos pour économiser le CPU et le réseau
    for (int i = 0; i < _youtubeControllers.length; i++) {
      if (i != index && _youtubeControllers[i] != null) {
        _youtubeControllers[i]!.pause();
      }
    }

    if (widget.videos.isNotEmpty && index < widget.videos.length) {
      final videoId =
          widget.videos[index].id ?? widget.videos[index].typeVideo.hashCode;
      _fetchVideoInteractions(videoId);
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
      print('🏫 Vidéo courante - id: ${video.id}, code: "${video.code}", etablissement: "${video.etablissement}", title: "${video.title}"');
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
      print('🏫 ✅ API OK - nom: "${ecoleData.nom}", ville: "${ecoleData.ville}", statut: "${ecoleData.statut}"');

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
      if (mounted) {
        CartSnackBar.showOverlay(
          context,
          productName: '',
          message: 'Erreur: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  // Afficher les options de partage
  void _shareVideo() {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    final String videoUrl =
        'https://www.youtube.com/watch?v=${video.youtubeVideoId}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
      ),
      builder: (context) => ShareBottomSheet(
        title: 'Partager la vidéo',
        itemTitle: video.displayTitle,
        shareText:
            '🎬 Découvrez cette visite guidée : ${video.displayTitle}\n\nRegardez la vidéo ici : $videoUrl\n\nTéléchargez l\'application ici : ${AppConfig.storeUrl}',
      ),
    );
  }

  // Afficher les commentaires
  void _showComments() {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];

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
      content: _CommentsSheet(videoId: video.id ?? video.typeVideo.hashCode),
    );
  }

  // Afficher la notation
  void _showRating() {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];

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
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      contentPadding: EdgeInsets.zero,
      content: _RatingSheet(video: video),
    );
  }

  Future<void> _toggleLike() async {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];
    final videoId = video.id ?? video.typeVideo.hashCode;

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

    // API Call
    final type = _likedVideoIds.contains(videoId) ? 'like' : 'dislike';
    final success = await InteractionApiService.toggleLike(
      videoId: videoId,
      userId: userId,
      type: type,
    );

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
    final isDarkMode = ThemeService().isDarkMode;

    // Handle empty videos list
    if (widget.videos.isEmpty) {
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
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              return _VideoPage(
                video: widget.videos[index],
                youtubeController: _youtubeControllers[index],
                isActive: index == _currentIndex,
              );
            },
          ),

          // Indicateur de page
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.videos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Boutons d'action latéraux
          Positioned(
            right: 16,
            bottom: 160,
            child: Column(
              children: [
                _ActionButton(
                  icon:
                      (_youtubeControllers.isNotEmpty &&
                          _currentIndex < _youtubeControllers.length &&
                          _youtubeControllers[_currentIndex] != null &&
                          _youtubeControllers[_currentIndex]!.value.isPlaying)
                      ? Icons.pause
                      : Icons.play_arrow,
                  label:
                      (_youtubeControllers.isNotEmpty &&
                          _currentIndex < _youtubeControllers.length &&
                          _youtubeControllers[_currentIndex] != null &&
                          _youtubeControllers[_currentIndex]!.value.isPlaying)
                      ? 'Pause'
                      : 'Lecture',
                  onTap: () {
                    if (_youtubeControllers.isNotEmpty &&
                        _currentIndex < _youtubeControllers.length &&
                        _youtubeControllers[_currentIndex] != null) {
                      final controller = _youtubeControllers[_currentIndex]!;
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.school,
                  label: 'École',
                  onTap: widget.videos.isNotEmpty
                      ? () =>
                            _navigateToEcole(widget.videos[_currentIndex].code)
                      : () {},
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon:
                      widget.videos.isNotEmpty &&
                          _likedVideoIds.contains(
                            widget.videos[_currentIndex].id ??
                                widget.videos[_currentIndex].typeVideo.hashCode,
                          )
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label:
                      widget.videos.isNotEmpty &&
                          _videoLikesCount.containsKey(
                            widget.videos[_currentIndex].id ??
                                widget.videos[_currentIndex].typeVideo.hashCode,
                          ) &&
                          _videoLikesCount[widget.videos[_currentIndex].id ??
                                  widget
                                      .videos[_currentIndex]
                                      .typeVideo
                                      .hashCode]! >
                              0
                      ? '${_videoLikesCount[widget.videos[_currentIndex].id ?? widget.videos[_currentIndex].typeVideo.hashCode]}'
                      : 'J\'aime',
                  onTap: widget.videos.isNotEmpty ? _toggleLike : () {},
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
                      widget.videos.isNotEmpty &&
                          _videoCommentsCount.containsKey(
                            widget.videos[_currentIndex].typeVideo.hashCode,
                          ) &&
                          _videoCommentsCount[widget
                                  .videos[_currentIndex]
                                  .typeVideo
                                  .hashCode]! >
                              0
                      ? '${_videoCommentsCount[widget.videos[_currentIndex].typeVideo.hashCode]}'
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
                          if (MainScreenWrapper.maybeOf(context) != null) {
                            MainScreenWrapper.of(context).goBackToPreviousTab();
                          } else {
                            Navigator.of(context).pop();
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
              right: 88, // Space for right-side vertical action buttons
              bottom:
                  130, // Increased bottom padding to avoid bottom navigation bar overlap
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
                  widget.video.displayDescription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      _ecoleDetailFuture = EcoleApiService.getEcoleDetail(widget.code, showNotification: false);
    } else {
      _ecoleDetailFuture = Future.error('Code école vide');
    }
  }

  @override
  void didUpdateWidget(covariant _SchoolLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      if (widget.code.isNotEmpty) {
        _ecoleDetailFuture = EcoleApiService.getEcoleDetail(widget.code, showNotification: false);
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
  final int videoId;

  const _CommentsSheet({required this.videoId});

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

    final comments = await InteractionApiService.listInteractions(
      videoId: widget.videoId,
      type: 'comment',
    );

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
      final newComment = await InteractionApiService.createInteraction(
        videoId: widget.videoId,
        userId: _currentUserId!,
        type: 'comment',
        content: _commentController.text.trim(),
      );

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
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
  double _averageRating = 4.2;
  int _totalRatings = 127;

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.white24,
                    ),
                    child: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visite guidée',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Current rating stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // User rating
              if (!_hasRated) ...[
                const Text(
                  'Votre note :',
                  style: TextStyle(
                    color: Colors.white,
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
                CustomButton(
                  text: 'Envoyer la note',
                  color: Colors.green,
                  onPressed: _currentRating > 0 ? _submitRating : null,
                  height: 48,
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
      // Mettre à jour les statistiques (simulation)
      _totalRatings++;
      _averageRating =
          ((_averageRating * (_totalRatings - 1)) + _currentRating) /
          _totalRatings;
    });

    // Simuler l'envoi au serveur
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
}
