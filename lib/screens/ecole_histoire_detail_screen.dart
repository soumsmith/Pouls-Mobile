import 'package:flutter/material.dart';
import '../models/ecole_histoire.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/components/bottom_spacer.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../utils/html_helper.dart';

/// Couleur d'accent de la fonctionnalité "Mémoire des écoles" (ton sépia,
/// évocateur de souvenirs/archives).
const Color kHistoireAccentColor = Color(0xFF8D6E63);

/// Détail d'une "histoire" (mémoire/événement marquant) d'un établissement :
/// image de couverture, titre, période, contenu et galerie éventuelle.
/// Réutilisé depuis l'accueil, l'écran "voir plus" et la timeline d'école.
class EcoleHistoireDetailScreen extends StatelessWidget {
  final EcoleHistoire histoire;

  const EcoleHistoireDetailScreen({super.key, required this.histoire});

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    final plainContent = HtmlHelper.stripHtmlTags(histoire.content);

    return Scaffold(
      backgroundColor: AppColors.screenSurfaceThemed(context),
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: histoire.title.isNotEmpty ? histoire.title : 'Mémoire de l\'école',
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (histoire.image != null && histoire.image!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      histoire.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kHistoireAccentColor.withOpacity(0.15),
                        child: const Center(
                          child: Icon(Icons.auto_stories_rounded, size: 48, color: kHistoireAccentColor),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (histoire.yearLabel.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kHistoireAccentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                histoire.yearLabel,
                                style: TextStyle(
                                  fontSize: textSizeService.getScaledFontSize(12),
                                  fontWeight: FontWeight.w700,
                                  color: kHistoireAccentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              histoire.etablissement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: textSizeService.getScaledFontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.screenTextSecondaryThemed(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        histoire.title.isNotEmpty ? histoire.title : 'Mémoire de l\'école',
                        style: TextStyle(
                          fontSize: textSizeService.getScaledFontSize(20),
                          fontWeight: FontWeight.w800,
                          color: AppColors.screenTextPrimaryThemed(context),
                        ),
                      ),
                      if (plainContent.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          plainContent,
                          style: TextStyle(
                            fontSize: textSizeService.getScaledFontSize(15),
                            height: 1.5,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                        ),
                      ],
                      if (histoire.gallery.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Galerie',
                          style: TextStyle(
                            fontSize: textSizeService.getScaledFontSize(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimaryThemed(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: histoire.gallery.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final img = histoire.gallery[index];
                              return GestureDetector(
                                onTap: () => _openGalleryViewer(context, index),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    img.image,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 90,
                                      height: 90,
                                      color: kHistoireAccentColor.withOpacity(0.12),
                                      child: const Icon(Icons.image_outlined, color: kHistoireAccentColor),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const BottomSpacer(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGalleryViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => _HistoireGalleryDialog(
        images: histoire.gallery,
        initialIndex: initialIndex,
      ),
    );
  }
}

/// Visionneuse plein écran (swipe + zoom) pour la galerie d'une histoire.
class _HistoireGalleryDialog extends StatefulWidget {
  final List<HistoireGalleryImage> images;
  final int initialIndex;

  const _HistoireGalleryDialog({required this.images, required this.initialIndex});

  @override
  State<_HistoireGalleryDialog> createState() => _HistoireGalleryDialogState();
}

class _HistoireGalleryDialogState extends State<_HistoireGalleryDialog> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.images[index].image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
