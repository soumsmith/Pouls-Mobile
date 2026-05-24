import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/coulisse_excellence.dart';
import '../models/ecole.dart';
import '../models/video_rating.dart';
import '../models/interaction.dart';
import '../services/ecole_api_service.dart';
import '../services/interaction_api_service.dart';
import '../services/theme_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import 'establishment_detail_screen.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';

class CoulisseVideoFeedScreen extends StatefulWidget {
  final List<CoulisseExcellence> videos;
  final int initialIndex;

  const CoulisseVideoFeedScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<CoulisseVideoFeedScreen> createState() =>
      _CoulisseVideoFeedScreenState();
}

class _CoulisseVideoFeedScreenState extends State<CoulisseVideoFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<YoutubePlayerController?> _youtubeControllers = [];
  final Set<int> _likedVideoIds = <int>{};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeControllers();
    if (widget.videos.isNotEmpty) {
      _fetchVideoLikes(widget.videos[_currentIndex].id);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _youtubeControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    // Créer les contrôleurs YouTube pour chaque vidéo
    final controllers = <YoutubePlayerController?>[];
    for (var video in widget.videos) {
      final videoId = video.youtubeVideoId;
      print('Traitement vidéo: ${video.id} - VideoID: $videoId');
      if (videoId.isNotEmpty) {
        final isInitialVideo = widget.videos.indexOf(video) == widget.initialIndex;
        controllers.add(
          YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: isInitialVideo,
              mute: false,
              enableCaption: false,
              forceHD: false,
              loop: true, // Loopper la vidéo comme sur TikTok / YouTube Shorts
              hideControls: true, // Masquer les contrôles natifs (et le titre/logo de la chaîne en haut)
            ),
          ),
        );
      } else {
        print('VideoID vide pour vidéo ${video.id} - ${video.titre}');
        controllers.add(null);
      }
    }

    setState(() {
      _youtubeControllers = controllers;
    });
  }

  Future<void> _fetchVideoLikes(int videoId) async {
    final userId = InteractionApiService.getCurrentUserId();
    if (userId == null) return;

    try {
      final likes = await InteractionApiService.listInteractions(
        videoId: videoId,
        type: 'like',
      );
      
      final hasLiked = likes.any((like) => like.userId == userId);
      
      if (mounted) {
        setState(() {
          if (hasLiked) {
            _likedVideoIds.add(videoId);
          } else {
            _likedVideoIds.remove(videoId);
          }
        });
      }
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des likes pour la vidéo $videoId: $e');
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (widget.videos.isNotEmpty && index < widget.videos.length) {
      _fetchVideoLikes(widget.videos[index].id);
    }

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
  }

  // Naviguer vers le détail de l'école
  Future<void> _navigateToEcole(String code) async {
    if (code.isEmpty) return;

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    try {
      // Charger les détails de l'école via l'API de détail
      final ecoleDetail = await EcoleApiService.getEcoleDetail(code);

      // Créer un objet Ecole minimal avec les données récupérées
      final ecole = Ecole(
        pays: ecoleDetail.data.pays,
        ville: ecoleDetail.data.ville,
        adresse: ecoleDetail.data.adresse,
        parametreNom: ecoleDetail.data.nom,
        logo: ecoleDetail.data.logo ?? '',
        telephone: ecoleDetail.data.telephone,
        parametreCode: code,
        statut: ecoleDetail.data.statut,
        filiereNom: [],
        imagefond: ecoleDetail.image,
        paramecole: null,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EstablishmentDetailScreen(ecole: ecole),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // Afficher les options de partage
  Future<void> _shareVideo() async {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];

    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareOptionsSheet(video: video),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(videoId: video.id),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RatingSheet(video: video),
    );
  }

  void _toggleLike() async {
    if (widget.videos.isEmpty) return;

    final video = widget.videos[_currentIndex];
    final userId = InteractionApiService.getCurrentUserId();
    if (userId == null) {
      print('⚠️ Aucun utilisateur connecté pour aimer la vidéo.');
      return;
    }

    final isLike = !_likedVideoIds.contains(video.id);

    // Optimistic UI: update locally immediately
    setState(() {
      if (isLike) {
        _likedVideoIds.add(video.id);
      } else {
        _likedVideoIds.remove(video.id);
      }
    });

    try {
      final success = await InteractionApiService.toggleLike(
        videoId: video.id,
        userId: userId,
        type: isLike ? 'like' : 'dislike',
      );

      if (!success) {
        // Rollback on failure
        setState(() {
          if (isLike) {
            _likedVideoIds.remove(video.id);
          } else {
            _likedVideoIds.add(video.id);
          }
        });
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du like: $e');
      // Rollback on exception
      setState(() {
        if (isLike) {
          _likedVideoIds.remove(video.id);
        } else {
          _likedVideoIds.add(video.id);
        }
      });
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
            'Coulisses Excellence',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
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
                  icon: Icons.play_arrow,
                  label: 'Lecture',
                  onTap: () {
                    if (_youtubeControllers[_currentIndex] != null) {
                      _youtubeControllers[_currentIndex]!.play();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onTap: () {
                    if (_youtubeControllers[_currentIndex] != null) {
                      _youtubeControllers[_currentIndex]!.pause();
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
                            widget.videos[_currentIndex].id,
                          )
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'J\'aime',
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
                  label: 'Commenter',
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

          // CustomSliverAppBarFixed overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 56 + MediaQuery.of(context).padding.top,
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  CustomSliverAppBar(
                    title: '',
                    isDark: true, // Always dark style on top of video playback for supreme premium contrast
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: true,
                    actions: [
                      AppBarIconButton(
                        icon: Icons.grid_view,
                        isDark: true,
                        onTap: () => Navigator.of(context).pop(),
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

class _SchoolLogo extends StatelessWidget {
  final String code;
  final String fallbackName;

  const _SchoolLogo({required this.code, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: EcoleApiService.getEcoleDetail(code),
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
            backgroundImage: logoUrl != null &&
                    logoUrl.isNotEmpty &&
                    (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'))
                ? NetworkImage(logoUrl)
                : null,
            child: logoUrl == null ||
                    logoUrl.isEmpty ||
                    (!logoUrl.startsWith('http://') && !logoUrl.startsWith('https://'))
                ? Text(
                    fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : 'E',
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

class _VideoPage extends StatelessWidget {
  final CoulisseExcellence video;
  final YoutubePlayerController? youtubeController;
  final bool isActive;

  const _VideoPage({
    required this.video,
    this.youtubeController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Vidéo YouTube
        if (youtubeController != null)
          YoutubePlayer(
            controller: youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
            onReady: () {
              if (isActive) {
                youtubeController!.play();
              }
            },
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
              bottom: 24,
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
                      code: video.code,
                      fallbackName: video.etablissement,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video.etablissement,
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
                  video.titre,
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
                  '${video.fullName} · ${video.classe}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _ExpandableDescription(text: video.description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final isLong = widget.text.length > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
          ),
        ),
        if (isLong)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _isExpanded ? "Moins" : "... plus",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour commenter'),
        ),
      );
      return;
    }

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
      // Si l'API retourne un succès mais sans données, on recharge la liste
      await _loadComments();
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire ajouté avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white54 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    final handleColor = isDarkMode ? Colors.white24 : Colors.black26;
    final inputBgColor = isDarkMode ? Colors.black87 : Colors.grey[100];
    final inputBorderColor = isDarkMode ? Colors.white24 : Colors.black12;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          BottomSheetHeader(
            icon: Icons.comment_rounded,
            iconColor: const Color(0xFF0288D1),
            title: 'Commentaires',
            description: 'Échangez sur cette vidéo',
            onClose: () => Navigator.of(context).pop(),
          ),

          // Comments list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
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

          // Comment input (exactly like message input zone in messages_screen.dart)
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  (MediaQuery.of(context).viewInsets.bottom > 0
                      ? 16
                      : (MediaQuery.of(context).padding.bottom > 0
                          ? MediaQuery.of(context).padding.bottom + 12
                          : 24)),
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: dividerColor,
                  width: 0.5,
                ),
              ),
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
                      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: inputBorderColor,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                        ),
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
      ),
    );
  }

  Future<void> _deleteComment(int commentId) async {
    if (_currentUserId == null) return;

    // Optimistic UI: remove immediately from local list
    setState(() {
      _comments.removeWhere((c) => c.id == commentId);
    });

    try {
      final success = await InteractionApiService.deleteComment(
        commentId: commentId,
        userId: _currentUserId!,
      );

      if (!success) {
        print('⚠️ La suppression API a retourné false, rechargement de la liste...');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la suppression API: $e');
    }

    // Always reload from server to stay in sync
    await _loadComments();
  }

  Future<void> _editComment(int commentId, String newContent) async {
    if (_currentUserId == null) return;

    // Optimistic UI: update locally immediately
    setState(() {
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = _comments[index].copyWith(content: newContent);
      }
    });

    try {
      final success = await InteractionApiService.updateComment(
        commentId: commentId,
        userId: _currentUserId!,
        content: newContent,
      );

      if (!success) {
        print('⚠️ La modification API a retourné false, rechargement de la liste...');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la modification API: $e');
    }

    // Always reload from server to stay in sync
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
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser) ...[
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: timeColor,
                    size: 20,
                  ),
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
                          const Icon(Icons.delete, color: Colors.redAccent, size: 16),
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
            padding: const EdgeInsets.only(left: 52), // Perfect align under the name
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
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Modifier',
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
    final bodyColor = isDarkMode ? Colors.white70 : Colors.black54;

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
          style: TextStyle(color: bodyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
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
  final CoulisseExcellence video;

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
    final isDarkMode = ThemeService().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    final handleColor = isDarkMode ? Colors.white24 : Colors.black26;
    final iconBgColor = isDarkMode ? Colors.white24 : Colors.grey[200];
    final cardBgColor = isDarkMode ? Colors.white10 : Colors.grey[100];
    final playIconColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          BottomSheetHeader(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            title: 'Noter la vidéo',
            description: 'Donnez votre avis sur cette vidéo',
            onClose: () => Navigator.of(context).pop(),
          ),

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
                            widget.video.titre,
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
                            widget.video.fullName,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Current rating stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                  const SizedBox(height: 8),
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
                          index < _currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _currentRating > 0 ? _submitRating : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.green.withOpacity(0.4),
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Envoyer la note',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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

          const SizedBox(height: 8),
        ],
      ),
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

class _ShareOptionsSheet extends StatelessWidget {
  final CoulisseExcellence video;

  const _ShareOptionsSheet({required this.video});

  Future<void> _shareGeneral() async {
    final String videoUrl =
        'https://www.youtube.com/watch?v=${video.youtubeVideoId}';
    final String shareText =
        '🎬 Regarde cette vidéo incroyable : ${video.titre}\n\n${video.description}\n\n#CoulissesExcellence #Éducation';

    try {
      await Share.share('$shareText\n\n$videoUrl', subject: video.titre);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final String videoUrl =
        'https://www.youtube.com/watch?v=${video.youtubeVideoId}';
    final String message =
        '🎬 *${video.titre}*\n\n${video.description}\n\n$videoUrl';

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _shareOnFacebook() async {
    final String videoUrl =
        'https://www.youtube.com/watch?v=${video.youtubeVideoId}';

    final Uri facebookUri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(videoUrl)}',
    );

    try {
      if (await canLaunchUrl(facebookUri)) {
        await launchUrl(facebookUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    final handleColor = isDarkMode ? Colors.white24 : Colors.black26;
    final iconColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          BottomSheetHeader(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFF0288D1),
            title: 'Partager la vidéo',
            description: 'Choisissez comment partager',
            onClose: () => Navigator.of(context).pop(),
          ),

          // Share options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // General share option
                ListTile(
                  leading: Icon(Icons.share, color: iconColor),
                  title: Text(
                    'Partager...',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Partager via les applications disponibles',
                    style: TextStyle(color: subtextColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareGeneral();
                  },
                ),

                // WhatsApp option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF7EE),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/icons/whatsapp.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  title: Text(
                    'WhatsApp',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Partager sur WhatsApp',
                    style: TextStyle(color: subtextColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareOnWhatsApp();
                  },
                ),

                // Facebook option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.facebook, color: Colors.white),
                  ),
                  title: Text(
                    'Facebook',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Partager sur Facebook',
                    style: TextStyle(color: subtextColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareOnFacebook();
                  },
                ),

                // Copy link option
                ListTile(
                  leading: Icon(Icons.link, color: iconColor),
                  title: Text(
                    'Copier le lien',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    'Copier le lien de la vidéo',
                    style: TextStyle(color: subtextColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Copy link logic would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
