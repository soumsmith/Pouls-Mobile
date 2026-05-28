import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class BottomSheetHeader extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;
  final Color iconColor;
  final String title;
  final String description;
  final Color? titleColor;
  final Color? descriptionColor;
  final VoidCallback onClose;
  final Color? backgroundColor;
  final double? iconSize;
  final double? titleFontSize;
  final double? descriptionFontSize;
  final FontWeight? titleFontWeight;
  final EdgeInsetsGeometry? padding;
  final DraggableScrollableController? draggableController;

  const BottomSheetHeader({
    Key? key,
    required this.icon,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onClose,
    this.titleColor,
    this.descriptionColor,
    this.backgroundColor,
    this.iconSize,
    this.titleFontSize,
    this.descriptionFontSize,
    this.titleFontWeight,
    this.padding,
    this.draggableController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget headerWidget = Container(
      color: backgroundColor ?? Colors.transparent,
      padding: padding ?? const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF444444) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Icon container with subtle background
                Container(
                  width: imagePath != null ? 44 : 36,
                  height: imagePath != null ? 44 : 36,
                  padding: imagePath != null ? const EdgeInsets.all(4) : null,
                  decoration: BoxDecoration(
                    color: imagePath != null 
                        ? AppColors.actionMenuCardBg(context) 
                        : (imageBackgroundColor ?? iconColor.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(imagePath != null ? (imageBorderRadius ?? 14) : 10),
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(math.max(0.0, (imageBorderRadius ?? 14.0) - 4.0)),
                          child: Image.asset(imagePath!, fit: BoxFit.contain),
                        )
                      : Icon(icon, color: iconColor, size: iconSize ?? 18),
                ),

                const SizedBox(width: 8),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize ?? 14,
                          fontWeight: titleFontWeight ?? FontWeight.w600,
                          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: descriptionFontSize ?? 10,
                          color: descriptionColor ?? (isDark ? Colors.white70 : const Color(0xFF666666)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ✅ Bouton fermer dans un cercle gris
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : const Color(0xFF666666),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
            height: 1,
          ),
        ],
      ),
    );

    if (draggableController != null) {
      headerWidget = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          final controller = draggableController!;
          if (controller.isAttached) {
            final screenHeight = MediaQuery.of(context).size.height;
            if (screenHeight > 0) {
              final deltaFraction = -details.primaryDelta! / screenHeight;
              final newSize = (controller.size + deltaFraction).clamp(0.0, 1.0);
              controller.jumpTo(newSize);
            }
          }
        },
        onVerticalDragEnd: (details) {
          final controller = draggableController!;
          if (controller.isAttached) {
            final snaps = [0.4, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95];
            final current = controller.size;
            double closest = snaps.first;
            double minDiff = (current - closest).abs();
            for (final snap in snaps) {
              final diff = (current - snap).abs();
              if (diff < minDiff) {
                minDiff = diff;
                closest = snap;
              }
            }
            controller.animateTo(
              closest,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        },
        child: headerWidget,
      );
    }

    return headerWidget;
  }
}
