import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'components/custom_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final Color headerColor;
  final String title;

  const ErrorStateWidget({
    super.key,
    required this.error,
    required this.onRetry,
    required this.headerColor,
    this.title = 'Erreur de chargement',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: headerColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final String? refreshText;
  final Color? buttonColor;
  final IconData? buttonIcon;
  final bool buttonIsLight;
  final bool buttonIconOnRight;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.refreshText,
    this.buttonColor,
    this.buttonIcon = Icons.refresh_rounded,
    this.buttonIsLight = true,
    this.buttonIconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.screenOrangeLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.screenOrange),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimaryThemed(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: refreshText ?? 'Actualiser',
                onPressed: onRefresh,
                width: 200,
                color: buttonColor ?? AppColors.screenOrange,
                icon: buttonIcon,
                isLight: buttonIsLight,
                iconOnRight: buttonIconOnRight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
