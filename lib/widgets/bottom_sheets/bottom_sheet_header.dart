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
      padding: padding ?? const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header content
          Row(
            children: [
              // Icon container with gradient (like paiement)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor,
                      iconColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize ?? 22,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize ?? 18,
                        fontWeight: titleFontWeight ?? FontWeight.w800,
                        color: titleColor ?? const Color(0xFF1A1A1A),
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: descriptionFontSize ?? 13,
                        color: descriptionColor ?? const Color(0xFF666666),
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Close button (simple icon like paiement)
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          const Divider(
            color: Color(0xFFE5E5E5),
            height: 1,
          ),
        ],
      ),
    );
  }
}
