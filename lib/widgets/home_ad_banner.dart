import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';

class HomeAdBanner extends StatefulWidget {
  const HomeAdBanner({Key? key}) : super(key: key);

  @override
  State<HomeAdBanner> createState() => _HomeAdBannerState();
}

class _HomeAdBannerState extends State<HomeAdBanner> {
  final AdService _adService = AdService();
  final PageController _pageController = PageController();
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final ads = await _adService.fetchAds();
    if (mounted) {
      setState(() {
        // Optionnel : on pourrait filtrer sur 'page' == 'accueil' selon les specs de l'API
        // Pour l'instant on prend toutes les pubs ou celles adaptées.
        _ads = ads;
        _isLoading = false;
      });
      if (_ads.isNotEmpty) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_ads.length <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _ads.length) {
          nextPage = 0;
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120, // Hauteur de la bannière
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
                  _currentPage = page;
                });
              },
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return GestureDetector(
                  onTap: () {
                    _launchUrl(ad.linkUrl);
                  },
                  child: CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
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
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
