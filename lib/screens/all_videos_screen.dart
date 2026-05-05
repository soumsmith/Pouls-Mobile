import 'package:flutter/material.dart';
import '../models/coulisse_excellence.dart';
import '../services/coulisse_excellence_service.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import 'coulisse_video_feed_screen.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({Key? key}) : super(key: key);

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  List<CoulisseExcellence> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await CoulisseExcellenceService.getAllCoulisseExcellenceVideos();
      setState(() {
        _videos = videos;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Couliste de l\'Excellence',
            pinned: true,
            elevation: 0,
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadVideos,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (_videos.isEmpty)
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
                      'Aucune vidéo disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les vidéos apparaîtront ici dès qu\'elles seront disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildVideoCard(_videos[index]);
                  },
                  childCount: _videos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(CoulisseExcellence video) {
    return ImageMenuCardExternalTitle(
      index: _videos.indexOf(video),
      cardKey: video.id.toString(),
      title: video.titre,
      subtitle: video.classe.isNotEmpty ? video.classe : null,
      imagePath: video.videoYoutube.isNotEmpty 
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      iconData: Icons.play_circle_outline,
      color: const Color(0xFF10B981), // Green color for videos
      width: double.infinity,
      height: 200,
      imageFlex: 7.0,
      imageBorderRadius: 16.0,
      titleFontSize: 14.0,
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      onTap: () => _handleVideoAction(video),
    );
  }

  void _handleVideoAction(CoulisseExcellence video) {
    // Navigation vers l'écran de lecture de vidéo
    final videoIndex = _videos.indexWhere((v) => v.id == video.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoulisseVideoFeedScreen(
          videos: _videos,
          initialIndex: videoIndex >= 0 ? videoIndex : 0,
        ),
      ),
    );
  }
}

// Écran de lecture de vidéo
class VideoPlayerScreen extends StatelessWidget {
  final CoulisseExcellence video;

  const VideoPlayerScreen({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          video.titre,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: 100,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lecteur vidéo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.titre,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
