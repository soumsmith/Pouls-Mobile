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
import '../widgets/bottom_sheets/inscription_bottom_sheet.dart';
import '../widgets/bottom_fade_gradient.dart';

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

  final List<String> _filters = ['Tout', 'Alertes', 'Paiements', 'Notes'];

  @override
  void initState() {
    super.initState();
    _textSizeService.addListener(() {
      if (mounted) setState(() {});
    });
    _loadChildren();
    _loadUnreadNotificationsCount();
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
          height: 88,
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
        width: 68,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                // Notification dot
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kDarkBg, width: 2),
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
                fontSize: _textSizeService.getScaledFontSize(10),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              child.grade.isNotEmpty ? child.grade : '—',
              style: TextStyle(
                color: _kOrange,
                fontSize: _textSizeService.getScaledFontSize(9),
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
        width: 68,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kDarkBorder,
                  width: 2,
                  style: BorderStyle
                      .solid, // dashed not directly supported; use a package for dashed
                ),
              ),
              child: const Icon(Icons.add, color: _kDarkBorder, size: 20),
            ),
            const SizedBox(height: 5),
            const Text(
              'Nouveau',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 10,
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
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 24),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'inscription',
                      title: 'Inscription',
                      imagePath: 'assets/images/icons/inscription.png',
                      color: const Color(0xFF8B5CF6),
                      backgroundColor: const Color(0xFFF3E8FF),
                      textColor: const Color(0xFF5B21B6),
                      actionText: 'S\'inscrire',
                      enableBorder: true,
                      borderColor: Colors.blue,
                      onTap: () => InscriptionBottomSheet.show(context),
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'integration',
                      title: 'Intégration',
                      imagePath: 'assets/images/inscription.jpg',
                      color: const Color(0xFF1565C0),
                      backgroundColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF0D47A1),
                      actionText: 'Commencer',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const IntegrationBottomSheet(),
                      ),
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'consulter_demande',
                      title: 'Consulter\ndemande',
                      imagePath: 'assets/images/mes-demande.jpg',
                      color: const Color(0xFF1B8A56),
                      backgroundColor: const Color(0xFFEAF7F0),
                      textColor: const Color(0xFF065F46),
                      actionText: 'Consulter',
                      onTap: () => IntegrationRequestBottomSheet.show(context),
                    ),
                    _buildCard(
                      index: 3,
                      cardKey: 'parrainage',
                      title: 'Parrainage',
                      imagePath: 'assets/images/scolarite.jpg',
                      color: _kOrange,
                      backgroundColor: const Color(0xFFFFF4EE),
                      textColor: const Color(0xFF9A3412),
                      actionText: 'Inviter',
                      onTap: () => showSponsorshipBottomSheet(context),
                    ),
                  ],
                ),
              ),

              SectionRow(title: 'SCOLARITÉ'),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 24),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'bulletins',
                      title: 'Bulletins',
                      imagePath: 'assets/images/notes.jpg',
                      color: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFFFFF0F0),
                      textColor: const Color(0xFF991B1B),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'agenda',
                      title: 'Agenda',
                      imagePath: 'assets/images/emploi-du-temps.jpg',
                      color: const Color(0xFF22C55E),
                      backgroundColor: const Color(0xFFE8F8F0),
                      textColor: const Color(0xFF166534),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'absences',
                      title: 'Absences',
                      imagePath: 'assets/images/school-event.jpg',
                      color: _kOrange,
                      backgroundColor: const Color(0xFFFFF4EE),
                      textColor: const Color(0xFF9A3412),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 3,
                      cardKey: 'notes',
                      title: 'Notes',
                      imagePath: 'assets/images/notes.jpg',
                      color: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4338CA),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 4,
                      cardKey: 'emploi_temps',
                      title: 'Emploi\ndu temps',
                      imagePath: 'assets/images/emploi-du-temps.jpg',
                      color: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF065F46),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SectionRow(title: 'PAIEMENTS & FINANCE'),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 24),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'paiements',
                      title: 'Paiements',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: const Color(0xFFF5A623),
                      backgroundColor: const Color(0xFFFFF8E8),
                      textColor: const Color(0xFF92400E),
                      actionText: 'Payer',
                      onTap: () {
                        PaymentBottomSheet.show(
                          context: context,
                          childName: null,
                          matricule: null,
                          onPayment: (montant, matricule) async {
                            try {
                              final montantInt = int.tryParse(montant);
                              if (montantInt == null || montantInt <= 0) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Montant invalide'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              final paiementService = PaiementService();
                              final paiementResponse = await paiementService
                                  .initierPaiementEnLigne(
                                    matricule,
                                    montantInt,
                                  );
                              if (paiementResponse.success &&
                                  paiementResponse.url.isNotEmpty) {
                                final launched = await paiementService
                                    .lancerUrlPaiement(paiementResponse.url);
                                if (!launched && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Impossible d\'ouvrir la page de paiement',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(paiementResponse.message),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erreur lors du paiement: $e',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'scolarite',
                      title: 'Scolarité',
                      imagePath: 'assets/images/scolarite.jpg',
                      color: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF065F46),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'historique',
                      title: 'Historique',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4338CA),
                      actionText: 'Consulter',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SectionRow(title: 'COMMUNICATION'),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 24),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'messages',
                      title: 'Messages',
                      imagePath: 'assets/images/messages.jpg',
                      color: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4338CA),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'professeurs',
                      title: 'Professeurs',
                      imagePath: 'assets/images/ecole.jpg',
                      color: const Color(0xFF8B5CF6),
                      backgroundColor: const Color(0xFFF3E8FF),
                      textColor: const Color(0xFF6B21A8),
                      actionText: 'Contacter',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'notifications',
                      title: 'Alertes',
                      imagePath: 'assets/images/school-event.jpg',
                      color: _kOrange,
                      backgroundColor: const Color(0xFFFFF4EE),
                      textColor: const Color(0xFF9A3412),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SectionRow(title: 'BOUTIQUE & ACHATS'),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 24),
                  children: [
                    _buildCard(
                      index: 0,
                      cardKey: 'panier',
                      title: 'Mon panier',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: _kOrange,
                      backgroundColor: const Color(0xFFFFF4EE),
                      textColor: const Color(0xFF9A3412),
                      actionText: 'Voir',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MainScreenWrapper(child: CartScreen()),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      index: 1,
                      cardKey: 'commandes',
                      title: 'Mes commandes',
                      imagePath: 'assets/images/mes-demande.jpg',
                      color: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF065F46),
                      actionText: 'Voir',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MainScreenWrapper(child: OrdersScreen()),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      index: 2,
                      cardKey: 'boutique_libouli',
                      title: 'Boutique\n(Libouli)',
                      imagePath: 'assets/images/ecole.jpg',
                      color: const Color(0xFF8B5CF6),
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
                    _buildCard(
                      index: 3,
                      cardKey: 'fournitures',
                      title: 'Fournitures',
                      imagePath: 'assets/images/foutnitures-scolaire.jpg',
                      color: const Color(0xFF8B5CF6),
                      backgroundColor: const Color(0xFFF3E8FF),
                      textColor: const Color(0xFF6B21A8),
                      actionText: 'Acheter',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 4,
                      cardKey: 'uniformes',
                      title: 'Uniformes',
                      imagePath: 'assets/images/ecole.jpg',
                      color: const Color(0xFF06B6D4),
                      backgroundColor: const Color(0xFFECFEFF),
                      textColor: const Color(0xFF0E7490),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 5,
                      cardKey: 'livres',
                      title: 'Livres',
                      imagePath: 'assets/images/notes.jpg',
                      color: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF047857),
                      actionText: 'Acheter',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 6,
                      cardKey: 'sports',
                      title: 'Sports',
                      imagePath: 'assets/images/school-event.jpg',
                      color: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFFFFF8E8),
                      textColor: const Color(0xFF92400E),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                    _buildCard(
                      index: 7,
                      cardKey: 'accessoires',
                      title: 'Accessoires',
                      imagePath: 'assets/images/mes-commandes.jpg',
                      color: const Color(0xFFEC4899),
                      backgroundColor: const Color(0xFFFDF2F8),
                      textColor: const Color(0xFFBE185D),
                      actionText: 'Voir',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Filter chips
              _buildFilterRow(),
              // Activity list
              _buildActivityList(),
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
    bool enableBorder = false,
    Color? borderColor,
  }) {
    final isDark = _themeService.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageMenuCardExternalTitle(
          index: index,
          cardKey: cardKey,
          title: title,
          width: 80,
          height: 100,
          imageFlex: 2,
          imagePath: imagePath,
          isDark: isDark,
          titleFontSize: 11,
          imageBorderRadius: 14,
          color: color,
          backgroundColor: isDark
              ? backgroundColor.withOpacity(0.15)
              : backgroundColor,
          textColor: isDark ? color.withOpacity(0.75) : textColor,
          actionText: actionText,
          actionTextColor: color,
          enableBorder: enableBorder,
          borderColor: borderColor,
          onTap: onTap,
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

  // ─── ACTIVITY LIST ─────────────────────────────────────────────────────────
  Widget _buildActivityList() {
    if (_isLoading) {
      return CustomLoader(
        message: 'Chargement...',
        loaderColor: _kOrange,
        backgroundColor: _kSheetBg,
        showBackground: false,
      );
    }
    if (_error != null) {
      return _buildErrorState();
    }

    // Dummy activity cards — replace with real data from your API
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Column(
        children: [
          _buildActivityCard(
            type: 'Absence signalée',
            typeColor: _kOrange,
            typeIcon: Icons.warning_amber_rounded,
            accentColor: _kOrange,
            title: 'Fatoumat-Zara Kante',
            subtitle: 'Non justifiée · 6ème G · Collège Hînneh Biabou',
            time: '08h30',
            actions: [
              _ActivityAction('Justifier', false, null, () {}),
              _ActivityAction('Contacter', false, null, () {}),
            ],
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            type: 'Paiement dû',
            typeColor: const Color(0xFFF5A623),
            typeIcon: Icons.info_outline_rounded,
            accentColor: const Color(0xFFF5A623),
            title: 'Scolarité Trimestre 3 — 25 000 FCFA',
            subtitle: 'Abdoul Kader · Collège Privé BKB',
            time: 'Hier',
            actions: [
              _ActivityAction(
                'Payer maintenant',
                true,
                const Color(0xFFF5A623),
                () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            type: 'Message professeur',
            typeColor: const Color(0xFF378ADD),
            typeIcon: Icons.chat_bubble_outline_rounded,
            accentColor: const Color(0xFF378ADD),
            title: 'M. Koné — SVT',
            subtitle: 'Abdoul Kader · Résultats devoir sur table disponibles',
            time: 'Lun.',
            actions: [
              _ActivityAction('Lire', false, null, () {}),
              _ActivityAction('Répondre', false, null, () {}),
            ],
          ),
          const SizedBox(height: 10),
          _buildActivityCard(
            type: 'Bulletin disponible',
            typeColor: const Color(0xFF4CAF50),
            typeIcon: Icons.description_outlined,
            accentColor: const Color(0xFF4CAF50),
            title: 'Trimestre 2 — Fatoumat-Zara',
            subtitle: '6ème G · Collège Hînneh Biabou',
            time: 'Dim.',
            actions: [
              _ActivityAction('Consulter le bulletin', false, null, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String type,
    required Color typeColor,
    required IconData typeIcon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String time,
    required List<_ActivityAction> actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kSheetCard,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(width: 3.5, color: accentColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: typeColor, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          type,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: _textSizeService.getScaledFontSize(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: TextStyle(
                            color: _kTextSecondary,
                            fontSize: _textSizeService.getScaledFontSize(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: _textSizeService.getScaledFontSize(13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: _textSizeService.getScaledFontSize(11),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: actions.map((a) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: actions.last == a ? 0 : 7,
                            ),
                            child: GestureDetector(
                              onTap: a.onTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: a.isPrimary
                                      ? (a.primaryColor ?? _kOrange)
                                      : _kSheetBg,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  a.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: a.isPrimary
                                        ? Colors.white
                                        : _kTextPrimary,
                                    fontSize: _textSizeService
                                        .getScaledFontSize(11),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

  // ─── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 30,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadChildren,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _kOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
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

// ─── HELPERS ──────────────────────────────────────────────────────────────────

class _ActivityAction {
  final String label;
  final bool isPrimary;
  final Color? primaryColor;
  final VoidCallback onTap;
  const _ActivityAction(
    this.label,
    this.isPrimary,
    this.primaryColor,
    this.onTap,
  );
}
