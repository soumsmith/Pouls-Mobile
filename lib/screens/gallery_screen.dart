import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/gallery_image.dart';
import '../services/gallery_service.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../config/app_dimensions.dart';
import '../widgets/components/bottom_spacer.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
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
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 12.0, // Espacement fixe et prévisible
            mainAxisSpacing: 16.0,
            childAspectRatio: AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context) 
                ? 0.95 // Ratio un peu plus bas pour donner assez de hauteur au texte
                : AppDimensions.isDesktop(context) ? 1.0 : 0.95,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final image = _images[index];
            
            return ImageMenuCardExternalTitle(
              index: index,
              cardKey: image.id ?? 'img_$index',
              title: 'Image ${index + 1}',
              subtitle: 'Galerie ${widget.ecoleNom}',
              imagePath: image.imageUrl,
              iconData: Icons.image,
              isDark: isDark,
              color: AppColors.screenOrange,
              height: AppDimensions.getEcoleCardHeight(context),
              onTap: () {
                _showImageDialog(index);
              },
            );
          }, childCount: _images.length),
        ),
      ),
      const SliverToBoxAdapter(
        child: BottomSpacer(height: 125),
      ),
    ];
  }

  int _getCrossAxisCount(BuildContext context) {
    if (AppDimensions.isDesktop(context)) {
      return 6; // Desktop
    } else if (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) {
      return 5; // iPad/Tablette
    } else {
      return 2; // Mobile
    }
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
                    child: image.imageUrl.startsWith('http')
                        ? Image.network(
                            image.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white,
                                size: 64,
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
