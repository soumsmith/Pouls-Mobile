import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/coulisse_excellence.dart';
import '../services/coulisse_excellence_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';
import 'coulisse_video_feed_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String ecoleId;
  final String ecoleNom;

  const GalleryScreen({
    super.key,
    required this.ecoleId,
    required this.ecoleNom,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<CoulisseExcellence> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    print('=== CHARGEMENT DES VIDÉOS GALERIE ===');
    print('École ID: ${widget.ecoleId}');
    print('École Nom: ${widget.ecoleNom}');
    
    try {
      final videos = await CoulisseExcellenceService.getCoulisseExcellenceList(widget.ecoleId);
      print('Vidéos reçues du service: ${videos.length}');
      
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
      
      print('State mis à jour - _videos.length: ${_videos.length}');
      print('_isLoading: $_isLoading');
      print('_error: $_error');
      
    } catch (e) {
      print('ERREUR lors du chargement des vidéos: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logs pour débogage
    print('=== BUILD METHOD ===');
    print('_isLoading: $_isLoading');
    print('_error: $_error');
    print('_videos.length: ${_videos.length}');

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Galerie',
            isDark: false,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          ..._buildBodySlivers(),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    final isDark = false; // Forcer le mode clair pour fond blanc
    
    if (_isLoading) {
      return [
        SliverFillRemaining(
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.screenTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadVideos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_videos.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'Aucune vidéo disponible',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.screenTextPrimary,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        sliver: SliverMasonryGrid(
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final video = _videos[index];
            final cardType = _getCardType(index);
            
            return _buildGalleryCard(
              video: video,
              index: index,
              cardType: cardType,
              isDark: isDark,
            );
          }, childCount: _videos.length),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
      ),
    ];
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4; // Desktop
    } else if (screenWidth > 800) {
      return 3; // iPad/Tablette
    } else {
      return 2; // Mobile
    }
  }

  // Définir les types de cartes pour l'effet masonry
  GalleryCardType _getCardType(int index) {
    // Créer un pattern de tailles variées comme dans l'image
    final pattern = [
      GalleryCardType.large,   // Grande image à gauche (bateau)
      GalleryCardType.medium,  // Image moyenne en haut à droite
      GalleryCardType.small,   // Petite image au milieu à droite
      GalleryCardType.medium,  // Image moyenne en bas à droite
      GalleryCardType.medium,  // Image moyenne en bas à gauche
      GalleryCardType.small,   // Petite image en bas à droite
    ];
    
    return pattern[index % pattern.length];
  }

  Widget _buildGalleryCard({
    required CoulisseExcellence video,
    required int index,
    required GalleryCardType cardType,
    required bool isDark,
  }) {
    double height;
    double imageHeight;
    
    switch (cardType) {
      case GalleryCardType.large:
        height = 280;
        imageHeight = 200;
        break;
      case GalleryCardType.medium:
        height = 200;
        imageHeight = 140;
        break;
      case GalleryCardType.small:
        height = 140;
        imageHeight = 80;
        break;
    }

    return Container(
      height: height,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CoulisseVideoFeedScreen(
                  videos: _videos,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder avec différentes tailles
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Icône de lecture
                      Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: cardType == GalleryCardType.large ? 60 : 40,
                          color: Colors.white,
                        ),
                      ),
                      // Badge en haut à droite
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'VIDÉO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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
              // Section texte
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.titre,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.screenTextPrimary,
                          fontSize: cardType == GalleryCardType.large ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${video.fullName} · ${video.classe}",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GalleryCardType {
  small,
  medium,
  large,
}
