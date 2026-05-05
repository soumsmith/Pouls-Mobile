import 'package:flutter/material.dart';
import '../../config/app_dimensions.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final Color? textColor;
  final double? titleFontSize;
  final VoidCallback? onSeeMore;
  final String? seeMoreText;

  const SectionRow({
    super.key,
    required this.title,
    this.textColor,
    this.titleFontSize,
    this.onSeeMore,
    this.seeMoreText,
  });

  @override
  Widget build(BuildContext context) {
    const kTextSecondary = Color(0xFF8A8A9E);

    final effectiveTextColor = textColor ?? kTextSecondary;
    final effectiveFontSize = titleFontSize ?? AppDimensions.getSectionTitleTextSize(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.getSectionHorizontalPadding(context), 
        vertical: AppDimensions.getSectionVerticalMargin(context),
      ),
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
          if (onSeeMore != null)
            GestureDetector(
              onTap: onSeeMore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: effectiveTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  seeMoreText ?? 'Voir plus',
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: effectiveFontSize - 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.chevron_right,
                color: kTextSecondary.withOpacity(0.5),
                size: AppDimensions.getSectionIconSize(context),
              ),
            ),
        ],
      ),
    );
  }
}
