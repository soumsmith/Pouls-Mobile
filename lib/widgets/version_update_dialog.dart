import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_check_result.dart';
import 'dart:io';
import '../config/app_colors.dart';
import '../config/app_config.dart';

class VersionUpdateDialog extends StatelessWidget {
  final VersionCheckResult result;
  final VoidCallback onDismiss;

  const VersionUpdateDialog({
    Key? key,
    required this.result,
    required this.onDismiss,
  }) : super(key: key);

  Future<void> _launchStoreUrl() async {
    String url = result.storeUrl;
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF232330) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo-app.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Mise à jour disponible',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  'Une nouvelle version est disponible pour améliorer votre expérience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Version Comparison
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Actuelle',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                          ),
                          Text(
                            result.currentVersion,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.shopBlue),
                      Column(
                        children: [
                          Text(
                            'Nouvelle',
                            style: TextStyle(fontSize: 11, color: AppColors.shopBlue.withOpacity(0.8), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            result.latestVersion,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.shopBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Changelog
                if (result.changelog != null && result.changelog!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.shopBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.shopBlue.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.orange[400]),
                            const SizedBox(width: 6),
                            const Text(
                              'Nouveautés',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.changelog!,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Call to action
                const Text(
                  'Appuyez ci-dessous pour télécharger :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF2F4F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 12.0,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismiss();
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Plus tard",
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          _launchStoreUrl();
                          Navigator.of(context).pop();
                          onDismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Image.asset(
                            Platform.isIOS
                                ? 'assets/images/icons/icone-appstore.png'
                                : 'assets/images/icons/icone-playstore.png',
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
