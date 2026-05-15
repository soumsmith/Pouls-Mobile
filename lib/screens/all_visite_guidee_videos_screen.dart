import 'package:flutter/material.dart';
import '../models/video.dart';
import '../models/visite_guidee_video.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import 'visite_guidee_video_feed_screen.dart';

class AllVisiteGuideeVideosScreen extends StatelessWidget {
  final List<Video> videos;

  const AllVisiteGuideeVideosScreen({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Visites guidées',
            pinned: true,
            elevation: 0,
          ),
          if (videos.isEmpty)
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
                      'Les vidéos de visite guidée apparaîtront ici dès qu\'elles seront disponibles.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildVideoCard(context, videos[index]);
                }, childCount: videos.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Video video) {
    return ImageMenuCardExternalTitle(
      index: videos.indexOf(video),
      cardKey: 'visite_${video.youtubeVideoId}_${videos.indexOf(video)}',
      title: video.title,
      subtitle: video.createdAt.isNotEmpty
          ? video.createdAt
          : video.description,
      imagePath: video.youtubeVideoId.isNotEmpty
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      iconData: Icons.play_circle_outline,
      color: const Color(0xFF3B82F6),
      width: double.infinity,
      height: 220,
      imageFlex: 7.0,
      imageBorderRadius: 16.0,
      titleFontSize: 14.0,
      externalTitleSpacing: 8.0,
      centerTitle: false,
      allowLineBreak: true,
      titleMaxLines: 2,
      onTap: () => _handleVideoAction(context, video),
    );
  }

  void _handleVideoAction(BuildContext context, Video video) {
    final initialIndex = videos.indexOf(video);
    final visiteVideos = videos
        .map(
          (v) => VisiteGuideeVideo(
            typeVideo: v.typevideo,
            youtubeUrl: v.youtubeUrl,
          ),
        )
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisiteGuideeVideoFeedScreen(
          videos: visiteVideos,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}
