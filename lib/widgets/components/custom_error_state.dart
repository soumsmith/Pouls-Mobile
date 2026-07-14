import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'custom_button.dart';

class CustomErrorState extends StatefulWidget {
  final String title;
  final String message;
  final dynamic onRetry;
  final String retryText;
  final IconData icon;
  final Color? iconColor;
  final Color? buttonColor;
  final bool buttonIsLight;
  final bool buttonHasBorder;
  final Color? buttonBorderColor;
  final double? buttonWidth;
  final bool? isLoading;

  const CustomErrorState({
    super.key,
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
    this.isLoading,
  });

  @override
  State<CustomErrorState> createState() => _CustomErrorStateState();
}

class _CustomErrorStateState extends State<CustomErrorState> {
  bool _internalLoading = false;

  bool get _activeLoading => widget.isLoading ?? _internalLoading;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null) return;
    setState(() {
      _internalLoading = true;
    });
    try {
      final startTime = DateTime.now();
      final result = widget.onRetry();
      if (result is Future) {
        await result;
      }
      final elapsedTime = DateTime.now().difference(startTime);
      final remainingTime = 800 - elapsedTime.inMilliseconds;
      if (remainingTime > 0) {
        await Future.delayed(Duration(milliseconds: remainingTime));
      }
    } finally {
      if (mounted) {
        setState(() {
          _internalLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultErrorColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final Color activeIconColor = widget.iconColor ?? defaultErrorColor;

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
                    widget.icon,
                    size: 24,
                    color: activeIconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
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
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondaryThemed(context),
                height: 1.4,
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                width: widget.buttonWidth != null
                    ? (widget.buttonWidth! > 150 ? 150 : widget.buttonWidth!)
                    : 150,
                text: widget.retryText,
                onPressed: _activeLoading ? null : _handleRetry,
                icon: Icons.refresh_rounded,
                color: widget.buttonColor ?? AppColors.screenOrange,
                borderColor: widget.buttonBorderColor,
                isLight: widget.buttonIsLight,
                hasBorder: widget.buttonHasBorder,
                isLoading: _activeLoading,
                height: 38,
                fontSize: 13,
                borderRadius: 10,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
