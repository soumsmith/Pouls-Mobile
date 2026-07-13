import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../config/app_colors.dart';
import 'share_bottom_sheet.dart';
import 'home_ad_banner.dart';

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

  void _showBannerMenu(BuildContext context, AdModel ad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final scale = 0.9 + (animation.value * 0.1);
        final opacity = animation.value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Le menu flottant iOS
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: menuBgColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // En-tête / Titre
                              if (ad.title.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Text(
                                    ad.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ),
                                Container(height: 0.5, color: dividerColor),
                              ],
                              // Option Ouvrir l'image
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    Navigator.push(
                                      context, // Context d'origine externe
                                      MaterialPageRoute(
                                        builder: (context) => AdImageDetailScreen(ad: ad),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.vertical(
                                    top: ad.title.isEmpty ? const Radius.circular(14) : Radius.zero,
                                    bottom: const Radius.circular(14),
                                  ),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Ouvrir l\'image', style: textStyle),
                                        Icon(
                                          Icons.fullscreen_rounded,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bouton Annuler flottant
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: menuBgColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(dialogContext),
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // _launchUrl(ad.linkUrl); // Mis en commentaire
        _showBannerMenu(context, ad);
      },
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
