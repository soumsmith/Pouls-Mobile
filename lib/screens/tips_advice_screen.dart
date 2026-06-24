import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../widgets/components/bottom_spacer.dart';
import '../widgets/scroll_to_top_fab.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────────────
const _kTipsBlue = Color(0xFF5B8DEF);
const _kTipsPurple = Color(0xFF8B5CF6);
const _kTipsGreen = Color(0xFF10B981);
const _kTipsOrange = Color(0xFFFF6B2C);
const _kTipsYellow = Color(0xFFF59E0B);
const _kTipsPink = Color(0xFFEC4899);

class TipsAdviceScreen extends StatefulWidget {
  const TipsAdviceScreen({super.key});

  @override
  State<TipsAdviceScreen> createState() => _TipsAdviceScreenState();
}

class _TipsAdviceScreenState extends State<TipsAdviceScreen>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
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
        floatingActionButton: ScrollToTopFab(
          scrollController: _scrollController,
          bottomSpacerHeight: 70,
        ),
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
                      _buildHeaderBanner(),
                      const SizedBox(height: 24),
                      _buildTipsSection(
                        title: '📚 Conseils Scolaires',
                        tips: _scolaireTips,
                      ),
                      const SizedBox(height: 24),
                      _buildTipsSection(
                        title: '💡 Astuces Parents',
                        tips: _parentTips,
                      ),
                      const SizedBox(height: 24),
                      _buildTipsSection(
                        title: '🌟 Bien-être de l\'enfant',
                        tips: _bienEtreTips,
                      ),
                      const SizedBox(height: 16),
                      const BottomSpacer(),
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
                      'Astuces & Conseils',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimaryThemed(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Des conseils pratiques pour les parents',
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

  // ─── HEADER BANNER ────────────────────────────────────────────────────────
  Widget _buildHeaderBanner() {
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A3C), Color(0xFFFF6B2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B2C).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '✨ Le saviez-vous ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les enfants qui lisent 20 minutes par jour sont exposés à 1,8 million de mots par an !',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TIPS SECTION ─────────────────────────────────────────────────────────
  Widget _buildTipsSection({
    required String title,
    required List<Map<String, dynamic>> tips,
  }) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.screenTextPrimaryThemed(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...tips.asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;
            return _buildTipCard(tip, index);
          }),
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip, int index) {
    final color = tip['color'] as Color;

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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                tip['icon'] as IconData,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              tip['title'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimaryThemed(context),
                letterSpacing: -0.2,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tip['category'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            iconColor: AppColors.screenTextSecondaryThemed(context),
            collapsedIconColor: AppColors.screenTextSecondaryThemed(context),
            children: [
              Divider(
                color: AppColors.screenDividerThemed(context),
                height: 1,
              ),
              const SizedBox(height: 12),
              Text(
                tip['content'] as String,
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

  // ─── DATA ─────────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _scolaireTips = [
    {
      'title': 'Créer un espace de travail dédié',
      'category': 'Organisation',
      'icon': Icons.desk_rounded,
      'color': _kTipsBlue,
      'content':
          'Aménagez un coin calme et bien éclairé pour les devoirs. Un bureau rangé avec le matériel nécessaire à portée de main aide votre enfant à se concentrer et à être plus productif. Évitez les distractions comme la télévision ou les jeux à proximité.',
    },
    {
      'title': 'Établir une routine quotidienne',
      'category': 'Habitudes',
      'icon': Icons.schedule_rounded,
      'color': _kTipsPurple,
      'content':
          'Fixez des horaires réguliers pour les devoirs, la lecture et le repos. Une routine prévisible rassure l\'enfant et l\'aide à mieux gérer son temps. Incluez des pauses de 10 minutes toutes les 45 minutes de travail.',
    },
    {
      'title': 'Encourager la lecture quotidienne',
      'category': 'Lecture',
      'icon': Icons.menu_book_rounded,
      'color': _kTipsGreen,
      'content':
          'Lisez ensemble 15 à 20 minutes chaque jour. Choisissez des livres adaptés à l\'âge et aux centres d\'intérêt de votre enfant. Posez des questions sur l\'histoire pour développer sa compréhension et son esprit critique.',
    },
    {
      'title': 'Suivre les progrès régulièrement',
      'category': 'Suivi',
      'icon': Icons.trending_up_rounded,
      'color': _kTipsOrange,
      'content':
          'Consultez régulièrement les notes et les bulletins via l\'application Pouls. N\'attendez pas la fin du trimestre pour réagir. Un suivi régulier permet d\'identifier les difficultés tôt et de mettre en place un soutien adapté.',
    },
  ];

  final List<Map<String, dynamic>> _parentTips = [
    {
      'title': 'Communiquer avec les enseignants',
      'category': 'Communication',
      'icon': Icons.chat_rounded,
      'color': _kTipsBlue,
      'content':
          'N\'hésitez pas à utiliser la messagerie de l\'application pour échanger avec les enseignants. Une bonne communication parent-enseignant est essentielle pour le suivi scolaire de votre enfant. Posez des questions sur ses progrès et ses défis.',
    },
    {
      'title': 'Valoriser les efforts, pas que les notes',
      'category': 'Motivation',
      'icon': Icons.emoji_events_rounded,
      'color': _kTipsYellow,
      'content':
          'Félicitez votre enfant pour ses efforts et sa persévérance, pas uniquement pour ses bonnes notes. Un enfant qui se sent encouragé développe une meilleure estime de soi et une motivation intrinsèque pour apprendre.',
    },
    {
      'title': 'Participer à la vie scolaire',
      'category': 'Engagement',
      'icon': Icons.groups_rounded,
      'color': _kTipsPink,
      'content':
          'Assistez aux réunions parents-professeurs, aux événements de l\'école et consultez les actualités via l\'application. Votre implication montre à votre enfant que l\'école est importante et renforce son sentiment d\'appartenance.',
    },
    {
      'title': 'Gérer le temps d\'écran',
      'category': 'Numérique',
      'icon': Icons.phone_android_rounded,
      'color': _kTipsPurple,
      'content':
          'Limitez le temps d\'écran récréatif à 1-2 heures par jour. Privilégiez les contenus éducatifs et interactifs. Instaurez des moments sans écran, notamment pendant les repas et avant le coucher, pour favoriser un meilleur sommeil.',
    },
  ];

  final List<Map<String, dynamic>> _bienEtreTips = [
    {
      'title': 'Assurer un sommeil suffisant',
      'category': 'Santé',
      'icon': Icons.bedtime_rounded,
      'color': _kTipsBlue,
      'content':
          'Un enfant de 6-12 ans a besoin de 9 à 12 heures de sommeil. Établissez une routine du coucher apaisante : bain, lecture, extinction des lumières à heure fixe. Un bon sommeil améliore la concentration et la mémoire.',
    },
    {
      'title': 'Encourager l\'activité physique',
      'category': 'Sport',
      'icon': Icons.sports_soccer_rounded,
      'color': _kTipsGreen,
      'content':
          'Les enfants ont besoin d\'au moins 60 minutes d\'activité physique par jour. Inscrivez-les à un sport, faites des promenades en famille ou des jeux actifs. L\'exercice libère des endorphines qui améliorent l\'humeur et la concentration.',
    },
    {
      'title': 'Favoriser une alimentation équilibrée',
      'category': 'Nutrition',
      'icon': Icons.restaurant_rounded,
      'color': _kTipsOrange,
      'content':
          'Un petit-déjeuner complet est essentiel pour bien commencer la journée scolaire. Privilégiez les fruits, les céréales complètes et les protéines. Préparez des goûters sains et hydratez bien votre enfant avec de l\'eau.',
    },
    {
      'title': 'Écouter et rassurer votre enfant',
      'category': 'Émotions',
      'icon': Icons.favorite_rounded,
      'color': _kTipsPink,
      'content':
          'Prenez le temps d\'écouter votre enfant chaque jour. Demandez-lui comment s\'est passée sa journée, ce qu\'il a aimé ou ce qui l\'a inquiété. Validez ses émotions et montrez-lui que vous êtes là pour le soutenir quoi qu\'il arrive.',
    },
  ];
}
