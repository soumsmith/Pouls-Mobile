import 'dart:async';
import 'dart:io';
import 'package:parents_responsable/config/app_config.dart';

import 'dart:ui';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../widgets/bottom_sheets/reusable_bottom_sheet.dart';
import '../widgets/privilege_guard.dart';
import '../widgets/module_guard.dart';
import '../services/module_access_service.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parents_responsable/screens/all_children_screen.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/models/video.dart';
import 'package:parents_responsable/services/video_service.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_request_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/sponsorship_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/components/bottom_spacer.dart';
import '../config/app_dimensions.dart';
import '../models/child.dart';
import '../models/gestion_presence_eleve_entry.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/gestion_presence_eleve_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/notification_service.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/integration_request_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_guard.dart';
import '../utils/notification_helper.dart';
import '../services/recommendation_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_loader.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/conditional_showcase.dart';
import '../config/app_colors.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/components/section_row.dart';
import '../widgets/components/custom_error_state.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
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
import '../widgets/scroll_to_top_fab.dart';
import '../services/astuce_conseil_service.dart';
import '../models/astuce_conseil.dart';
import 'tips_advice_screen.dart';
import 'tips_advice_detail_screen.dart';
import '../widgets/ad_widget.dart';
import '../widgets/home_ad_banner.dart';
import '../services/version_update_service.dart';
import '../models/version_check_result.dart';
import '../widgets/version_update_dialog.dart';
import 'force_update_screen.dart';

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

class _FlashInfoItem {
  final int id;
  final String content;
  final String slug;
  final String type;
  final String startDate;
  final String endDate;

  const _FlashInfoItem({
    required this.id,
    required this.content,
    required this.slug,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  factory _FlashInfoItem.fromJson(Map<String, dynamic> json) {
    return _FlashInfoItem(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _AnimatedEmptyChildrenMessage extends StatefulWidget {
  const _AnimatedEmptyChildrenMessage({super.key});

  @override
  State<_AnimatedEmptyChildrenMessage> createState() =>
      _AnimatedEmptyChildrenMessageState();
}

class _AnimatedEmptyChildrenMessageState
    extends State<_AnimatedEmptyChildrenMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLevel =
        AuthService.instance.getCurrentUser()?.userLevel ?? 'free';
    final isPremium = userLevel == 'premium' || userLevel == 'vip';

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      !isPremium
                          ? 'Aucun enfant pour le moment'
                          : 'Débloquez le suivi scolaire',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            AppDimensions.getChildNameTextSize(context) + 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !isPremium
                          ? 'Commencez à suivre leur parcours'
                          : 'Passez Premium pour ajouter vos enfants',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize:
                            AppDimensions.getChildNameTextSize(context) - 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Transform.translate(
                offset: Offset(_animation.value, 0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();
  final GlobalKey _four = GlobalKey();
  final GlobalKey _five = GlobalKey();
  bool _hasCheckedTutorial = false;

  Future<void> _checkAndStartTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenHomeTutorial') ?? false;
    if (!hasSeenTutorial) {
      await prefs.setBool('hasSeenHomeTutorial', true);
      final bottomNavKey = MainScreenWrapper.maybeOf(context)?.bottomNavKey;
      final keys = [_one, _two, _three, _five, _four];
      if (bottomNavKey != null) keys.add(bottomNavKey);
      ShowCaseWidget.of(context).startShowCase(keys);
    }
  }

  void forceReplayTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenHomeTutorial', false);
    setState(() {
      _hasCheckedTutorial = false;
    });
  }

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
  bool _hasUpdateNotification = false;
  String _activeFilter = 'Tout';
  int _selectedChildIndex = 0;
  final ValueNotifier<int> _selectedChildIndexNotifier = ValueNotifier<int>(0);

  // Variables pour les notifications par enfant
  Map<String, List<GroupMessage>> _childrenNotifications = {};
  Map<String, EcheanceNotification?> _childrenEcheances = {};
  Map<String, bool> _childrenNotificationsLoading = {};
  Map<String, bool> _childrenEcheancesLoading = {};

  List<_FlashInfoItem> _presenceBannerItems = [];
  final Set<String> _dismissedPresenceBannerItemKeys = {};
  bool _presenceBannerLoading = false;
  PageController? _presencePageController;
  Timer? _presenceAutoScrollTimer;
  final ValueNotifier<int> _presencePageIndex = ValueNotifier<int>(0);

  // Variables pour les vidéos Coulisses de l'Excellence
  List<CoulisseExcellence> _coulisseVideos = [];
  List<CoulisseExcellence> _filteredCoulisseVideos = [];
  bool _coulisseVideosLoading = true;
  String? _coulisseVideosError;

  bool get _hasCoulisseExcellenceData =>
      !_coulisseVideosLoading &&
      _coulisseVideosError == null &&
      _filteredCoulisseVideos.isNotEmpty;

  // Variables pour les événements
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _eventsLoading = true;
  String? _eventsError;

  bool get _hasEventsData =>
      !_eventsLoading && _eventsError == null && _filteredEvents.isNotEmpty;

  // Variables pour les blogs/actualités
  List<Blog> _blogs = [];
  List<Blog> _filteredBlogs = [];
  bool _blogsLoading = true;
  String? _blogsError;

  bool get _hasBlogsData =>
      !_blogsLoading && _blogsError == null && _filteredBlogs.isNotEmpty;

  final List<String> _filters = ['Tout', 'Alertes', 'Paiements', 'Notes'];

  // Variables pour les vidéos de visite guidée
  List<Video> _visiteGuideeVideos = [];
  List<Video> _filteredVisiteGuideeVideos = [];
  bool _visiteGuideeVideosLoading = true;
  String? _visiteGuideeVideosError;

  bool get _hasVisiteGuideeData =>
      !_visiteGuideeVideosLoading &&
      _visiteGuideeVideosError == null &&
      _filteredVisiteGuideeVideos.isNotEmpty;

  // Variables pour Astuces et Conseils
  List<AstuceConseil> _astuces = [];
  List<AstuceConseil> _filteredAstuces = [];
  bool _astucesLoading = true;
  String? _astucesError;

  bool get _hasAstucesData =>
      !_astucesLoading && _astucesError == null && _filteredAstuces.isNotEmpty;

  @override
  void initState() {
    super.initState();
    ConnectivityService().onReconnect(_onReconnect);
    _textSizeService.addListener(() {
      if (mounted) setState(() {});
    });
    _loadChildren();
    _loadUnreadNotificationsCount();
    _checkAppUpdate();
    _loadChildrenNotifications(); // Charger les notifications pour chaque enfant
    _loadCoulisseVideos(); // Charger les vidéos Coulisses de l'Excellence
    _loadEvents(); // Charger les événements
    _loadBlogs(); // Charger les blogs/actualités
    _loadVisiteGuideeVideos(); // Ajouter cette ligne
    _loadAstuces(); // Charger les astuces/conseils
    _startPresenceAutoScrollIfNeeded();
  }

  Future<void> _refreshHome() async {
    await _loadChildren();
    await Future.wait([
      _loadUnreadNotificationsCount(),
      _checkAppUpdate(),
      _loadCoulisseVideos(),
      _loadEvents(),
      _loadVisiteGuideeVideos(), // Ajouter cette ligne
      _loadBlogs(),
      _loadAstuces(),
    ]);
    await _loadChildrenNotifications();
    await _loadChildrenPresenceSignals();
  }

  @override
  void dispose() {
    ConnectivityService().removeReconnectCallback(_onReconnect);
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

  void _onReconnect() {
    if (mounted) {
      print('🌐 [HomeScreen] Reconnexion détectée, rafraîchissement global...');
      _refreshHome();
    }
  }

  Future<void> _loadChildrenPresenceSignals() async {
    print('=== DÉBUT CHARGEMENT FLASH INFOS ===');
    if (_presenceBannerLoading) return;

    if (mounted) {
      setState(() {
        _presenceBannerLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/flash-infos',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final items = data
            .map((json) => _FlashInfoItem.fromJson(json))
            .toList();

        final visibleItems = items
            .where(
              (i) =>
                  !_dismissedPresenceBannerItemKeys.contains(i.id.toString()),
            )
            .toList();

        print('🎯 Flash Infos visibles: ${visibleItems.length}');

        if (!mounted) return;
        setState(() {
          _presenceBannerItems = visibleItems;
          _presenceBannerLoading = false;
        });
        _ensurePresencePagerReady();
        _startPresenceAutoScrollIfNeeded();
      } else {
        throw Exception('API error code: ${response.statusCode}');
      }
      print('=== FIN CHARGEMENT FLASH INFOS ===');
    } catch (e) {
      print('❌ Erreur globale chargement Flash Infos: $e');
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
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecommendationBottomSheet(
        icon: Icons.recommend_rounded,
        imagePath: 'assets/images/icons/recommander_une_ecole.png',
        imageBackgroundColor: const Color(0xFFFCFAFF),
        imageBorderRadius: AppDimensions.getImageBorderRadius(context),
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
            NotificationHelper.showSuccess('Recommandation envoyée avec succès!');

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
            NotificationHelper.showError('Erreur: $e');
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

  Future<void> _checkAppUpdate() async {
    try {
      final updateResult = await VersionUpdateService.checkForUpdate();
      if (updateResult != null && updateResult.updateAvailable) {
        if (mounted) {
          setState(() {
            _hasUpdateNotification = true;
          });
        }
      }
    } catch (e) {
      // Ignorer l'erreur silencieusement
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      MainScreenWrapper.of(context).refreshCurrentUser();
      final user = AuthService.instance.getCurrentUser();
      final parentId = user?.id ??
          MainScreenWrapper.of(context).currentUserId ??
          'parent1';
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
    final visiteVideos = _visiteGuideeVideos.map((v) {
      print(
        '🔄 Mapping Video→VisiteGuideeVideo - id: ${v.id}, code: "${v.code}", etablissement: "${v.etablissement}"',
      );
      return VisiteGuideeVideo(
        id: v.id,
        typeVideo: v.typevideo,
        youtubeUrl: v.youtubeUrl,
        title: v.title,
        description: v.description,
        code: v.code,
        etablissement: v.etablissement,
      );
    }).toList();

    // Naviguer vers l'écran de visualisation des vidéos
    MainScreenWrapper.of(context).navigateToExtraScreen(
      VisiteGuideeVideoFeedScreen(
        videos: visiteVideos,
        initialIndex: videoIndex >= 0 ? videoIndex : 0,
      ),
    );
  }

  // Gérer l'action "Voir+" pour les vidéos de visite guidée
  void _handleSeeMoreVisiteGuidee() {
    MainScreenWrapper.of(context).navigateToExtraScreen(
      AllVisiteGuideeVideosScreen(videos: _visiteGuideeVideos, ecoleCode: ''),
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

      // Charger les notifications d'échéance (Désactivé)
      if (mounted) {
        setState(() {
          _childrenEcheances[child.id] = null;
          _childrenEcheancesLoading[child.id] = false;
        });
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
          _filteredCoulisseVideos = List.from(videos);
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
          _filteredVisiteGuideeVideos = List.from(videos);
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
          _filteredEvents = List.from(events);
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
          _filteredBlogs = List.from(blogs);
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

  // Charger les astuces/conseils depuis l'API
  Future<void> _loadAstuces() async {
    if (mounted) {
      setState(() {
        _astucesLoading = true;
        _astucesError = null;
      });
    }
    try {
      final response = await AstuceConseilService().getAstucesConseils();
      if (mounted) {
        setState(() {
          _astuces = response.data;
          _filteredAstuces = List.from(response.data);
          _astucesLoading = false;
          _astucesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _astucesLoading = false;
          _astucesError = e.toString();
        });
      }
    }
  }

  // Construire la section Événements et Faits Scolaires
  Widget _buildEventsSection() {
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;
    final double textHeight = AppDimensions.getScaledSize(context, 85.0);
    final double containerHeight = imageHeight + textHeight;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredEvents.length > limit
            ? limit + 1
            : _filteredEvents.length + 1,
        itemBuilder: (context, index) {
          if (index < _filteredEvents.length && index < limit) {
            return _buildEventCard(_filteredEvents[index], index);
          } else if (index == limit ||
              (index == _filteredEvents.length &&
                  _filteredEvents.length <= limit)) {
            return _buildSeeMoreEventsCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte d'événement
  Widget _buildEventCard(Event event, int index) {
    final uiData = event.toUiMap();
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    String? typeBilleterie;
    Color? tagColor;
    if (uiData['typebilleterie'] != null &&
        (uiData['typebilleterie'] as String).toLowerCase() != 'non_defini') {
      typeBilleterie = (uiData['typebilleterie'] as String).toUpperCase();
      tagColor = typeBilleterie.toLowerCase() == 'gratuit'
          ? Colors.green
          : Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: 'event_${event.id ?? event.slug}',
        title: event.title,
        subtitle: event.nomecole,
        actionText: uiData['date'] as String,
        actionTextColor: AppColors.screenTextSecondaryThemed(context),
        actionTextFontSize: 11.0,
        tag: typeBilleterie,
        color: tagColor ?? (uiData['color'] as Color),
        imagePath: event.image,
        iconData: Icons.event,
        titleMaxLines: 2,
        externalTitleSpacing: 4,
        titleFontSize: isTablet ? 16.0 : 14.0,
        subtitleFontSize: 11.0,
        height: null,
        imageHeight: _getCardWidth(context, 16.0) * (isTablet ? 0.62 : 0.8),
        width: _getCardWidth(context, 16.0),
        allowLineBreak: true,
        centerTitle: false,
        showPlayIcon: false,
        onTap: () {
          _handleEventAction(event);
        },
      ),
    );
  }

  // Construire la carte "Voir+"
  Widget _buildSeeMoreEventsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: SeeMoreCard(
          cardColor: isDarkMode ? AppColors.grey800 : Colors.white,
          borderColor: const Color(0xFFFF7A3C),
          iconColor: Colors.white,
          textColor: const Color(0xFFFF7A3C),
          subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          title: 'Voir+',
          subtitle: 'd\'événements',
          onTap: _handleSeeMoreEvents,
          icon: Icons.add,
          width: cardWidth,
          height: imageHeight * 1.15,
        ),
      ),
    );
  }

  // Gérer l'action sur un événement
  void _handleEventAction(Event event) {
    MainScreenWrapper.of(
      context,
    ).navigateToExtraScreen(EventDetailScreen(event: event));
  }

  // Gérer l'action "Voir+"
  void _handleSeeMoreEvents() {
    MainScreenWrapper.of(
      context,
    ).navigateToExtraScreen(const AllEventsScreen());
  }

  // Construire la section Actualités/Blogs
  Widget _buildBlogsSection() {
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;
    final double textHeight = AppDimensions.getScaledSize(context, 85.0);
    final double containerHeight = imageHeight + textHeight;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredBlogs.length > limit
            ? limit + 1
            : _filteredBlogs.length + 1,
        itemBuilder: (context, index) {
          if (index < _filteredBlogs.length && index < limit) {
            return _buildBlogCard(_filteredBlogs[index], index);
          } else if (index == limit ||
              (index == _filteredBlogs.length &&
                  _filteredBlogs.length <= limit)) {
            return _buildSeeMoreBlogsCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte de blog
  Widget _buildBlogCard(Blog blog, int index) {
    final uiData = blog.toUiMap();
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: 'blog_${blog.slug}',
        title: blog.title,
        subtitle: blog.nomecole,
        actionText: uiData['date'] as String,
        actionTextColor: AppColors.screenTextSecondaryThemed(context),
        actionTextFontSize: 11.0,
        color: uiData['color'] as Color,
        imagePath: blog.image,
        iconData: Icons.article,
        titleMaxLines: 2,
        externalTitleSpacing: 4,
        titleFontSize: isTablet ? 16.0 : 14.0,
        subtitleFontSize: 11.0,
        height: null,
        imageHeight: _getCardWidth(context, 16.0) * (isTablet ? 0.62 : 0.8),
        width: _getCardWidth(context, 16.0),
        allowLineBreak: true,
        centerTitle: false,
        showPlayIcon: false,
        onTap: () {
          _handleBlogAction(blog);
        },
      ),
    );
  }

  // Construire la carte "Voir+" pour les blogs
  Widget _buildSeeMoreBlogsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: SeeMoreCard(
          cardColor: isDarkMode ? AppColors.grey800 : Colors.white,
          borderColor: const Color(0xFF8B5CF6),
          iconColor: Colors.white,
          textColor: const Color(0xFF8B5CF6),
          subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          title: 'Voir+',
          subtitle: 'd\'actualités',
          onTap: _handleSeeMoreBlogs,
          icon: Icons.add,
          width: cardWidth,
          height: imageHeight * 1.15,
        ),
      ),
    );
  }

  // Gérer l'action sur un blog
  void _handleBlogAction(Blog blog) {
    MainScreenWrapper.of(
      context,
    ).navigateToExtraScreen(BlogDetailScreen(blog: blog));
  }

  // Gérer l'action "Voir+" pour les blogs
  void _handleSeeMoreBlogs() {
    MainScreenWrapper.of(context).navigateToExtraScreen(const AllBlogsScreen());
  }

  // Construire la section Astuces et Conseils
  Widget _buildAstucesSection() {
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;
    final double textHeight = AppDimensions.getScaledSize(context, 85.0);
    final double containerHeight = imageHeight + textHeight;

    final bool showSeeMore = _filteredAstuces.length > limit;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: showSeeMore ? limit + 1 : _filteredAstuces.length,
        itemBuilder: (context, index) {
          if (index < _filteredAstuces.length && index < limit) {
            return _buildAstuceCard(_filteredAstuces[index], index);
          } else if (showSeeMore && index == limit) {
            return _buildSeeMoreAstucesCard();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Construire une carte d'astuce
  Widget _buildAstuceCard(AstuceConseil astuce, int index) {
    final uiData = astuce.toUiMap();
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: ImageMenuCardExternalTitle(
        index: index,
        cardKey: 'astuce_${astuce.slug}',
        title: astuce.title,
        subtitle: 'Astuces & Conseils',
        actionText: uiData['date'] as String,
        actionTextColor: AppColors.screenTextSecondaryThemed(context),
        actionTextFontSize: 11.0,
        color: uiData['color'] as Color,
        imagePath: uiData['image'] as String?,
        iconData: Icons.lightbulb_outline,
        titleMaxLines: 2,
        externalTitleSpacing: 4,
        titleFontSize: isTablet ? 16.0 : 14.0,
        subtitleFontSize: 11.0,
        height: null,
        imageHeight: _getCardWidth(context, 16.0) * (isTablet ? 0.62 : 0.8),
        width: _getCardWidth(context, 16.0),
        allowLineBreak: true,
        centerTitle: false,
        showPlayIcon:
            astuce.youtubeUrl != null && astuce.youtubeUrl!.isNotEmpty,
        onTap: () {
          _handleAstuceAction(astuce);
        },
      ),
    );
  }

  // Construire la carte "Voir+" pour les astuces
  Widget _buildSeeMoreAstucesCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: SeeMoreCard(
          cardColor: isDarkMode ? AppColors.grey800 : Colors.white,
          borderColor: const Color(0xFFF59E0B),
          iconColor: Colors.white,
          textColor: const Color(0xFFF59E0B),
          subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          title: 'Voir+',
          subtitle: 'd\'astuces',
          onTap: _handleSeeMoreAstuces,
          icon: Icons.add,
          width: cardWidth,
          height: imageHeight * 1.15,
        ),
      ),
    );
  }

  // Gérer l'action sur une astuce
  void _handleAstuceAction(AstuceConseil astuce) {
    if (astuce.youtubeUrl != null && astuce.youtubeUrl!.isNotEmpty) {
      // Convertir toutes les astuces vidéo en VisiteGuideeVideo
      final allVideoAstuces = _filteredAstuces
          .where((a) => a.youtubeUrl != null && a.youtubeUrl!.isNotEmpty)
          .toList();
      final allVideos = allVideoAstuces
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
      final tappedIndex = allVideoAstuces.indexWhere((a) => a.id == astuce.id);
      MainScreenWrapper.of(context).navigateToExtraScreen(
        VisiteGuideeVideoFeedScreen(
          videos: allVideos,
          initialIndex: tappedIndex >= 0 ? tappedIndex : 0,
        ),
      );
    } else {
      MainScreenWrapper.of(
        context,
      ).navigateToExtraScreen(TipsAdviceDetailScreen(astuce: astuce));
    }
  }

  // Gérer l'action "Voir+" pour les astuces
  void _handleSeeMoreAstuces() {
    MainScreenWrapper.of(
      context,
    ).navigateToExtraScreen(const TipsAdviceScreen());
  }

  // Gérer l'action "Voir+" pour les vidéos
  void _handleSeeMoreVideos() {
    MainScreenWrapper.of(
      context,
    ).navigateToExtraScreen(const AllVideosScreen(ecoleCode: ''));
  }

  // Construire la section Coulisse de l'Excellence
  // Helper pour calculer la largeur des cartes dynamiquement
  double _getCardWidth(BuildContext context, double rightMargin) {
    final isTablet =
        AppDimensions.isTablet(context) ||
        AppDimensions.isLargeTablet(context) ||
        AppDimensions.isDesktop(context);
    if (isTablet) {
      final availableWidth = MediaQuery.sizeOf(context).width - 32.0;
      final isLandscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      // En paysage, on montre ~5.2 éléments. En portrait, on montre ~3.2 éléments.
      final itemsCount = isLandscape ? 5.2 : 3.2;
      return (availableWidth / itemsCount) - rightMargin;
    }
    return AppDimensions.getScaledSize(
      context,
      105.0,
    ); // Réduit de 120.0 à 105.0
  }

  Widget _buildCoulisseSection() {
    if (_coulisseVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.9;
    final double imageHeight = cardWidth * imageRatio; // Format dynamique
    final double textHeight = AppDimensions.getScaledSize(
      context,
      85.0,
    ); // Espace suffisant pour le texte
    final double containerHeight = imageHeight + textHeight;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredCoulisseVideos.length > limit
            ? limit + 1
            : _filteredCoulisseVideos.length + 1,
        itemBuilder: (context, index) {
          if (index < _filteredCoulisseVideos.length && index < limit) {
            return _buildVideoCard(_filteredCoulisseVideos[index]);
          } else if (index == limit ||
              (index == _filteredCoulisseVideos.length &&
                  _filteredCoulisseVideos.length <= limit)) {
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
        // subtitle: schoolData['subtitle'] as String,
        imagePath: schoolData['imagePath'] as String?,
        iconData: Icons.business,
        isDark: Theme.of(context).brightness == Brightness.dark,
        color: schoolData['color'] as Color,
        //location: schoolData['location'] as String?, // Permettre null
        //tag: schoolData['tag'] as String?, // Permettre null
        titleMaxLines: 2,
        externalTitleSpacing: 4,
        titleFontSize:
            (AppDimensions.isTablet(context) ||
                AppDimensions.isLargeTablet(context))
            ? 16.0
            : null,
        subtitleFontSize:
            (AppDimensions.isTablet(context) ||
                AppDimensions.isLargeTablet(context))
            ? 14.0
            : null,
        height: null,
        imageHeight:
            _getCardWidth(context, 16.0) *
            ((AppDimensions.isTablet(context) ||
                    AppDimensions.isLargeTablet(context))
                ? 0.62
                : 0.9), // Plus haut sur téléphone
        width: _getCardWidth(context, 16.0),
        allowLineBreak: true,
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
        video.classe != null &&
        video.classe!.isNotEmpty &&
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
      // Naviguer vers l'écran de lecture vidéo en gardant la bottom nav
      MainScreenWrapper.of(context).navigateToExtraScreen(
        CoulisseVideoFeedScreen(
          videos: _coulisseVideos,
          initialIndex: videoIndex,
        ),
      );
    } else {
      // Afficher un message si la vidéo n'est pas trouvée
      NotificationHelper.showInfo('Vidéo non trouvée: ${schoolData['title']}');
    }
  }

  // Construire la carte "Voir+" pour les vidéos
  Widget _buildSeeMoreVideosCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.9;
    final double imageHeight = cardWidth * imageRatio;

    return Padding(
      padding: const EdgeInsets.only(
        right: 16,
      ), // Espacement horizontal cohérent
      child: Align(
        alignment: Alignment.topCenter,
        child: SeeMoreCard(
          cardColor: isDarkMode
              ? const Color.fromARGB(255, 0, 0, 0)
              : Colors.white,
          borderColor: const Color(0xFF10B981),
          iconColor: Colors.white,
          textColor: const Color(0xFF10B981),
          subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          title: 'Voir+',
          subtitle: 'de vidéos',
          onTap: _handleSeeMoreVideos,
          icon: Icons.play_arrow,
          width: cardWidth,
          height: imageHeight * 1.15,
        ),
      ),
    );
  }

  // Construire la section Visite guidée
  Widget _buildVisiteGuideeSection() {
    if (_visiteGuideeVideosLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CustomLoader(
            message: 'Chargement des vidéos...',
            size: 32.0,
            showBackground: false,
            loaderColor: AppColors.screenOrange,
          ),
        ),
      );
    }

    if (_visiteGuideeVideosError != null ||
        _filteredVisiteGuideeVideos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: CustomErrorState(
          title: "Aucune vidéo disponible",
          message: _visiteGuideeVideosError != null
              ? "Impossible de charger les vidéos. Veuillez vérifier votre connexion internet et réessayer."
              : "Il n'y a aucune vidéo de visite guidée disponible pour le moment.",
          icon: Icons.videocam_off_outlined,
          buttonWidth: 200,
          onRetry: _loadVisiteGuideeVideos,
          iconColor: AppColors.screenOrange,
          buttonColor: AppColors.screenOrange,
        ),
      );
    }

    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final limit = isTablet ? 6 : 5;

    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio; // Format dynamique
    final double textHeight = AppDimensions.getScaledSize(
      context,
      85.0,
    ); // Espace suffisant pour le texte
    final double containerHeight = imageHeight + textHeight;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredVisiteGuideeVideos.length > limit
            ? limit + 1
            : _filteredVisiteGuideeVideos.length + 1,
        itemBuilder: (context, index) {
          if (index < _filteredVisiteGuideeVideos.length && index < limit) {
            return _buildVisiteGuideeCard(
              _filteredVisiteGuideeVideos[index],
              index,
            );
          } else if (index == limit ||
              (index == _filteredVisiteGuideeVideos.length &&
                  _filteredVisiteGuideeVideos.length <= limit)) {
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
    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: SeeMoreCard(
          cardColor: isDarkMode ? AppColors.grey800 : Colors.white,
          borderColor: const Color(0xFF3B82F6),
          iconColor: Colors.white,
          textColor: const Color(0xFF3B82F6),
          subtitleColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
          title: 'Voir+',
          subtitle: 'de visites',
          onTap: _handleSeeMoreVisiteGuidee,
          icon: Icons.play_circle_outline,
          width: cardWidth,
          height: imageHeight * 1.15,
        ),
      ),
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
        titleFontSize:
            (AppDimensions.isTablet(context) ||
                AppDimensions.isLargeTablet(context))
            ? 18.0
            : null,
        subtitleFontSize:
            (AppDimensions.isTablet(context) ||
                AppDimensions.isLargeTablet(context))
            ? 14.0
            : null,
        height: null,
        imageHeight:
            _getCardWidth(context, 16.0) *
            ((AppDimensions.isTablet(context) ||
                    AppDimensions.isLargeTablet(context))
                ? 0.62
                : 0.8), // Plus haut sur téléphone
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

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: CustomErrorState(
        message:
            "Impossible de charger les données. Veuillez vérifier votre connexion et réessayer.",
        onRetry: _refreshHome,
        iconColor: AppColors.screenOrange,
        buttonColor: AppColors.screenOrange,
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isMobileLandscape =
        AppDimensions.isLandscape(context) &&
        MediaQuery.sizeOf(context).width < AppDimensions.smallTabletMaxWidth;

    Widget bodyContent;
    if (isMobileLandscape) {
      bodyContent = RefreshIndicator(
        onRefresh: _refreshHome,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildDarkHeader(),
              if (_error != null)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: _buildErrorState(),
                )
              else
                _buildBottomSheet(isMobileLandscape: true),
            ],
          ),
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          _buildDarkHeader(),
          if (_error != null)
            Expanded(child: _buildErrorState())
          else
            Expanded(child: _buildBottomSheet(isMobileLandscape: false)),
        ],
      );
    }

    if (!_hasCheckedTutorial) {
      _hasCheckedTutorial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartTutorial(context);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Stack(
        children: [
          Scaffold(backgroundColor: Colors.black, body: bodyContent),
          // const AdWidget(), // Mis en commentaire pour le nouveau test de publicité
        ],
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

  Widget _buildAppBar() {
    final rawFirstName = AuthService.instance.getCurrentUser()?.firstName ?? '';
    final isTablet = AppDimensions.isTablet(context);
    final displayFirstName = (!isTablet && rawFirstName.length > 4)
        ? '${rawFirstName.substring(0, 4)}...'
        : rawFirstName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
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
                  '${_getGreeting()}, $displayFirstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(18),
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
              ConditionalShowcase(
                showcaseKey: _four,
                description: 'Consultez les dernières alertes ici.',
                child: _PulsingNotificationButton(
                  icon: Icons.notifications_outlined,
                  onTap: _showNotificationsMenu,
                  showBadge:
                      _unreadNotificationsCount > 0 || _hasUpdateNotification,
                  badgeCount:
                      _unreadNotificationsCount +
                      (_hasUpdateNotification ? 1 : 0),
                  isPulsing: _hasUpdateNotification,
                ),
              ),
              const SizedBox(width: 8),
              // User avatar
              ConditionalShowcase(
                showcaseKey: _one,
                description: 'Accédez à votre profil et paramètres depuis ici.',
                child: GestureDetector(
                  onTap: () {
                    if (AuthGuard.isLoggedIn()) {
                      MainScreenWrapper.of(
                        context,
                      ).navigateToExtraScreen(const ProfileScreen());
                    } else {
                      // Après connexion depuis ce bouton, on reste sur l'accueil
                      // plutôt que de naviguer vers le profil.
                      AuthGuard.ensureLoggedIn(
                        context,
                        reason: 'Connectez-vous pour accéder à votre profil',
                        onAuthenticatedAsync: () async {
                          // Rafraîchit l'avatar (initiales) et recharge les
                          // enfants du compte qui vient de se connecter
                          // (sinon la liste reste vide jusqu'au redémarrage
                          // de l'app, cet écran n'étant pas recréé après une
                          // connexion depuis ce bouton).
                          if (mounted) await _loadChildren();
                        },
                      );
                    }
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
                      child: AuthGuard.isLoggedIn()
                          ? Text(
                              _getUserInitials(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: _textSizeService.getScaledFontSize(13),
                              ),
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 20,
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

  Widget _buildPresenceBannerItem(_FlashInfoItem item) {
    final date = _tryParseApiDate(item.startDate);
    final timeLabel = date == null
        ? ''
        : _isSameDate(date, DateTime.now())
        ? 'Aujourd\'hui'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.settingsGreen.withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: AppColors.settingsGreen.withOpacity(0.3),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showFlashInfoDetails(item),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.screenOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _textSizeService.getScaledFontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel.isNotEmpty
                                ? 'Flash Info · $timeLabel'
                                : 'Flash Info',
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
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _dismissedPresenceBannerItemKeys.add(item.id.toString());
                  _presenceBannerItems.removeWhere((i) => i.id == item.id);
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
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashInfoDetails(_FlashInfoItem item) {
    _stopPresenceAutoScroll();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) => _buildFlashInfoBottomSheet(item),
    ).then((_) {
      _startPresenceAutoScrollIfNeeded();
    });
  }

  Widget _buildFlashInfoBottomSheet(_FlashInfoItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final cardColor = isDark
        ? const Color(0xFF2D2D3F)
        : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final handleColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    final date = _tryParseApiDate(item.startDate);
    final timeLabel = date == null
        ? ''
        : _isSameDate(date, DateTime.now())
        ? 'Aujourd\'hui'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    // Intelligently split content to extract source / title if it has a colon
    String sheetTitle = 'Flash Info';
    String messageBody = item.content;
    if (item.content.contains(':')) {
      final parts = item.content.split(':');
      sheetTitle = parts[0].trim();
      messageBody = parts.sublist(1).join(':').trim();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Row with Megaphone Icon & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.screenOrange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.screenOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.screenOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FLASH INFO',
                      style: TextStyle(
                        color: AppColors.screenOrange,
                        fontSize: _textSizeService.getScaledFontSize(10),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              // Close Icon
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title / Establishment
          Text(
            sheetTitle,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          // Date
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Publié le $timeLabel',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(11),
                color: subtextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: isDark ? Colors.white10 : Colors.grey[200],
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 20),

          // Message Content Container
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  messageBody,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: textColor,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Elegant Action/Close Button at the bottom
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.screenOrange, Color(0xFFFF7A45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.screenOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Compris',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

  // ─── NOTIFICATIONS MENU ───────────────────────────────────────────────────
  void _showNotificationsMenu() {
    ReusableBottomSheet.show(
      context: context,
      title: 'Notifications',
      icon:
          Icons.notifications_none, // Optionnel, ajoute l'icône dans l'en-tête
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      content: FutureBuilder<VersionCheckResult?>(
        future: VersionUpdateService.checkForUpdate(),
        builder: (context, snapshot) {
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final bool hasUpdate =
              snapshot.hasData &&
              snapshot.data != null &&
              (snapshot.data!.updateAvailable || snapshot.data!.forceUpdate);

          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasUpdate) ...[
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    final String rawUrl = snapshot.data!.storeUrl;
                    final String targetUrl = rawUrl.isNotEmpty
                        ? rawUrl
                        : (Platform.isIOS
                              ? AppConfig.IOS_STORE_URL
                              : AppConfig.ANDROID_STORE_URL);
                    final url = Uri.parse(targetUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          Theme.of(context).platform == TargetPlatform.iOS
                              ? 'assets/images/icons/icone-appstore.png'
                              : 'assets/images/icons/icone-playstore.png',
                          height: 50,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mise à jour disponible 🚀',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                snapshot.data!.latestVersion.isNotEmpty
                                    ? 'La version ${snapshot.data!.latestVersion} est disponible.'
                                    : 'Une nouvelle version est disponible.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Mettre à jour',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
              const SizedBox(height: 20),
              Icon(
                Icons.notifications_off_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                hasUpdate
                    ? 'Aucune autre notification'
                    : 'Aucune notification pour le moment',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // ─── SHARE MENU ────────────────────────────────────────────────────────────
  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) => ShareBottomSheet(
        title: 'Partager l\'application',
        itemTitle: 'Invitez vos amis à suivre leurs enfants',
        shareText:
            'Découvrez Parents Responsable, l\'application qui vous permet de suivre le parcours scolaire de vos enfants en temps réel !\n\n'
            'Téléchargez l\'application ici :\n${AppConfig.storeUrl}',
      ),
    );
  }

  // ─── CHILDREN SECTION ──────────────────────────────────────────────────────
  Widget _buildChildrenSection() {
    final userLevel =
        AuthService.instance.getCurrentUser()?.userLevel ?? 'free';
    final isPremium = userLevel == 'premium' || userLevel == 'vip';

    return ConditionalShowcase(
      showcaseKey: _two,
      description:
          'Sélectionnez un enfant pour consulter ses informations spécifiques.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SectionRow(
            title: 'MES ENFANTS',
            onSeeMore: (_filteredChildren.length > 4)
                ? () {
                    AuthGuard.ensureLoggedIn(
                      context,
                      reason: 'Connectez-vous pour voir tous vos enfants',
                      onAuthenticated: () {
                        MainScreenWrapper.of(
                          context,
                        ).navigateToExtraScreen(const AllChildrenScreen());
                      },
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
                // ── Liste scrollable des enfants ou message vide ──
                Expanded(
                  child:
                      (isPremium || (_filteredChildren.isEmpty && !_isLoading))
                      ? const _AnimatedEmptyChildrenMessage()
                      : ListView(
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
          if (!isPremium) _buildChildrenCarouselIndicators(),
          if (_filteredChildren.isEmpty) const SizedBox(height: 16),
        ],
      ),
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
      color: const Color(
        0xFF141414,
      ), // Toujours sombre car le header est toujours noir
      child: const Icon(Icons.person, color: Color(0xFF8A8AFF), size: 26),
    );
  }

  Widget _buildAddChildButton() {
    final addChildCard = GestureDetector(
      onTap: () async {
        await AuthGuard.ensureLoggedIn(
          context,
          reason: 'Connectez-vous pour ajouter un enfant',
          onAuthenticated: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
          },
        );
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

    // Un invité doit se voir proposer la connexion immédiatement au tap,
    // jamais un verrou d'abonnement — le contrôle de privilège
    // (PrivilegeGuard) ne s'applique donc qu'aux utilisateurs déjà connectés.
    final child = AuthGuard.isLoggedIn()
        ? PrivilegeGuard(
            requiredLevel: 'free',
            showLockOverlay: false,
            fallback: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: Opacity(
                opacity: 0.5, // Effet grisé
                child: SizedBox(
                  width: AppDimensions.getChildImageSize(context) + 16,
                  child: Column(
                    children: [
                      Container(
                        width: AppDimensions.getChildImageSize(context),
                        height: AppDimensions.getChildImageSize(context),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _kDarkBorder, width: 2),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: const Color.fromARGB(
                                255,
                                226,
                                226,
                                240,
                              ).withOpacity(0.3),
                              size:
                                  AppDimensions.getChildImageSize(context) *
                                  0.33,
                            ),
                            const Icon(
                              Icons.lock_rounded,
                              color: Colors.amber,
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Nouveau',
                        style: TextStyle(
                          color: _kTextSecondary,
                          fontSize: AppDimensions.getChildNameTextSize(
                            context,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: addChildCard,
          )
        : addChildCard;

    return ConditionalShowcase(
      showcaseKey: _five,
      description: 'Ajoutez un nouvel enfant en cliquant ici.',
      child: child,
    );
  }

  // ─── BOTTOM SHEET (white panel) ────────────────────────────────────────────
  Widget _buildBottomSheet({bool isMobileLandscape = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bottomSheetBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppDimensions.getBottomSheetMaxWidth(context),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                ), // ← fixe, ne scroll pas
                child: isMobileLandscape
                    ? ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: _buildBottomSheetChildren(),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshHome,
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: _buildBottomSheetChildren(),
                        ),
                      ),
              ),
              const BottomFadeGradient(),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ScrollToTopFab(
                    scrollController: _scrollController,
                    bottomSpacerHeight: 115.0,
                    useGlassEffect: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBottomSheetChildren() {
    return [
      SectionRow(title: 'ACTIONS RAPIDES'),
      const SizedBox(height: 16),
      ConditionalShowcase(
        showcaseKey: _three,
        description: 'Accédez en un clic aux bulletins, absences et retards.',
        child: SizedBox(
          height: AppDimensions.getSquareCardHeightSize(context) + 0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal:
                  AppDimensions.getPaymentBannerCardSpacing(context) * 0.9,
            ),
            children: [
              _buildCard(
                index: 0,
                cardKey: 'inscription',
                title: 'Inscription \n en ligne',
                imagePath: 'assets/images/icons/inscription_en_ligne.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFF8FCFF),
                textColor: const Color(0xFF333333),
                actionText: '',
                allowLineBreak: true,
                enableInnerBorder: false,
                enableOuterBorder: false,
                innerBorderColor: const Color(0xFF93C5FD),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                onTap: () => InscriptionBottomSheet.show(
                  context,
                  imagePath: 'assets/images/icons/inscription_en_ligne.png',
                  imageBackgroundColor: const Color(0xFFF8FCFF),
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 1,
                cardKey: 'integration',
                title: 'Demande\nintégration',
                imagePath: 'assets/images/icons/demande_integration.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFF7FEFC),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                enableOuterBorder: false,
                allowLineBreak: true,
                innerBorderColor: const Color(0xFF6EE7B7),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                moduleIdentifiant: 'demande-intégration',
                onTap: () => AuthGuard.ensureLoggedIn(
                  context,
                  reason: 'Connectez-vous pour faire une demande d\'intégration',
                  onAuthenticated: () => showIntegrationBottomSheet(
                    context: context,
                    imagePath: 'assets/images/icons/demande_integration.png',
                    imageBackgroundColor: const Color(0xFFF7FEFC),
                    imageBorderRadius: AppDimensions.getImageBorderRadius(
                      context,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 2,
                cardKey: 'consulter_demande',
                title: 'Consulter\ndemande',
                imagePath: 'assets/images/icons/consulter_demande.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFFFFEF7),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                enableOuterBorder: false,
                allowLineBreak: true,
                innerBorderColor: const Color(0xFFFCD34D),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                moduleIdentifiant: 'demande-intégration',
                onTap: () => IntegrationRequestBottomSheet.show(
                  context,
                  imagePath: 'assets/images/icons/consulter_demande.png',
                  imageBackgroundColor: const Color(0xFFFFFEF7),
                  imageBorderRadius: AppDimensions.getImageBorderRadius(
                    context,
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 3,
                cardKey: 'parrainage',
                title: 'Parrainer\nutilisateur',
                imagePath: 'assets/images/icons/parrainer_utilisateur.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFFCFAFF),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                allowLineBreak: true,
                enableOuterBorder: false,
                innerBorderColor: const Color(0xFFC4B5FD),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                onTap: () => AuthGuard.ensureLoggedIn(
                  context,
                  reason: 'Connectez-vous pour parrainer un utilisateur',
                  onAuthenticated: () => showSponsorshipBottomSheet(
                    context,
                    imagePath: 'assets/images/icons/parrainer_utilisateur.png',
                    imageBackgroundColor: const Color(0xFFFCFAFF),
                    imageBorderRadius: AppDimensions.getImageBorderRadius(
                      context,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 4,
                cardKey: 'panier',
                title: 'Mon\npanier',
                imagePath: 'assets/images/icons/mon_panier.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFFCFAFF),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                enableOuterBorder: false,
                allowLineBreak: true,
                innerBorderColor: const Color(0xFFFB923C),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                onTap: () {
                  MainScreenWrapper.of(context).navigateToExtraScreen(const CartScreen());
                },
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 5,
                cardKey: 'commandes',
                title: 'Mes\ncommandes',
                imagePath: 'assets/images/icons/mes_commandes.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFFCFAFF),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                enableOuterBorder: false,
                allowLineBreak: true,
                innerBorderColor: const Color(0xFF34D399),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                onTap: () {
                  AuthGuard.ensureLoggedIn(
                    context,
                    reason: 'Connectez-vous pour voir vos commandes',
                    onAuthenticated: () {
                      MainScreenWrapper.of(
                        context,
                      ).navigateToExtraScreen(const OrdersScreen());
                    },
                  );
                },
              ),
              SizedBox(width: AppDimensions.getActionButtonsSpacing(context)),
              _buildCard(
                index: 6,
                cardKey: 'recommendation',
                title: 'Proposer\nune école',
                imagePath: 'assets/images/icons/recommander_une_ecole.png',
                color: AppColors.cardLightGrey,
                backgroundColor: const Color(0xFFFCFAFF),
                textColor: const Color(0xFF333333),
                actionText: '',
                enableInnerBorder: false,
                enableOuterBorder: false,
                allowLineBreak: true,
                innerBorderColor: const Color(0xFFFDBA74),
                imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                width: AppDimensions.getSquareCardWidthSize(context),
                height: AppDimensions.getSquareCardHeightSize(context),
                centerTitle: true,
                onTap: _showRecommendationBottomSheet,
              ),
            ],
          ),
        ),
      ),

      // Section Astuces et Conseils
      if (_hasAstucesData) ...[
        SectionRow(
          title: 'ASTUCES ET CONSEILS',
          onSeeMore: _filteredAstuces.length > 5
              ? () {
                  MainScreenWrapper.of(
                    context,
                  ).navigateToExtraScreen(const TipsAdviceScreen());
                }
              : null,
        ),
        const SizedBox(height: 16),
        _buildAstucesSection(),
      ],

      // Section Coulisses de l'Excellence
      if (_hasCoulisseExcellenceData) ...[
        const SizedBox(height: 24),
        SectionRow(
          title: 'COULISSES DE L\'EXCELLENCE',
          onSeeMore: () {
            MainScreenWrapper.of(
              context,
            ).navigateToExtraScreen(const AllVideosScreen(ecoleCode: ''));
          },
        ),
        const SizedBox(height: 16),
        _buildCoulisseSection(),
      ],
      // Section Publicitaire (Bannière)
      const HomeAdBanner(),
      // const SizedBox(height: 16),

      // Section Événements et Faits Scolaires
      if (_hasEventsData) ...[
        const SizedBox(height: 12),
        SectionRow(
          title: 'ÉVÉNEMENTS',
          onSeeMore: () {
            MainScreenWrapper.of(
              context,
            ).navigateToExtraScreen(AllEventsScreen());
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
            SectionRow(
              title: 'ACTUALITÉS  ET FAITS SCOLAIRES',
              onSeeMore: () {
                MainScreenWrapper.of(
                  context,
                ).navigateToExtraScreen(const AllBlogsScreen());
              },
            ),
            const SizedBox(height: 16),
            _buildBlogsSection(),
            const SizedBox(height: 16),
          ],
        ),

      // Section Visite guidée
      SectionRow(
        title: 'VISITE GUIDÉE',
        onSeeMore: () {
          MainScreenWrapper.of(context).navigateToExtraScreen(
            AllVisiteGuideeVideosScreen(
              videos: _visiteGuideeVideos,
              ecoleCode: '',
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      _buildVisiteGuideeSection(),
      const BottomSpacer(),
    ];
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
    String moduleIdentifiant = '',
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
    return ImageMenuCardExternalTitle(
      index: index,
      cardKey: cardKey,
      title: title,
      width: width,
      height: null, // Force l'image à être un carré (hauteur = largeur)
      imageFlex: 2,
      imagePath: imagePath,
      isDark: isDark,
      titleFontSize: AppDimensions.getScaledSize(context, 11.0),
      imageBorderRadius:
          width / 2, // Moitié de la largeur pour un cercle parfait
      doubleBorderGap: doubleBorderGap,
      color: color,
      backgroundColor: isDark
          ? backgroundColor.withOpacity(0.15)
          : backgroundColor,
      textColor: isDark ? Colors.white : textColor,
      actionText: actionText,
      onTap: onTap,
      enableInnerBorder: enableInnerBorder,
      enableOuterBorder: enableOuterBorder,
      innerBorderColor: innerBorderColor,
      centerTitle: centerTitle,
      allowLineBreak: allowLineBreak,
      moduleIdentifiant: moduleIdentifiant,
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
    if (currentUser == null) return '?';

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
        _filteredEvents = List.from(_events);
        _filteredBlogs = List.from(_blogs);
        _filteredVisiteGuideeVideos = List.from(_visiteGuideeVideos);
        _filteredCoulisseVideos = List.from(_coulisseVideos);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChildren = List.from(_children);
        _filteredEvents = List.from(_events);
        _filteredBlogs = List.from(_blogs);
        _filteredVisiteGuideeVideos = List.from(_visiteGuideeVideos);
        _filteredCoulisseVideos = List.from(_coulisseVideos);
      });
      return;
    }
    final lq = query.toLowerCase();
    setState(() {
      _filteredChildren = _children.where((c) {
        final name = '${c.firstName} ${c.lastName}'.toLowerCase();
        return name.contains(lq) || c.establishment.toLowerCase().contains(lq);
      }).toList();

      _filteredEvents = _events.where((e) {
        return e.title.toLowerCase().contains(lq) ||
            e.nomecole.toLowerCase().contains(lq);
      }).toList();

      _filteredBlogs = _blogs.where((b) {
        return b.title.toLowerCase().contains(lq) ||
            b.nomecole.toLowerCase().contains(lq);
      }).toList();

      _filteredVisiteGuideeVideos = _visiteGuideeVideos.where((v) {
        return v.title.toLowerCase().contains(lq) ||
            v.description.toLowerCase().contains(lq);
      }).toList();

      _filteredCoulisseVideos = _coulisseVideos.where((v) {
        return v.titre.toLowerCase().contains(lq) ||
            v.description.toLowerCase().contains(lq);
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

class _PulsingNotificationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;
  final bool isPulsing;

  const _PulsingNotificationButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
    this.isPulsing = false,
  }) : super(key: key);

  @override
  _PulsingNotificationButtonState createState() =>
      _PulsingNotificationButtonState();
}

class _PulsingNotificationButtonState extends State<_PulsingNotificationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PulsingNotificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _controller.repeat();
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.homeTopCard(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: 17,
          color: AppColors.homeTextPrimary(context),
        ),
      ),
    );

    if (widget.isPulsing) {
      button = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave1 = _controller.value;
          final wave2 = (_controller.value + 0.5) % 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (wave1 * 0.8),
                child: Opacity(
                  opacity: 1.0 - wave1,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + (wave2 * 0.8),
                child: Opacity(
                  opacity: 1.0 - wave2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: button,
      );
    }

    return Stack(
      children: [
        button,
        if (widget.showBadge && widget.badgeCount > 0)
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
                  widget.badgeCount > 9 ? '9+' : '\${widget.badgeCount}',
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
}
