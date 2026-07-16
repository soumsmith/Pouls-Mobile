import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/ad_model.dart';
import '../widgets/components/custom_button.dart';

class AdVideoPage extends StatefulWidget {
  final AdModel ad;
  final bool isActive;

  const AdVideoPage({Key? key, required this.ad, required this.isActive})
    : super(key: key);

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
                // _launchUrl(widget.ad.linkUrl);
              }
            },
            child: _youtubeController != null
                ? YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: false,
                  )
                : CachedNetworkImage(
                    imageUrl: widget.ad.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                        size: 50,
                      ),
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
          // Positioned(
          //   top: MediaQuery.of(context).padding.top + 16,
          //   left: 16,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.6),
          //       borderRadius: BorderRadius.circular(6),
          //       border: Border.all(color: Colors.white24),
          //     ),
          //     child: const Text(
          //       'Sponsorisé',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),

          // Bottom Info
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.ad.title.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.ad.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // const SizedBox(height: 12),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: () => _launchUrl(widget.ad.linkUrl),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.grey[800],
                //       foregroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(vertical: 14),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       elevation: 0,
                //     ),
                //     child: const Text(
                //       'En savoir plus',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdVideoCarouselPage extends StatefulWidget {
  final AdGroup adGroup;
  final bool isActive;

  const AdVideoCarouselPage({
    Key? key,
    required this.adGroup,
    required this.isActive,
  }) : super(key: key);

  @override
  State<AdVideoCarouselPage> createState() => _AdVideoCarouselPageState();
}

class _AdVideoCarouselPageState extends State<AdVideoCarouselPage> {
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // Grand nombre pour simuler un scroll infini
  static const int _infiniteMultiplier = 10000;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.adGroup.ads.length > 1
        ? _infiniteMultiplier ~/ 2 * widget.adGroup.ads.length
        : 0;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
    if (widget.isActive) {
      _startAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant AdVideoCarouselPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAutoPlay();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (widget.adGroup.ads.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.adGroup.ads.isEmpty) return const SizedBox.shrink();
    if (widget.adGroup.ads.length == 1) {
      return AdVideoPage(
        ad: widget.adGroup.ads.first,
        isActive: widget.isActive,
      );
    }

    final adCount = widget.adGroup.ads.length;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final realIndex = index % adCount;
            return AdVideoPage(
              ad: widget.adGroup.ads[realIndex],
              isActive: widget.isActive,
            );
          },
        ),
        // Indicateur de page (dots)
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 140,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(adCount, (index) {
              final isCurrentDot = (_currentPage % adCount) == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrentDot ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isCurrentDot
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
