import 'package:flutter/material.dart';
import '../models/coulisse_excellence.dart';
import '../services/coulisse_excellence_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/image_menu_card_external_title.dart';
import 'coulisse_video_feed_screen.dart';

class CoulisseExcellenceScreen extends StatefulWidget {
  final String ecoleId;
  final String ecoleNom;

  const CoulisseExcellenceScreen({
    super.key,
    required this.ecoleId,
    required this.ecoleNom,
  });

  @override
  State<CoulisseExcellenceScreen> createState() => _CoulisseExcellenceScreenState();
}

class _CoulisseExcellenceScreenState extends State<CoulisseExcellenceScreen> {
  List<CoulisseExcellence> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    print('=== CHARGEMENT DES VIDÉOS COULISSE EXCELLENCE ===');
    print('École ID: ${widget.ecoleId}');
    print('École Nom: ${widget.ecoleNom}');
    
    try {
      final videos = await CoulisseExcellenceService.getCoulisseExcellenceList(widget.ecoleId);
      print('Vidéés reçues du service: ${videos.length}');
      
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Logs pour débogage
    print('=== BUILD METHOD ===');
    print('_isLoading: $_isLoading');
    print('_error: $_error');
    print('_videos.length: ${_videos.length}');

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : AppColors.backgroundLight,
        title: Text(
          'Coulisses Excellence',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.screenTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppColors.screenTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Text(
          'Aucune vidéo disponible',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.screenTextPrimary,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: AppDimensions.getAdaptiveGridSpacing(context),
              childAspectRatio: AppDimensions.getProductsGridChildAspectRatio(context, imageFlex: AppDimensions.getGridImageFlex(context)),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = _videos[index];
              return ImageMenuCardExternalTitle(
                index: index,
                cardKey: 'video_${video.id}',
                title: video.titre,
                subtitle: "${video.fullName} • ${video.classe}",
                imagePath: null, // Pas d'image spécifique, utilisera l'icône
                iconData: Icons.play_circle_outline,
                isDark: isDark,
                color: AppColors.primary,
                location: null,
                tag: null,
                titleMaxLines: 2,
                externalTitleSpacing: 8,
                height: 120,
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
              );
            }, childCount: _videos.length),
          ),
        ),
      ],
    );
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
}

