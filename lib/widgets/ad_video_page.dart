import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/ad_model.dart';
import '../widgets/components/custom_button.dart';

class AdVideoPage extends StatefulWidget {
  final AdModel ad;
  final bool isActive;

  const AdVideoPage({
    Key? key,
    required this.ad,
    required this.isActive,
  }) : super(key: key);

  @override
  State<AdVideoPage> createState() => _AdVideoPageState();
}

class _AdVideoPageState extends State<AdVideoPage> {
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.ad.youtubeUrl != null && widget.ad.youtubeUrl!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.ad.youtubeUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            loop: true,
            hideControls: true,
            hideThumbnail: true,
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant AdVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _youtubeController?.play();
      } else {
        _youtubeController?.pause();
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty || urlString == '#') return;
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media
          GestureDetector(
            onTap: () {
              if (_youtubeController != null) {
                if (_youtubeController!.value.isPlaying) {
                  _youtubeController!.pause();
                } else {
                  _youtubeController!.play();
                }
              } else {
                _launchUrl(widget.ad.linkUrl);
              }
            },
            child: _youtubeController != null
                ? YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: false,
                  )
                : CachedNetworkImage(
                    imageUrl: widget.ad.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error_outline, color: Colors.grey, size: 50),
                    ),
                  ),
          ),
          
          // Overlay Gradient
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Sponsorisé Badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Sponsorisé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Bottom Info
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.ad.title.isNotEmpty)
                  Text(
                    widget.ad.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'En savoir plus',
                    color: Theme.of(context).primaryColor,
                    onPressed: () => _launchUrl(widget.ad.linkUrl),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdVideoCarouselPage extends StatelessWidget {
  final AdGroup adGroup;
  final bool isActive;

  const AdVideoCarouselPage({
    Key? key,
    required this.adGroup,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (adGroup.ads.isEmpty) return const SizedBox.shrink();
    if (adGroup.ads.length == 1) {
      return AdVideoPage(ad: adGroup.ads.first, isActive: isActive);
    }

    return PageView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: adGroup.ads.length,
      itemBuilder: (context, index) {
        return AdVideoPage(
          ad: adGroup.ads[index],
          isActive: isActive,
        );
      },
    );
  }
}
