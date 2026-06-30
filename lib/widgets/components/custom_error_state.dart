import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'custom_button.dart';

class CustomErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;
  final Color? iconColor;
  final Color? buttonColor;
  final bool buttonIsLight;
  final bool buttonHasBorder;
  final Color? buttonBorderColor;
  final double? buttonWidth;

  const CustomErrorState({
    Key? key,
    this.title = 'Oups, un problème est survenu',
    required this.message,
    this.onRetry,
    this.retryText = 'Réessayer',
    this.icon = Icons.cloud_off_rounded,
    this.iconColor,
    this.buttonColor,
    this.buttonIsLight = false,
    this.buttonHasBorder = true,
    this.buttonBorderColor,
    this.buttonWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultErrorColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final Color activeIconColor = iconColor ?? defaultErrorColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeIconColor.withOpacity(isDark ? 0.15 : 0.08),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeIconColor.withOpacity(isDark ? 0.25 : 0.15),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: activeIconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimaryThemed(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondaryThemed(context),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                width: buttonWidth ?? 200,
                text: retryText,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                color: buttonColor ?? AppColors.screenOrange,
                borderColor: buttonBorderColor,
                isLight: buttonIsLight,
                hasBorder: buttonHasBorder,
                height: 44,
                fontSize: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
