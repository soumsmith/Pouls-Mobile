import 'package:flutter/material.dart';
import '../config/app_dimensions.dart';
import '../config/app_typography.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = AppDimensions.isTablet(context) || AppDimensions.isLargeTablet(context);
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? (isTablet ? 56.0 : 48.0),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(isTablet ? 20.0 : 16.0),
          ),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: isTablet ? 24.0 : 20.0,
            vertical: isTablet ? 16.0 : 12.0,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isTablet ? 24.0 : 20.0,
                height: isTablet ? 24.0 : 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTypography.buttonText.copyWith(
                  color: textColor ?? Colors.white,
                ),
              ),
      ),
    );
  }
}
