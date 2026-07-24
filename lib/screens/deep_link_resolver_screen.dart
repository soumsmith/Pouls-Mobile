import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/deep_link_service.dart';
import '../services/coulisse_excellence_service.dart';
import '../services/visite_guidee_service.dart';
import '../models/coulisse_excellence.dart';
import '../models/visite_guidee_video.dart';
import '../services/theme_service.dart';
import '../config/app_colors.dart';
import 'coulisse_video_feed_screen.dart';
import 'visite_guidee_video_feed_screen.dart';

// Nouveaux imports
import '../services/blog_service.dart';
import '../services/astuce_conseil_service.dart';
import '../services/event_service.dart';
import '../services/produit_service.dart';
import '../models/blog.dart';
import '../models/astuce_conseil.dart';
import '../models/event.dart';
import '../models/product.dart';
import 'blog_detail_screen.dart';
import 'tips_advice_detail_screen.dart';
import 'event_detail_screen.dart';
import 'product_detail_screen.dart';

/// Écran intermédiaire affiché lorsque l'application est ouverte via un deep link.
///
/// Reçoit un [DeepLinkData], charge la vidéo correspondante via l'API,
/// puis redirige vers l'écran de lecture approprié (Coulisse ou Visite Guidée).
class DeepLinkResolverScreen extends StatefulWidget {
  final DeepLinkData deepLinkData;

  const DeepLinkResolverScreen({super.key, required this.deepLinkData});

  @override
  State<DeepLinkResolverScreen> createState() => _DeepLinkResolverScreenState();
}

class _DeepLinkResolverScreenState extends State<DeepLinkResolverScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadAndNavigate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAndNavigate() async {
    try {
      final data = widget.deepLinkData;
      final id = data.id;

      if (id.isEmpty) {
        _showError('Lien invalide.');
        return;
      }

      switch (data.type) {
        case DeepLinkContentType.coulisse:
          final videoId = int.tryParse(id);
          if (videoId != null)
            await _loadCoulisseVideo(videoId);
          else
            _showError('Lien invalide.');
          break;
        case DeepLinkContentType.visite:
          final videoId = int.tryParse(id);
          if (videoId != null)
            await _loadVisiteGuideeVideo(videoId);
          else
            _showError('Lien invalide.');
          break;
        case DeepLinkContentType.article:
          await _loadArticle(id);
          break;
        case DeepLinkContentType.tip:
          await _loadTip(id);
          break;
        case DeepLinkContentType.event:
          await _loadEvent(id);
          break;
        case DeepLinkContentType.product:
          await _loadProduct(id);
          break;
        case DeepLinkContentType.unknown:
          _showError('Type de contenu non reconnu.');
          break;
      }
    } catch (e) {
      _showError('Impossible de charger le contenu.\n$e');
    }
  }

  Future<void> _loadCoulisseVideo(int videoId) async {
    try {
      // L'API ne fournit pas d'endpoint par ID unique, on récupère la liste
      // et on filtre. C'est acceptable car les vidéos sont mises en cache.
      final allVideos =
          await CoulisseExcellenceService.getAllCoulisseExcellenceVideos(
            perPage: 1000,
          );

      if (!mounted) return;

      final targetVideo = allVideos.where((v) => v.id == videoId).toList();

      if (targetVideo.isEmpty) {
        _showError('Cette vidéo n\'existe plus ou a été supprimée.');
        return;
      }

      // Trouver l'index de la vidéo cible dans la liste
      final targetIndex = allVideos.indexWhere((v) => v.id == videoId);

      // Naviguer vers l'écran de lecture avec la liste complète
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CoulisseVideoFeedScreen(
            videos: allVideos,
            initialIndex: targetIndex >= 0 ? targetIndex : 0,
          ),
        ),
      );
    } catch (e) {
      _showError(
        'Impossible de charger la vidéo.\nVérifiez votre connexion internet.',
      );
    }
  }

  Future<void> _loadVisiteGuideeVideo(int videoId) async {
    try {
      _showError(
        'Fonctionnalité bientôt disponible.\n'
        'Le partage de vidéos visite guidée sera disponible dans une prochaine mise à jour.',
      );
    } catch (e) {
      _showError(
        'Impossible de charger la vidéo.\nVérifiez votre connexion internet.',
      );
    }
  }

  Future<void> _loadArticle(String slug) async {
    try {
      final allBlogs = await BlogService.getBlogsList();
      if (!mounted) return;

      final target = allBlogs.firstWhere(
        (b) => b.slug == slug,
        orElse: () => throw Exception('Not found'),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BlogDetailScreen(blog: target)),
      );
    } catch (e) {
      _showError('Cet article n\'existe plus ou a été supprimé.');
    }
  }

  Future<void> _loadTip(String idStr) async {
    try {
      final response = await AstuceConseilService().getAstucesConseils(page: 1);
      if (!mounted) return;

      final id = int.tryParse(idStr);
      final target = response.data.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Not found'),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TipsAdviceDetailScreen(astuce: target),
        ),
      );
    } catch (e) {
      _showError('Ce conseil n\'existe plus ou a été supprimé.');
    }
  }

  Future<void> _loadEvent(String slug) async {
    try {
      final events = await EventService.getEventsList();
      if (!mounted) return;

      final target = events.firstWhere(
        (e) => e.slug == slug,
        orElse: () => throw Exception('Not found'),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EventDetailScreen(event: target),
        ),
      );
    } catch (e) {
      _showError('Cet événement n\'existe plus ou a été supprimé.');
    }
  }

  Future<void> _loadProduct(String id) async {
    try {
      final target = await ProduitService().getProduitDetail(id);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: target),
        ),
      );
    } catch (e) {
      _showError('Ce produit n\'existe plus ou a été supprimé.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chargement en cours...',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading ? _buildLoading(isDark) : _buildError(isDark),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône de vidéo animée
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.9 + (_pulseController.value * 0.15),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF6366F1,
                      ).withOpacity(0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + (_pulseController.value * 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Chargement du contenu...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Veuillez patienter un instant',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Contenu introuvable',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton Réessayer
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadAndNavigate();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton Fermer
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Fermer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white70
                      : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
