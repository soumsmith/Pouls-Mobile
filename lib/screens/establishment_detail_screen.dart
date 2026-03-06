import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../config/app_colors.dart';
import '../models/scolarite.dart';
import '../models/niveau.dart';
import '../models/avis.dart';
import '../services/text_size_service.dart';
import '../services/ecole_api_service.dart';
import '../services/theme_service.dart';
import '../services/blog_service.dart';
import '../services/events_service.dart';
import '../services/avis_service.dart';
import '../services/scolarite_service.dart';
import '../services/niveau_service.dart';
import '../services/integration_service.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/testimonial_service.dart';
import '../models/ecole.dart';
import '../models/ecole_detail.dart';
import '../widgets/color_card_grid.dart';
import '../widgets/gradient_submit_button.dart' show RatingSubmitButton, SponsorshipSubmitButton;
import '../widgets/main_screen_wrapper.dart';
import '../widgets/establishment_header_card.dart';
import '../widgets/section_title.dart';
import '../widgets/app_loader.dart';
import '../config/app_typography.dart';
import '../utils/image_helper.dart';
import 'all_events_screen.dart';

// ─── Design tokens (aligned with CartScreen) ─────────────────────────────────
const _kOrange      = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);
const _kSurface     = Color(0xFFF8F8F8);
const _kCard        = Colors.white;
const _kTextPrimary   = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);
const _kDivider       = Color(0xFFF0F0F0);
const _kShadow        = Color(0x0D000000);

const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x06000000), blurRadius: 4,  offset: Offset(0, 1)),
];

const _kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFF7A3C), _kOrange],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);


// ─── Action card definition ──────────────────────────────────────────────────
class _ActionDef {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _ActionDef({required this.icon, required this.label, required this.subtitle, required this.color});
}

const _kActions = <String, _ActionDef>{
  'integration': _ActionDef(icon: Icons.person_add_alt_1_rounded, label: 'Intégration',   subtitle: 'Rejoindre',  color: Color(0xFF3B82F6)),
  'rating':      _ActionDef(icon: Icons.star_rate_rounded,         label: 'Noter',         subtitle: 'Évaluer',    color: Color(0xFF10B981)),
  'sponsorship': _ActionDef(icon: Icons.card_giftcard_rounded,     label: 'Parrainer',     subtitle: 'Inviter',    color: Color(0xFFF59E0B)),
  'recommend':   _ActionDef(icon: Icons.recommend_rounded,         label: 'Recommander',   subtitle: 'Suggérer',   color: Color(0xFF8B5CF6)),
  'share':       _ActionDef(icon: Icons.share_rounded,             label: 'Partager',      subtitle: 'Diffuser',   color: Color(0xFFEC4899)),
  'informations':_ActionDef(icon: Icons.info_rounded,              label: 'Informations',  subtitle: 'Détails',    color: Color(0xFF3B82F6)),
  'communication':_ActionDef(icon: Icons.chat_rounded,             label: 'Communication', subtitle: 'Annonces',   color: Color(0xFF10B981)),
  'niveaux':     _ActionDef(icon: Icons.layers_rounded,            label: 'Niveaux',       subtitle: 'Classes',    color: Color(0xFFF59E0B)),
  'events':      _ActionDef(icon: Icons.event_rounded,             label: 'Événements',    subtitle: 'Calendrier', color: Color(0xFF8B5CF6)),
  'scolarite':   _ActionDef(icon: Icons.school_rounded,            label: 'Scolarité',     subtitle: 'Frais',      color: Color(0xFFEF4444)),
  'notes':       _ActionDef(icon: Icons.grade_rounded,             label: 'Notes',         subtitle: 'Bulletins',  color: Color(0xFFF59E0B)),
};

/// Écran de détail d'un établissement
class EstablishmentDetailScreen extends StatefulWidget implements MainScreenChild {
  final Ecole ecole;
  const EstablishmentDetailScreen({super.key, required this.ecole});

  @override
  State<EstablishmentDetailScreen> createState() => _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState extends State<EstablishmentDetailScreen>
    with TickerProviderStateMixin implements MainScreenChild {
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;
  final ThemeService    _themeService    = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  EcoleDetail? _ecoleDetail;
  late Future<ScolariteResponse> _scolariteFuture;

  List<Map<String, dynamic>> _blogs        = [];
  List<Map<String, dynamic>> _schoolEvents = [];
  List<Map<String, dynamic>> _avis         = [];
  bool   _isLoadingBlogs  = false;
  bool   _isLoadingEvents = false;
  bool   _isLoadingAvis   = false;
  String? _blogsError;
  String? _eventsError;
  String? _avisError;
  final BlogService   _blogService   = BlogService();
  final EventsService _eventsService = EventsService();
  final AvisService   _avisService   = AvisService();

  // form state
  String _selectedSexe    = 'M';
  String _selectedStatutAff = 'Affecté';
  String _searchQuery = '';
  String? _expandedBranche;

  // Integration controllers
  final TextEditingController _studentNameController       = TextEditingController();
  final TextEditingController _studentFirstNameController  = TextEditingController();
  final TextEditingController _matriculeController         = TextEditingController();
  final TextEditingController _birthDateController         = TextEditingController();
  final TextEditingController _lieuNaissanceController     = TextEditingController();
  final TextEditingController _nationaliteController       = TextEditingController();
  final TextEditingController _adresseController           = TextEditingController();
  final TextEditingController _contact1Controller          = TextEditingController();
  final TextEditingController _contact2Controller          = TextEditingController();
  final TextEditingController _nomPereController           = TextEditingController();
  final TextEditingController _nomMereController           = TextEditingController();
  final TextEditingController _nomTuteurController         = TextEditingController();
  final TextEditingController _niveauAntController         = TextEditingController();
  final TextEditingController _ecoleAntController          = TextEditingController();
  final TextEditingController _moyenneAntController        = TextEditingController();
  final TextEditingController _rangAntController           = TextEditingController();
  final TextEditingController _decisionAntController       = TextEditingController();
  final TextEditingController _motifController             = TextEditingController();
  final TextEditingController _filiereController           = TextEditingController();
  final TextEditingController _ratingController            = TextEditingController();
  final TextEditingController _commentController           = TextEditingController();
  final TextEditingController _requestedClassController    = TextEditingController();
  final TextEditingController _parentEmailController       = TextEditingController();
  final TextEditingController _parentPhoneController       = TextEditingController();
  final TextEditingController _schoolNameController        = TextEditingController();
  final TextEditingController _schoolAddressController     = TextEditingController();
  final TextEditingController _schoolTypeController        = TextEditingController();
  final TextEditingController _schoolCityController        = TextEditingController();
  final TextEditingController _recommenderNameController   = TextEditingController();
  final TextEditingController _commentsController          = TextEditingController();
  // Recommendation controllers
  final TextEditingController _parentNomController            = TextEditingController();
  final TextEditingController _parentPrenomController         = TextEditingController();
  final TextEditingController _parentTelephoneController      = TextEditingController();
  final TextEditingController _recommandationEmailController  = TextEditingController();
  final TextEditingController _parentPaysController           = TextEditingController();
  final TextEditingController _parentVilleController          = TextEditingController();
  final TextEditingController _parentAdresseController        = TextEditingController();
  final TextEditingController _etablissementController        = TextEditingController();
  final TextEditingController _paysController                 = TextEditingController();
  final TextEditingController _villeController                = TextEditingController();
  final TextEditingController _ordreController                = TextEditingController();
  final TextEditingController _adresseEtablissementController = TextEditingController();
  // Sponsorship controllers
  final TextEditingController _sponsorNameController    = TextEditingController();
  final TextEditingController _sponsorEmailController   = TextEditingController();
  final TextEditingController _promoCodeController      = TextEditingController();
  // File upload variables
  String? _bulletinFile;
  String? _certificatVaccinationFile;
  String? _certificatScolariteFile;
  String? _extraitNaissanceFile;
  String? _cniParentFile;

  // ── helpers ────────────────────────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'primaire': return const Color(0xFF3B82F6);
      case 'collège':  return const Color(0xFF8B5CF6);
      case 'lycée':    return const Color(0xFF10B981);
      case 'privé':    return const Color(0xFFF59E0B);
      case 'public':   return const Color(0xFF6366F1);
      default:         return const Color(0xFFEF4444);
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadEcoleDetail();
    _loadBlogsEventsAndAvis();
    _fadeController.forward();
    _scolariteFuture = ScolariteService.getScolaritesByEcole(widget.ecole.parametreCode);
  }

  Future<void> _loadEcoleDetail() async {
    try {
      final detail = await EcoleApiService.getEcoleDetail(widget.ecole.parametreCode);
      setState(() => _ecoleDetail = detail);
    } catch (e) {
      debugPrint('Erreur lors du chargement des détails: $e');
    }
  }

  Future<void> _loadBlogsEventsAndAvis() async {
    final nom  = widget.ecole.parametreNom ?? '';
    final code = widget.ecole.parametreCode ?? '';
    if (nom.isEmpty || code.isEmpty) return;
    setState(() {
      _isLoadingBlogs  = true;
      _isLoadingEvents = true;
      _isLoadingAvis   = true;
    });
    try {
      final results = await Future.wait([
        _blogService.getBlogsForUI(nom).catchError((e) { setState(() { _blogsError = e.toString(); _isLoadingBlogs = false; }); throw e; }),
        _eventsService.getEventsForUI(nomEtablissement: nom).catchError((e) { setState(() { _eventsError = e.toString(); _isLoadingEvents = false; }); throw e; }),
        _avisService.getAvisForUI(code).catchError((e) { setState(() { _avisError = e.toString(); _isLoadingAvis = false; }); throw e; }),
      ]);
      setState(() {
        if (_blogsError  == null) { _blogs        = results[0] as List<Map<String, dynamic>>; _isLoadingBlogs  = false; }
        if (_eventsError == null) { _schoolEvents  = results[1] as List<Map<String, dynamic>>; _isLoadingEvents = false; }
        if (_avisError   == null) { _avis          = results[2] as List<Map<String, dynamic>>; _isLoadingAvis   = false; }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeController.dispose();
    // Integration controllers
    _studentNameController.dispose(); _studentFirstNameController.dispose();
    _matriculeController.dispose(); _birthDateController.dispose();
    _lieuNaissanceController.dispose(); _nationaliteController.dispose();
    _adresseController.dispose(); _contact1Controller.dispose();
    _contact2Controller.dispose(); _nomPereController.dispose();
    _nomMereController.dispose(); _nomTuteurController.dispose();
    _niveauAntController.dispose(); _ecoleAntController.dispose();
    _moyenneAntController.dispose(); _rangAntController.dispose();
    _decisionAntController.dispose(); _motifController.dispose();
    _filiereController.dispose(); _ratingController.dispose();
    _commentController.dispose();
    // Recommendation controllers
    _parentNomController.dispose(); _parentPrenomController.dispose();
    _parentTelephoneController.dispose(); _recommandationEmailController.dispose();
    _parentPaysController.dispose(); _parentVilleController.dispose();
    _parentAdresseController.dispose(); _etablissementController.dispose();
    _paysController.dispose(); _villeController.dispose();
    _ordreController.dispose(); _adresseEtablissementController.dispose();
    // Sponsorship controllers
    _sponsorNameController.dispose(); _sponsorEmailController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: AnimatedBuilder(
        animation: Listenable.merge([_themeService, _textSizeService]),
        builder: (context, _) {
          final isDark = _themeService.isDarkMode;
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0F0F) : _kSurface,
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(isDark),
                  SliverToBoxAdapter(child: _buildContent(isDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : _kSurface,
      leading: GestureDetector(
        onTap: () {
          if (MainScreenWrapper.maybeOf(context) != null) {
            MainScreenWrapper.of(context).navigateToHome();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : _kCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: isDark ? Colors.white : _kTextPrimary),
        ),
      ),
      title: Text(
        'Détails de l\'établissement',
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(18),
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : _kTextPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        _appBarIconBtn(Icons.favorite_border, isDark, () {}),
        _appBarIconBtn(Icons.share, isDark, () {}),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _appBarIconBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : _kCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white70 : _kTextPrimary),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildEstablishmentHeader(isDark),
        const SizedBox(height: 24),
        _buildSectionHeader('Actions rapides', isDark),
        const SizedBox(height: 12),
        _buildActionButtons(isDark),
        const SizedBox(height: 24),
        _buildSectionHeader('Menu principal', isDark),
        const SizedBox(height: 12),
        _buildMenuCards(isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : _kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────────
  Widget _buildEstablishmentHeader(bool isDark) {
    final imageUrl         = _ecoleDetail?.image ?? widget.ecole.displayImage;
    final establishmentName= _ecoleDetail?.data.nom ?? widget.ecole.parametreNom ?? 'École';
    final establishmentType= widget.ecole.typePrincipal ?? 'Primaire';
    final motto            = _ecoleDetail?.data.slogan ?? 'L\'excellence notre priorité';
    final address          = _ecoleDetail?.data.adresse ?? widget.ecole.adresse ?? 'Adresse non disponible';
    final phone            = _ecoleDetail?.data.telephone ?? widget.ecole.telephone ?? 'Téléphone non disponible';
    final email            = _ecoleDetail?.data.email ?? 'Email non disponible';
    final typeColor        = _getTypeColor(establishmentType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : _kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            // ── Cover / image strip ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderCover(typeColor),
                    )
                  else
                    _placeholderCover(typeColor),
                  // gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        ),
                      ),
                    ),
                  ),
                  // type badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        establishmentType,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info block ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    establishmentName,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(20),
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _kTextPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    motto,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(13),
                      color: _kOrange,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(Icons.location_on_outlined,   address, isDark),
                  const SizedBox(height: 6),
                  _infoRow(Icons.phone_outlined,          phone,   isDark),
                  const SizedBox(height: 6),
                  _infoRow(Icons.email_outlined,          email,   isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover(Color color) => Container(
    height: 160, width: double.infinity,
    decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: const Icon(Icons.school_rounded, size: 56, color: Colors.white54),
  );

  Widget _infoRow(IconData icon, String text, bool isDark) => Row(
    children: [
      Icon(icon, size: 14, color: _kOrange),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : _kTextSecondary, fontWeight: FontWeight.w400),
        ),
      ),
    ],
  );

  // ── Action buttons (quick actions) ─────────────────────────────────────────
  Widget _buildActionButtons(bool isDark) {
    final actions = ['integration', 'rating', 'sponsorship', 'recommend', 'share'];
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final def = _kActions[actions[i]]!;
          return _buildActionChip(def, actions[i], isDark, i);
        },
      ),
    );
  }

  Widget _buildActionChip(_ActionDef def, String key, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: GestureDetector(
        onTap: () => _showActionBottomSheet(key, def),
        child: Container(
          width: 90,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: def.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(def.icon, color: def.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                def.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _kTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu cards (6 grid items) ──────────────────────────────────────────────
  Widget _buildMenuCards(bool isDark) {
    final menus = [
      ['informations', 'Informations'],
      ['communication', 'Communication'],
      ['niveaux', 'Niveaux'],
      ['events', 'Event school'],
      ['scolarite', 'Scolarité'],
      ['notes', 'Notes'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(children: menus.sublist(0, 3).asMap().entries.map((e) => _buildMenuCard(e.key, e.value[0], e.value[1], isDark)).toList()),
          const SizedBox(height: 12),
          Row(children: menus.sublist(3, 6).asMap().entries.map((e) => _buildMenuCard(e.key, e.value[0], e.value[1], isDark)).toList()),
        ],
      ),
    );
  }

  Widget _buildMenuCard(int index, String key, String title, bool isDark) {
    final def = _kActions[key]!;
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 350 + index * 80),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
        child: GestureDetector(
          onTap: () => _showActionBottomSheet(key, def),
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : _kCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: def.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(def.icon, color: def.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : _kTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════════════════
  void _showActionBottomSheet(String actionType, _ActionDef def) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : _kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Sheet header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: def.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(def.icon, color: def.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.label,
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(18),
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : _kTextPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              def.subtitle,
                              style: const TextStyle(fontSize: 13, color: _kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : _kSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.close, size: 16, color: isDark ? Colors.white54 : _kTextSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: _kDivider, height: 1),
                ],
              ),
            ),
            // ── Sheet content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _buildActionContent(actionType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION CONTENT ROUTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActionContent(String actionType) {
    switch (actionType) {
      case 'integration':   return _buildIntegrationForm();
      case 'rating':        return _buildRatingForm();
      case 'sponsorship':   return _buildSponsorshipForm();
      case 'recommend':     return _buildRecommendationForm();
      case 'share':         return _buildShareForm();
      case 'informations':  return _buildInformationsContent();
      case 'communication': return _buildCommunicationTab();
      case 'niveaux':       return _buildLevelsTab();
      case 'events':        return _buildEventsTab();
      case 'scolarite':     return _buildScolariteTab();
      case 'notes':         return _buildNotesTab();
      default:              return const Center(child: Text('Contenu non disponible'));
    }
  }

  // ── Sponsorship form ───────────────────────────────────────────────────────
  Widget _buildSponsorshipForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Vos informations',
          icon: Icons.person_rounded,
          children: [
            _buildTextField('Votre nom', 'Entrez votre nom complet', Icons.person_rounded, controller: _sponsorNameController),
            _buildTextField('Votre email', 'votre@email.com', Icons.email_rounded, controller: _sponsorEmailController, keyboardType: TextInputType.emailAddress),
            _buildTextField('Email de l\'ami à parrainer', 'ami@email.com', Icons.person_add_rounded, controller: TextEditingController(), keyboardType: TextInputType.emailAddress),
            _buildTextField('Code promo (optionnel)', 'Entrez un code promo', Icons.local_offer_rounded, controller: _promoCodeController),
          ],
        ),
        _buildOrangeButton(
          label: 'Envoyer l\'invitation',
          onTap: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Invitation de parrainage envoyée avec succès!'),
              backgroundColor: Colors.green[500],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Recommendation form ────────────────────────────────────────────────────
  Widget _buildRecommendationForm() {
    _etablissementController.text = widget.ecole.parametreNom ?? '';
    _paysController.text = 'Côte d\'Ivoire';
    _villeController.text = 'Abidjan';
    _ordreController.text = 'Primaire, collège';
    _adresseEtablissementController.text = 'Adjamé';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Informations sur l\'établissement',
          icon: Icons.business_rounded,
          children: [
            _buildTextField('Nom de l\'établissement', 'Entrez le nom', Icons.business_rounded, controller: _etablissementController, required: true),
            _buildTextField('Adresse', 'Adresse complète', Icons.location_on_rounded, controller: _adresseEtablissementController),
            _buildTextField('Ordre', 'Ex: Primaire, collège...', Icons.category_rounded, controller: _ordreController),
            _buildTextField('Ville', 'Ville de l\'établissement', Icons.location_city_rounded, controller: _villeController),
            _buildTextField('Pays', 'Pays de l\'établissement', Icons.public_rounded, controller: _paysController),
          ],
        ),
        _formSectionCard(
          title: 'Vos informations',
          icon: Icons.person_rounded,
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField('Nom', 'Votre nom', Icons.person_rounded, controller: _parentNomController, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Prénom', 'Votre prénom', Icons.person_outline_rounded, controller: _parentPrenomController, required: true)),
              ],
            ),
            _buildTextField('Téléphone', 'Votre numéro', Icons.phone_rounded, controller: _parentTelephoneController, keyboardType: TextInputType.phone, required: true),
            _buildTextField('Email', 'Votre adresse email', Icons.email_rounded, controller: _recommandationEmailController, keyboardType: TextInputType.emailAddress, required: true),
            _buildTextField('Pays', 'Votre pays', Icons.public_rounded, controller: _parentPaysController),
            _buildTextField('Ville', 'Votre ville', Icons.location_city_rounded, controller: _parentVilleController),
            _buildTextField('Adresse', 'Votre adresse', Icons.home_rounded, controller: _parentAdresseController),
          ],
        ),
        _buildOrangeButton(
          label: 'Envoyer la recommandation',
          onTap: () async {
            showDialog(
              context: context, barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator(color: _kOrange)),
            );
            if (_etablissementController.text.isEmpty || _parentNomController.text.isEmpty ||
                _parentPrenomController.text.isEmpty || _parentTelephoneController.text.isEmpty ||
                _recommandationEmailController.text.isEmpty) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Veuillez remplir tous les champs obligatoires'),
                backgroundColor: const Color(0xFFF59E0B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
              return;
            }
            Navigator.of(context).pop();
            try {
              final result = await RecommendationService.submitRecommendation(
                etablissement: _etablissementController.text,
                pays: _paysController.text,
                ville: _villeController.text,
                ordre: _ordreController.text,
                adresseEtablissement: _adresseEtablissementController.text,
                nomParent: _parentNomController.text,
                prenomParent: _parentPrenomController.text,
                telephone: _parentTelephoneController.text,
                email: _recommandationEmailController.text,
                paysParent: _parentPaysController.text,
                villeParent: _parentVilleController.text,
                adresseParent: _parentAdresseController.text,
              );
              if (result['success'] == true) {
                Navigator.of(context).pop();
                _parentNomController.clear(); _parentPrenomController.clear();
                _parentTelephoneController.clear(); _recommandationEmailController.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Recommandation envoyée avec succès!'),
                  backgroundColor: Colors.green[500],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Erreur lors de l\'envoi'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Share form ─────────────────────────────────────────────────────────────
  Widget _buildShareForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ecole.parametreNom ?? 'École',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(widget.ecole.adresse ?? '', style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(Icons.message, 'WhatsApp', const Color(0xFF25D366)),
                  _buildShareOption(Icons.email, 'Email', const Color(0xFF4285F4)),
                  _buildShareOption(Icons.link, 'Copier', const Color(0xFF6366F1)),
                  _buildShareOption(Icons.share, 'Réseaux', _kOrange),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: _kTextSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MENU CONTENT TABS  (Communication, Niveaux, Events, Scolarité, Notes)
  // ══════════════════════════════════════════════════════════════════════════

  // ── Communication tab ─────────────────────────────────────────────────────
  Widget _buildCommunicationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Communication et Actualités',
          style: TextStyle(fontSize: _textSizeService.getScaledFontSize(20), fontWeight: FontWeight.bold, color: _kTextPrimary)),
        const SizedBox(height: 4),
        Text('Dernières communications de ${widget.ecole.parametreNom}',
          style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
        const SizedBox(height: 20),
        if (_isLoadingBlogs)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kOrange)))
        else if (_blogsError != null)
          _buildTabError(_blogsError!, _loadBlogsEventsAndAvis)
        else if (_blogs.isEmpty)
          _buildTabEmpty(Icons.article_outlined, 'Aucune communication', 'Aucune communication disponible pour le moment.')
        else
          ..._blogs.map((blog) => _buildBlogCard(blog)).toList(),
      ],
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog) {
    final Color color = blog['color'] as Color? ?? _kOrange;
    final String? imageUrl = blog['image'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: ImageHelper.buildNetworkImage(imageUrl: imageUrl, placeholder: blog['title'] ?? '', width: double.infinity, height: 180, fit: BoxFit.cover),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Center(child: Icon(blog['icon'] as IconData? ?? Icons.article, size: 40, color: Colors.white70)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(blog['type'] as String? ?? 'Actualité', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(blog['date'] as String? ?? '', style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(blog['title'] as String? ?? 'Sans titre',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(blog['content'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: _kTextSecondary, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: _kTextSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(blog['auteur'] as String? ?? 'Administration', style: const TextStyle(fontSize: 11, color: _kTextSecondary))),
                    if ((blog['establishment'] as String?)?.isNotEmpty == true) ...[
                      const Icon(Icons.location_on_outlined, size: 13, color: _kTextSecondary),
                      const SizedBox(width: 3),
                      Flexible(child: Text(blog['establishment'] as String? ?? '', style: const TextStyle(fontSize: 11, color: _kTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Levels tab ─────────────────────────────────────────────────────────────
  Widget _buildLevelsTab() {
    final ecoleCode = widget.ecole.parametreCode ?? '';
    return FutureBuilder<List<Niveau>>(
      future: NiveauService.getNiveauxByEcole(ecoleCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kOrange));
        }
        if (snapshot.hasError) {
          return _buildTabError(snapshot.error.toString(), () => setState(() {}));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildTabEmpty(Icons.school_outlined, 'Aucun niveau disponible', 'Cette école n\'a pas de niveaux configurés');
        }
        final niveaux = snapshot.data!;
        final Map<String, Map<String, List<Niveau>>> grouped = {};
        for (final n in niveaux) {
          final filiere = (n.filiere?.isNotEmpty == true) ? n.filiere! : 'AUTRE';
          final niveauLabel = (n.niveau?.isNotEmpty == true) ? n.niveau! : n.nom ?? '?';
          grouped.putIfAbsent(filiere, () => {});
          grouped[filiere]!.putIfAbsent(niveauLabel, () => []);
          grouped[filiere]![niveauLabel]!.add(n);
        }
        final sortedFilieres = grouped.keys.toList()..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveaux d\'enseignement',
              style: TextStyle(fontSize: _textSizeService.getScaledFontSize(20), fontWeight: FontWeight.bold, color: _kTextPrimary)),
            const SizedBox(height: 4),
            Text('${niveaux.length} classe${niveaux.length > 1 ? 's' : ''} disponible${niveaux.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
            const SizedBox(height: 20),
            ...sortedFilieres.map((filiere) {
              final niveauxMap = grouped[filiere]!;
              final sortedNiveauKeys = niveauxMap.keys.toList()
                ..sort((a, b) {
                  final oA = niveauxMap[a]!.map((e) => e.ordre ?? 99).reduce((x, y) => x < y ? x : y);
                  final oB = niveauxMap[b]!.map((e) => e.ordre ?? 99).reduce((x, y) => x < y ? x : y);
                  return oA.compareTo(oB);
                });
              return _buildFiliereSection(filiere, sortedNiveauKeys, niveauxMap);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFiliereSection(String filiere, List<String> sortedNiveauKeys, Map<String, List<Niveau>> niveauxMap) {
    final color = _getFiliereColor(filiere);
    final totalClasses = niveauxMap.values.fold(0, (s, l) => s + l.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getFiliereIcon(filiere), color: Colors.white, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getFiliereLabel(filiere), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                      Text('$totalClasses classe${totalClasses > 1 ? 's' : ''} · ${sortedNiveauKeys.length} niveau${sortedNiveauKeys.length > 1 ? 'x' : ''}',
                        style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(filiere, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: sortedNiveauKeys.map((nl) {
                final classes = niveauxMap[nl]!..sort((a, b) => (a.ordre ?? 0).compareTo(b.ordre ?? 0));
                return _buildNiveauGroup(nl, classes, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauGroup(String niveauLabel, List<Niveau> classes, Color color) {
    if (classes.length == 1) return _buildSingleClassTile(classes.first, color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(niveauLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('${classes.length} séries', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: classes.map((c) => _buildClassChip(c, color)).toList()),
        ],
      ),
    );
  }

  Widget _buildSingleClassTile(Niveau niveau, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(
              (niveau.nom ?? '?').substring(0, (niveau.nom?.length ?? 0).clamp(0, 2)),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(niveau.nom ?? 'Classe', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                if (niveau.niveau != null && niveau.niveau!.isNotEmpty)
                  Text('Niveau : ${niveau.niveau}', style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
              ],
            ),
          ),
          if (niveau.code != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(niveau.code!, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildClassChip(Niveau niveau, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(niveau.nom ?? '?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          if (niveau.serie != null && niveau.serie!.isNotEmpty)
            Text('Série ${niveau.serie}', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Color _getFiliereColor(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':     return const Color(0xFF3B82F6);
      case 'GENERAL':      return const Color(0xFF8B5CF6);
      case 'TECHNIQUE':    return const Color(0xFF10B981);
      case 'PROFESSIONNEL':return const Color(0xFFF59E0B);
      default:             return const Color(0xFF6366F1);
    }
  }

  IconData _getFiliereIcon(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':     return Icons.child_care_rounded;
      case 'GENERAL':      return Icons.menu_book_rounded;
      case 'TECHNIQUE':    return Icons.precision_manufacturing_rounded;
      case 'PROFESSIONNEL':return Icons.work_rounded;
      default:             return Icons.school_rounded;
    }
  }

  String _getFiliereLabel(String f) {
    switch (f.toUpperCase()) {
      case 'PRIMAIRE':     return 'Enseignement Primaire';
      case 'GENERAL':      return 'Enseignement Général';
      case 'TECHNIQUE':    return 'Enseignement Technique';
      case 'PROFESSIONNEL':return 'Enseignement Professionnel';
      default:             return f;
    }
  }

  // ── Events tab ─────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Événements scolaires',
          style: TextStyle(fontSize: _textSizeService.getScaledFontSize(20), fontWeight: FontWeight.bold, color: _kTextPrimary)),
        const SizedBox(height: 4),
        Text('Découvrez les événements de ${widget.ecole.parametreNom}',
          style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
        const SizedBox(height: 20),
        if (_isLoadingEvents)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kOrange)))
        else if (_eventsError != null)
          _buildTabError(_eventsError!, _loadBlogsEventsAndAvis)
        else if (_schoolEvents.isEmpty)
          _buildTabEmpty(Icons.event_outlined, 'Aucun événement', 'Aucun événement disponible pour le moment.')
        else
          LayoutBuilder(builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
              ),
              itemCount: _schoolEvents.length,
              itemBuilder: (context, i) => _buildEventCard(_schoolEvents[i]),
            );
          }),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final Color color = event['color'] as Color? ?? _kOrange;
    final String? imageUrl = event['image'] as String?;
    final bool isAvailable = event['available'] as bool? ?? true;
    return GestureDetector(
      onTap: () => _showTicketPurchaseDialog(event),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    imageUrl != null
                        ? ImageHelper.buildNetworkImage(imageUrl: imageUrl, placeholder: event['title'] ?? '', width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                            child: Center(child: Icon(event['icon'] as IconData? ?? Icons.event, size: 40, color: Colors.white70)),
                          ),
                    Positioned(top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                        child: Text(event['date'] as String? ?? '', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (!isAvailable) Positioned(top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Complet', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] as String? ?? 'Sans titre',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: color),
                        const SizedBox(width: 3),
                        Expanded(child: Text(event['establishment'] as String? ?? '', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(event['price'] as String? ?? 'Gratuit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: isAvailable ? color : Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                          child: Text(isAvailable ? 'Acheter' : 'Indisponible',
                            style: TextStyle(fontSize: 9, color: isAvailable ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ],
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

  void _showTicketPurchaseDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Achat de ticket\n${event['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event['date']}'), Text('Lieu: ${event['location'] ?? event['establishment']}'),
            Text('Prix: ${event['price']}'),
            const SizedBox(height: 16),
            const Text('Nombre de tickets :', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.remove_circle_outline, color: _kOrange)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: _kOrange), borderRadius: BorderRadius.circular(8)),
                  child: const Text('1', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: _kOrange)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: _kTextSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Ticket acheté avec succès!'),
                backgroundColor: Colors.green[500],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ── Scolarité tab ──────────────────────────────────────────────────────────
  Widget _buildScolariteTab() {
    return FutureBuilder<ScolariteResponse>(
      future: _scolariteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kOrange));
        }
        if (snapshot.hasError) {
          return _buildTabError(snapshot.error.toString(), () {
            setState(() { _scolariteFuture = ScolariteService.getScolaritesByEcole(widget.ecole.parametreCode ?? ''); });
          });
        }
        if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
          return _buildTabEmpty(Icons.account_balance_wallet_outlined, 'Aucun frais de scolarité', 'Cette école n\'a pas de frais configurés');
        }
        final scolarites = ScolariteService.filtrerEtTrierScolarites(snapshot.data!.data);
        final scolaritesParBranche = ScolariteService.grouperParBranche(scolarites);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frais de scolarité', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(20), fontWeight: FontWeight.bold, color: _kTextPrimary)),
            const SizedBox(height: 4),
            const Text('Frais par branche et statut', style: TextStyle(fontSize: 13, color: _kTextSecondary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kDivider)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Rechercher un niveau...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _kOrange, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...scolaritesParBranche.entries
                .where((e) => _searchQuery.isEmpty || e.key.toLowerCase().contains(_searchQuery))
                .map((e) => StatefulBuilder(
                  builder: (context, setState) {
                    String? expandedBranche = _expandedBranche;
                    return _buildBrancheSection(e.key, e.value, setState, expandedBranche, (newValue) {
                      setState(() => expandedBranche = newValue);
                      setState(() => _expandedBranche = newValue);
                    });
                  },
                ))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildBrancheSection(String branche, List<Scolarite> scolarites, StateSetter setState, String? expandedBranche, Function(String?) onExpandedChanged) {
    final scolaritesParStatut = ScolariteService.separerParStatut(scolarites);
    final affectes = scolaritesParStatut['AFF'] ?? [];
    final nonAffectes = scolaritesParStatut['NAFF'] ?? [];
    final totaux = ScolariteService.calculerTotauxParStatut(scolarites);
    final isExpanded = expandedBranche == branche;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onExpandedChanged(isExpanded ? null : branche),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kOrange.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: isExpanded ? Radius.zero : const Radius.circular(20),
                  bottomRight: isExpanded ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(branche, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(16), fontWeight: FontWeight.w700, color: _kOrange)),
                          Text('${scolarites.length} frais', style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
                        ]),
                      ),
                      AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.expand_more, color: _kOrange, size: 24)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _kOrange.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kOrange.withOpacity(0.2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTotalItem('Affectés', totaux['AFF'] ?? 0, const Color(0xFF3B82F6), Icons.check_circle_rounded),
                        Container(width: 1, height: 30, color: _kDivider),
                        _buildTotalItem('Non Affectés', totaux['NAFF'] ?? 0, const Color(0xFFEF4444), Icons.remove_circle_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (affectes.isNotEmpty) ...[
                          _buildStatutSection(title: '🔵 Montants affectés', scolarites: affectes, color: const Color(0xFF3B82F6), isAffecte: true, totalMontant: totaux['AFF'] ?? 0),
                          const SizedBox(height: 16),
                        ],
                        if (nonAffectes.isNotEmpty)
                          _buildStatutSection(title: '🔴 Montants non affectés', scolarites: nonAffectes, color: const Color(0xFFEF4444), isAffecte: false, totalMontant: totaux['NAFF'] ?? 0),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, int montant, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(ScolariteService.formaterMontant(montant), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatutSection({required String title, required List<Scolarite> scolarites, required Color color, required bool isAffecte, required int totalMontant}) {
    final scolaritesParRubrique = ScolariteService.separerParRubrique(scolarites);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(ScolariteService.formaterMontant(totalMontant), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...scolaritesParRubrique.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(entry.key == 'INS' ? 'Inscription' : 'Scolarité',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
              ),
              ...entry.value.map((s) => _buildScolariteCard(s, color)).toList(),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScolariteCard(Scolarite scolarite, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(scolarite.rubrique == 'INS' ? Icons.how_to_reg_rounded : Icons.menu_book_rounded, color: color, size: 16),
        ),
        title: Text(ScolariteService.formaterMontant(scolarite.totalMontant ?? 0),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kTextPrimary)),
        subtitle: Text('Date limite: ${scolarite.dateLimiteFormatee}', style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(ScolariteService.getStatutLibelle(scolarite.statut), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Notes (Avis) tab ───────────────────────────────────────────────────────
  Widget _buildNotesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes et Avis', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(20), fontWeight: FontWeight.bold, color: _kTextPrimary)),
        const SizedBox(height: 4),
        Text('Avis des parents et élèves sur ${widget.ecole.parametreNom}', style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
        const SizedBox(height: 20),
        if (_isLoadingAvis)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kOrange)))
        else if (_avisError != null)
          _buildTabError(_avisError!, _loadBlogsEventsAndAvis)
        else if (_avis.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 80, height: 80,
                    decoration: BoxDecoration(color: _kOrangeLight, shape: BoxShape.circle),
                    child: const Icon(Icons.star_rate_outlined, size: 40, color: _kOrange)),
                  const SizedBox(height: 16),
                  const Text('Aucun avis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                  const SizedBox(height: 6),
                  const Text('Aucun avis disponible.\nSoyez le premier à donner votre avis !',
                    style: TextStyle(fontSize: 13, color: _kTextSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showActionBottomSheet('rating', _kActions['rating']!),
                    icon: const Icon(Icons.star_rate_rounded, size: 18),
                    label: const Text('Donner mon avis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._avis.map((a) => _buildAvisCard(a)).toList(),
      ],
    );
  }

  Widget _buildAvisCard(Map<String, dynamic> avi) {
    final Color color = avi['color'] as Color? ?? _kOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(avi['icon'] as IconData? ?? Icons.person_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(avi['auteur'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: color),
                                const SizedBox(width: 3),
                                Text(avi['type'] as String? ?? '', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(avi['date'] as String? ?? '', style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (avi['image'] != null && (avi['image'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageHelper.buildNetworkImage(imageUrl: avi['image'] as String, placeholder: '', width: double.infinity, height: 180, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(avi['content'] as String? ?? '', style: const TextStyle(fontSize: 13, color: _kTextSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Submit integration ─────────────────────────────────────────────────────
  void _submitIntegrationRequest() async {
    if (_studentNameController.text.isEmpty || _studentFirstNameController.text.isEmpty ||
        _birthDateController.text.isEmpty || _contact1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez remplir tous les champs obligatoires'),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    final requestData = <String, dynamic>{
      'nom': _studentNameController.text, 'prenoms': _studentFirstNameController.text,
      'matricule': _matriculeController.text.isNotEmpty ? _matriculeController.text : null,
      'sexe': _selectedSexe, 'date_naissance': _birthDateController.text,
      'lieu_naissance': _lieuNaissanceController.text.isNotEmpty ? _lieuNaissanceController.text : null,
      'nationalite': _nationaliteController.text.isNotEmpty ? _nationaliteController.text : 'Ivoirienne',
      'adresse': _adresseController.text.isNotEmpty ? _adresseController.text : null,
      'contact_1': _contact1Controller.text,
      'contact_2': _contact2Controller.text.isNotEmpty ? _contact2Controller.text : null,
      'nom_pere': _nomPereController.text.isNotEmpty ? _nomPereController.text : null,
      'nom_mere': _nomMereController.text.isNotEmpty ? _nomMereController.text : null,
      'nom_tuteur': _nomTuteurController.text.isNotEmpty ? _nomTuteurController.text : null,
      'niveau_ant': _niveauAntController.text.isNotEmpty ? _niveauAntController.text : null,
      'ecole_ant': _ecoleAntController.text.isNotEmpty ? _ecoleAntController.text : null,
      'moyenne_ant': _moyenneAntController.text.isNotEmpty ? _moyenneAntController.text : null,
      'rang_ant': _rangAntController.text.isNotEmpty ? int.tryParse(_rangAntController.text) : null,
      'decision_ant': _decisionAntController.text.isNotEmpty ? _decisionAntController.text : null,
      'bulletin': _bulletinFile, 'certificat_vaccination': _certificatVaccinationFile,
      'certificat_scolarite': _certificatScolariteFile, 'extrait_naissance': _extraitNaissanceFile,
      'cni_parent': _cniParentFile,
      'motif': _motifController.text.isNotEmpty ? _motifController.text : 'Nouvelle inscription',
      'statut_aff': _selectedStatutAff,
      'filiere': _filiereController.text.isNotEmpty ? _filiereController.text : 'primaire',
    };
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AppLoader(message: 'Envoi de la demande...', backgroundColor: Colors.white, iconColor: _getTypeColor(widget.ecole.typePrincipal), size: 80.0),
    );
    try {
      final result = await IntegrationService.submitIntegrationRequest(widget.ecole.parametreCode ?? '', requestData);
      Navigator.of(context).pop();
      if (result['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Demande d\'intégration envoyée avec succès!'),
          backgroundColor: Colors.green[500],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        final responseData = result['data'];
        if (responseData != null && responseData['demande_uid'] != null) {
          _showSuccessDialog(responseData['demande_uid']);
        }
      } else {
        _showErrorDialog('Erreur lors de l\'envoi', 'Une erreur est survenue.', details: result['error']);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Exception', 'Une erreur inattendue est survenue.', details: e.toString());
    }
  }

  void _showErrorDialog(String title, String message, {String? details}) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(32)),
                  child: const Icon(Icons.error_rounded, color: Colors.white, size: 32)),
                const SizedBox(height: 20),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(message, style: const TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.4), textAlign: TextAlign.center),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kDivider)),
                    child: Text(details, style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer', style: TextStyle(color: _kTextSecondary, fontWeight: FontWeight.w600)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: _kOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String demandeUid) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: Colors.green[500], borderRadius: BorderRadius.circular(32)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32)),
                const SizedBox(height: 20),
                const Text('Demande envoyée avec succès !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text('Votre demande d\'intégration a été soumise et est en cours de traitement.',
                  style: TextStyle(fontSize: 14, color: _kTextSecondary, height: 1.4), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kDivider)),
                  child: Column(
                    children: [
                      Row(children: [const Icon(Icons.fingerprint_rounded, color: _kOrange, size: 18), const SizedBox(width: 8), const Text('Numéro de suivi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary))]),
                      const SizedBox(height: 6),
                      Text(demandeUid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kOrange, letterSpacing: 1.2), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: _kOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('OK, j\'ai compris', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab helpers ────────────────────────────────────────────────────────────
  Widget _buildTabError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red[300]),
            const SizedBox(height: 12),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
            const SizedBox(height: 6),
            Text(error, style: const TextStyle(fontSize: 12, color: _kTextSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabEmpty(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(color: _kOrangeLight, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: _kOrange)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: _kTextSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FORMS
  // ══════════════════════════════════════════════════════════════════════════

  // ── Shared form field helpers ─────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(Icons.circle, size: 6, color: _kOrange),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.2)),
      ],
    ),
  );

  Widget _buildTextField(String label, String hint, IconData icon, {
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
            if (required) const Text(' *', style: TextStyle(color: _kOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _kTextPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: _kOrange, size: 18),
            filled: true,
            fillColor: _kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOrange, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, IconData icon, {
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
            if (required) const Text(' *', style: TextStyle(color: _kOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14, color: _kTextPrimary)))).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: _kOrange, size: 18),
            filled: true,
            fillColor: _kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOrange, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildFileField(String label, String hint, IconData icon, {String? fileName, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fileName != null ? _kOrange : _kDivider, width: fileName != null ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: _kOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName ?? hint,
                    style: TextStyle(fontSize: 13, color: fileName != null ? _kTextPrimary : const Color(0xFFBBBBBB)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.cloud_upload_outlined, color: fileName != null ? _kOrange : _kTextSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: _kOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: Divider(color: _kDivider, height: 1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _intersperse(children, const SizedBox(height: 12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) result.add(separator);
    }
    return result;
  }

  Widget _buildOrangeButton({required String label, VoidCallback? onTap, bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF7A3C), _kOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _kOrange.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
        ),
      ),
    );
  }

  // ── Integration form ───────────────────────────────────────────────────────
  Widget _buildIntegrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionCard(
          title: 'Informations de l\'élève',
          icon: Icons.person_rounded,
          children: [
            _buildTextField('Nom', 'Entrez le nom complet', Icons.person_rounded, controller: _studentNameController, required: true),
            _buildTextField('Prénoms', 'Entrez les prénoms', Icons.person_outline_rounded, controller: _studentFirstNameController, required: true),
            _buildTextField('Matricule', 'Entrez le matricule', Icons.badge_rounded, controller: _matriculeController),
            StatefulBuilder(builder: (context, ss) =>
              _buildDropdown('Sexe', 'Sélectionner le sexe', Icons.person_rounded,
                value: _selectedSexe, items: ['M', 'F'], onChanged: (v) => ss(() => _selectedSexe = v ?? 'M')),
            ),
            _buildTextField('Date de naissance', 'AAAA-MM-JJ', Icons.cake_rounded, controller: _birthDateController, keyboardType: TextInputType.datetime),
            _buildTextField('Lieu de naissance', 'Entrez le lieu de naissance', Icons.location_on_rounded, controller: _lieuNaissanceController),
            _buildTextField('Nationalité', 'Entrez la nationalité', Icons.flag_rounded, controller: _nationaliteController),
            _buildTextField('Adresse', 'Entrez l\'adresse complète', Icons.home_rounded, controller: _adresseController, maxLines: 2),
          ],
        ),
        _formSectionCard(
          title: 'Contacts',
          icon: Icons.phone_rounded,
          children: [
            _buildTextField('Contact 1', 'Numéro principal', Icons.phone_rounded, controller: _contact1Controller, keyboardType: TextInputType.phone, required: true),
            _buildTextField('Contact 2', 'Numéro secondaire', Icons.phone_android_rounded, controller: _contact2Controller, keyboardType: TextInputType.phone),
          ],
        ),
        _formSectionCard(
          title: 'Informations des parents',
          icon: Icons.family_restroom_rounded,
          children: [
            _buildTextField('Nom du père', 'Nom complet du père', Icons.person_rounded, controller: _nomPereController),
            _buildTextField('Nom de la mère', 'Nom complet de la mère', Icons.person_outline_rounded, controller: _nomMereController),
            _buildTextField('Nom du tuteur', 'Nom du tuteur (optionnel)', Icons.supervisor_account_rounded, controller: _nomTuteurController),
          ],
        ),
        _formSectionCard(
          title: 'Scolarité antérieure',
          icon: Icons.school_rounded,
          children: [
            _buildTextField('Niveau antérieur', 'Ex: CP1, 6ème...', Icons.school_rounded, controller: _niveauAntController),
            _buildTextField('École antérieure', 'Nom de l\'école précédente', Icons.account_balance_rounded, controller: _ecoleAntController),
            _buildTextField('Moyenne', 'Ex: 12.5', Icons.assessment_rounded, controller: _moyenneAntController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            _buildTextField('Rang', 'Ex: 3', Icons.format_list_numbered_rounded, controller: _rangAntController, keyboardType: TextInputType.number),
            _buildTextField('Décision', 'Ex: Passage, Redoublement...', Icons.gavel_rounded, controller: _decisionAntController),
          ],
        ),
        _formSectionCard(
          title: 'Documents à fournir',
          icon: Icons.description_rounded,
          children: [
            _buildFileField('Bulletin scolaire', 'Sélectionner le bulletin', Icons.description_rounded, fileName: _bulletinFile, onTap: () => _showFilePickerMessage('bulletin')),
            _buildFileField('Certificat de vaccination', 'Sélectionner le certificat', Icons.medical_services_rounded, fileName: _certificatVaccinationFile, onTap: () => _showFilePickerMessage('certificat_vaccination')),
            _buildFileField('Certificat de scolarité', 'Sélectionner le certificat', Icons.school_rounded, fileName: _certificatScolariteFile, onTap: () => _showFilePickerMessage('certificat_scolarite')),
            _buildFileField('Extrait de naissance', 'Sélectionner l\'extrait', Icons.card_membership_rounded, fileName: _extraitNaissanceFile, onTap: () => _showFilePickerMessage('extrait_naissance')),
            _buildFileField('CNI des parents', 'Sélectionner la CNI', Icons.credit_card_rounded, fileName: _cniParentFile, onTap: () => _showFilePickerMessage('cni_parent')),
          ],
        ),
        _formSectionCard(
          title: 'Détails de la demande',
          icon: Icons.note_rounded,
          children: [
            _buildTextField('Motif', 'Ex: Nouvelle inscription, Transfert...', Icons.note_rounded, controller: _motifController),
            StatefulBuilder(builder: (context, ss) =>
              _buildDropdown('Statut d\'affectation', 'Sélectionner le statut', Icons.assignment_turned_in_rounded,
                value: _selectedStatutAff, items: ['Affecté', 'En attente', 'Refusé'], onChanged: (v) => ss(() => _selectedStatutAff = v ?? 'Affecté')),
            ),
            _buildTextField('Filière', 'Ex: primaire, secondaire, technique...', Icons.category_rounded, controller: _filiereController),
          ],
        ),
        _buildOrangeButton(
          label: 'Envoyer la demande',
          onTap: () { _submitIntegrationRequest(); Navigator.of(context).pop(); },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showFilePickerMessage(String fileType) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sélection de fichier pour: $fileType'),
      backgroundColor: _kOrange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }


  // ── Rating form ────────────────────────────────────────────────────────────
  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E0), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.grade_rounded, color: Color(0xFFF59E0B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Votre note', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, ss) {
                  final current = int.tryParse(_ratingController.text) ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final selected = current > i;
                      return GestureDetector(
                        onTap: () => ss(() => _ratingController.text = (i + 1).toString()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFF8E0) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            selected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFDDDDDD),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Comment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kDivider),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 5,
            style: const TextStyle(fontSize: 14, color: _kTextPrimary),
            decoration: InputDecoration(
              labelText: 'Votre commentaire',
              hintText: 'Partagez votre expérience...',
              labelStyle: const TextStyle(color: _kTextSecondary, fontWeight: FontWeight.w600),
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 4, right: 8),
                child: Icon(Icons.comment_rounded, color: _kOrange, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        RatingSubmitButton(
          onPressed: () async {
            if (_ratingController.text.isEmpty || _commentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Veuillez remplir la note et le commentaire'),
                backgroundColor: const Color(0xFFF59E0B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
              return;
            }
            final currentUser = AuthService().getCurrentUser();
            if (currentUser == null || currentUser.phone.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Utilisateur non connecté'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
              return;
            }
            showDialog(
              context: context, barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator(color: _kOrange)),
            );
            try {
              final result = await TestimonialService.submitTestimonial(
                codeecole: widget.ecole.parametreCode ?? '',
                note: _ratingController.text,
                contenu: _commentController.text,
                userNumero: currentUser.phone,
              );
              Navigator.of(context).pop();
              if (result['success'] == true) {
                Navigator.of(context).pop();
                _ratingController.clear();
                _commentController.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Témoignage envoyé avec succès!'),
                  backgroundColor: Colors.green[500],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Erreur lors de l\'envoi'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            } catch (_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Erreur lors de l\'envoi du témoignage'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Informations content ───────────────────────────────────────────────────
  Widget _buildInformationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewSection(),
        const SizedBox(height: 16),
        _buildContactSection(),
        const SizedBox(height: 16),
        _buildInfoSection(),
        const SizedBox(height: 16),
        _buildDetailedInfoSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Overview section ───────────────────────────────────────────────────────
  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kOrange.withOpacity(0.08), _kOrange.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kOrange.withOpacity(0.15)),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aperçu', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(18), fontWeight: FontWeight.bold, color: _kOrange)),
                    Text(widget.ecole.parametreNom ?? 'Établissement',
                      style: TextStyle(fontSize: _textSizeService.getScaledFontSize(13), color: _kTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Type', widget.ecole.typePrincipal, Icons.category_rounded, _getTypeColor(widget.ecole.typePrincipal))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Statut', widget.ecole.statut ?? 'Actif', Icons.verified_rounded, Colors.green)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                const SizedBox(height: 6),
                Text(widget.ecole.parametreNom ?? 'Aucune description disponible',
                  style: TextStyle(fontSize: _textSizeService.getScaledFontSize(13), color: _kTextSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(9), color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(11), fontWeight: FontWeight.bold, color: _kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact section ────────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withOpacity(0.08), const Color(0xFF3B82F6).withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.contact_phone_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(18), fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                  Text('Informations de contact', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(13), color: _kTextSecondary)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactInfoCard('Adresse',
            '${widget.ecole.adresse ?? 'Non disponible'}, ${widget.ecole.ville ?? ''}, ${widget.ecole.pays ?? ''}',
            Icons.location_on_rounded, const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          if (widget.ecole.telephone?.isNotEmpty == true) ...[
            _buildContactInfoCard('Téléphone', widget.ecole.telephone!, Icons.phone_rounded, Colors.green),
            const SizedBox(height: 8),
          ],
          FutureBuilder<EcoleDetail>(
            future: EcoleApiService.getEcoleDetail(widget.ecole.parametreCode ?? ''),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final d = snap.data!.data;
              return Column(
                children: [
                  if (d.email?.isNotEmpty == true) ...[
                    _buildContactInfoCard('Email', d.email!, Icons.email_rounded, Colors.orange),
                    const SizedBox(height: 8),
                  ],
                  if (d.site?.isNotEmpty == true)
                    _buildContactInfoCard('Site web', d.site!, Icons.web_rounded, Colors.purple),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(11), fontWeight: FontWeight.w600, color: _kTextSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(12), color: _kTextPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info section ───────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.08), Colors.green.withOpacity(0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.info_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(18), fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Détails administratifs', style: TextStyle(fontSize: _textSizeService.getScaledFontSize(13), color: _kTextSecondary)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoDetailCard('Code établissement', widget.ecole.parametreCode ?? 'Non disponible', Icons.code_rounded, const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _buildInfoDetailCard('Ville', widget.ecole.ville ?? 'Non spécifiée', Icons.location_city_rounded, Colors.orange),
          const SizedBox(height: 8),
          _buildInfoDetailCard('Pays', widget.ecole.pays ?? 'Non spécifié', Icons.public_rounded, Colors.purple),
          const SizedBox(height: 8),
          if (widget.ecole.filiereNom.isNotEmpty)
            _buildInfoDetailCard('Filières', widget.ecole.filiereNom.join(', '), Icons.school_rounded, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildInfoDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(11), fontWeight: FontWeight.w600, color: _kTextSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: _textSizeService.getScaledFontSize(12), color: _kTextPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Detailed info from API (logo, infos académiques, infra, rubriques) ─────
  Widget _buildDetailedInfoSection() {
    return FutureBuilder<EcoleDetail>(
      future: EcoleApiService.getEcoleDetail(widget.ecole.parametreCode ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _kOrange)));
        }
        if (snapshot.hasError || !snapshot.hasData) return const SizedBox.shrink();
        final detail = snapshot.data!;
        final data = detail.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero logo card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kCard, borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  if (data.logo != null)
                    ClipRRect(borderRadius: BorderRadius.circular(14),
                      child: Image.network(data.logo!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: _kSurface, child: const Icon(Icons.school_rounded, color: _kTextSecondary))))
                  else
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: _kOrangeLight, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.school_rounded, color: _kOrange, size: 30)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextPrimary), maxLines: 2),
                      if (data.slogan != null) ...[
                        const SizedBox(height: 4),
                        Text(data.slogan!, style: const TextStyle(fontSize: 12, color: _kOrange, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _infoCard('Informations principales', [
              _infoDetailRow('Code', data.code),
              _infoDetailRow('Type', data.type),
              _infoDetailRow('Statut', data.statut),
              _infoDetailRow('Période', data.periode),
              _infoDetailRow('Année', data.annee),
            ]),
            _infoCard('Informations académiques', [
              _infoDetailRow('Directeur rentrée', data.dren),
              _infoDetailRow('Nbre d\'années', data.nbrannee?.toString() ?? 'N/A'),
              _infoDetailRow('Mode inscription', data.modeinsc.toString()),
              _infoDetailRow('Statut inscription', data.inscriptionsatatus.toString()),
              if (detail.client.effectif != null) _infoDetailRow('Effectif', '${detail.client.effectif} élèves'),
            ]),
            if (data.montantReservation != null && data.montantReservation! > 0)
              _infoCard('Réservations', [
                _infoDetailRow('Montant', '${data.montantReservation} FCFA'),
                _infoDetailRow('Début', data.debutReservation ?? 'N/A'),
                _infoDetailRow('Fin', data.finReservation ?? 'N/A'),
              ]),
            if (detail.infrastructures.isNotEmpty)
              _infoCard('Infrastructure & services',
                detail.infrastructures.map((i) => _infoDetailRow(i['nom']?.toString() ?? 'Service', i['description']?.toString() ?? 'Disponible')).toList()),
            if (detail.rubriques.isNotEmpty)
              _infoCard('Rubriques',
                detail.rubriques.map((r) => _infoDetailRow(r['nom']?.toString() ?? 'Rubrique', r['description']?.toString() ?? 'Disponible')).toList()),
          ],
        );
      },
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), child: Divider(color: _kDivider, height: 1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: _kTextPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CustomTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CustomTabBarDelegate(this.child);
  @override double get minExtent => 58.0;
  @override double get maxExtent => 58.0;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(_CustomTabBarDelegate old) => false;
}