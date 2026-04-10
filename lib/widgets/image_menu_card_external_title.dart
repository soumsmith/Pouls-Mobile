import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';

class ImageMenuCardExternalTitle extends StatelessWidget {
  final int index;
  final String cardKey;
  final String? title;
  final String? subtitle;
  final String? imagePath;
  final IconData? iconData;
  final bool isDark;
  final IconData? icon;
  final Color? color;
  final String? location;
  final Color? backgroundColor;
  final Color? textColor;
  final String? actionText;
  final Color? actionTextColor;
  final String? tag;
  final double? width;
  final double? height;
  final double? externalTitleSpacing;
  final int titleMaxLines;
  final double imageFlex;
  final double? imageBorderRadius;
  final double? titleFontSize;
  final String? buttonText;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final VoidCallback? onButtonTap;
  final VoidCallback onTap;

  const ImageMenuCardExternalTitle({
    super.key,
    required this.index,
    required this.cardKey,
    this.title,
    this.subtitle,
    this.imagePath,
    this.iconData,
    required this.isDark,
    this.icon,
    this.color,
    this.location,
    this.backgroundColor,
    this.textColor,
    this.actionText,
    this.actionTextColor,
    this.tag,
    this.width,
    this.height,
    this.externalTitleSpacing = 8.0,
    this.titleMaxLines = 2,
    this.imageFlex = 7.0,
    this.imageBorderRadius = 20.0,
    this.titleFontSize = 12.0,
    this.buttonText,
    this.buttonColor,
    this.buttonTextColor,
    this.onButtonTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(20 * (1 - v), 0),
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Image card ──────────────────────────────────────────
                SizedBox(
                  height: height != null ? height! * 0.7 : 70,
                  child: Container(
                    width: width ?? double.infinity,
                    decoration: BoxDecoration(
                      color: backgroundColor ??
                          (isDark
                              ? const Color(0xFF1E1E1E)
                              : AppColors.screenCard),
                      borderRadius:
                          BorderRadius.circular(imageBorderRadius ?? 20),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(imageBorderRadius ?? 20),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: color?.withOpacity(0.1) ??
                                      AppColors.screenCard.withOpacity(0.1),
                                  child: _buildImageOrIcon(context),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (tag != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Titre externe ───────────────────────────────────────
                if (title?.isNotEmpty == true) ...[
                  SizedBox(height: externalTitleSpacing ?? 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width ?? double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: textSizeService
                                  .getScaledFontSize(titleFontSize ?? 11),
                              fontWeight: FontWeight.w700,
                              color: textColor ??
                                  (isDark
                                      ? Colors.white
                                      : AppColors.screenTextPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle?.isNotEmpty == true) ...[
                            const SizedBox(height: 1),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize:
                                    textSizeService.getScaledFontSize(9),
                                fontWeight: FontWeight.w500,
                                color: textColor?.withOpacity(0.7) ??
                                    (isDark
                                        ? Colors.white70
                                        : AppColors.screenTextSecondary),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (actionText != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    actionText!,
                                    style: TextStyle(
                                      fontSize:
                                          textSizeService.getScaledFontSize(10),
                                      fontWeight: FontWeight.w700,
                                      color: actionTextColor ??
                                          color ??
                                          AppColors.screenOrange,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (buttonText != null) ...[
                                  const SizedBox(width: 4),
                                  _buildSmallButton(textSizeService),
                                ],
                              ],
                            ),
                          ] else if (location != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 10,
                                        color: textColor?.withOpacity(0.5) ??
                                            (isDark
                                                ? Colors.white54
                                                : AppColors.screenTextSecondary),
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          location!,
                                          style: TextStyle(
                                            fontSize: textSizeService
                                                .getScaledFontSize(9),
                                            color:
                                                textColor?.withOpacity(0.5) ??
                                                    (isDark
                                                        ? Colors.white54
                                                        : AppColors
                                                            .screenTextSecondary),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (buttonText != null) ...[
                                  const SizedBox(width: 4),
                                  _buildSmallButton(textSizeService),
                                ],
                              ],
                            ),
                          ] else if (buttonText != null) ...[
                            const SizedBox(height: 2),
                            SizedBox(
                              width: double.infinity,
                              height: 26,
                              child: ElevatedButton(
                                onPressed: onButtonTap ?? () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor ??
                                      color ??
                                      AppColors.screenOrange,
                                  foregroundColor:
                                      buttonTextColor ?? Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  buttonText!,
                                  style: TextStyle(
                                    fontSize:
                                        textSizeService.getScaledFontSize(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],

            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(TextSizeService textSizeService) {
    return SizedBox(
      height: 22,
      child: ElevatedButton(
        onPressed: onButtonTap ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? color ?? AppColors.screenOrange,
          foregroundColor: buttonTextColor ?? Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          buttonText!,
          style: TextStyle(
            fontSize: textSizeService.getScaledFontSize(8),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildImageOrIcon(BuildContext context) {
    if (imagePath != null && imagePath!.startsWith('http')) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/img-shcool-not-found.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            icon ?? Icons.image,
            color: color ?? AppColors.screenOrange,
            size: 40,
          ),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: Icon(
              icon ?? Icons.image,
              color: (color ?? AppColors.screenOrange).withOpacity(0.5),
              size: 40,
            ),
          );
        },
      );
    }

    if (imagePath != null && imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          icon ?? Icons.image,
          color: color ?? AppColors.screenOrange,
          size: 40,
        ),
      );
    }

    if (imagePath == null) {
      return Image.asset(
        'assets/images/img-shcool-not-found.jpg',
        fit: BoxFit.cover,
      );
    }

    if (iconData != null) {
      return Icon(iconData, color: color ?? AppColors.screenOrange, size: 40);
    }

    return Icon(
      icon ?? Icons.image,
      color: color ?? AppColors.screenOrange,
      size: 40,
    );
  }
}