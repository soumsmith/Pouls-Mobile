import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import 'login_screen.dart';

/// Écran d'introduction avec slider auto-play
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Données des slides avec icônes et couleurs
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Parent responsable',
      'subtitle': 'Suivi scolaire simplifié',
      'description': 'Accédez à toutes les informations scolaires de votre enfant',
      'icon': Icons.school,
      'color': AppColors.primary,
      'features': [
        {'icon': Icons.grade, 'title': 'Suivi des notes', 'desc': 'Consultez les résultats scolaires de votre enfant', 'color': Colors.orange},
        {'icon': Icons.calendar_month, 'title': 'Emploi du temps', 'desc': 'Accédez aux horaires et activités', 'color': Colors.blue},
        {'icon': Icons.message, 'title': 'Communication', 'desc': 'Restez en contact avec l\'établissement', 'color': Colors.green},
      ],
      'hasFeatures': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _startAutoPlay();
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fond
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? Colors.black : Colors.white,
          ),
          // Image de fond
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDark
                      ? 'assets/images/intro_background_dark.png'
                      : 'assets/images/intro_background.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay semi-transparent (light mode uniquement)
          if (!isDark)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          // Dégradé blanc vers le bas (light mode uniquement)
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.0, 0),
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFFFFFFFF),
                    ],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          // Contenu principal
          SafeArea(
            child: AppDimensions.isMobile(context)
                ? _buildPhoneLayout(context)
                : _buildTabletLayout(context),
          ),
        ],
      ),
    );
  }

  /// Layout pour téléphone (original)
  Widget _buildPhoneLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.defaultPadding),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Expanded(
            flex: 4,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(context, _slides[index]);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPageIndicators(),
          ),
          const Spacer(flex: 1),
          _buildButton(),
          const SizedBox(height: AppDimensions.spacingL),
        ],
      ),
    );
  }

  /// Layout pour tablette (responsive)
  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: AppDimensions.getResponsivePadding(context),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Expanded(
            flex: 5,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(context, _slides[index]);
              },
            ),
          ),
          SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPageIndicators(),
          ),
          const Spacer(flex: 1),
          _buildButton(),
          SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        ],
      ),
    );
  }

  Widget _buildSlide(BuildContext context, Map<String, dynamic> slide) {
    final hasFeatures = slide['hasFeatures'] as bool;
    final iconSize = AppDimensions.getAdaptiveIconSize(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo-app.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: AppDimensions.isTablet(context) ? AppDimensions.spacingL : AppDimensions.spacingM,
            ),
            padding: EdgeInsets.all(
              AppDimensions.isTablet(context) ? AppDimensions.spacingXL : AppDimensions.spacingL,
            ),
            decoration: BoxDecoration(
              color: (slide['color'] as Color).withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDimensions.defaultBorderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: hasFeatures
                ? _buildFeaturesContent(slide, context)
                : _buildSimpleContent(slide, context),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleContent(Map<String, dynamic> slide, BuildContext context) {
    return Column(
      children: [
        Text(
          slide['title'] as String,
          style: TextStyle(
            fontSize: AppDimensions.getFormTitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        Text(
          slide['description'] as String,
          style: TextStyle(
            fontSize: AppDimensions.getFormSubtitleFontSize(context),
            color: Colors.white.withOpacity(0.8),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesContent(Map<String, dynamic> slide, BuildContext context) {
    final features = slide['features'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide['title'] as String,
          style: TextStyle(
            fontSize: AppDimensions.getFormTitleFontSize(context) * 0.9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppDimensions.getAdaptiveSpacing(context)),
        ...features.map((feature) => _buildFeatureItem(
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['desc'] as String,
          feature['color'] as Color,
          context,
        )).toList(),
      ],
    );
  }

  Widget _buildFeatureItem(
      IconData icon,
      String title,
      String description,
      Color color,
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.isTablet(context) ? AppDimensions.spacingS : AppDimensions.spacingXS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.isTablet(context) ? 20 : 16,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDimensions.isTablet(context) ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppDimensions.isTablet(context) ? 14 : 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: AppDimensions.isTablet(context) ? 360 : 280,
            height: AppDimensions.isTablet(context) ? AppDimensions.buttonHeightLarge : AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadiusL),
                ),
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Commencer',
                    style: TextStyle(
                      fontSize: AppDimensions.isTablet(context) ? 20 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Icon(Icons.arrow_forward, size: AppDimensions.isTablet(context) ? 24 : 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPageIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < _slides.length; i++) {
      indicators.add(
        GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == i ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == i ? Colors.white : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }
    return indicators;
  }
}
