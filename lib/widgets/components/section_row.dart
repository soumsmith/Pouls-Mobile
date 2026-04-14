import 'package:flutter/material.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final Color? textColor;
  final double? titleFontSize;

  const SectionRow({
    super.key,
    required this.title,
    this.textColor,
    this.titleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    const kTextSecondary = Color(0xFF8A8A9E);

    final effectiveTextColor = textColor ?? kTextSecondary;
    final effectiveFontSize = titleFontSize ?? 11;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.chevron_right,
              color: kTextSecondary.withOpacity(0.5),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
