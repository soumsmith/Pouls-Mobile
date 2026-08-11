import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../config/app_colors.dart';
import '../services/coulisse_excellence_service.dart';
import '../services/visite_guidee_service.dart';
import '../widgets/components/custom_error_state.dart';
import '../models/coulisse_excellence.dart';
import '../models/visite_guidee_video.dart';
import 'coulisse_video_feed_screen.dart';
import 'visite_guidee_video_feed_screen.dart';
import 'all_videos_screen.dart';
import 'all_visite_guidee_videos_screen.dart';
import 'tips_advice_screen.dart';
import '../services/video_service.dart';
import '../models/video.dart';

import '../services/blog_service.dart';
import '../services/astuce_conseil_service.dart';
import '../models/astuce_conseil.dart';
import '../services/event_service.dart';
import '../services/produit_service.dart';
import '../app.dart';
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

      print(
        '🔎 [DeepLinkResolver] _loadAndNavigate → type=${data.type} '
        'id="$id" ecole="${data.ecole}" uri=${data.originalUri}',
      );

      if (id.isEmpty) {
        print('❌ [DeepLinkResolver] id vide → "Lien invalide."');
        _showError('Lien invalide.');
        return;
      }

      switch (data.type) {
        case DeepLinkContentType.coulisse:
          final videoId = int.tryParse(id);
          if (videoId != null) {
            await _loadCoulisseVideo(videoId, data.ecole);
          } else {
            _showError('Lien invalide.');
          }
          break;
        case DeepLinkContentType.visite:
          final videoId = int.tryParse(id);
          if (videoId != null) {
            await _loadVisiteGuideeVideo(videoId, data.ecole);
          } else {
            _showError('Lien invalide.');
          }
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
    } catch (e, stack) {
      print('❌ [DeepLinkResolver] Exception non catchée dans _loadAndNavigate: $e');
      print(stack.toString());
      _showError('Impossible de charger le contenu.\n$e');
    }
  }

  Future<void> _loadCoulisseVideo(int videoId, String? ecole) async {
    print('🔎 [DeepLinkResolver] _loadCoulisseVideo videoId=$videoId ecole="$ecole"');
    try {
      List<CoulisseExcellence> allVideos = [];

      // Chemin nominal : le lien transporte le code école, on réutilise le
      // même appel scopé que la navigation classique (un seul appel, fiable).
      if (ecole != null && ecole.isNotEmpty) {
        print('🔎 [DeepLinkResolver] Tentative scopée école="$ecole"...');
        allVideos = await CoulisseExcellenceService.getCoulisseExcellenceList(
          ecole,
        );
        print(
          '🔎 [DeepLinkResolver] getCoulisseExcellenceList("$ecole") → '
          '${allVideos.length} vidéo(s), ids=${allVideos.map((v) => v.id).toList()}',
        );
      } else {
        print('🔎 [DeepLinkResolver] Pas de code école dans le lien, on saute la recherche scopée.');
      }

      // Repli (anciens liens sans `ecole`, ou vidéo non trouvée dans l'école
      // indiquée) : recherche paginée sur tout le catalogue.
      if (!allVideos.any((v) => v.id == videoId)) {
        print(
          '🔎 [DeepLinkResolver] Vidéo $videoId non trouvée dans le lot scopé '
          '(${allVideos.length} vidéo(s)) → repli sur la recherche paginée globale.',
        );
        allVideos = [];
        int currentPage = 1;
        bool found = false;

        while (!found) {
          print('🔎 [DeepLinkResolver] Repli: page $currentPage (perPage=50)...');
          final pageVideos =
              await CoulisseExcellenceService.getAllCoulisseExcellenceVideos(
                page: currentPage,
                perPage: 50,
              );
          print(
            '🔎 [DeepLinkResolver] Repli: page $currentPage → '
            '${pageVideos.length} vidéo(s)',
          );

          if (pageVideos.isEmpty) {
            print('🔎 [DeepLinkResolver] Repli: page vide, fin de la pagination.');
            break;
          }

          allVideos.addAll(pageVideos);

          if (allVideos.any((v) => v.id == videoId)) {
            found = true;
            print('✅ [DeepLinkResolver] Repli: vidéo $videoId trouvée page $currentPage.');
          } else if (pageVideos.length < 50) {
            print('🔎 [DeepLinkResolver] Repli: dernière page atteinte (< 50 résultats), vidéo non trouvée.');
            break;
          } else {
            currentPage++;
          }
        }
      }

      if (!mounted) return;

      final targetVideo = allVideos.where((v) => v.id == videoId).toList();

      if (targetVideo.isEmpty) {
        print(
          '❌ [DeepLinkResolver] Vidéo $videoId introuvable au final parmi '
          '${allVideos.length} vidéo(s) chargée(s) → "Cette vidéo n\'existe plus..."',
        );
        _showError('Cette vidéo n\'existe plus ou a été supprimée.');
        return;
      }

      // Trouver l'index de la vidéo cible dans la liste
      final targetIndex = allVideos.indexWhere((v) => v.id == videoId);
      print('✅ [DeepLinkResolver] Vidéo $videoId trouvée à l\'index $targetIndex, navigation...');

      final videoRoute = MaterialPageRoute(
        builder: (context) => CoulisseVideoFeedScreen(
          videos: allVideos,
          initialIndex: targetIndex >= 0 ? targetIndex : 0,
        ),
      );

      // Si on connaît l'école, on insère la liste "Coulisses d'Excellence"
      // sous le lecteur : le bouton retour de la vidéo revient alors sur
      // cette liste plutôt que directement à l'accueil.
      if (ecole != null && ecole.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AllVideosScreen(ecoleCode: ecole),
          ),
        );
        Navigator.of(context).push(videoRoute);
      } else {
        Navigator.of(context).pushReplacement(videoRoute);
      }
    } catch (e, stack) {
      print('❌ [DeepLinkResolver] Exception dans _loadCoulisseVideo: $e');
      print(stack.toString());
      _showError(
        'Impossible de charger la vidéo.\nVérifiez votre connexion internet.',
      );
    }
  }

  Future<void> _loadVisiteGuideeVideo(int videoId, String? ecole) async {
    print('🔎 [DeepLinkResolver] _loadVisiteGuideeVideo videoId=$videoId ecole="$ecole"');
    try {
      List<VisiteGuideeVideo> allVideos = [];

      // Chemin nominal : le lien transporte le code école, on réutilise le
      // même appel scopé que la navigation classique (un seul appel, fiable).
      if (ecole != null && ecole.isNotEmpty) {
        print('🔎 [DeepLinkResolver] Tentative scopée école="$ecole"...');
        allVideos = await VisiteGuideeService.getVideosByEcole(ecole);
        print(
          '🔎 [DeepLinkResolver] getVideosByEcole("$ecole") → '
          '${allVideos.length} vidéo(s), ids=${allVideos.map((v) => v.id).toList()}',
        );
      } else {
        print('🔎 [DeepLinkResolver] Pas de code école dans le lien, on saute la recherche scopée.');
      }

      // Repli (anciens liens sans `ecole`, ou vidéo non trouvée dans l'école
      // indiquée) : recherche paginée sur tout le catalogue.
      if (!allVideos.any((v) => v.id == videoId)) {
        print(
          '🔎 [DeepLinkResolver] Vidéo $videoId non trouvée dans le lot scopé '
          '(${allVideos.length} vidéo(s)) → repli sur la recherche paginée globale.',
        );
        allVideos = [];
        int currentPage = 1;
        bool found = false;

        while (!found) {
          print('🔎 [DeepLinkResolver] Repli: page $currentPage (perPage=50)...');
          final pageVideos = await VisiteGuideeService.getAllVisiteGuideeVideos(
            page: currentPage,
            perPage: 50,
          );
          print(
            '🔎 [DeepLinkResolver] Repli: page $currentPage → '
            '${pageVideos.length} vidéo(s)',
          );

          if (pageVideos.isEmpty) {
            print('🔎 [DeepLinkResolver] Repli: page vide, fin de la pagination.');
            break;
          }

          allVideos.addAll(pageVideos);

          if (allVideos.any((v) => v.id == videoId)) {
            found = true;
            print('✅ [DeepLinkResolver] Repli: vidéo $videoId trouvée page $currentPage.');
          } else if (pageVideos.length < 50) {
            print('🔎 [DeepLinkResolver] Repli: dernière page atteinte (< 50 résultats), vidéo non trouvée.');
            break;
          } else {
            currentPage++;
          }
        }
      }

      if (!mounted) return;

      final targetVideo = allVideos.where((v) => v.id == videoId).toList();

      if (targetVideo.isEmpty) {
        print(
          '❌ [DeepLinkResolver] Vidéo $videoId introuvable au final parmi '
          '${allVideos.length} vidéo(s) chargée(s) → "Cette vidéo n\'existe plus..."',
        );
        _showError('Cette vidéo n\'existe plus ou a été supprimée.');
        return;
      }

      final targetIndex = allVideos.indexWhere((v) => v.id == videoId);
      print('✅ [DeepLinkResolver] Vidéo $videoId trouvée à l\'index $targetIndex, navigation...');

      final videoRoute = MaterialPageRoute(
        builder: (context) => VisiteGuideeVideoFeedScreen(
          videos: allVideos,
          initialIndex: targetIndex >= 0 ? targetIndex : 0,
        ),
      );

      // Si on connaît l'école, on insère la liste "Visite Guidée" sous le
      // lecteur : le bouton retour de la vidéo revient alors sur cette liste
      // plutôt que directement à l'accueil. AllVisiteGuideeVideosScreen
      // attend le modèle `Video` (via VideoService), distinct du modèle
      // `VisiteGuideeVideo` utilisé pour la résolution ci-dessus — on
      // recharge donc sa première page dans le bon format.
      List<Video>? listScreenVideos;
      if (ecole != null && ecole.isNotEmpty) {
        try {
          listScreenVideos = await VideoService.getVideosByType(
            'visiteguide',
            ecoleCode: ecole,
          );
        } catch (e) {
          print('⚠️ [DeepLinkResolver] Échec du chargement de la liste Visite Guidée pour le retour: $e');
        }
      }

      if (!mounted) return;

      if (listScreenVideos != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AllVisiteGuideeVideosScreen(
              videos: listScreenVideos!,
              ecoleCode: ecole!,
            ),
          ),
        );
        Navigator.of(context).push(videoRoute);
      } else {
        Navigator.of(context).pushReplacement(videoRoute);
      }
    } catch (e, stack) {
      print('❌ [DeepLinkResolver] Exception dans _loadVisiteGuideeVideo: $e');
      print(stack.toString());
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
    final id = int.tryParse(idStr);
    if (id == null) {
      _showError('Lien invalide.');
      return;
    }
    print('🔎 [DeepLinkResolver] _loadTip id=$id');

    try {
      // Pagine jusqu'à trouver l'astuce ciblée (une astuce partagée depuis
      // le lecteur vidéo peut être au-delà de la page 1).
      final List<AstuceConseil> allAstuces = [];
      int currentPage = 1;
      AstuceConseil? target;

      while (target == null) {
        final response = await AstuceConseilService().getAstucesConseils(
          page: currentPage,
        );
        print(
          '🔎 [DeepLinkResolver] getAstucesConseils(page: $currentPage) → '
          '${response.data.length} astuce(s), currentPage=${response.currentPage}, lastPage=${response.lastPage}',
        );
        allAstuces.addAll(response.data);
        target = allAstuces.where((t) => t.id == id).firstOrNull;
        if (target != null || response.currentPage >= response.lastPage) {
          break;
        }
        currentPage++;
      }

      if (!mounted) return;

      if (target == null) {
        print('❌ [DeepLinkResolver] Astuce/conseil $id introuvable.');
        _showError('Ce conseil n\'existe plus ou a été supprimé.');
        return;
      }

      final hasVideo = target.youtubeUrl != null && target.youtubeUrl!.isNotEmpty;
      print('✅ [DeepLinkResolver] Astuce/conseil $id trouvée, hasVideo=$hasVideo');

      if (hasVideo) {
        // Même logique d'enveloppe que TipsAdviceScreen : seules les
        // astuces avec vidéo intègrent le lecteur VisiteGuideeVideoFeedScreen.
        final videoAstuces = allAstuces
            .where((a) => a.youtubeUrl != null && a.youtubeUrl!.isNotEmpty)
            .toList();
        final videos = videoAstuces
            .map(
              (a) => VisiteGuideeVideo(
                id: a.id,
                typeVideo: 'astuce',
                youtubeUrl: a.youtubeUrl!,
                title: a.title,
                description: a.content,
                code: a.codeecole,
                slug: a.slug,
              ),
            )
            .toList();
        final targetIndex = videoAstuces.indexWhere((a) => a.id == id);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TipsAdviceScreen()),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VisiteGuideeVideoFeedScreen(
              videos: videos,
              initialIndex: targetIndex >= 0 ? targetIndex : 0,
              cameFromGrid: true,
            ),
          ),
        );
      } else {
        // Astuce sans vidéo : écran de détail texte, avec la liste des
        // astuces en dessous pour un retour cohérent.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TipsAdviceScreen()),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TipsAdviceDetailScreen(astuce: target!),
          ),
        );
      }
    } catch (e, stack) {
      print('❌ [DeepLinkResolver] Exception dans _loadTip: $e');
      print(stack.toString());
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

      // Passe par App()/MainScreenWrapper (avec le produit pré-empilé) pour
      // que la bottom nav reste visible, plutôt qu'un push direct qui en
      // sortirait complètement.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => App(
            initialExtraScreen: ProductDetailScreen(product: target),
          ),
        ),
        (route) => false,
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
    return Scaffold(
      backgroundColor: AppColors.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.screenTextPrimaryThemed(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _isLoading ? _buildLoading(context) : _buildError(context),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône animée, dans les couleurs de l'application
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.94 + (_pulseController.value * 0.06),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppColors.screenOrangeGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.screenOrange.withOpacity(
                        0.25 + _pulseController.value * 0.15,
                      ),
                      blurRadius: 22 + (_pulseController.value * 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Chargement du contenu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.screenTextPrimaryThemed(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Un instant, on prépare votre vidéo…',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondaryThemed(context),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppColors.screenDividerThemed(context),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.screenOrange,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final bool isNetworkError =
        _errorMessage?.toLowerCase().contains('connexion') ?? false;

    return CustomErrorState(
      title: isNetworkError ? 'Erreur de connexion' : 'Contenu introuvable',
      message: _errorMessage ?? 'Une erreur est survenue.',
      icon: isNetworkError ? Icons.wifi_off_rounded : Icons.videocam_off_rounded,
      onRetry: () {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        _loadAndNavigate();
      },
      retryText: 'Réessayer',
      buttonIsLight: true,
      buttonWidth: 200,
    );
  }
}
