import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../config/app_colors.dart';

class AdBannerCard extends StatelessWidget {
  final AdModel ad;

  const AdBannerCard({Key? key, required this.ad}) : super(key: key);

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty || urlString == '#') return;
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(ad.linkUrl),
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: ad.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.screenCardThemed(context),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.screenCardThemed(context),
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
              // Gradient for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Title
              if (ad.title.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Badge "Sponsorisé"
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Sponsorisé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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

class AdBannerCarousel extends StatefulWidget {
  final AdGroup adGroup;
  final Duration autoScrollDuration;

  const AdBannerCarousel({
    Key? key,
    required this.adGroup,
    this.autoScrollDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<AdBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    final adCount = widget.adGroup.ads.length;
    final initialPage = adCount > 1 ? adCount * 5000 : 0;
    _currentPage = 0;
    _pageController = PageController(initialPage: initialPage);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.adGroup.ads.length <= 1) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.adGroup.ads.isEmpty) return const SizedBox.shrink();
    if (widget.adGroup.ads.length == 1) {
      return AdBannerCard(ad: widget.adGroup.ads.first);
    }

    final adCount = widget.adGroup.ads.length;

    return SizedBox(
      height: 160,
      child: GestureDetector(
        onPanDown: (_) => _stopAutoScroll(),
        onPanEnd: (_) => _startAutoScroll(),
        onPanCancel: () => _startAutoScroll(),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: adCount * 10000,
          onPageChanged: (index) {
            setState(() => _currentPage = index % adCount);
          },
          itemBuilder: (context, index) {
            final adIndex = index % adCount;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AdBannerCard(ad: widget.adGroup.ads[adIndex]),
            );
          },
        ),
      ),
    );
  }
}
