import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/child.dart';
import '../services/database_service.dart';
import '../services/pouls_scolaire_api_service.dart';
import '../services/text_size_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import 'add_child_screen.dart';

// ─── DESIGN TOKENS (alignés sur CartScreen) ───────────────────────────────
const _kOrange      = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);
const _kSurface     = Color(0xFFF8F8F8);
const _kCard        = Colors.white;
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);
const _kDivider     = Color(0xFFF0F0F0);
const _kShadow      = Color(0x0D000000);

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

  @override
  void initState() {
    super.initState();
    _textSizeService.addListener(() { if (mounted) setState(() {}); });
    _loadChildren();
  }

  @override
  void dispose() {
    _textSizeService.removeListener(() {});
    super.dispose();
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
      color: _kCard,
      items: [
        _shareMenuItem(Icons.email, Colors.red, 'Partager par mail', 'mail'),
        _shareMenuItem(
            Icons.message, Colors.green, 'Partager par WhatsApp', 'whatsapp'),
        _shareMenuItem(
            Icons.facebook, Colors.blue, 'Partager sur Facebook', 'facebook'),
        _shareMenuItem(Icons.share, _kTextSecondary, 'Autres options', 'other'),
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
                color: _kTextPrimary,
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
        backgroundColor: _kSurface,
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
      color: _kSurface,
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
                      'Pouls École',
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(22),
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      'Suivi scolaire en temps réel',
                      style: TextStyle(
                        fontSize:
                            _textSizeService.getScaledFontSize(12),
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

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
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBarIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: _kOrange),
      ),
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
                    color: _kTextPrimary,
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
              color: _kCard,
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
                      color: _kDivider,
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
    return Column(
      children: [
        Row(
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
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.grade_rounded,
                color: const Color(0xFF27AE60),
                value: _getAverageGradeDisplay(),
                label: 'Niveau moyen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.school_rounded,
                color: _kOrange,
                value: '${_getUniqueSchoolsCount()}',
                label:
                    'École${_getUniqueSchoolsCount() > 1 ? 's' : ''}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.class_rounded,
                color: const Color(0xFF8E44AD),
                value: '${_getUniqueClassesCount()}',
                label:
                    'Classe${_getUniqueClassesCount() > 1 ? 's' : ''}',
              ),
            ),
          ],
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
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4)),
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
              color: _kTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              color: _kTextSecondary,
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
              color: _kTextPrimary,
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
                colors: [Color(0xFFFF7A3C), _kOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withOpacity(0.3),
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
      return const Center(
        child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5),
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
                color: _kOrangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care_rounded,
                  size: 44, color: _kOrange),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez votre parcours',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(19),
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez votre premier enfant\npour suivre son évolution',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(13),
                color: _kTextSecondary,
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
                    _kCard.withOpacity(0),
                    _kCard,
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
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: _kShadow, blurRadius: 12, offset: Offset(0, 4)),
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
                      colors: [Color(0xFFFF7A3C), _kOrange],
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
                        color: _kTextPrimary,
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
                        color: _kTextSecondary,
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
                        color: _kOrangeLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.grade.isNotEmpty
                            ? child.grade
                            : 'Classe non renseignée',
                        style: TextStyle(
                          fontSize:
                              _textSizeService.getScaledFontSize(11),
                          color: _kOrange,
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
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: _kOrange, size: 14),
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
            colors: [Color(0xFFFF7A3C), _kOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kOrange.withOpacity(0.35),
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
}