import 'package:flutter/material.dart';

class BottomSheetHeader extends StatelessWidget {
  final IconData icon;
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

  const BottomSheetHeader({
    Key? key,
    required this.icon,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
              // Icon container with gradient (like paiement)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: iconSize ?? 18),
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
                        color: titleColor ?? const Color(0xFF1A1A1A),
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
                        color: descriptionColor ?? const Color(0xFF666666),
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
                    color: const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF666666),
                    size: 14,
                  ),
                ),
              ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          const Divider(color: Color(0xFFE5E5E5), height: 1),
        ],
      ),
    );
  }
}
