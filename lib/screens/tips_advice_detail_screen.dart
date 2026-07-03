import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/astuce_conseil.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../config/app_dimensions.dart';
import '../widgets/components/custom_button.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/components/bottom_spacer.dart';
import '../utils/image_helper.dart';
import '../utils/html_helper.dart';
import '../widgets/scroll_to_top_fab.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/image_menu_card_external_title.dart';
import '../config/app_config.dart';
import '../services/astuce_conseil_service.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────
class _C {
  static const orange = Colors.orange;
  static const orangeLight = Color(0xFFFFF7ED);
  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFFEEF2FF);
  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFEF4444);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate900 = Color(0xFF1E293B);
  static const slate100 = Color(0xFFF1F5F9);
  static const surface = Color(0xFFF8F8FC);
}

class TipsAdviceDetailScreen extends StatefulWidget {
  final AstuceConseil astuce;

  const TipsAdviceDetailScreen({super.key, required this.astuce});

  @override
  State<TipsAdviceDetailScreen> createState() => _TipsAdviceDetailScreenState();
}

class _TipsAdviceDetailScreenState extends State<TipsAdviceDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isBookmarked = false;
  AnimationController? _bookmarkController;
  Animation<double>? _bookmarkAnim;

  List<Map<String, dynamic>> _comments = [];
  bool _isSubmittingComment = false;
  bool _isLoadingComments = true;

  late int _likesCount;
  late int _commentsCount;
  final AstuceConseilService _apiService = AstuceConseilService();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.astuce.likesCount;
    _commentsCount = widget.astuce.commentsCount;

    _bookmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bookmarkAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _bookmarkController!, curve: Curves.elasticOut),
    );

    _fetchComments();
    _checkLikeStatus();
  }

  Future<void> _fetchComments() async {
    final apiComments = await _apiService.getComments(widget.astuce.slug);
    if (!mounted) return;
    setState(() {
      _comments = apiComments
          .map(
            (c) => <String, dynamic>{
              'author':
                  (c['author_name'] ?? c['nom'])?.toString() ?? 'Utilisateur',
              'comment': (c['content'] ?? c['contenu'])?.toString() ?? '',
              'date':
                  c['created_at']?.toString() ??
                  DateTime.now().toIso8601String(),
            },
          )
          .toList();
      _commentsCount = _comments.length;
      _isLoadingComments = false;
    });
  }

  Future<void> _checkLikeStatus() async {
    final user = AuthService.instance.getCurrentUser();
    if (user == null) return;

    final likes = await _apiService.getLikes(widget.astuce.slug);
    final hasLiked = likes.any((like) => like['userid']?.toString() == user.id);

    if (mounted) {
      setState(() {
        _isBookmarked = hasLiked;
        // Optionnel : on peut mettre à jour le count basé sur le serveur
        // _likesCount = likes.length;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _bookmarkController?.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final user = AuthService.instance.getCurrentUser();
    if (user == null) {
      _showSnack('Veuillez vous connecter pour aimer', _C.orange);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isBookmarked = !_isBookmarked;
      _likesCount += _isBookmarked ? 1 : -1;
    });
    _bookmarkController?.forward(from: 0);

    final success = await _apiService.likeArticle(
      widget.astuce.slug,
      nom: user.fullName,
      userId: int.tryParse(user.id) ?? 0,
    );

    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _isBookmarked = !_isBookmarked;
        _likesCount += _isBookmarked ? 1 : -1;
      });
      _showSnack('Erreur lors de l\'enregistrement', _C.rose);
    }
  }

  void _showShareMenu() {
    final user = AuthService.instance.getCurrentUser();
    if (user != null) {
      _apiService.recordShare(
        widget.astuce.slug,
        nom: user.fullName,
        userId: int.tryParse(user.id) ?? 0,
      );
    }

    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        title: 'Partager l\'astuce',
        itemTitle: widget.astuce.title,
        shareText:
            '''
💡 ${widget.astuce.title}

${HtmlHelper.stripHtmlTags(widget.astuce.content)}

Découvrez plus d\'astuces sur notre application! 📱
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

  Future<void> _submitComment() async {
    final user = AuthService.instance.getCurrentUser();
    if (user == null) {
      _showSnack('Veuillez vous connecter pour commenter', _C.orange);
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      _showSnack('Veuillez entrer un commentaire', _C.rose);
      return;
    }

    setState(() => _isSubmittingComment = true);

    final content = _commentController.text.trim();
    final success = await _apiService.addComment(
      widget.astuce.slug,
      nom: user.fullName,
      userId: int.tryParse(user.id) ?? 0,
      contenu: content,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _comments.insert(0, <String, dynamic>{
          'author': user.fullName,
          'comment': content,
          'date': DateTime.now().toIso8601String(),
        });
        _commentsCount = _comments.length;
        _isSubmittingComment = false;
        _commentController.clear();
      });
      _showSnack('Commentaire ajouté avec succès', _C.emerald);
    } else {
      setState(() => _isSubmittingComment = false);
      _showSnack('Erreur lors de l\'ajout du commentaire', _C.rose);
    }
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.screenSurfaceThemed(context),
        floatingActionButton: ScrollToTopFab(
          scrollController: _scrollController,
          bottomSpacerHeight: 70,
        ),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
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
          icon: Icons.share_rounded,
          iconColor: Colors.white,
          onTap: _showShareMenu,
        ),
        const SizedBox(width: 8),
        _NavIconBtn(
          icon: _isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          iconColor: _isBookmarked ? _C.amber : Colors.white,
          onTap: _toggleBookmark,
          scaleAnim: _bookmarkAnim,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _HeroBanner(
          astuce: widget.astuce,
          onShare: _showShareMenu,
        ),
      ),
    );
  }

  Widget _buildBody() {
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
          _buildMetaCards(),
          const SizedBox(height: 24),
          _buildContent(),
          const SizedBox(height: 28),
          _buildComments(),
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

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildActionItem(
            0,
            'action_share',
            'Partager',
            _C.emerald,
            _showShareMenu,
            imagePath: 'assets/images/icons/partage.png',
          ),
          _buildActionItem(
            1,
            'action_comment',
            'Avis',
            _C.emerald,
            _scrollToComments,
            imagePath: 'assets/images/icons/comment.png',
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    int index,
    String key,
    String title,
    Color color,
    VoidCallback onTap, {
    IconData? icon,
    String? imagePath,
  }) {
    final size = AppDimensions.getSquareCardWidthSize(context);
    return ImageMenuCardExternalTitle(
      index: index,
      cardKey: key,
      width: size,
      title: title,
      iconData: icon,
      imagePath: imagePath,
      color: color,
      imageHeight: size,
      imageBorderRadius: size / 2,
      centerTitle: true,
      allowLineBreak: true,
      titleMaxLines: 2,
      onTap: onTap,
    );
  }

  Widget _buildMetaCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              icon: Icons.lightbulb_outline,
              iconBg: _C.orange.withOpacity(0.12),
              iconColor: _C.orange,
              title: 'Conseil',
              subtitle: widget.astuce.toUiMap()['date'] as String,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCard(
              icon: Icons.favorite_rounded,
              iconBg: _C.rose.withOpacity(0.12),
              iconColor: _C.rose,
              title: '$_likesCount J\'aime',
              subtitle: 'Interactions',
            ),
          ),
        ],
      ),
    );
  }

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
            child: _ExpandableText(
              text: HtmlHelper.stripHtmlTags(widget.astuce.content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Commentaires',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.screenCardThemed(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppDimensions.getSettingsCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laisser un commentaire',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Votre avis...',
                  hintStyle: TextStyle(
                    color: AppColors.screenTextSecondaryThemed(context),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E2A)
                      : AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Publier',
                  icon: Icons.send_rounded,
                  color: _C.emerald,
                  onPressed: _submitComment,
                  isLoading: _isSubmittingComment,
                ),
              ),
            ],
          ),
        ),
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
                    color: isDark
                        ? _C.emerald.withOpacity(0.2)
                        : _C.emeraldLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_commentsCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.emerald,
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
              child: _isLoadingComments
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E2A)
                                : _C.slate100,
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
                    ? _C.emerald.withOpacity(0.2)
                    : _C.emeraldLight,
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _C.emerald,
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

class _HeroBanner extends StatelessWidget {
  final AstuceConseil astuce;
  final VoidCallback onShare;

  const _HeroBanner({required this.astuce, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, astuce),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (astuce.image != null && astuce.image!.isNotEmpty)
            ImageHelper.buildNetworkImage(
              imageUrl: astuce.image!,
              placeholder: 'assets/images/placeholder.png',
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            )
          else
            Container(
              color: _C.orange.withOpacity(0.1),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: _C.orange,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CONSEIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  astuce.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, AstuceConseil astuce) {
    if (astuce.image == null || astuce.image!.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ImageHelper.buildNetworkImage(
                    imageUrl: astuce.image!,
                    placeholder: 'assets/images/placeholder.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text(
                        'Partager',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onShare();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Animation<double>? scaleAnim;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
    this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(child: Icon(icon, color: iconColor, size: 20)),
    );
    if (scaleAnim != null) {
      child = ScaleTransition(scale: scaleAnim!, child: child);
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: child,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: _C.orange,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _expanded ? 0.5 : 0,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _C.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
