import 'package:flutter/material.dart';
import '../../services/text_size_service.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLight;
  final IconData? icon;
  final bool iconOnRight;
  final bool isLoading;
  final bool hasBorder;
  final double? borderRadius;
  final double? height;
  final double? fontSize;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.isLight = false,
    this.icon,
    this.iconOnRight = false,
    this.isLoading = false,
    this.hasBorder = true,
    this.borderRadius,
    this.height,
    this.fontSize,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextSizeService textSizeService = TextSizeService();
    final bool isEnabled = onPressed != null && !isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on enabled/disabled and light/solid styles
    Color bg;
    Color contentColor;
    List<BoxShadow>? shadow;

    if (!isEnabled) {
      bg = isDark ? Colors.white10 : Colors.grey[200]!;
      contentColor = isDark ? Colors.white30 : Colors.grey[400]!;
      shadow = null;
    } else if (isLight) {
      bg = color.withOpacity(0.08);
      contentColor = color;
      shadow = null;
    } else {
      bg = color;
      contentColor = Colors.white;
      shadow = [
        BoxShadow(
          color: color.withOpacity(0.24),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    final iconWidget = icon != null
        ? Icon(
            icon,
            color: contentColor,
            size: 18,
          )
        : null;

    final textWidget = Text(
      text,
      style: TextStyle(
        color: contentColor,
        fontSize: textSizeService.getScaledFontSize(fontSize ?? 14),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius ?? 14),
            boxShadow: shadow,
            border: isEnabled && isLight && hasBorder
                ? Border.all(color: color.withOpacity(0.2), width: 1.0)
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconWidget != null && !iconOnRight) ...[
                        iconWidget,
                        const SizedBox(width: 8),
                      ],
                      textWidget,
                      if (iconWidget != null && iconOnRight) ...[
                        const SizedBox(width: 8),
                        iconWidget,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
