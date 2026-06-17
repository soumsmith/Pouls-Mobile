import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/blog.dart';
import '../models/ecole.dart';
import '../config/app_colors.dart';
import '../services/ecole_api_service.dart';
import '../widgets/components/section_row.dart';
import '../widgets/share_bottom_sheet.dart';
import 'establishment_detail_screen.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../config/app_dimensions.dart';
import '../widgets/components/custom_button.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/components/bottom_spacer.dart';
import '../config/app_config.dart';
import '../services/blog_service.dart';
import '../widgets/image_menu_card_external_title.dart';
import 'all_blogs_screen.dart';

// ─────────────────────────────────────────────
//  Design tokens (cohérents avec EventDetailScreen)
// ─────────────────────────────────────────────
class _C {
  static const indigo = Color(0xFF6366F1);
  static const indigoDark = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF2FF);
  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEE2E2);
  static const slate900 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFF1F5F9);
  static const gold = Color(0xFFF59E0B);
  static const surface = Color(0xFFF8F8FC);
  static const white = Colors.white;
}

// ─────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────
class BlogDetailScreen extends StatefulWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── state ───────────────────────────────────
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _userRating = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _isSubmittingComment = false;

  List<Blog> _schoolBlogs = [];
  bool _schoolBlogsLoading = true;

  bool _isBookmarked = false;
  AnimationController? _bookmarkController;
  Animation<double>? _bookmarkAnim;

  @override
  void initState() {
    super.initState();
    _bookmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bookmarkAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _bookmarkController!, curve: Curves.elasticOut),
    );
    _loadSchoolBlogs();
  }

  Future<void> _loadSchoolBlogs() async {
    try {
      final blogsResponse = await BlogService().getBlogsByEcole(
        '',
        widget.blog.codeecole ?? '',
      );
      if (mounted) {
        setState(() {
          _schoolBlogs = blogsResponse.data
              .where((b) => b.slug != widget.blog.slug)
              .toList();
          _schoolBlogsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _schoolBlogsLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _bookmarkController?.dispose();
    super.dispose();
  }

  // ── actions ─────────────────────────────────
  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() => _isBookmarked = !_isBookmarked);
    _bookmarkController?.forward(from: 0);
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        title: 'Partager l\'actualité',
        itemTitle: widget.blog.title,
        shareText:
            '''
📰 ${widget.blog.title}

🏫 ${widget.blog.nomecole}

${widget.blog.content.replaceAll(RegExp(r'<[^>]*>'), '').trim()}
${widget.blog.toUiMap()['liendetailblog'] != null ? '\n🔗 Lien: ${widget.blog.toUiMap()['liendetailblog']}\n' : ''}
Découvrez plus d\'actualités sur notre application! 📱
Téléchargez l'application ici : ${AppConfig.storeUrl}
''',
      ),
    );
  }

  void _scrollToComments() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _visitSchool() async {
    final code = widget.blog.codeecole?.trim() ?? '';
    if (code.isEmpty) {
      _showSnack('Code école non disponible', _C.rose);
      return;
    }
    try {
      final ecoleDetail = await EcoleApiService.getEcoleDetail(code);
      final ecole = Ecole(
        pays: ecoleDetail.data.pays,
        ville: ecoleDetail.data.ville,
        adresse: ecoleDetail.data.adresse,
        parametreNom: ecoleDetail.data.nom,
        logo: ecoleDetail.data.logo ?? '',
        telephone: ecoleDetail.data.telephone,
        parametreCode: code,
        statut: ecoleDetail.data.statut,
        filiereNom: const [],
        imagefond: ecoleDetail.image,
        paramecole: null,
      );
      if (!mounted) return;
      MainScreenWrapper.of(context).navigateToEstablishmentDetail(ecole);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur: $e', _C.rose);
    }
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) {
      _showSnack('Veuillez entrer un commentaire', _C.rose);
      return;
    }
    if (_userRating == 0) {
      _showSnack('Veuillez attribuer une note', _C.amber);
      return;
    }
    setState(() => _isSubmittingComment = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _comments.insert(0, {
          'author': 'Vous',
          'comment': _commentController.text.trim(),
          'rating': _userRating,
          'date': DateTime.now().toIso8601String(),
        });
        _isSubmittingComment = false;
        _commentController.clear();
        _userRating = 0;
      });
      _showSnack('Commentaire ajouté avec succès', _C.emerald);
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uiData = widget.blog.toUiMap();
    final typeColor = uiData['color'] as Color;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(uiData, typeColor),
            SliverToBoxAdapter(child: _buildBody(typeColor, uiData)),
          ],
        ),
      ),
    );
  }

  // ── Hero SliverAppBar ───────────────────────
  Widget _buildSliverAppBar(Map<String, dynamic> uiData, Color typeColor) {
    return CustomSliverAppBar(
      title: '',
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Center(
          child: _NavIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (MainScreenWrapper.maybeOf(context) != null) {
                MainScreenWrapper.of(context).goBackToPreviousTab();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
      actions: [
        _NavIconBtn(
          icon: _isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: _isBookmarked ? _C.amber : Colors.white,
          onTap: _toggleBookmark,
          scaleAnim: _bookmarkAnim,
        ),
        const SizedBox(width: 4),
        _NavIconBtn(icon: Icons.share_rounded, onTap: _showShareMenu),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _HeroBanner(
          blog: widget.blog,
          typeColor: typeColor,
          uiData: uiData,
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────
  Widget _buildBody(Color typeColor, Map<String, dynamic> uiData) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenSurfaceThemed(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildDragHandle(),
          const SizedBox(height: 20),
          _buildActionBar(),
          const SizedBox(height: 24),
          _buildMetaCards(typeColor, uiData),
          const SizedBox(height: 24),
          _buildContent(),
          const SizedBox(height: 28),
          _buildOtherBlogs(),
          const SizedBox(height: 28),
          _buildRatingAndComments(),
          const SizedBox(height: 40),
          const BottomSpacer(height: 125),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF333333) : _C.slate300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Action Bar ──────────────────────────────
  Widget _buildActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemWidth = (MediaQuery.of(context).size.width - 40 - 12) / 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          CustomButton(
            width: itemWidth,
            icon: Icons.share_rounded,
            text: 'Partager',
            color: _C.indigo,
            isLight: true,
            onPressed: _showShareMenu,
          ),
          CustomButton(
            width: itemWidth,
            icon: _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            text: _isBookmarked ? 'Enregistré' : 'Enregistrer',
            color: _C.amber,
            isLight: true,
            onPressed: _toggleBookmark,
          ),
          CustomButton(
            width: itemWidth,
            icon: Icons.chat_bubble_outline_rounded,
            text: 'Commenter',
            color: _C.emerald,
            isLight: true,
            onPressed: _scrollToComments,
          ),
          CustomButton(
            width: itemWidth,
            icon: Icons.school_rounded,
            text: 'École',
            color: isDark ? const Color(0xFF333333) : _C.slate900,
            isLight: true,
            onPressed: _visitSchool,
          ),
        ],
      ),
    );
  }

  // ── Meta Cards ──────────────────────────────
  Widget _buildMetaCards(Color typeColor, Map<String, dynamic> uiData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              icon: uiData['icon'] as IconData,
              iconBg: typeColor.withOpacity(0.12),
              iconColor: typeColor,
              title: uiData['type'] as String,
              subtitle: uiData['date'] as String,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCard(
              icon: Icons.school_rounded,
              iconBg: _C.emeraldLight,
              iconColor: _C.emerald,
              title: widget.blog.nomecole,
              subtitle: 'Établissement',
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ─────────────────────────────────
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contenu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: _ExpandableText(text: _stripHtmlTags(widget.blog.content)),
          ),
        ],
      ),
    );
  }

  // ── Other Blogs ─────────────────────────────
  double _getCardWidth(BuildContext context, double rightMargin) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (rightMargin * 2);

    if (AppDimensions.isLargeTablet(context)) {
      return availableWidth / 4.5;
    } else if (AppDimensions.isTablet(context)) {
      return availableWidth / 3.5;
    }
    return availableWidth / 2.2;
  }

  Widget _buildOtherBlogs() {
    if (_schoolBlogsLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_schoolBlogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet =
        AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    final double cardWidth = _getCardWidth(context, 16.0);
    final double imageRatio = isTablet ? 0.62 : 0.8;
    final double imageHeight = cardWidth * imageRatio;
    final double textHeight = AppDimensions.getScaledSize(context, 85.0);
    final double containerHeight = imageHeight + textHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Autres actualités',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimaryThemed(context),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  MainScreenWrapper.of(context).navigateToExtraScreen(
                    AllBlogsScreen(schoolCode: widget.blog.codeecole),
                  );
                },
                child: const Text(
                  'Voir plus',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: containerHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _schoolBlogs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 0),
            itemBuilder: (context, i) =>
                _buildSchoolBlogCard(_schoolBlogs[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolBlogCard(Blog blog, int index) {
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
        actionTextColor: uiData['color'] as Color,
        tag: (uiData['type'] as String).toUpperCase(),
        color: uiData['color'] as Color,
        imagePath: blog.image,
        iconData: uiData['icon'] as IconData,
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
          if (MainScreenWrapper.maybeOf(context) != null) {
            MainScreenWrapper.of(context).navigateToExtraScreen(
              BlogDetailScreen(key: UniqueKey(), blog: blog),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BlogDetailScreen(key: UniqueKey(), blog: blog)),
            );
          }
        },
      ),
    );
  }

  // ── Ratings & Comments ──────────────────────
  Widget _buildRatingAndComments() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Avis & commentaires',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Formulaire d'avis
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.screenCardThemed(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? _C.indigo.withOpacity(0.2)
                            : _C.indigoLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: _C.indigo,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre avis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.screenTextPrimaryThemed(context),
                          ),
                        ),
                        Text(
                          'Partagez votre opinion',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.screenTextSecondaryThemed(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 16),

                // Étoiles
                Text(
                  'Note',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondaryThemed(context),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < _userRating;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _userRating = i + 1.0);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            key: ValueKey('$i-$filled'),
                            color: filled
                                ? _C.gold
                                : (isDark
                                      ? const Color(0xFF444444)
                                      : _C.slate300),
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_userRating > 0) ...[
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_userRating),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? _C.amber.withOpacity(0.2)
                            : _C.amberLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _ratingLabel(_userRating.toInt()),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.amber,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Commentaire
                Text(
                  'Commentaire',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextSecondaryThemed(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Partagez votre avis sur ce blog…',
                    hintStyle: TextStyle(
                      color: AppColors.screenTextSecondaryThemed(context),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E2A) : _C.slate100,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _C.indigo,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton envoyer
                CustomButton(
                  text: 'Publier mon avis',
                  color: _C.indigo,
                  icon: Icons.send_rounded,
                  onPressed: _submitComment,
                  isLoading: _isSubmittingComment,
                  height: 50,
                ),
              ],
            ),
          ),
        ),

        // Liste des commentaires
        if (_comments.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Commentaires récents',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? _C.indigo.withOpacity(0.2) : _C.indigoLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _buildCommentCard(_comments[i]),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2A) : _C.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 26,
                      color: AppColors.screenTextSecondaryThemed(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier à commenter',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.screenTextSecondaryThemed(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rating = (comment['rating'] as double).toInt();
    final author = comment['author'] as String;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark
                    ? _C.indigo.withOpacity(0.2)
                    : _C.indigoLight,
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _C.indigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.screenTextPrimaryThemed(context),
                      ),
                    ),
                    Text(
                      _formatDate(comment['date'] as String),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.screenTextSecondaryThemed(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: _C.gold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment['comment'] as String,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.screenTextPrimaryThemed(context),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────
  String _ratingLabel(int rating) {
    const labels = ['Mauvais', 'Passable', 'Bien', 'Très bien', 'Excellent'];
    if (rating < 1 || rating > 5) return '';
    return labels[rating - 1];
  }

  String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(
      r'<[^>]*>',
      multiLine: true,
      caseSensitive: false,
    );
    return htmlString.replaceAll(exp, '').trim();
  }

  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      const months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateString;
    }
  }
}

// ─────────────────────────────────────────────
//  Hero Banner
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final Blog blog;
  final Color typeColor;
  final Map<String, dynamic> uiData;

  const _HeroBanner({
    required this.blog,
    required this.typeColor,
    required this.uiData,
  });

  void _openImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ShareBottomSheet(
                      title: 'Partager l\'actualité',
                      itemTitle: blog.title,
                      shareText:
                          '''
📰 ${blog.title}

🏫 ${blog.nomecole}

${blog.content.replaceAll(RegExp(r'<[^>]*>'), '').trim()}
${blog.toUiMap()['liendetailblog'] != null ? '\n🔗 Lien: ${blog.toUiMap()['liendetailblog']}\n' : ''}
Découvrez plus d\'actualités sur notre application! 📱
Téléchargez l'application ici : ${AppConfig.storeUrl}
''',
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image de fond
        blog.image != null && blog.image!.isNotEmpty
            ? Image.network(
                blog.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),

        // Gradient overlay
        GestureDetector(
          onTap: () {
            if (blog.image != null && blog.image!.isNotEmpty) {
              _openImage(context, blog.image!);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Contenu positionné en bas
        Positioned(
          bottom: 36,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      uiData['icon'] as IconData,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      uiData['type'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Titre
              Text(
                blog.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // École
              Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      blog.nomecole,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [typeColor.withOpacity(0.85), typeColor.withOpacity(0.4)],
        ),
      ),
      child: const Icon(Icons.article_rounded, color: Colors.white24, size: 80),
    );
  }
}

// ─────────────────────────────────────────────
//  Reusable widgets
// ─────────────────────────────────────────────
class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Animation<double>? scaleAnim;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
    );
    if (scaleAnim != null) {
      return ScaleTransition(scale: scaleAnim!, child: btn);
    }
    return btn;
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.screenCardThemed(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.screenTextPrimaryThemed(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.screenTextSecondaryThemed(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Expandable Text
// ─────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const _ExpandableText({required this.text, this.maxLines = 6});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.screenTextPrimaryThemed(context),
              height: 1.65,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.screenTextPrimaryThemed(context),
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Voir moins' : 'Lire la suite',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.indigo,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _expanded ? 0.5 : 0,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _C.indigo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// End of file
