import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/integration_request_bottom_sheet.dart';
import 'package:parents_responsable/widgets/bottom_sheets/sponsorship_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_dimensions.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/integration_request_service.dart';
import '../services/auth_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_loader.dart';
import '../widgets/search_bar_widget.dart';
import '../config/app_colors.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../widgets/components/section_row.dart';
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
import '../services/coulisse_excellence_service.dart';
import '../models/coulisse_excellence.dart';
import 'coulisse_video_feed_screen.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
const _kDarkBg = Color(0xFF0F0F14);
const _kDarkCard = Color(0xFF1E1E2A);
const _kDarkBorder = Color(0xFF2A2A35);
const _kDarkAlert = Color(0xFF1A1020);
const _kDarkAlertBorder = Color(0xFF2D1830);
const _kOrange = Color(0xFFFF7A3C);
const _kOrangeDeep = Color(0xFFFF5C1B);
const _kSheetBg = Color(0xFFF5F5F7);
const _kSheetCard = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A1A2A);
const _kTextSecondary = Color(0xFF8A8A9E);
const _kDivider = Color(0xFFD1D1D6);
const _kChipActive = Color(0xFF1A1A2A);
const _kChipBg = Color(0xFFEBEBEF);

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
  bool _isSearching = false;

  int _unreadNotificationsCount = 0;
  bool _notificationsLoading = false;
  String _activeFilter = 'Tout';
  int _selectedChildIndex = 0;

  // Variables pour les notifications par enfant
  Map<String, List<GroupMessage>> _childrenNotifications = {};
  Map<String, EcheanceNotification?> _childrenEcheances = {};
  Map<String, bool> _childrenNotificationsLoading = {};
  Map<String, bool> _childrenEcheancesLoading = {};

  // Variables pour les vidéos Coulisses de l'Excellence
  List<CoulisseExcellence> _coulisseVideos = [];
  bool _coulisseVideosLoading = true;
  String? _coulisseVideosError;

  final List<String> _filters = ['Tout', 'Alertes', 'Paiements', 'Notes'];

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
  }

  @override
  void dispose() {
    _textSizeService.removeListener(() {});
    _matriculeController.dispose();
    _searchController.dispose();
    super.dispose();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    try {
      final videos = await CoulisseExcellenceService.getAllCoulisseExcellenceVideos();
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

  // Construire la section Coulisses de l'Excellence
  Widget _buildCoulisseExcellenceSection() {
    if (_coulisseVideosLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_coulisseVideosError != null) {
      return Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_coulisseVideos.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Aucune vidéo disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _coulisseVideos.length,
        itemBuilder: (context, index) {
          final video = _coulisseVideos[index];
          return _buildCoulisseVideoCard(video, index);
        },
      ),
    );
  }

  // Construire une carte de vidéo pour le carrousel
  Widget _buildCoulisseVideoCard(CoulisseExcellence video, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CoulisseVideoFeedScreen(
              videos: _coulisseVideos,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image miniature de la vidéo YouTube
              FadeInImage.assetNetwork(
                width: 300,
                height: 120,
                fit: BoxFit.cover,
                placeholder: 'assets/images/video-placeholder.jpg',
                image: 'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg',
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 300,
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.movie,
                      color: Colors.grey,
                      size: 48,
                    ),
                  );
                },
              ),
              
              // Overlay sombre pour améliorer la lisibilité
              Container(
                width: 300,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Icône de lecture centrale
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              
              // Informations en bas
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${video.fullName} · ${video.classe}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
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
        backgroundColor: _kDarkBg,
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
      color: _kDarkBg,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimanche 12 avril',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: _kOrange,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bonjour, ${AuthService.instance.getCurrentUser()?.firstName ?? ''}',
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
              color: _kDarkCard,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
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
                border: Border.all(color: _kDarkBg, width: 1.5),
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
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: _kDarkAlert,
          border: Border.all(color: _kDarkAlertBorder),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _kOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Absence signalée — Fatoumat, 6ème G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Ce matin · Collège Hînneh Biabou',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: _textSizeService.getScaledFontSize(10),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _kTextSecondary, size: 18),
          ],
        ),
      ),
    );
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
            color: _kDarkCard,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _kDarkBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.search_rounded,
                color: _kTextSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _textSizeService.getScaledFontSize(13),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou ecole...',
                    hintStyle: TextStyle(
                      color: _kTextSecondary,
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.close_rounded,
                      color: _kTextSecondary,
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
                  icon: Icons.chat_rounded,
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
    required IconData icon,
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
            child: Icon(icon, color: iconColor, size: 26),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'MES ENFANTS',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: AppDimensions.getChildImageSize(context) + 48,
          child: Row(
            children: [
              // ── Liste scrollable des enfants ──
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 4, 0),
                  children: _children
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChildAvatar(Child child, int index) {
    final isSelected = index == _selectedChildIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedChildIndex = index);
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
                      padding: EdgeInsets.all(AppDimensions.getNotificationBadgeSize(context) * 0.125),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kDarkBg, width: 2),
                      ),
                      constraints: BoxConstraints(
                        minWidth: AppDimensions.getNotificationBadgeSize(context),
                        minHeight: AppDimensions.getNotificationBadgeSize(context),
                      ),
                      child: Text(
                        getNotificationCountForChild(child) > 9
                            ? '9+'
                            : getNotificationCountForChild(child).toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppDimensions.getNotificationBadgeTextSize(context),
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
        if (result == true) _loadChildren();
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
                color: _kDarkBorder, 
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
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              SectionRow(title: 'INSCRIPTIONS & DÉMARCHES'),
              const SizedBox(height: 16),
              SizedBox(
                height: AppDimensions.getPaymentBannerCardHeight(context) +10,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.getPaymentBannerCardSpacing(context) * 0.8),
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
                      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () => InscriptionBottomSheet.show(context),
                    ),
                    SizedBox(width: AppDimensions.getPaymentBannerCardSpacing(context)),
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
                      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const IntegrationBottomSheet(),
                      ),
                    ),
                    SizedBox(width: AppDimensions.getPaymentBannerCardSpacing(context)),
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
                      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () => IntegrationRequestBottomSheet.show(context),
                    ),
                    SizedBox(width: AppDimensions.getPaymentBannerCardSpacing(context)),
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
                      imageBorderRadius: AppDimensions.getImageBorderRadius(context),
                      width: AppDimensions.getSquareCardWidthSize(context),
                      height: AppDimensions.getSquareCardHeightSize(context),
                      centerTitle: true,
                      onTap: () => showSponsorshipBottomSheet(context),
                    ),
                  ],
                ),
              ),

              // SectionRow(title: 'SCOLARITÉ'),
              // SizedBox(
              //   height: 140,
              //   child: ListView(
              //     scrollDirection: Axis.horizontal,
              //     padding: const EdgeInsets.only(left: 16, right: 24),
              //     children: [
              //       _buildCard(
              //         index: 0,
              //         cardKey: 'bulletins',
              //         title: 'Bulletins',
              //         imagePath: 'assets/images/notes.jpg',
              //         color: const Color(0xFFEF4444),
              //         backgroundColor: const Color(0xFFFFF0F0),
              //         textColor: const Color(0xFF991B1B),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 1,
              //         cardKey: 'agenda',
              //         title: 'Agenda',
              //         imagePath: 'assets/images/emploi-du-temps.jpg',
              //         color: const Color(0xFF22C55E),
              //         backgroundColor: const Color(0xFFE8F8F0),
              //         textColor: const Color(0xFF166534),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 2,
              //         cardKey: 'absences',
              //         title: 'Absences',
              //         imagePath: 'assets/images/school-event.jpg',
              //         color: _kOrange,
              //         backgroundColor: const Color(0xFFFFF4EE),
              //         textColor: const Color(0xFF9A3412),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 3,
              //         cardKey: 'notes',
              //         title: 'Notes',
              //         imagePath: 'assets/images/notes.jpg',
              //         color: const Color(0xFF6366F1),
              //         backgroundColor: const Color(0xFFEEF2FF),
              //         textColor: const Color(0xFF4338CA),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 4,
              //         cardKey: 'emploi_temps',
              //         title: 'Emploi\ndu temps',
              //         imagePath: 'assets/images/emploi-du-temps.jpg',
              //         color: const Color(0xFF10B981),
              //         backgroundColor: const Color(0xFFECFDF5),
              //         textColor: const Color(0xFF065F46),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //     ],
              //   ),
              // ),

              // SectionRow(title: 'PAIEMENTS & FINANCE'),
              // SizedBox(
              //   height: 140,
              //   child: ListView(
              //     scrollDirection: Axis.horizontal,
              //     padding: const EdgeInsets.only(left: 16, right: 24),
              //     children: [
              //       _buildCard(
              //         index: 0,
              //         cardKey: 'paiements',
              //         title: 'Paiements',
              //         imagePath: 'assets/images/icons/paiement.png',
              //         color: Colors.grey.shade50,
              //         backgroundColor: Colors.grey.shade50,
              //         textColor: const Color(0xFF333333),
              //         actionText: 'Payer',
              //         onTap: () {
              //           PaymentBottomSheet.show(
              //             context: context,
              //             childName: null,
              //             matricule: null,
              //             onPayment: (montant, matricule) async {
              //               try {
              //                 final montantInt = int.tryParse(montant);
              //                 if (montantInt == null || montantInt <= 0) {
              //                   if (mounted) {
              //                     ScaffoldMessenger.of(context).showSnackBar(
              //                       const SnackBar(
              //                         content: Text('Montant invalide'),
              //                         backgroundColor: AppColors.error,
              //                       ),
              //                     );
              //                   }
              //                   return;
              //                 }
              //                 final paiementService = PaiementService();
              //                 final paiementResponse = await paiementService
              //                     .initierPaiementEnLigne(
              //                       matricule,
              //                       montantInt,
              //                     );
              //                 if (paiementResponse.success &&
              //                     paiementResponse.url.isNotEmpty) {
              //                   final launched = await paiementService
              //                       .lancerUrlPaiement(paiementResponse.url);
              //                   if (!launched && mounted) {
              //                     ScaffoldMessenger.of(context).showSnackBar(
              //                       const SnackBar(
              //                         content: Text(
              //                           'Impossible d\'ouvrir la page de paiement',
              //                         ),
              //                         backgroundColor: AppColors.error,
              //                       ),
              //                     );
              //                   }
              //                 } else {
              //                   if (mounted) {
              //                     ScaffoldMessenger.of(context).showSnackBar(
              //                       SnackBar(
              //                         content: Text(paiementResponse.message),
              //                         backgroundColor: AppColors.error,
              //                       ),
              //                     );
              //                   }
              //                 }
              //               } catch (e) {
              //                 if (mounted) {
              //                   ScaffoldMessenger.of(context).showSnackBar(
              //                     SnackBar(
              //                       content: Text(
              //                         'Erreur lors du paiement: $e',
              //                       ),
              //                       backgroundColor: AppColors.error,
              //                     ),
              //                   );
              //                 }
              //               }
              //             },
              //           );
              //         },
              //       ),
              //       _buildCard(
              //         index: 1,
              //         cardKey: 'scolarite',
              //         title: 'Scolarité',
              //         imagePath: 'assets/images/icons/scolarite.png',
              //         color: Colors.grey.shade50,
              //         backgroundColor: Colors.grey.shade50,
              //         textColor: const Color(0xFF333333),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 2,
              //         cardKey: 'historique',
              //         title: 'Historique',
              //         imagePath: 'assets/images/mes-commandes.jpg',
              //         color: const Color(0xFF6366F1),
              //         backgroundColor: const Color(0xFFEEF2FF),
              //         textColor: const Color(0xFF4338CA),
              //         actionText: 'Consulter',
              //         onTap: () {},
              //       ),
              //     ],
              //   ),
              // ),

              // SectionRow(title: 'COMMUNICATION'),
              // SizedBox(
              //   height: 140,
              //   child: ListView(
              //     scrollDirection: Axis.horizontal,
              //     padding: const EdgeInsets.only(left: 16, right: 24),
              //     children: [
              //       _buildCard(
              //         index: 0,
              //         cardKey: 'messages',
              //         title: 'Messages',
              //         imagePath: 'assets/images/messages.jpg',
              //         color: const Color(0xFF6366F1),
              //         backgroundColor: const Color(0xFFEEF2FF),
              //         textColor: const Color(0xFF4338CA),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 1,
              //         cardKey: 'professeurs',
              //         title: 'Professeurs',
              //         imagePath: 'assets/images/ecole.jpg',
              //         color: const Color(0xFF8B5CF6),
              //         backgroundColor: const Color(0xFFF3E8FF),
              //         textColor: const Color(0xFF6B21A8),
              //         actionText: 'Contacter',
              //         onTap: () {},
              //       ),
              //       _buildCard(
              //         index: 2,
              //         cardKey: 'notifications',
              //         title: 'Alertes',
              //         imagePath: 'assets/images/school-event.jpg',
              //         color: _kOrange,
              //         backgroundColor: const Color(0xFFFFF4EE),
              //         textColor: const Color(0xFF9A3412),
              //         actionText: 'Voir',
              //         onTap: () {},
              //       ),
              //     ],
              //   ),
              // ),

               // Section Coulisses de l'Excellence
              SectionRow(title: 'COULISSES DE L\'EXCELLENCE'),
              const SizedBox(height: 16),
              _buildCoulisseExcellenceSection(),
               const SizedBox(height: 16),

              SectionRow(title: 'BOUTIQUE & ACHATS'),
              SizedBox(
                height: AppDimensions.getPaymentBannerCardHeight(context),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: AppDimensions.getSectionHorizontalPadding(context), 
                    right: AppDimensions.getSectionHorizontalPadding(context) + 8,
                  ),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'panier',
                      title: 'Mon panier',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: _kOrange,
                      width: AppDimensions.getHorizontalCardWidth(context),
                      height: AppDimensions.getHorizontalCardHeight(context), // Ajout d'une hauteur dynamique
                      backgroundColor: const Color(0xFFFFF4EE),
                      textColor: const Color(0xFF9A3412),
                      actionText: 'Voir',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'commandes',
                      title: 'Mes commandes',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: const Color(0xFF10B981),
                      width: AppDimensions.getHorizontalCardWidth(context),
                      height: AppDimensions.getHorizontalCardHeight(context), // Ajout d'une hauteur dynamique
                      backgroundColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF065F46),
                      actionText: 'Voir',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrdersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'boutique_libouli',
                      title: 'Boutique\n(Libouli)',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: const Color(0xFF8B5CF6),
                      width: AppDimensions.getHorizontalCardWidth(context),
                      height: AppDimensions.getHorizontalCardHeight(context), // Ajout d'une hauteur dynamique
                      backgroundColor: const Color(0xFFF3E8FF),
                      textColor: const Color(0xFF6B21A8),
                      actionText: 'Accéder',
                      onTap: () {
                        final wrapper = MainScreenWrapper.maybeOf(context);
                        if (wrapper != null) {
                          wrapper.updateCurrentIndex(1);
                        } else {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MainScreenWrapper(initialIndex: 1),
                            ),
                            (r) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 125),
            ],
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
}
