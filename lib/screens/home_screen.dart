import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/text_size_service.dart';
import '../services/integration_request_service.dart';
import '../services/auth_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_loader.dart';
import '../config/app_colors.dart';
import 'add_child_screen.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

/// Écran d'accueil avec liste des enfants
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Child> _children = [];
  bool _isLoading = true;
  String? _error;
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _matriculeController = TextEditingController();
  
  // Variables pour les notifications
  int _unreadNotificationsCount = 0;
  bool _notificationsLoading = false;

  @override
  void initState() {
    super.initState();
    _textSizeService.addListener(() { if (mounted) setState(() {}); });
    _loadChildren();
    _loadUnreadNotificationsCount();
  }

  @override
  void dispose() {
    _textSizeService.removeListener(() {});
    _matriculeController.dispose();
    super.dispose();
  }

  // Charge le nombre de notifications non lues
  Future<void> _loadUnreadNotificationsCount() async {
    if (!mounted) return;
    
    setState(() {
      _notificationsLoading = true;
    });

    try {
      final authService = AuthService.instance;
      final currentUser = authService.getCurrentUser();
      
      if (currentUser != null) {
        final databaseService = DatabaseService.instance;
        final unreadCount = await databaseService.getUnreadNotificationsCount(currentUser.id);
        
        if (mounted) {
          setState(() {
            _unreadNotificationsCount = unreadCount;
            _notificationsLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
      if (mounted) {
        setState(() {
          _notificationsLoading = false;
        });
      }
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      MainScreenWrapper.of(context).refreshCurrentUser();
      final parentId =
          MainScreenWrapper.of(context).currentUserId ?? 'parent1';
      final apiService = MainScreenWrapper.of(context).apiService;
      final children = await apiService.getChildrenForParent(parentId);

      // ✅ Affichage immédiat des enfants sans attendre les photos
      if (!mounted) return;
      setState(() {
        _children = List.from(children);
        _isLoading = false;
      });

      // 🔄 Mise à jour des photos en arrière-plan (sans bloquer l'UI)
      _updatePhotosInBackground(children);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Met à jour les photos enfant par enfant sans bloquer l'affichage
  Future<void> _updatePhotosInBackground(List<Child> children) async {
    final poulsApiService = PoulsScolaireApiService();
    for (final child in children) {
      if ((child.photoUrl == null || child.photoUrl!.isEmpty) &&
          child.id.isNotEmpty) {
        try {
          final childInfo =
              await DatabaseService.instance.getChildInfoById(child.id);
          if (childInfo != null) {
            final ecoleId = childInfo['ecoleId'] as int?;
            final matricule = childInfo['matricule'] as String?;
            if (ecoleId != null && matricule != null) {
              final anneeScolaire =
                  await poulsApiService.getAnneeScolaireOuverte(ecoleId);
              final anneeId = anneeScolaire.anneeOuverteCentraleId;
              final eleve = await poulsApiService.findEleveByMatricule(
                  ecoleId, anneeId, matricule);
              if (eleve != null &&
                  eleve.urlPhoto != null &&
                  eleve.urlPhoto!.isNotEmpty) {
                await DatabaseService.instance
                    .updateChildPhoto(child.id, eleve.urlPhoto);
                if (!mounted) return;
                // Mise à jour optimiste : seule la carte concernée se rafraîchit
                setState(() {
                  final index =
                      _children.indexWhere((c) => c.id == child.id);
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
                  }
                });
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  // ─── SHARE MENU ────────────────────────────────────────────────────────────
  void _showShareMenu() {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
            MediaQuery.of(context).size.width - 16, kToolbarHeight + 50, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: AppColors.screenCard,
      items: [
        _shareMenuItem(Icons.email, Colors.red, 'Partager par mail', 'mail'),
        _shareMenuItem(
            Icons.message, Colors.green, 'Partager par WhatsApp', 'whatsapp'),
        _shareMenuItem(
            Icons.facebook, Colors.blue, 'Partager sur Facebook', 'facebook'),
        _shareMenuItem(Icons.share, AppColors.screenTextSecondary, 'Autres options', 'other'),
      ],
    ).then((value) {
      if (value != null) _handleShareAction(value);
    });
  }

  PopupMenuItem<String> _shareMenuItem(
      IconData icon, Color color, String label, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _handleShareAction(String action) async {
    const appUrl =
        'https://play.google.com/store/apps/details?id=com.pouls.ecole';
    const shareText =
        'Découvrez Pouls École, l\'application qui vous permet de suivre le parcours scolaire de vos enfants en temps réel !';
    switch (action) {
      case 'mail':
        final uri = Uri(
            scheme: 'mailto',
            query:
                'subject=${Uri.encodeComponent('Découvrez Pouls École')}&body=${Uri.encodeComponent('$shareText\n\nTéléchargez l\'application ici : $appUrl')}');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
      case 'whatsapp':
        final uri = Uri(
            scheme: 'https',
            host: 'wa.me',
            queryParameters: {
              'text': '$shareText\n\nTéléchargez l\'application ici : $appUrl'
            });
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
      case 'facebook':
        final uri = Uri(
            scheme: 'https',
            host: 'www.facebook.com',
            path: 'sharer/sharer.php',
            queryParameters: {'u': appUrl, 'quote': shareText});
        if (await canLaunchUrl(uri)) await launchUrl(uri);
        break;
      case 'other':
        await Share.share('$shareText\n\nTéléchargez l\'application ici : $appUrl',
            subject: 'Découvrez Pouls École');
        break;
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Row(
            children: [
              // Logo / title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent responsable',
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(22),
                        fontWeight: FontWeight.w800,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      'Suivi scolaire en temps réel',
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(12),
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Consultation demandes button
              _appBarIconButton(
                icon: Icons.search_rounded,
                onTap: _showIntegrationRequestBottomSheet,
                backgroundColor: AppColors.screenOrange,
                iconColor: Colors.white,
              ),
              const SizedBox(width: 8),
              // Share button
              _appBarIconButton(
                icon: Icons.share_outlined,
                onTap: _showShareMenu,
              ),
              const SizedBox(width: 8),
              // Notifications button
              _appBarIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {/* TODO: Notifications */},
                showBadge: true,
                badgeCount: _unreadNotificationsCount,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarIconButton(
      {required IconData icon, 
      required VoidCallback onTap,
      Color? backgroundColor,
      Color? iconColor,
      bool showBadge = false,
      int badgeCount = 0}) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: backgroundColor != null ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ) : null,
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? AppColors.screenTextSecondary,
            ),
          ),
        ),
        if (showBadge && badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section fixe : hero + stats ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Suivez le parcours scolaire\nde vos enfants',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(22),
                    fontWeight: FontWeight.w800,
                    color: AppColors.screenTextPrimary,
                    letterSpacing: -0.6,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats grid
              _buildStatsGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // ── Panneau scrollable : header + liste ──
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 20,
                    offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.screenDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: _buildSectionHeader(),
                ),
                // Scrollable list
                Expanded(
                  child: _buildChildrenContent(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── STATS GRID ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.child_care_rounded,
            color: const Color(0xFF4A90D9),
            value: '${_children.length}',
            label:
                'Enfant${_children.length > 1 ? 's' : ''} inscrit${_children.length > 1 ? 's' : ''}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.grade_rounded,
            color: const Color(0xFF27AE60),
            value: _getAverageGradeDisplay(),
            label: 'Niveau moyen',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.school_rounded,
            color: AppColors.screenOrange,
            value: '${_getUniqueSchoolsCount()}',
            label:
                'École${_getUniqueSchoolsCount() > 1 ? 's' : ''}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(22),
              fontWeight: FontWeight.w800,
              color: AppColors.screenTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Mes Enfants',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(17),
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddChildScreen()),
            );
            if (result == true) _loadChildren();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.screenOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 15),
                const SizedBox(width: 5),
                Text(
                  'Ajouter un enfant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        _textSizeService.getScaledFontSize(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── CHILDREN CONTENT ──────────────────────────────────────────────────────
  Widget _buildChildrenContent() {
    if (_isLoading) {
      return CustomLoader(
        message: 'Chargement de vos enfants...',
        loaderColor: AppColors.screenOrange,
        backgroundColor: AppColors.screenSurface,
        showBackground: false,
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: _buildErrorState(),
      );
    }
    if (_children.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: _buildEmptyState(),
      );
    }
    return _buildChildrenList();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 36, color: Colors.red[400]),
            ),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(17),
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                color: AppColors.screenTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildOrangeButton(
              label: 'Réessayer',
              onTap: _loadChildren,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.screenOrangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care_rounded,
                  size: 44, color: AppColors.screenOrange),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez votre parcours',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(19),
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez votre premier enfant\npour suivre son évolution',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                color: AppColors.screenTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          itemCount: _children.length,
          itemBuilder: (context, index) =>
              _buildChildCard(_children[index], index),
        ),
        // Gradient fade at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.screenCard.withOpacity(0),
                    AppColors.screenCard,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(Child child, int index) {
    return GestureDetector(
      onTap: () =>
          MainScreenWrapper.of(context).navigateToChildDetail(child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Photo / avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: child.photoUrl != null &&
                          child.photoUrl!.isNotEmpty
                      ? Image.network(
                          child.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26),
                        )
                      : const Icon(Icons.person,
                          color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      child.establishment.isNotEmpty
                          ? child.establishment
                          : 'Établissement non renseigné',
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(12),
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Grade badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.grade.isNotEmpty
                            ? child.grade
                            : 'Classe non renseignée',
                        style: TextStyle(
                          fontSize:
                              _textSizeService.getScaledFontSize(11),
                          color: AppColors.screenOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.screenOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.screenOrange, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ORANGE BUTTON (same as CartScreen) ───────────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  int _getUniqueClassesCount() =>
      _children.map((c) => c.grade).toSet().length;

  int _getUniqueSchoolsCount() =>
      _children.map((c) => c.establishment).toSet().length;

  String _getAverageGradeDisplay() {
    if (_children.isEmpty) return '-';
    final levels = _children.map((child) {
      final g = child.grade.toLowerCase();
      if (g.contains('cp') || g.contains('1ère')) return 1;
      if (g.contains('ce1') || g.contains('2ème')) return 2;
      if (g.contains('ce2') || g.contains('3ème')) return 3;
      if (g.contains('cm1') || g.contains('4ème')) return 4;
      if (g.contains('cm2') || g.contains('5ème')) return 5;
      if (g.contains('6ème')) return 6;
      if (g.contains('seconde')) return 10;
      if (g.contains('première')) return 11;
      if (g.contains('terminale')) return 12;
      return 3;
    }).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    if (avg <= 1) return 'CP';
    if (avg <= 2) return 'CE1';
    if (avg <= 3) return 'CE2';
    if (avg <= 4) return 'CM1';
    if (avg <= 5) return 'CM2';
    if (avg <= 6) return '6ème';
    if (avg <= 10) return 'Collège';
    if (avg <= 11) return 'Première';
    return 'Lycée';
  }

  // ─── INTEGRATION REQUEST BOTTOM SHEET ───────────────────────────────────────
  void _showIntegrationRequestBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Text(
                'Consulter ma demande',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre matricule pour vérifier le statut de votre demande d\'intégration',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A9A),
                ),
              ),
              const SizedBox(height: 24),
              // Matricule field
              TextField(
                controller: _matriculeController,
                decoration: InputDecoration(
                  labelText: 'Matricule',
                  hintText: 'Ex: 1234RTFGHJ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.screenOrange),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitIntegrationRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Consulter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SUBMIT INTEGRATION REQUEST ───────────────────────────────────────────────
  Future<void> _submitIntegrationRequest() async {
    if (_matriculeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un matricule'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Close bottom sheet
    Navigator.of(context).pop();

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomLoader(
        message: 'Consultation en cours...',
        loaderColor: AppColors.screenOrange,
      ),
    );

    try {
      // Pour le moment, utiliser un code d'école par défaut
      // TODO: Récupérer le code de l'école actuelle dynamiquement
      final schoolCode = 'gainhs';

      final result = await IntegrationRequestService.consultIntegrationRequest(
        ecoleCode: schoolCode,
        matricule: _matriculeController.text,
      );

      // Close loader
      Navigator.of(context).pop();

      if (result['success'] == true) {
        _showIntegrationResultDialog(result['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la consultation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loader
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── SHOW INTEGRATION RESULT DIALOG ───────────────────────────────────────────
  void _showIntegrationResultDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: data['statut'] == 2 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  data['statut'] == 2 ? Icons.check_rounded : Icons.info_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Résultat de votre demande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Text(
                data['message'] ?? 'Aucun message disponible',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.screenOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}