import 'package:flutter/material.dart';
import '../config/app_dimensions.dart';

class SeeMoreCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color subtitleColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final double? width;
  final double? height;

  const SeeMoreCard({
    Key? key,
    required this.cardColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.getMediumCardBorderRadius(context)),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
