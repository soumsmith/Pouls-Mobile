import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/main_screen_wrapper.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../config/app_typography.dart';
import 'add_child_screen.dart';
import '../utils/auth_guard.dart';
import 'pdf_viewer_screen.dart';
import 'visite_guidee_video_feed_screen.dart';
import '../models/visite_guidee_video.dart';
import '../widgets/scroll_to_top_fab.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final TextSizeService _textSizeService = TextSizeService();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color ?? AppColors.screenOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        floatingActionButton: ScrollToTopFab(scrollController: _scrollController, bottomSpacerHeight: 70),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildQuickHelpCards(),
                      const SizedBox(height: 24),
                      _buildFAQSection(),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 24),
                      _buildResourcesSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppColors.screenSurfaceThemed(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  if (MainScreenWrapper.maybeOf(context) != null) {
                    MainScreenWrapper.of(context).goBackToPreviousTab();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenCardThemed(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppDimensions.getSettingsCardShadow(context),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aide & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimaryThemed(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Comment pouvons-nous vous aider ?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondaryThemed(context),
                        fontWeight: FontWeight.w400,
                      ),
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

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.screenTextPrimaryThemed(context),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher une aide...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppColors.screenTextSecondaryThemed(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.screenOrange,
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close,
                    color: AppColors.screenTextSecondaryThemed(context),
                    size: 16,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.screenTextPrimaryThemed(context),
        letterSpacing: -0.3,
      ),
    );
  }

  // ─── QUICK HELP CARDS ─────────────────────────────────────────────────────
  Widget _buildQuickHelpCards() {
    final cards = [
      {
        'title': 'Premiers pas',
        'subtitle': 'Guide de démarrage rapide',
        'icon': Icons.rocket_launch_outlined,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Ajouter un enfant',
        'subtitle': 'Comment gérer vos enfants',
        'icon': Icons.child_care_outlined,
        'color': AppColors.screenOrange,
      },
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Aide Rapide'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
              final double screenWidth = MediaQuery.of(context).size.width;
              final double horizontalPadding = 32.0; // 16 margin on each side
              final double spacing = 12.0;
              final double columnWidth = (screenWidth - horizontalPadding - spacing) / 2;
              final double targetHeight = isTablet ? 150.0 : 135.0;
              final double childAspectRatio = columnWidth / targetHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final color = card['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      if (card['title'] == 'Ajouter un enfant') {
                        AuthGuard.ensureLoggedIn(
                          context,
                          reason: 'Connectez-vous pour ajouter un enfant',
                          onAuthenticated: () {
                            MainScreenWrapper.of(
                              context,
                            ).navigateToExtraScreen(const AddChildScreen());
                          },
                        );
                      } else if (card['title'] == 'Premiers pas') {
                        MainScreenWrapper.of(context).navigateToExtraScreen(
                          const PDFViewerScreen(
                            pdfUrl: 'assets/document/guide-complet.pdf',
                            title: 'Guide Complet',
                          ),
                        );
                      } else {
                        _showSnack('Ouverture de ${card['title']}...');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.screenCardThemed(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppDimensions.getSettingsCardShadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              card['icon'] as IconData,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            card['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.screenTextPrimaryThemed(context),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Text(
                              card['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.screenTextSecondaryThemed(context),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── FAQ SECTION ──────────────────────────────────────────────────────────
  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'Comment ajouter un enfant à mon compte ?',
        'answer':
            'Allez dans l\'écran d\'accueil, cliquez sur le bouton "+" en bas à droite et remplissez les informations de votre enfant.',
        'category': 'Compte',
        'categoryColor': AppColors.screenOrange,
      },
      {
        'question': 'Comment payer les frais scolaires ?',
        'answer':
            'Naviguez vers l\'écran "Frais" depuis le menu, sélectionnez l\'enfant et le type de frais, puis choisissez votre méthode de paiement.',
        'category': 'Paiements',
        'categoryColor': const Color(0xFFF59E0B),
      },
      {
        'question': 'Comment contacter un enseignant ?',
        'answer':
            'Depuis le profil de votre enfant, cliquez sur "Établissement" puis sur "Contact" pour accéder aux coordonnées des enseignants.',
        'category': 'Communication',
        'categoryColor': const Color(0xFF3B82F6),
      },
      {
        'question': 'Mes données sont-elles sécurisées ?',
        'answer':
            'Oui, toutes vos données sont chiffrées et protégées conformément au RGPD. Nous ne partageons jamais vos informations sans consentement.',
        'category': 'Sécurité',
        'categoryColor': const Color(0xFF4CAF50),
      },
    ];

    final filtered = _searchQuery.isEmpty
        ? faqs
        : faqs
              .where(
                (f) =>
                    (f['question'] as String).toLowerCase().contains(
                      _searchQuery,
                    ) ||
                    (f['answer'] as String).toLowerCase().contains(
                      _searchQuery,
                    ) ||
                    (f['category'] as String).toLowerCase().contains(
                      _searchQuery,
                    ),
              )
              .toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Questions Fréquentes'),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.screenCardThemed(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppDimensions.getSettingsCardShadow(context),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 36,
                      color: AppColors.screenOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimaryThemed(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Essayez avec d\'autres mots-clés',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.screenTextSecondaryThemed(context),
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.asMap().entries.map((entry) {
              return _buildFAQItem(entry.value, entry.key);
            }),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, int index) {
    final catColor = faq['categoryColor'] as Color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.screenCardThemed(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDimensions.getSettingsCardShadow(context),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.screenOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                color: AppColors.screenOrange,
                size: 18,
              ),
            ),
            title: Text(
              faq['question'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextPrimaryThemed(context),
                letterSpacing: -0.2,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  faq['category'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: catColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            iconColor: AppColors.screenTextSecondaryThemed(context),
            collapsedIconColor: AppColors.screenTextSecondaryThemed(context),
            children: [
              Divider(color: AppColors.screenDividerThemed(context), height: 1),
              const SizedBox(height: 12),
              Text(
                faq['answer'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextSecondaryThemed(context),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CONTACT SECTION ──────────────────────────────────────────────────────
  Widget _buildContactSection() {
    final contacts = [
      {
        'title': 'Support par Email',
        'subtitle': 'mous-soum@groupegain.com',
        'icon': Icons.email_outlined,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Support Téléphonique',
        'subtitle': "+225 07 48 01 12 47",
        'icon': Icons.phone_outlined,
        'color': AppColors.screenOrange,
      },
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Contactez-nous'),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Column(
              children: contacts.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final isLast = i == contacts.length - 1;
                final color = c['color'] as Color;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {}, // Aucune action
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(20) : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(20)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  c['icon'] as IconData,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.screenTextPrimaryThemed(
                                              context,
                                            ),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['subtitle'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppColors.screenTextSecondaryThemed(
                                              context,
                                            ),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 13,
                                color: AppColors.screenTextSecondaryThemed(
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: EdgeInsets.only(left: 74),
                        child: Divider(
                          color: AppColors.screenDividerThemed(context),
                          height: 1,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContact(String action) {
    switch (action) {
      case 'chat':
        _showSnack('Le chat sera bientôt disponible !');
        break;
      case 'email':
        _showSnack('Ouverture du client email...');
        break;
      case 'phone':
        _showSnack('Ouverture du téléphone...');
        break;
    }
  }

  // ─── RESOURCES SECTION ────────────────────────────────────────────────────
  Widget _buildResourcesSection() {
    final resources = [
      {
        'title': 'Guide Complet',
        'subtitle': 'Manuel d\'utilisation détaillé',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF9C27B0),
      },
      {
        'title': 'Vidéos Tutoriel',
        'subtitle': 'Apprenez en vidéo',
        'icon': Icons.video_library_outlined,
        'color': const Color(0xFFF44336),
      },
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ressources'),
          const SizedBox(height: 14),
          ...resources.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final color = r['color'] as Color;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  if (r['title'] == 'Guide Complet') {
                    MainScreenWrapper.of(context).navigateToExtraScreen(
                      const PDFViewerScreen(
                        pdfUrl:
                            'https://groupegain.s3.eu-west-1.amazonaws.com/parent_respo/guide-complet-parent-respo.pdf',
                        title: 'Guide Complet',
                      ),
                    );
                  } else if (r['title'] == 'Vidéos Tutoriel') {
                    MainScreenWrapper.of(context).navigateToExtraScreen(
                      VisiteGuideeVideoFeedScreen(
                        videos: [
                          VisiteGuideeVideo(
                            id: 1,
                            typeVideo: 'tutoriel',
                            youtubeUrl:
                                'https://groupegain.s3.eu-west-1.amazonaws.com/parent_respo/parent_respo_video.mp4',
                            title: 'Tutoriel complet',
                            description:
                                'Apprenez à utiliser l\'application étape par étape',
                            code: 'app',
                            etablissement: 'Pouls Scolaire',
                          ),
                        ],
                      ),
                    );
                  } else {
                    _showSnack('Ouverture de ${r['title']}...');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.screenCardThemed(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDimensions.getSettingsCardShadow(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          r['icon'] as IconData,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.screenTextPrimaryThemed(
                                  context,
                                ),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.screenTextSecondaryThemed(
                                  context,
                                ),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.screenSurfaceThemed(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.open_in_new,
                          size: 15,
                          color: AppColors.screenTextSecondaryThemed(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const BottomSpacer(height: 125),
        ],
      ),
    );
  }
}
