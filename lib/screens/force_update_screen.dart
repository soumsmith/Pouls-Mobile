import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_check_result.dart';
import 'dart:io';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_dimensions.dart';

class ForceUpdateScreen extends StatefulWidget {
  final VersionCheckResult result;

  const ForceUpdateScreen({Key? key, required this.result}) : super(key: key);

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation1 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _slideAnimation2 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _slideAnimation3 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchStoreUrl() async {
    String url = widget.result.storeUrl;
    if (url.isEmpty) {
      url = Platform.isIOS
          ? AppConfig.IOS_STORE_URL
          : AppConfig.ANDROID_STORE_URL;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A24), const Color(0xFF0F0F14)]
                  : [Colors.white, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Header with Glow Effect
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(AppDimensions.spacingXL),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF232330)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  198,
                                  198,
                                  198,
                                ).withOpacity(isDark ? 0.4 : 0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo-app.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingXL),

                    // Title and Description
                    SlideTransition(
                      position: _slideAnimation1,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Mise à jour essentielle',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppDimensions.spacingM),
                            Text(
                              'Une version plus performante et sécurisée de l\'application est disponible. Veuillez la télécharger pour continuer.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingL),

                    // Version Comparison Box
                    SlideTransition(
                      position: _slideAnimation2,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF232330)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Actuelle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.result.currentVersion,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.shopBlue,
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Nouvelle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.shopBlue.withOpacity(
                                        0.8,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.result.latestVersion,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.shopBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingL),

                    // Changelog and Button
                    SlideTransition(
                      position: _slideAnimation3,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            if (widget.result.changelog != null &&
                                widget.result.changelog!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppDimensions.spacingM),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A3A).withOpacity(0.5)
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant
                                            .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Theme.of(
                                            context,
                                          ).dividerColor.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 16,
                                          color: Colors.orange[400],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Nouveautés',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.result.changelog!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: AppDimensions.spacingXL * 1.2),
                            ] else ...[
                              SizedBox(height: AppDimensions.spacingXL * 0.5),
                            ],

                            // Update Button
                            Column(
                              children: [
                                Text(
                                  'Appuyez ci-dessous pour télécharger :',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _launchStoreUrl,
                                  child: Image.asset(
                                    Platform.isIOS
                                        ? 'assets/images/icons/icone-appstore.png'
                                        : 'assets/images/icons/icone-playstore.png',
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
