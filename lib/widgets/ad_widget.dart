import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';

class AdWidget extends StatefulWidget {
  const AdWidget({super.key});

  @override
  State<AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> with TickerProviderStateMixin {
  final AdService _adService = AdService();
  List<AdModel> _ads = [];
  bool _isLoading = true;
  
  late AnimationController _controller;
  late AnimationController _wiggleController;
  
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadAds();
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _controller.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final ads = await _adService.fetchAds();
    if (mounted) {
      setState(() {
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
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _ads.length) {
          nextPage = 0;
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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

  void _showAdDialog(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: ad.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                      onPressed: () {
                        Share.share('Découvrez ceci : ${ad.title}\n\n${ad.linkUrl}');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _launchUrl(ad.linkUrl);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('En savoir plus'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ads.isEmpty) {
      return const SizedBox.shrink();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double expandedWidth = screenWidth * 0.8;
    
    final safeIndex = _currentIndex < _ads.length ? _currentIndex : 0;
    final currentAd = _ads[safeIndex];
    final bool isLandscape = currentAd.format == 'paysage';
    final double expandedHeight = isLandscape ? expandedWidth * 0.6 : expandedWidth * 1.4;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _wiggleController]),
        builder: (context, child) {
          final bool isOpen = _controller.value > 0.0;
          return Stack(
            children: [
              // Voile de fond cliquable pour fermer
              if (isOpen)
                GestureDetector(
                  onTap: () => _controller.reverse(),
                  child: Container(
                    color: Colors.black.withOpacity(0.3 * _controller.value),
                  ),
                ),
              // Le widget de pub lui-même
              Positioned(
                // Position de base + un léger rebond (wiggle) de 6px vers la gauche quand fermé
                right: -(expandedWidth - 5) * (1 - _controller.value) + (_wiggleController.value * 6 * (1 - _controller.value)),
                top: screenHeight * 0.32, // Monté légèrement (0.32 au lieu de 0.35)
                child: child!,
              ),
            ],
          );
        },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le drapeau "PUBLICITÉ"
          GestureDetector(
            onTap: () {
              if (_controller.isCompleted) {
                _controller.reverse();
              } else {
                _controller.forward();
              }
            },
            onHorizontalDragUpdate: (details) {
              _controller.value -= details.primaryDelta! / expandedWidth;
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -500 || _controller.value > 0.5) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            child: Container(
              width: 24, // Largeur du bras réduite
              padding: const EdgeInsets.symmetric(vertical: 12), // Padding réduit pour diminuer la hauteur
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(-2, 2),
                  ),
                ],
              ),
              child: RotatedBox(
                quarterTurns: 1,
                child: const Text(
                  'PUBLICITÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11, // Police plus petite
                    letterSpacing: 1.5, // Espacement réduit
                  ),
                ),
              ),
            ),
          ),
          
          // Le contenu étendu (Carousel)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: expandedWidth,
            height: expandedHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(-2, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
              ),
              child: Stack(
                children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _ads.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    return GestureDetector(
                      onTap: () => _showAdDialog(context, ad),
                      child: CachedNetworkImage(
                        imageUrl: ad.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      _controller.reverse();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
