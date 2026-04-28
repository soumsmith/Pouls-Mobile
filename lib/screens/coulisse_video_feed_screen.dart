import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/coulisse_excellence.dart';
import '../models/ecole.dart';
import '../models/video_comment.dart';
import '../models/video_rating.dart';
import '../services/ecole_api_service.dart';
import 'establishment_detail_screen.dart';

class CoulisseVideoFeedScreen extends StatefulWidget {
  final List<CoulisseExcellence> videos;
  final int initialIndex;

  const CoulisseVideoFeedScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<CoulisseVideoFeedScreen> createState() => _CoulisseVideoFeedScreenState();
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
        controllers.add(YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
            forceHD: false,
            loop: false,
          ),
        ));
      } else {
        print('VideoID vide pour vidéo ${video.id} - ${video.titre}');
        controllers.add(null);
      }
    }

    setState(() {
      _youtubeControllers = controllers;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Mettre en pause la vidéo précédente
    if (_currentIndex > 0 && _youtubeControllers[_currentIndex - 1] != null) {
      _youtubeControllers[_currentIndex - 1]!.pause();
    }
    if (_currentIndex < _youtubeControllers.length - 1 && _youtubeControllers[_currentIndex + 1] != null) {
      _youtubeControllers[_currentIndex + 1]!.pause();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Afficher les options de partage
  Future<void> _shareVideo() async {
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
    final video = widget.videos[_currentIndex];
    
    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(videoId: "video.id"), //video.id
    );
  }

  // Afficher la notation
  void _showRating() {
    final video = widget.videos[_currentIndex];
    
    // Mettre en pause la vidéo actuelle
    if (_youtubeControllers[_currentIndex] != null) {
      _youtubeControllers[_currentIndex]!.pause();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RatingSheet(video: video),
    );
  }

  void _toggleLike() {
    final video = widget.videos[_currentIndex];
    setState(() {
      if (_likedVideoIds.contains(video.id)) {
        _likedVideoIds.remove(video.id);
      } else {
        _likedVideoIds.add(video.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Coulisses Excellence',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Bouton pour revenir à la grille
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
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
                  onTap: () {
                    _navigateToEcole(widget.videos[_currentIndex].code);
                  },
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: _likedVideoIds.contains(widget.videos[_currentIndex].id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'J\'aime',
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
        ],
      ),
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
                colors: [
                  Colors.black87,
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  video.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${video.fullName} · ${video.classe}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                  maxLines: 3,
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
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
  final String videoId;

  const _CommentsSheet({required this.videoId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<VideoComment> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    // Simuler le chargement des commentaires
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _comments = [
        VideoComment(
          id: '1',
          videoId: widget.videoId,
          userId: 'user1',
          userName: 'Marie Dupont',
          userAvatar: '',
          content: 'Vidéo vraiment inspirante ! Continuez comme ça.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 5,
        ),
        VideoComment(
          id: '2',
          videoId: widget.videoId,
          userId: 'user2',
          userName: 'Jean Martin',
          userAvatar: '',
          content: 'Excellent travail, les élèves sont exceptionnels.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          likes: 3,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = VideoComment(
      id: DateTime.now().toString(),
      videoId: widget.videoId,
      userId: 'current_user',
      userName: 'Vous',
      userAvatar: '',
      content: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, newComment);
      _commentController.clear();
    });

    // Simuler l'envoi au serveur
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Commentaires',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24),
          
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _CommentItem(comment: comment);
                    },
                  ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black87,
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final VideoComment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimestamp(comment.timestamp),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              Text(
                '${comment.likes}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Text(
                'Répondre',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Noter la vidéo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24),
          
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
                      child: const Icon(Icons.play_circle, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.video.titre,
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
                            widget.video.fullName,
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
                                index < _averageRating.floor() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          Text(
                            '$_totalRatings évaluations',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentRating > 0 ? _submitRating : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
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
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() {
      _hasRated = true;
      // Mettre à jour les statistiques (simulation)
      _totalRatings++;
      _averageRating = ((_averageRating * (_totalRatings - 1)) + _currentRating) / _totalRatings;
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
    final String videoUrl = 'https://www.youtube.com/watch?v=${video.youtubeVideoId}';
    final String shareText = '🎬 Regarde cette vidéo incroyable : ${video.titre}\n\n${video.description}\n\n#CoulissesExcellence #Éducation';
    
    try {
      await Share.share(
        '$shareText\n\n$videoUrl',
        subject: video.titre,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final String videoUrl = 'https://www.youtube.com/watch?v=${video.youtubeVideoId}';
    final String message = '🎬 *${video.titre}*\n\n${video.description}\n\n$videoUrl';
    
    final Uri whatsappUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _shareOnFacebook() async {
    final String videoUrl = 'https://www.youtube.com/watch?v=${video.youtubeVideoId}';
    
    final Uri facebookUri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(videoUrl)}');
    
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Partager la vidéo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24),
          
          // Share options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // General share option
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.white),
                  title: const Text(
                    'Partager...',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Partager via les applications disponibles',
                    style: TextStyle(color: Colors.white70),
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
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message, color: Colors.white),
                  ),
                  title: const Text(
                    'WhatsApp',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Partager sur WhatsApp',
                    style: TextStyle(color: Colors.white70),
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
                  title: const Text(
                    'Facebook',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Partager sur Facebook',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareOnFacebook();
                  },
                ),
                
                // Copy link option
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white),
                  title: const Text(
                    'Copier le lien',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Copier le lien de la vidéo',
                    style: TextStyle(color: Colors.white70),
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
