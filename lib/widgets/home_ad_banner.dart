import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';
import 'share_bottom_sheet.dart';

class HomeAdBanner extends StatefulWidget {
  const HomeAdBanner({Key? key}) : super(key: key);

  @override
  State<HomeAdBanner> createState() => _HomeAdBannerState();
}

class _HomeAdBannerState extends State<HomeAdBanner> {
  final AdService _adService = AdService();
  PageController? _pageController;
  Timer? _timer;

  List<AdModel> _ads = [];
  bool _isLoading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    debugPrint('🏠 [HomeAdBanner] Début du chargement des publicités (paysage) pour la Home Page...');
    final ads = await _adService.fetchAds(format: 'paysage');
    if (mounted) {
      final initialPage = ads.length > 1 ? ads.length * 5000 : 0;
      _pageController = PageController(initialPage: initialPage);
      setState(() {
        _ads = ads;
        _isLoading = false;
      });
      debugPrint('🏠 [HomeAdBanner] ${ads.length} publicité(s) paysage affichée(s) sur la bannière de la Home Page');
      if (_ads.isNotEmpty) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_ads.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController != null && _pageController!.hasClients) {
        int nextPage = _pageController!.page!.round() + 1;
        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty || urlString == '#') return;
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showBannerMenu(AdModel ad) {
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
                                color: Colors.black.withOpacity(
                                  isDark ? 0.4 : 0.15,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    ad.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
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
                                      this.context, // Context d'origine externe
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdImageDetailScreen(ad: ad),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.vertical(
                                    top: ad.title.isEmpty
                                        ? const Radius.circular(14)
                                        : Radius.zero,
                                    bottom: const Radius.circular(14),
                                  ),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Ouvrir l\'image',
                                          style: textStyle,
                                        ),
                                        Icon(
                                          Icons.fullscreen_rounded,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
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
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.1,
                                ),
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
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 160, // Hauteur de la bannière
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page % _ads.length;
                });
              },
              itemCount: _ads.length * 10000,
              itemBuilder: (context, index) {
                final adIndex = index % _ads.length;
                final ad = _ads[adIndex];
                return GestureDetector(
                  onTap: () {
                    // _launchUrl(ad.linkUrl); // Mis en commentaire
                    _showBannerMenu(ad);
                  },
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
            // Badge "Sponsorisé"
            // Positioned(
            //   top: 8,
            //   left: 8,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.6),
            //       borderRadius: BorderRadius.circular(4),
            //     ),
            //     child: const Text(
            //       'Sponsorisé',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 10,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     ),
            //   ),
            // ),
            // Indicateurs de page
            if (_ads.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_ads.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdImageDetailScreen extends StatelessWidget {
  final AdModel ad;
  const AdImageDetailScreen({Key? key, required this.ad}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          ad.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.share_rounded),
          //   onPressed: () {
          //     showModalBottomSheet(
          //       context: context,
          //       isScrollControlled: true,
          //       backgroundColor: Colors.transparent,
          //       builder: (context) => ShareBottomSheet(
          //         title: 'Partager l\'image',
          //         itemTitle: ad.title,
          //         shareText:
          //             '🎬 Regarde cette image : ${ad.imageUrl}\n\nVisite le site : ${ad.linkUrl}\n\n#PoulsMobile',
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: ad.imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
