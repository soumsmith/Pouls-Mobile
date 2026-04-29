import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gallery_image.dart';
import '../services/gallery_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';

class GalleryScreen extends StatefulWidget {
  final String ecoleCode;
  final String ecoleNom;

  const GalleryScreen({
    super.key,
    required this.ecoleCode,
    required this.ecoleNom,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryImage> _images = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    print('=== CHARGEMENT DES IMAGES GALERIE ===');
    print('École Code: ${widget.ecoleCode}');
    print('École Nom: ${widget.ecoleNom}');
    
    try {
      final images = await GalleryService.getGalleryImages(widget.ecoleCode);
      print('Images reçues du service: ${images.length}');
      
      setState(() {
        _images = images;
        _isLoading = false;
      });
      
      print('State mis à jour - _images.length: ${_images.length}');
      print('_isLoading: $_isLoading');
      print('_error: $_error');
      
    } catch (e) {
      print('ERREUR lors du chargement des images: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logs pour débogage
    print('=== BUILD METHOD ===');
    print('_isLoading: $_isLoading');
    print('_error: $_error');
    print('_images.length: ${_images.length}');

    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Galerie',
            isDark: false,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          ..._buildBodySlivers(),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    final isDark = false; // Forcer le mode clair pour fond blanc
    
    if (_isLoading) {
      return [
        SliverFillRemaining(
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
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
                  onPressed: _loadImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_images.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'Aucune image disponible',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.screenTextPrimary,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        sliver: SliverMasonryGrid(
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final image = _images[index];
            final cardType = _getCardType(index);
            
            return _buildGalleryCard(
              image: image,
              index: index,
              cardType: cardType,
              isDark: isDark,
            );
          }, childCount: _images.length),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
      ),
    ];
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

  // Définir les types de cartes pour l'effet masonry
  GalleryCardType _getCardType(int index) {
    // Créer un pattern de tailles variées comme dans l'image
    final pattern = [
      GalleryCardType.large,   // Grande image à gauche (bateau)
      GalleryCardType.medium,  // Image moyenne en haut à droite
      GalleryCardType.small,   // Petite image au milieu à droite
      GalleryCardType.medium,  // Image moyenne en bas à droite
      GalleryCardType.medium,  // Image moyenne en bas à gauche
      GalleryCardType.small,   // Petite image en bas à droite
    ];
    
    return pattern[index % pattern.length];
  }

  Widget _buildGalleryCard({
    required GalleryImage image,
    required int index,
    required GalleryCardType cardType,
    required bool isDark,
  }) {
    double height;
    double imageHeight;
    
    switch (cardType) {
      case GalleryCardType.large:
        height = 280;
        imageHeight = 200;
        break;
      case GalleryCardType.medium:
        height = 200;
        imageHeight = 140;
        break;
      case GalleryCardType.small:
        height = 140;
        imageHeight = 80;
        break;
    }

    return Container(
      height: height,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final initialIndex = _images.indexOf(image);
            _showImageDialog(initialIndex);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image réelle avec différentes tailles
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  height: imageHeight,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.8),
                              AppColors.primary.withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: cardType == GalleryCardType.large ? 60 : 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.withOpacity(0.8),
                              Colors.grey.withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: cardType == GalleryCardType.large ? 60 : 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Section texte avec informations sur l'image
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image ${index + 1}',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.screenTextPrimary,
                          fontSize: cardType == GalleryCardType.large ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Galerie ${widget.ecoleNom}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche une image en plein écran dans un dialogue avec navigation par swipe
  void _showImageDialog(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _ImageDialog(
        images: _images,
        initialIndex: initialIndex,
      ),
    );
  }
}

enum GalleryCardType {
  small,
  medium,
  large,
}

/// Dialogue pour afficher les images avec navigation par swipe et flèches
class _ImageDialog extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const _ImageDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
  late PageController _pageController;
  late int _currentIndex;
  double _scale = 1.0;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController.addListener(() {
      setState(() {
        _scale = _transformationController.value.getMaxScaleOnAxis();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final newScale = _scale * 1.5;
    if (newScale <= 4.0) {
      _transformationController.value = Matrix4.identity()..scale(newScale);
    }
  }

  void _zoomOut() {
    final newScale = _scale / 1.5;
    if (newScale >= 0.5) {
      _transformationController.value = Matrix4.identity()..scale(newScale);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // PageView pour navigation par swipe
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _resetZoom();
                });
              },
              physics: _scale > 1.0 ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final image = widget.images[index];
                return Center(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    child: CachedNetworkImage(
                      imageUrl: image.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bouton fermeture
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
          // Flèche gauche
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentIndex > 0 ? _previousImage : null,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (_currentIndex > 0)
                        ? Colors.black.withOpacity(0.7)
                        : Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          // Flèche droite
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentIndex < widget.images.length - 1 ? _nextImage : null,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (_currentIndex < widget.images.length - 1)
                        ? Colors.black.withOpacity(0.7)
                        : Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          // Indicateur de position
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          // Boutons de zoom
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton zoom in
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton zoom out
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton reset zoom
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
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
