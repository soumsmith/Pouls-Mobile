import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/models/video.dart';
import 'package:parents_responsable/screens/all_children_screen.dart';
import 'package:parents_responsable/services/video_service.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_request_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/sponsorship_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_dimensions.dart';
import '../models/child.dart';
import '../models/gestion_presence_eleve_entry.dart';
import '../services/database_service.dart';
import '../services/gestion_presence_eleve_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/integration_request_service.dart';
import '../services/auth_service.dart';
import '../services/recommendation_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_loader.dart';
import '../widgets/search_bar_widget.dart';
import '../config/app_colors.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/components/section_row.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'add_child_screen.dart';
import 'inscription_screen.dart' as inscription;
import '../widgets/payment_bottom_sheet.dart';
import '../services/paiement_service.dart';
import '../services/group_message_service.dart';
import '../services/echeance_service.dart';
import '../models/group_message.dart';
import '../models/echeance_notification.dart';
import '../widgets/bottom_sheets/inscription_bottom_sheet.dart';
import '../widgets/bottom_fade_gradient.dart';
import '../widgets/see_more_card.dart';
import '../services/coulisse_excellence_service.dart';
import '../models/coulisse_excellence.dart';
import 'coulisse_video_feed_screen.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../models/visite_guidee_video.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import 'event_detail_screen.dart';
import 'all_events_screen.dart';
import 'all_videos_screen.dart';
import 'all_visite_guidee_videos_screen.dart';
import '../services/blog_service.dart';
import '../models/blog.dart';
import 'all_blogs_screen.dart';
import 'blog_detail_screen.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
const _kDarkBg = Color(0xFF0F0F14);
const _kDarkCard = Color(0xFF1E1E2A);
const _kDarkBorder = Color(0xFF2A2A35);
const _kOrange = Color(0xFFFF7A3C);
const _kOrangeDeep = Color(0xFFFF5C1B);
const _kSheetBg = Color(0xFFF5F5F7);
const _kSheetCard = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A1A2A);
const _kTextSecondary = Color(0xFF8A8A9E);
const _kDivider = Color(0xFFD1D1D6);
const _kChipActive = Color(0xFF1A1A2A);
const _kChipBg = Color(0xFFEBEBEF);

class _PresenceBannerItem {
  final String key;
  final Child child;
  final GestionPresenceEleveEntry entry;
  final bool isPresence;

  const _PresenceBannerItem({
    required this.key,
    required this.child,
    required this.entry,
    required this.isPresence,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Child> _children = [];
  List<Child> _filteredChildren = [];
  bool _isLoading = true;
  String? _error;
  final TextSizeService _textSizeService = TextSizeService();
  final ThemeService _themeService = ThemeService();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _recommenderNameController =
      TextEditingController();
  final TextEditingController _etablissementController =
      TextEditingController();
  final TextEditingController _paysRecommendController =
      TextEditingController();
  final TextEditingController _villeRecommendController =
      TextEditingController();
  final TextEditingController _parentNomController = TextEditingController();
  final TextEditingController _parentPrenomController = TextEditingController();
  final TextEditingController _parentTelephoneController =
      TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _ordreController = TextEditingController();
  final TextEditingController _adresseEtablissementController =
      TextEditingController();
  final TextEditingController _paysParentController = TextEditingController();
  final TextEditingController _villeParentController = TextEditingController();
  final TextEditingController _adresseParentController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;

  int _unreadNotificationsCount = 0;
  bool _notificationsLoading = false;
  String _activeFilter = 'Tout';
  int _selectedChildIndex = 0;
  final ValueNotifier<int> _selectedChildIndexNotifier = ValueNotifier<int>(0);

  // Variables pour les notifications par enfant
  Map<String, List<GroupMessage>> _childrenNotifications = {};
  Map<String, EcheanceNotification?> _childrenEcheances = {};
  Map<String, bool> _childrenNotificationsLoading = {};
  Map<String, bool> _childrenEcheancesLoading = {};

  List<_PresenceBannerItem> _presenceBannerItems = [];
  final Set<String> _dismissedPresenceBannerItemKeys = {};
  bool _presenceBannerLoading = false;
  PageController? _presencePageController;
  Timer? _presenceAutoScrollTimer;
  final ValueNotifier<int> _presencePageIndex = ValueNotifier<int>(0);

  // Variables pour les vidéos Coulisses de l'Excellence
  List<CoulisseExcellence> _coulisseVideos = [];
  bool _coulisseVideosLoading = true;
  String? _coulisseVideosError;

  bool get _hasCoulisseExcellenceData =>
      !_coulisseVideosLoading &&
      _coulisseVideosError == null &&
      _coulisseVideos.isNotEmpty;

  // Variables pour les événements
  List<Event> _events = [];
  bool _eventsLoading = true;
  String? _eventsError;

  bool get _hasEventsData =>
      !_eventsLoading && _eventsError == null && _events.isNotEmpty;

  // Variables pour les blogs/actualités
  List<Blog> _blogs = [];
  bool _blogsLoading = true;
  String? _blogsError;

  bool get _hasBlogsData =>
      !_blogsLoading && _blogsError == null && _blogs.isNotEmpty;

  final List<String> _filters = ['Tout', 'Alertes', 'Paiements', 'Notes'];

  // Variables pour les vidéos de visite guidée
  List<Video> _visiteGuideeVideos = [];
  bool _visiteGuideeVideosLoading = true;
  String? _visiteGuideeVideosError;

  bool get _hasVisiteGuideeData =>
      !_visiteGuideeVideosLoading &&
      _visiteGuideeVideosError == null &&
      _visiteGuideeVideos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _textSizeService.addListener(() {
      if (mounted) setState(() {});
    });
    _loadChildren();
    _loadUnreadNotificationsCount();
    _loadChildrenNotifications(); // Charger les notifications pour chaque enfant
    _loadCoulisseVideos(); // Charger les vidéos Coulisses de l'Excellence
    _loadEvents(); // Charger les événements
    _loadBlogs(); // Charger les blogs/actualités
    _loadVisiteGuideeVideos(); // Ajouter cette ligne
    _startPresenceAutoScrollIfNeeded();
  }

  Future<void> _refreshHome() async {
    await _loadChildren();
    await Future.wait([
      _loadUnreadNotificationsCount(),
      _loadCoulisseVideos(),
      _loadEvents(),
      _loadVisiteGuideeVideos(), // Ajouter cette ligne
      _loadBlogs(),
    ]);
    await _loadChildrenNotifications();
    await _loadChildrenPresenceSignals();
  }

  @override
  void dispose() {
    _textSizeService.removeListener(() {});
    _matriculeController.dispose();
    _searchController.dispose();

    _presenceAutoScrollTimer?.cancel();
    _presencePageController?.dispose();

    _recommenderNameController.dispose();
    _etablissementController.dispose();
    _paysRecommendController.dispose();
    _villeRecommendController.dispose();
    _parentNomController.dispose();
    _parentPrenomController.dispose();
    _parentTelephoneController.dispose();
    _parentEmailController.dispose();
    _ordreController.dispose();
    _adresseEtablissementController.dispose();
    _paysParentController.dispose();
    _villeParentController.dispose();
    _adresseParentController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _loadChildrenPresenceSignals() async {
    print('=== DÉBUT CHARGEMENT PRÉSENCE/ABSENCE POUR TOUS LES ENFANTS ===');
    if (_presenceBannerLoading) return;

    if (_children.isEmpty) {
      print('📭 Aucun enfant à charger pour présence/absence');
      return;
    }

    if (mounted) {
      setState(() {
        _presenceBannerLoading = true;
      });
    }

    try {
      final futures = _children.map((child) async {
        print('👤 Enfant: ${child.fullName} (${child.id})');
        final childInfo = await DatabaseService.instance.getChildInfoById(
          child.id,
        );
        final matricule = childInfo?['matricule'] as String?;
        final paramEcole = childInfo?['paramEcole'] as String?;

        print('🔍 Info enfant: matricule=$matricule, paramEcole=$paramEcole');

        if (matricule == null || matricule.isEmpty) {
          print('⚠️ Matricule manquant pour ${child.fullName}');
          return null;
        }
        if (paramEcole == null || paramEcole.isEmpty) {
          print('⚠️ Code école (paramEcole) manquant pour ${child.fullName}');
          return null;
        }

        final entries =
            await GestionPresenceEleveService.getGestionPresenceEleve(
              matricule,
              paramEcole,
            );

        print('📊 ${entries.length} entrée(s) reçue(s) pour ${child.fullName}');

        final signaled = entries
            .where((e) => e.presence != null)
            .cast<GestionPresenceEleveEntry?>()
            .toList();

        if (signaled.isEmpty) {
          print('ℹ️ Aucune entrée de présence trouvée pour ${child.fullName}');
          return null;
        }

        // Trier par date pour afficher dans l'ordre chronologique
        signaled.sort((a, b) {
          final da = _tryParseApiDate(a?.debut)?.millisecondsSinceEpoch ?? 0;
          final db = _tryParseApiDate(b?.debut)?.millisecondsSinceEpoch ?? 0;
          return da.compareTo(db);
        });

        // Créer un item par matière avec presence=1 (présent), sinon absent
        final items = signaled
            .map((entry) {
              if (entry == null) return null;
              final isPresence = (entry.presence ?? 0) == 1;
              final key =
                  '${child.id}::${entry.debut ?? ''}::${entry.fin ?? ''}::${entry.matiere ?? ''}::${entry.presence ?? ''}';
              print(
                '✅ Signalisation pour ${child.fullName}: ${isPresence ? 'Présence' : 'Absence'} - ${entry.matiere} (${entry.debut})',
              );
              return _PresenceBannerItem(
                key: key,
                child: child,
                entry: entry,
                isPresence: isPresence,
              );
            })
            .whereType<_PresenceBannerItem>()
            .toList();

        // Retourner le premier item pour le PageView (le carousel gérera les autres)
        if (items.isEmpty) return null;
        return items.first;
      }).toList();

      final results = await Future.wait(futures);
      final items = results.whereType<_PresenceBannerItem>().toList();
      final visibleItems = items
          .where((i) => !_dismissedPresenceBannerItemKeys.contains(i.key))
          .toList();

      print(
        '🎯 Bannières visibles: ${visibleItems.length} / ${items.length} (dont ${items.length - visibleItems.length} déjà masquées)',
      );

      if (!mounted) return;
      setState(() {
        _presenceBannerItems = visibleItems;
        _presenceBannerLoading = false;
      });
      _ensurePresencePagerReady();
      _startPresenceAutoScrollIfNeeded();
      print('=== FIN CHARGEMENT PRÉSENCE/ABSENCE ===');
    } catch (e) {
      print('❌ Erreur globale chargement présence/absence: $e');
      if (!mounted) return;
      setState(() {
        _presenceBannerItems = [];
        _presenceBannerLoading = false;
      });
      _stopPresenceAutoScroll();
    }
  }

  DateTime? _tryParseApiDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  void _ensurePresencePagerReady() {
    if (_presencePageController != null) return;
    _presencePageController = PageController();
  }

  void _startPresenceAutoScrollIfNeeded() {
    _presenceAutoScrollTimer?.cancel();
    if (_presenceBannerItems.length <= 1) return;

    _ensurePresencePagerReady();

    _presenceAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final controller = _presencePageController;
      if (controller == null || !controller.hasClients) return;

      final currentPage = controller.page?.round() ?? controller.initialPage;
      final nextPage = (currentPage + 1) % _presenceBannerItems.length;
      controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopPresenceAutoScroll() {
    _presenceAutoScrollTimer?.cancel();
    _presenceAutoScrollTimer = null;
  }

  void _showRecommendationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendationBottomSheet(
        accentColor: _kOrange,
        recommenderNameController: _recommenderNameController,
        etablissementController: _etablissementController,
        paysRecommendController: _paysRecommendController,
        villeRecommendController: _villeRecommendController,
        parentNomController: _parentNomController,
        parentPrenomController: _parentPrenomController,
        parentTelephoneController: _parentTelephoneController,
        parentEmailController: _parentEmailController,
        ordreController: _ordreController,
        adresseEtablissementController: _adresseEtablissementController,
        paysParentController: _paysParentController,
        villeParentController: _villeParentController,
        adresseParentController: _adresseParentController,
        onSubmit: (context) async {
          try {
            await RecommendationService.submitRecommendation(
              etablissement: _etablissementController.text,
              pays: _paysRecommendController.text,
              ville: _villeRecommendController.text,
              ordre: _ordreController.text.isEmpty
                  ? '1'
                  : _ordreController.text,
              adresseEtablissement: _adresseEtablissementController.text.isEmpty
                  ? 'Non spécifiée'
                  : _adresseEtablissementController.text,
              nomParent: _parentNomController.text,
              prenomParent: _parentPrenomController.text,
              telephone: _parentTelephoneController.text,
              email: _parentEmailController.text.isEmpty
                  ? 'email@example.com'
                  : _parentEmailController.text,
              paysParent: _paysParentController.text.isEmpty
                  ? _paysRecommendController.text
                  : _paysParentController.text,
              villeParent: _villeParentController.text.isEmpty
                  ? _villeRecommendController.text
                  : _villeParentController.text,
              adresseParent: _adresseParentController.text.isEmpty
                  ? 'Non spécifiée'
                  : _adresseParentController.text,
            );

            Navigator.of(context).pop();
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('Recommandation envoyée avec succès!'),
                backgroundColor: Colors.green,
              ),
            );

            _etablissementController.clear();
            _paysRecommendController.clear();
            _villeRecommendController.clear();
            _parentNomController.clear();
            _parentPrenomController.clear();
            _parentTelephoneController.clear();
            _parentEmailController.clear();
            _ordreController.clear();
            _adresseEtablissementController.clear();
            _paysParentController.clear();
            _villeParentController.clear();
            _adresseParentController.clear();
            _recommenderNameController.clear();
          } catch (e) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _loadUnreadNotificationsCount() async {
    if (!mounted) return;
    setState(() => _notificationsLoading = true);
    try {
      final authService = AuthService.instance;
      final currentUser = authService.getCurrentUser();
      if (currentUser != null) {
        final unreadCount = await DatabaseService.instance
            .getUnreadNotificationsCount(currentUser.id);
        if (mounted) {
          setState(() {
            _unreadNotificationsCount = unreadCount;
            _notificationsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _notificationsLoading = false);
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      MainScreenWrapper.of(context).refreshCurrentUser();
      final parentId = MainScreenWrapper.of(context).currentUserId ?? 'parent1';
      final apiService = MainScreenWrapper.of(context).apiService;
      final children = await apiService.getChildrenForParent(parentId);
      if (!mounted) return;
      setState(() {
        _children = List.from(children);
        _filteredChildren = List.from(children);
        _isLoading = false;
      });
      _updatePhotosInBackground(children);
      await _loadChildrenPresenceSignals();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Gérer l'action sur une vidéo de visite guidée
  void _handleVisiteGuideeAction(Video video) {
    // Convertir Video en VisiteGuideeVideo
    final visiteVideo = VisiteGuideeVideo(
      typeVideo: video.typevideo,
      youtubeUrl: video.youtubeUrl,
    );

    // Trouver l'index de la vidéo dans la liste
    final videoIndex = _visiteGuideeVideos.indexWhere(
      (v) => v.youtubeVideoId == video.youtubeVideoId,
    );

    // Convertir toutes les vidéos en VisiteGuideeVideo
    final visiteVideos = _visiteGuideeVideos
        .map(
          (v) => VisiteGuideeVideo(
            typeVideo: v.typevideo,
            youtubeUrl: v.youtubeUrl,
          ),
        )
        .toList();

    // Naviguer vers l'écran de visualisation des vidéos
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisiteGuideeVideoFeedScreen(
          videos: visiteVideos,
          initialIndex: videoIndex >= 0 ? videoIndex : 0,
        ),
      ),
    );
  }

  // Gérer l'action "Voir+" pour les vidéos de visite guidée
  void _handleSeeMoreVisiteGuidee() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AllVisiteGuideeVideosScreen(videos: _visiteGuideeVideos),
      ),
    );
  }

  // Méthode utilitaire pour lancer une URL
  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Formater la date
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Aujourd'hui";
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  // Charger les notifications pour tous les enfants
  Future<void> _loadChildrenNotifications() async {
    print(
      '=== DÉBUT DU CHARGEMENT DES NOTIFICATIONS POUR TOUS LES ENFANTS (HOME) ===',
    );

    // Attendre que les enfants soient chargés
    if (_children.isEmpty) {
      print('Enfants pas encore chargés, on attend...');
      await Future.delayed(const Duration(seconds: 2));
      if (_children.isEmpty) {
        print('Toujours pas d\'enfants, on réessayera plus tard');
        return;
      }
    }

    print('Chargement des notifications pour ${_children.length} enfant(s)');

    // Initialiser les états de chargement
    for (final child in _children) {
      _childrenNotificationsLoading[child.id] = true;
      _childrenEcheancesLoading[child.id] = true;
    }

    if (mounted) {
      setState(() {});
    }

    // Charger les notifications pour chaque enfant en parallèle
    final futures = <Future<void>>[];

    for (final child in _children) {
      futures.add(_loadNotificationsForChild(child));
    }

    try {
      await Future.wait(futures);
      print(
        '=== FIN DU CHARGEMENT DES NOTIFICATIONS POUR TOUS LES ENFANTS ===',
      );

      // Afficher le résumé
      for (final child in _children) {
        final notifCount =
            _childrenNotifications[child.id]?.where((n) => !n.estLu).length ??
            0;
        final hasUnpaidFees =
            _childrenEcheances[child.id]?.hasUnpaidFees == true;
        final totalCount = notifCount + (hasUnpaidFees ? 1 : 0);
        print(
          'Enfant ${child.fullName}: $totalCount notification(s) (messages: $notifCount, échéance: $hasUnpaidFees)',
        );
      }
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
    }
  }

  // Charger les notifications pour un enfant spécifique
  Future<void> _loadNotificationsForChild(Child child) async {
    print('Chargement des notifications pour: ${child.fullName}');

    // Récupérer le matricule depuis la base de données
    try {
      final childInfo = await DatabaseService.instance.getChildInfoById(
        child.id,
      );
      final matricule = childInfo?['matricule'] as String?;

      if (matricule == null || matricule.isEmpty) {
        print('Matricule non disponible pour ${child.fullName}');
        if (mounted) {
          setState(() {
            _childrenNotificationsLoading[child.id] = false;
            _childrenEcheancesLoading[child.id] = false;
          });
        }
        return;
      }

      print('Matricule trouvé pour ${child.fullName}: $matricule');

      // Charger les messages de groupe
      try {
        final notifications = await GroupMessageService.getGroupMessages(
          matricule,
        );
        if (mounted) {
          setState(() {
            _childrenNotifications[child.id] = notifications;
            _childrenNotificationsLoading[child.id] = false;
          });
        }
        print(
          'Messages chargés pour ${child.fullName}: ${notifications.length}',
        );
      } catch (e) {
        print('Erreur messages pour ${child.fullName}: $e');
        if (mounted) {
          setState(() {
            _childrenNotificationsLoading[child.id] = false;
          });
        }
      }

      // Charger les notifications d'échéance
      try {
        final echeanceNotification =
            await EcheanceService.getEcheanceNotification(matricule);
        if (mounted) {
          setState(() {
            _childrenEcheances[child.id] = echeanceNotification;
            _childrenEcheancesLoading[child.id] = false;
          });
        }
        print(
          'Échéance chargée pour ${child.fullName}: ${echeanceNotification.hasUnpaidFees ? 'Impayée' : 'Régulière'}',
        );
      } catch (e) {
        print('Erreur échéance pour ${child.fullName}: $e');
        if (mounted) {
          setState(() {
            _childrenEcheancesLoading[child.id] = false;
          });
        }
      }
    } catch (e) {
      print('Erreur générale pour ${child.fullName}: $e');
      if (mounted) {
        setState(() {
          _childrenNotificationsLoading[child.id] = false;
          _childrenEcheancesLoading[child.id] = false;
        });
      }
    }
  }

  // Obtenir le nombre total de notifications pour un enfant
  int getNotificationCountForChild(Child child) {
    final messages = _childrenNotifications[child.id] ?? [];
    final unreadMessages = messages.where((n) => !n.estLu).length;
    final hasUnpaidFees = _childrenEcheances[child.id]?.hasUnpaidFees == true;
    return unreadMessages + (hasUnpaidFees ? 1 : 0);
  }

  // Charger les vidéos Coulisses de l'Excellence
  Future<void> _loadCoulisseVideos() async {
    if (mounted) {
      setState(() {
        _coulisseVideosLoading = true;
        _coulisseVideosError = null;
      });
    }
    try {
      final videos =
          await CoulisseExcellenceService.getAllCoulisseExcellenceVideos();
      if (mounted) {
        setState(() {
          _coulisseVideos = videos;
          _coulisseVideosLoading = false;
          _coulisseVideosError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coulisseVideosLoading = false;
          _coulisseVideosError = e.toString();
        });
      }
    }
  }

  // Charger les vidéos de visite guidée
  Future<void> _loadVisiteGuideeVideos() async {
    if (mounted) {
      setState(() {
        _visiteGuideeVideosLoading = true;
        _visiteGuideeVideosError = null;
      });
    }
    try {
      final videos = await VideoService.getVideosByType('visiteguide');
      if (mounted) {
        setState(() {
          _visiteGuideeVideos = videos;
          _visiteGuideeVideosLoading = false;
          _visiteGuideeVideosError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _visiteGuideeVideosLoading = false;
          _visiteGuideeVideosError = e.toString();
        });
      }
    }
  }

  // Charger les événements depuis l'API
  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _eventsLoading = true;
        _eventsError = null;
      });
    }
    try {
      final events = await EventService.getEventsList();
      if (mounted) {
        setState(() {
          _events = events;
          _eventsLoading = false;
          _eventsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eventsLoading = false;
          _eventsError = e.toString();
        });
      }
    }
  }

  // Charger les blogs/actualités depuis l'API
  Future<void> _loadBlogs() async {
    if (mounted) {
      setState(() {
        _blogsLoading = true;
        _blogsError = null;
      });
    }
    try {
      final blogs = await BlogService.getBlogsList();
      if (mounted) {
        setState(() {
          _blogs = blogs;
          _blogsLoading = false;
          _blogsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _blogsLoading = false;
          _blogsError = e.toString();
        });
      }
    }
  }

  // Construire la section Coulisses de l'Excellence
  // Widget _buildCoulisseExcellenceSection() {
  //   if (!_hasCoulisseExcellenceData) {
  //     return const SizedBox.shrink();
  //   }

  //   return Container(
  //     height: 120,
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: _coulisseVideos.length,
  //       itemBuilder: (context, index) {
  //         final video = _coulisseVideos[index];
  //         return _buildCoulisseVideoCard(video, index);
  //       },
  //     ),
  //   );
  // }

  // Construire une carte de vidéo pour le carrousel
  // Widget _buildCoulisseVideoCard(CoulisseExcellence video, int index) {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.of(context).push(
  //         MaterialPageRoute(
  //           builder: (context) => CoulisseVideoFeedScreen(
  //             videos: _coulisseVideos,
  //             initialIndex: index,
  //           ),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       width: 120,
  //       margin: const EdgeInsets.only(right: 12),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(16),
  //         child: Stack(
  //           children: [
  //             // Image miniature de la vidéo YouTube
  //             FadeInImage.assetNetwork(
  //               width: 300,
  //               height: 120,
  //               fit: BoxFit.cover,
  //               placeholder: 'assets/images/video-placeholder.jpg',
  //               image:
  //                   'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg',
  //               imageErrorBuilder: (context, error, stackTrace) {
  //                 return Container(
  //                   width: 300,
  //                   height: 120,
  //                   color: Colors.grey[300],
  //                   child: const Icon(
  //                     Icons.movie,
  //                     color: Colors.grey,
  //                     size: 48,
  //                   ),
  //                 );
  //               },
  //             ),

  //             // Overlay sombre pour améliorer la lisibilité
  //             Container(
  //               width: 300,
  //               height: 120,
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                   colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
  //                 ),
  //               ),
  //             ),

  //             // Icône de lecture centrale
  //             Positioned(
  //               top: 0,
  //               left: 0,
  //               right: 0,
  //               bottom: 0,
  //               child: Center(
  //                 child: Container(
  //                   width: 50,
  //                   height: 50,
  //                   decoration: BoxDecoration(
  //                     color: Colors.black.withOpacity(0.6),
  //                     shape: BoxShape.circle,
  //                     border: Border.all(
  //                       color: Colors.white.withOpacity(0.8),
  //                       width: 2,
  //                     ),
  //                   ),
  //                   child: const Icon(
  //                     Icons.play_arrow,
  //                     color: Colors.white,
  //                     size: 28,
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             // Informations en bas
  //             Positioned(
  //               bottom: 8,
  //               left: 8,
  //               right: 8,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     video.titre,
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     '${video.fullName} · ${video.classe}',
  //                     style: const TextStyle(
  //                       color: Colors.white70,
  //                       fontSize: 11,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Construire la section Événements et Faits Scolaires
  Widget _buildEventsSection() {
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;
    
    return Container(
      height: isTablet ? 200 : 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _events.length > limit
            ? limit + 1
            : _events.length + 1,
        itemBuilder: (context, index) {
          if (index < _events.length && index < limit) {
            return _buildEventCard(_events[index]);
          } else if (index == limit ||
              (index == _events.length && _events.length <= limit)) {
            return _buildSeeMoreEventsCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte d'événement
  Widget _buildEventCard(Event event) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final uiData = event.toUiMap();

    return GestureDetector(
      onTap: () {
        // Action pour voir les détails de l'événement
        _handleEventAction(event);
      },
      child: Container(
        width: _getCardWidth(context, 16.0),
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode ? AppColors.grey800 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'événement
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 95 : 65,
                width: double.infinity,
                color: Colors.grey[200],
                child: event.image != null && event.image!.isNotEmpty
                    ? Image.network(
                        event.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.event,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Icon(Icons.event, color: Colors.grey[600], size: 40),
              ),
            ),
            // Informations de l'événement
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Color(0xFF1A1A2A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.nomecole,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    uiData['date'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: uiData['color'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la carte "Voir+"
  Widget _buildSeeMoreEventsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SeeMoreCard(
      cardColor: isDarkMode ? AppColors.grey800 : const Color(0xFFF3F4F6),
      borderColor: const Color(0xFFFF7A3C),
      iconColor: Colors.white,
      textColor: const Color(0xFFFF7A3C),
      subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
      title: 'Voir+',
      subtitle: 'd\'événements',
      onTap: _handleSeeMoreEvents,
      icon: Icons.add,
      width: _getCardWidth(context, 0.0),
      height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 100 : 80,
    );
  }

  // Gérer l'action sur un événement
  void _handleEventAction(Event event) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
  }

  // Gérer l'action "Voir+"
  void _handleSeeMoreEvents() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllEventsScreen()));
  }

  // Construire la section Actualités/Blogs
  Widget _buildBlogsSection() {
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;
    
    return Container(
      height: isTablet ? 200 : 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _blogs.length > limit
            ? limit + 1
            : _blogs.length + 1,
        itemBuilder: (context, index) {
          if (index < _blogs.length && index < limit) {
            return _buildBlogCard(_blogs[index]);
          } else if (index == limit ||
              (index == _blogs.length && _blogs.length <= limit)) {
            return _buildSeeMoreBlogsCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte de blog
  Widget _buildBlogCard(Blog blog) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final uiData = blog.toUiMap();

    return GestureDetector(
      onTap: () {
        // Action pour voir les détails du blog
        _handleBlogAction(blog);
      },
      child: Container(
        width: _getCardWidth(context, 16.0),
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDarkMode ? AppColors.grey800 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du blog
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 95 : 65,
                width: double.infinity,
                color: Colors.grey[200],
                child: blog.image != null && blog.image!.isNotEmpty
                    ? Image.network(
                        blog.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.article,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Icon(Icons.article, color: Colors.grey[600], size: 40),
              ),
            ),
            // Informations du blog
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Color(0xFF1A1A2A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blog.nomecole,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    uiData['date'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: uiData['color'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la carte "Voir+" pour les blogs
  Widget _buildSeeMoreBlogsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SeeMoreCard(
      cardColor: isDarkMode ? AppColors.grey800 : const Color(0xFFF3F4F6),
      borderColor: const Color(0xFF8B5CF6),
      iconColor: Colors.white,
      textColor: const Color(0xFF8B5CF6),
      subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
      title: 'Voir+',
      subtitle: 'd\'actualités',
      onTap: _handleSeeMoreBlogs,
      icon: Icons.add,
      width: _getCardWidth(context, 0.0),
      height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 100 : 80,
    );
  }

  // Gérer l'action sur un blog
  void _handleBlogAction(Blog blog) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)));
  }

  // Gérer l'action "Voir+" pour les blogs
  void _handleSeeMoreBlogs() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllBlogsScreen()));
  }

  // Gérer l'action "Voir+" pour les vidéos
  void _handleSeeMoreVideos() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllVideosScreen()));
  }

  // Construire la section Couliste de l'Excellence
  // Helper pour calculer la largeur des cartes dynamiquement
  double _getCardWidth(BuildContext context, double rightMargin) {
    final isTablet = AppDimensions.isTablet(context) ||
        AppDimensions.isLargeTablet(context) ||
        AppDimensions.isDesktop(context);
    if (isTablet) {
      final availableWidth = MediaQuery.of(context).size.width - 32.0; // padding 16 left, 16 right
      return (availableWidth / 5.2) - rightMargin;
    }
    return 120.0;
  }

  Widget _buildCoulisteSection() {
    if (_coulisseVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    return Container(
      height: isTablet ? 200 : 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _coulisseVideos.length > limit
            ? limit + 1
            : _coulisseVideos.length + 1,
        itemBuilder: (context, index) {
          if (index < _coulisseVideos.length && index < limit) {
            return _buildVideoCard(_coulisseVideos[index]);
          } else if (index == limit ||
              (index == _coulisseVideos.length &&
                  _coulisseVideos.length <= limit)) {
            return _buildSeeMoreVideosCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte d'école
  Widget _buildVideoCard(CoulisseExcellence video) {
    // Créer des données d'école d'exemple à partir des données vidéo
    final schoolData = _createSchoolDataFromVideo(video);

    return Padding(
      padding: const EdgeInsets.only(
        right: 16,
      ), // Espacement horizontal augmenté
      child: ImageMenuCardExternalTitle(
        index: 0,
        cardKey: 'school_${video.id}',
        title: schoolData['title'] as String,
        subtitle: schoolData['subtitle'] as String,
        imagePath: schoolData['imagePath'] as String?,
        iconData: Icons.business,
        isDark: Theme.of(context).brightness == Brightness.dark,
        color: schoolData['color'] as Color,
        //location: schoolData['location'] as String?, // Permettre null
        //tag: schoolData['tag'] as String?, // Permettre null
        titleMaxLines: 1,
        externalTitleSpacing: 4,
        height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 180 : 140, // Hauteur réduite pour éviter l'overflow
        width: _getCardWidth(context, 16.0),
        allowLineBreak: false,
        centerTitle: false,
        showPlayIcon: true, // Activer l'icône de play pour les vidéos
        onTap: () {
          // Action pour voir les détails de l'école
          _handleSchoolAction(schoolData);
        },
      ),
    );
  }

  // Créer des données d'école à partir des données vidéo
  Map<String, dynamic> _createSchoolDataFromVideo(CoulisseExcellence video) {
    // Classe optionnelle : afficher seulement si la classe est disponible et selon une logique
    final shouldShowClass =
        video.classe.isNotEmpty &&
        (video.id % 2) ==
            0; // 1 chance sur 2 d'afficher la classe si disponible
    final shouldShowLocation =
        (video.id % 3) == 0; // 1 chance sur 3 d'afficher la localisation

    return {
      'title': video.titre.isNotEmpty ? video.titre : 'École Excellence',
      'subtitle': video.description.isNotEmpty
          ? video.description
          : 'Établissement scolaire',
      'imagePath': video.videoYoutube.isNotEmpty
          ? 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg'
          : null,
      'color': _getRandomSchoolColor(video.id.hashCode),
      'location': shouldShowLocation ? 'Paris, France' : null,
      'tag': shouldShowClass
          ? video.classe
          : null, // Utiliser la classe réelle de l'élève
    };
  }

  // Obtenir une couleur aléatoire pour l'école
  Color _getRandomSchoolColor(int seed) {
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFFF59E0B), // Ambre
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[seed % colors.length];
  }

  // Gérer l'action sur une école (lire la vidéo)
  void _handleSchoolAction(Map<String, dynamic> schoolData) {
    // Trouver la vidéo correspondante dans la liste
    final videoIndex = _coulisseVideos.indexWhere(
      (video) => video.titre == schoolData['title'] as String,
    );

    if (videoIndex != -1) {
      // Naviguer vers l'écran de lecture vidéo
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoulisseVideoFeedScreen(
            videos: _coulisseVideos,
            initialIndex: videoIndex,
          ),
        ),
      );
    } else {
      // Afficher un message si la vidéo n'est pas trouvée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vidéo non trouvée: ${schoolData['title']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Construire la carte "Voir+" pour les vidéos
  Widget _buildSeeMoreVideosCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        right: 16,
      ), // Espacement horizontal cohérent
      child: SeeMoreCard(
        cardColor: isDarkMode
            ? const Color.fromARGB(255, 0, 0, 0)
            : const Color(0xFFF3F4F6),
        borderColor: const Color(0xFF10B981),
        iconColor: Colors.white,
        textColor: const Color(0xFF10B981),
        subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
        title: 'Voir+',
        subtitle: 'de vidéos',
        onTap: _handleSeeMoreVideos,
        icon: Icons.play_arrow,
        width: _getCardWidth(context, 16.0),
        height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 120 : 100,
      ),
    );
  }

  // Construire la section Visite guidée
  Widget _buildVisiteGuideeSection() {
    if (!_hasVisiteGuideeData) {
      return const SizedBox.shrink();
    }

    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    return Container(
      height: isTablet ? 200 : 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _visiteGuideeVideos.length > limit
            ? limit + 1
            : _visiteGuideeVideos.length + 1,
        itemBuilder: (context, index) {
          if (index < _visiteGuideeVideos.length && index < limit) {
            return _buildVisiteGuideeCard(_visiteGuideeVideos[index], index);
          } else if (index == limit ||
              (index == _visiteGuideeVideos.length &&
                  _visiteGuideeVideos.length <= limit)) {
            return _buildSeeMoreVisiteGuideeCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire la carte "Voir+" pour la visite guidée
  Widget _buildSeeMoreVisiteGuideeCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SeeMoreCard(
      cardColor: isDarkMode ? AppColors.grey800 : const Color(0xFFF3F4F6),
      borderColor: const Color(0xFF3B82F6),
      iconColor: Colors.white,
      textColor: const Color(0xFF3B82F6),
      subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
      title: 'Voir+',
      subtitle: 'de visites',
      onTap: _handleSeeMoreVisiteGuidee,
      icon: Icons.play_circle_outline,
      width: _getCardWidth(context, 0.0),
      height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 100 : 80,
    );
  }

  // Construire une carte pour la visite guidée
  Widget _buildVisiteGuideeCard(Video video, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: 'visite_${video.youtubeVideoId}',
        title: video.title,
        subtitle: _formatDate(video.createdAt),
        imagePath:
            'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg',
        iconData: Icons.play_circle_outline,
        color: const Color(0xFF3B82F6),
        titleMaxLines: 2,
        externalTitleSpacing: 4,
        height: (AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context)) ? 180 : 140,
        width: _getCardWidth(context, 16.0),
        allowLineBreak: true,
        centerTitle: false,
        showPlayIcon: true,
        onTap: () {
          _handleVisiteGuideeAction(video);
        },
      ),
    );
  }

  Future<void> _updatePhotosInBackground(List<Child> children) async {
    final poulsApiService = PoulsScolaireApiService();
    for (final child in children) {
      if ((child.photoUrl == null || child.photoUrl!.isEmpty) &&
          child.id.isNotEmpty) {
        try {
          final childInfo = await DatabaseService.instance.getChildInfoById(
            child.id,
          );
          if (childInfo != null) {
            final ecoleId = childInfo['ecoleId'] as int?;
            final matricule = childInfo['matricule'] as String?;
            if (ecoleId != null && matricule != null) {
              final anneeScolaire = await poulsApiService
                  .getAnneeScolaireOuverte(ecoleId);
              final anneeId = anneeScolaire.anneeOuverteCentraleId;
              final eleve = await poulsApiService.findEleveByMatricule(
                ecoleId,
                anneeId,
                matricule,
              );
              if (eleve != null &&
                  eleve.urlPhoto != null &&
                  eleve.urlPhoto!.isNotEmpty) {
                await DatabaseService.instance.updateChildPhoto(
                  child.id,
                  eleve.urlPhoto,
                );
                if (!mounted) return;
                setState(() {
                  final index = _children.indexWhere((c) => c.id == child.id);
                  if (index >= 0) {
                    _children[index] = Child(
                      id: child.id,
                      firstName: child.firstName,
                      lastName: child.lastName,
                      establishment: child.establishment,
                      grade: child.grade,
                      photoUrl: eleve.urlPhoto,
                      parentId: child.parentId,
                    );
                    final fi = _filteredChildren.indexWhere(
                      (c) => c.id == child.id,
                    );
                    if (fi >= 0) _filteredChildren[fi] = _children[index];
                  }
                });
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // ── Dark top section ──
            _buildDarkHeader(),
            // ── Light bottom sheet ──
            Expanded(child: _buildBottomSheet()),
          ],
        ),
      ),
    );
  }

  // ─── DARK HEADER SECTION ───────────────────────────────────────────────────
  Widget _buildDarkHeader() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildAlertBanner(),
            _buildChildrenSection(),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/logo-app.png',
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: _kOrange,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getGreeting()}, ${AuthService.instance.getCurrentUser()?.firstName ?? ''}',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(24),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              // Bouton recherche
              _darkIconButton(
                icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                onTap: _toggleSearch,
              ),
              const SizedBox(width: 8),
              // Bouton partage
              _darkIconButton(
                icon: Icons.share_outlined,
                onTap: _showShareMenu,
              ),
              const SizedBox(width: 8),
              // Bouton notifications
              _darkIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {},
                showBadge: _unreadNotificationsCount > 0,
                badgeCount: _unreadNotificationsCount,
              ),
              const SizedBox(width: 8),
              // User avatar
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_kOrange, _kOrangeDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: _textSizeService.getScaledFontSize(13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _darkIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.homeTopCard(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: AppColors.homeTextPrimary(context),
            ),
          ),
        ),
        if (showBadge && badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.homeBg(context),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── ALERT BANNER ──────────────────────────────────────────────────────────
  Widget _buildAlertBanner() {
    if (_presenceBannerLoading) {
      return const SizedBox.shrink();
    }

    if (_presenceBannerItems.isEmpty) {
      _stopPresenceAutoScroll();
      return const SizedBox.shrink();
    }

    _ensurePresencePagerReady();
    _startPresenceAutoScrollIfNeeded();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          height: 54,
          child: PageView.builder(
            controller: _presencePageController,
            itemCount: _presenceBannerItems.length,
            onPageChanged: (index) {
              _presencePageIndex.value = index;
            },
            itemBuilder: (context, index) {
              final item = _presenceBannerItems[index];
              return _buildPresenceBannerItem(item);
            },
          ),
        ),
        _buildPresenceCarouselIndicators(),
      ],
    );
  }

  Widget _buildPresenceBannerItem(_PresenceBannerItem item) {
    final titlePrefix = item.isPresence
        ? 'Présence signalée'
        : 'Absence signalée';
    final grade = item.child.grade;
    final enfant = item.child.firstName.isNotEmpty
        ? item.child.firstName
        : (item.entry.prenomEleve ?? '');
    final matiere = item.entry.matiere ?? '';

    final debutDate = _tryParseApiDate(item.entry.debut);
    final timeLabel = debutDate == null
        ? ''
        : _isSameDate(debutDate, DateTime.now())
        ? 'Aujourd\'hui'
        : '${debutDate.day.toString().padLeft(2, '0')}/${debutDate.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: AppColors.homeAlertBorder(context),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: item.isPresence ? Colors.greenAccent : _kOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$titlePrefix — $enfant, $grade',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 0),
                  Text(
                    matiere.isNotEmpty
                        ? '$matiere · ${timeLabel.isEmpty ? '' : '$timeLabel · '}${item.child.establishment}'
                        : '${timeLabel.isEmpty ? '' : '$timeLabel · '}${item.child.establishment}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _textSizeService.getScaledFontSize(10),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _dismissedPresenceBannerItemKeys.add(item.key);
                  _presenceBannerItems.removeWhere((i) => i.key == item.key);
                });
                if (_presenceBannerItems.length <= 1) {
                  _stopPresenceAutoScroll();
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceCarouselIndicators() {
    if (_presenceBannerItems.length <= 1) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int>(
      valueListenable: _presencePageIndex,
      builder: (context, currentIndex, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _presenceBannerItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: currentIndex == index ? 18 : 6,
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? AppColors.homeTextSecondary(context)
                    : AppColors.homeTextSecondary(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildrenCarouselIndicators() {
    if (_filteredChildren.length <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedChildIndexNotifier,
        builder: (context, currentIndex, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _filteredChildren.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: currentIndex == index ? 18 : 6,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? AppColors.homeTextSecondary(context)
                      : AppColors.homeTextSecondary(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ─── SEARCH BAR ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: _isSearching
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.homeTopCard(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.homeTopBorder(context)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search_rounded,
                color: AppColors.homeTextSecondary(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: AppColors.homeTextPrimary(context),
                    fontSize: _textSizeService.getScaledFontSize(13),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou ecole...',
                    hintStyle: TextStyle(
                      color: AppColors.homeTextSecondary(context),
                      fontSize: _textSizeService.getScaledFontSize(13),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.homeTextSecondary(context),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SHARE MENU ────────────────────────────────────────────────────────────
  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Partager l\'application',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(17),
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invitez vos amis a suivre leurs enfants',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(12),
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shareButton(
                  label: 'Mail',
                  icon: Icons.email_rounded,
                  bg: const Color(0xFFFFEEEE),
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _handleShareAction('mail');
                  },
                ),
                const SizedBox(width: 12),
                _shareButton(
                  label: 'WhatsApp',
                  icon: null,
                  imageAsset: 'assets/images/icons/whatsapp.png',
                  bg: const Color(0xFFEAF7EE),
                  iconColor: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    _handleShareAction('whatsapp');
                  },
                ),
                const SizedBox(width: 12),
                _shareButton(
                  label: 'Facebook',
                  icon: Icons.facebook_rounded,
                  bg: const Color(0xFFE8F0FE),
                  iconColor: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    _handleShareAction('facebook');
                  },
                ),
                const SizedBox(width: 12),
                _shareButton(
                  label: 'Autre',
                  icon: Icons.more_horiz_rounded,
                  bg: _kSheetBg,
                  iconColor: _kTextSecondary,
                  onTap: () {
                    Navigator.pop(context);
                    _handleShareAction('other');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareButton({
    required String label,
    IconData? icon,
    String? imageAsset,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(15),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              color: _kTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleShareAction(String action) async {
    const appUrl =
        'https://play.google.com/store/apps/details?id=com.pouls.ecole';
    const shareText =
        'Decouvrez Pouls Ecole, l\'application qui vous permet de suivre le parcours scolaire de vos enfants en temps reel !';
    switch (action) {
      case 'mail':
        final subject = Uri.encodeComponent('Decouvrez Pouls Ecole');
        final body = Uri.encodeComponent(
          '$shareText\n\nTelechargez l\'application ici : $appUrl',
        );
        final uri = Uri.parse('mailto:?subject=$subject&body=$body');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune application email trouvee'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'whatsapp':
        final uri = Uri(
          scheme: 'https',
          host: 'wa.me',
          queryParameters: {
            'text': '$shareText\n\nTelechargez l\'application ici : $appUrl',
          },
        );
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
      case 'facebook':
        final uri = Uri(
          scheme: 'https',
          host: 'www.facebook.com',
          path: 'sharer/sharer.php',
          queryParameters: {'u': appUrl, 'quote': shareText},
        );
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
      case 'other':
        await Share.share(
          '$shareText\n\nTelechargez l\'application ici : $appUrl',
          subject: 'Decouvrez Pouls Ecole',
        );
        break;
    }
  }

  // ─── CHILDREN SECTION ──────────────────────────────────────────────────────
  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SectionRow(
          title: 'MES ENFANTS',
          onSeeMore: _filteredChildren.length > 4
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllChildrenScreen(),
                    ),
                  );
                }
              : null,
          seeMoreText: 'Voir plus',
          seeMoreBackgroundColor: const Color.fromARGB(
            255,
            255,
            255,
            255,
          ).withOpacity(0.15),
          seeMoreTextColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: AppDimensions.getChildImageSize(context) + 48,
          child: Row(
            children: [
              // ── Liste scrollable des enfants ──
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 4, 0),
                  children: _filteredChildren
                      .asMap()
                      .entries
                      .map((e) => _buildChildAvatar(e.value, e.key))
                      .toList(),
                ),
              ),
              // ── Séparateur vertical ──
              // Container(
              //   width: 1,
              //   height: 52,
              //   margin: const EdgeInsets.symmetric(horizontal: 4),
              //   color: _kDarkBorder,
              // ),
              // // ── Bouton Nouveau toujours visible ──
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: _buildAddChildButton(),
              ),
            ],
          ),
        ),
        _buildChildrenCarouselIndicators(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChildAvatar(Child child, int index) {
    final isSelected = index == _selectedChildIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChildIndex = index;
          _selectedChildIndexNotifier.value = index;
        });
        MainScreenWrapper.of(context).navigateToChildDetail(child);
      },
      child: Container(
        width: AppDimensions.getChildImageSize(context) + 16,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: AppDimensions.getChildImageSize(context),
                  height: AppDimensions.getChildImageSize(context),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kDarkCard,
                    border: Border.all(
                      color: isSelected ? _kOrange : _kDarkBorder,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                        ? Image.network(
                            child.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultChildIcon(),
                          )
                        : _defaultChildIcon(),
                  ),
                ),
                // Badge de notification dynamique
                if (getNotificationCountForChild(child) > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: EdgeInsets.all(
                        AppDimensions.getNotificationBadgeSize(context) * 0.125,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kDarkBg, width: 2),
                      ),
                      constraints: BoxConstraints(
                        minWidth: AppDimensions.getNotificationBadgeSize(
                          context,
                        ),
                        minHeight: AppDimensions.getNotificationBadgeSize(
                          context,
                        ),
                      ),
                      child: Text(
                        getNotificationCountForChild(child) > 9
                            ? '9+'
                            : getNotificationCountForChild(child).toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppDimensions.getNotificationBadgeTextSize(
                            context,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              child.firstName,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppDimensions.getChildNameTextSize(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              child.grade.isNotEmpty ? child.grade : '---',
              style: TextStyle(
                color: _kOrange,
                fontSize: AppDimensions.getChildGradeTextSize(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultChildIcon() {
    return Container(
      color: const Color(0xFF22223A),
      child: const Icon(Icons.person, color: Color(0xFF8A8AFF), size: 26),
    );
  }

  Widget _buildAddChildButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
        // Le résultat n'est plus nécessaire car la redirection est gérée dans AddChildScreen
      },
      child: SizedBox(
        width: AppDimensions.getChildImageSize(context) + 16,
        child: Column(
          children: [
            Container(
              width: AppDimensions.getChildImageSize(context),
              height: AppDimensions.getChildImageSize(context),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kDarkBorder,
                  width: 2,
                  style: BorderStyle
                      .solid, // dashed not directly supported; use a package for dashed
                ),
              ),
              child: Icon(
                Icons.add,
                color: const Color.fromARGB(255, 226, 226, 240),
                size: AppDimensions.getChildImageSize(context) * 0.33,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Nouveau',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: AppDimensions.getChildNameTextSize(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM SHEET (white panel) ────────────────────────────────────────────
  // ─── BOTTOM SHEET (white panel) ────────────────────────────────────────────
  Widget _buildBottomSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF14141C)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20), // ← fixe, ne scroll pas
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  SectionRow(title: 'ACTIONS RAPIDES'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height:
                        AppDimensions.getPaymentBannerCardHeight(context) + 20,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            AppDimensions.getPaymentBannerCardSpacing(context) *
                            0.9,
                      ),
                      children: [
                        _buildCard(
                          index: 0,
                          cardKey: 'inscription',
                          title: 'Inscription \n en ligne',
                          imagePath: 'assets/images/icons/inscription.png',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFF8FCFF),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          allowLineBreak: true,
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          innerBorderColor: const Color(0xFF93C5FD),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () => InscriptionBottomSheet.show(context),
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 1,
                          cardKey: 'integration',
                          title: 'Demande\nintégration',
                          imagePath: 'assets/images/icons/integration.png',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFF7FEFC),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          allowLineBreak: true,
                          innerBorderColor: const Color(0xFF6EE7B7),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const IntegrationBottomSheet(),
                          ),
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 2,
                          cardKey: 'consulter_demande',
                          title: 'Consulter\ndemande',
                          imagePath: 'assets/images/icons/consulter.png',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFFFFEF7),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          allowLineBreak: true,
                          innerBorderColor: const Color(0xFFFCD34D),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () =>
                              IntegrationRequestBottomSheet.show(context),
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 3,
                          cardKey: 'parrainage',
                          title: 'Parrainer\nutilisateur',
                          imagePath: 'assets/images/icons/parrainer.png',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFFCFAFF),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          allowLineBreak: true,
                          enableOuterBorder: false,
                          innerBorderColor: const Color(0xFFC4B5FD),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () => showSponsorshipBottomSheet(context),
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 4,
                          cardKey: 'panier',
                          title: 'Mon\npanier',
                          imagePath: 'assets/images/mon-panier.jpg',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFFCFAFF),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          allowLineBreak: true,
                          innerBorderColor: const Color(0xFFFB923C),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 5,
                          cardKey: 'commandes',
                          title: 'Mes\ncommandes',
                          imagePath: 'assets/images/mes-commandes.jpg',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFFCFAFF),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          allowLineBreak: true,
                          innerBorderColor: const Color(0xFF34D399),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          width: AppDimensions.getPaymentBannerCardSpacing(
                            context,
                          ),
                        ),
                        _buildCard(
                          index: 6,
                          cardKey: 'recommendation',
                          title: 'Recommand-\ner une école',
                          imagePath: 'assets/images/recommander.jpg',
                          color: AppColors.cardLightGrey,
                          backgroundColor: const Color(0xFFFCFAFF),
                          textColor: const Color(0xFF333333),
                          actionText: '',
                          enableInnerBorder: false,
                          enableOuterBorder: false,
                          allowLineBreak: true,
                          innerBorderColor: const Color(0xFFFDBA74),
                          imageBorderRadius: AppDimensions.getImageBorderRadius(
                            context,
                          ),
                          width: AppDimensions.getSquareCardWidthSize(context),
                          height: AppDimensions.getSquareCardHeightSize(
                            context,
                          ),
                          centerTitle: true,
                          onTap: _showRecommendationBottomSheet,
                        ),
                      ],
                    ),
                  ),

                  // Section Coulisses de l'Excellence
                  if (_hasCoulisseExcellenceData) ...[
                    const SizedBox(height: 12),
                    SectionRow(
                      title: 'COULISSES DE L\'EXCELLENCE',
                      onSeeMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllVideosScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCoulisteSection(),
                  ],

                  // Section Événements et Faits Scolaires
                  if (_hasEventsData) ...[
                    const SizedBox(height: 12),
                    SectionRow(
                      title: 'ÉVÉNEMENTS ET FAITS SCOLAIRES',
                      onSeeMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllEventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEventsSection(),
                  ],

                  // Section Actualités
                  if (_hasBlogsData)
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        SectionRow(title: 'ACTUALITÉS'),
                        const SizedBox(height: 16),
                        _buildBlogsSection(),
                      ],
                    ),

                  // Section Visite guidée
                  const SizedBox(height: 24),
                  SectionRow(title: 'VISITE GUIDÉE'),
                  const SizedBox(height: 16),
                  _buildVisiteGuideeSection(),

                  const SizedBox(height: 125),
                ],
              ),
            ),
          ),
          const BottomFadeGradient(),
        ],
      ),
    );
  }

  // ─── CARD BUILDER (wrapper ImageMenuCardExternalTitle) ─────────────────────
  Widget _buildCard({
    required int index,
    required String cardKey,
    required String title,
    required String imagePath,
    required Color color,
    required Color backgroundColor,
    required Color textColor,
    required String actionText,
    required VoidCallback onTap,
    bool enableInnerBorder = false,
    bool enableOuterBorder = false,
    Color? innerBorderColor,
    double imageBorderRadius = 14,
    double width = 100,
    double height = 100,
    double doubleBorderGap = 1.0,
    bool centerTitle = false,
    bool allowLineBreak = false,
  }) {
    final isDark = _themeService.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageMenuCardExternalTitle(
          index: index,
          cardKey: cardKey,
          title: title,
          width: width,
          height: height,
          imageFlex: 2,
          imagePath: imagePath,
          isDark: isDark,
          titleFontSize: AppDimensions.getBottomSheetCardTextSize(context),
          imageBorderRadius: imageBorderRadius,
          doubleBorderGap: doubleBorderGap,
          color: color,
          backgroundColor: isDark
              ? backgroundColor.withOpacity(0.15)
              : backgroundColor,
          textColor: isDark ? color.withOpacity(0.75) : textColor,
          actionText: actionText,
          //actionTextColor: color,
          onTap: onTap,
          enableInnerBorder: enableInnerBorder,
          enableOuterBorder: enableOuterBorder,
          innerBorderColor: innerBorderColor,
          centerTitle: centerTitle,
          allowLineBreak: allowLineBreak,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // ─── FILTER ROW ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: _filters.map((f) {
          final isActive = f == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? _kChipActive : _kChipBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isActive ? Colors.white : _kTextSecondary,
                  fontSize: _textSizeService.getScaledFontSize(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── HELPER FUNCTIONS ───────────────────────────────────────────────────────
  String _getUserInitials() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) return 'AK';

    final firstName = currentUser.firstName?.trim() ?? '';
    final lastName = currentUser.lastName?.trim() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName.substring(0, 1).toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName.substring(0, 1).toUpperCase();
    }

    return 'AK';
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredChildren = List.from(_children);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredChildren = List.from(_children));
      return;
    }
    final lq = query.toLowerCase();
    setState(() {
      _filteredChildren = _children.where((c) {
        final name = '${c.firstName} ${c.lastName}'.toLowerCase();
        return name.contains(lq) || c.establishment.toLowerCase().contains(lq);
      }).toList();
    });
  }

  // ─── DATE AND GREETING METHODS ─────────────────────────────────────────────
  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    final dayName = days[now.weekday - 1];
    final dayNumber = now.day;
    final monthName = months[now.month - 1];

    return '$dayName $dayNumber $monthName';
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      return 'Bonjour';
    } else if (hour >= 12 && hour < 18) {
      return 'Bonjour';
    } else if (hour >= 18 && hour < 22) {
      return 'Bonsoir';
    } else {
      return 'Bonsoir';
    }
  }
}
