import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';

class ShareBottomSheet extends StatelessWidget {
  final String title;
  final String itemTitle;
  final String shareText;

  const ShareBottomSheet({
    super.key,
    required this.title,
    required this.itemTitle,
    required this.shareText,
  });

  Future<void> _launchWhatsApp() async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchFacebook() async {
    final url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://example.com')}&quote=${Uri.encodeComponent(shareText)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final subject = Uri.encodeComponent(itemTitle);
    final body = Uri.encodeComponent(shareText);
    final url = 'mailto:?subject=$subject&body=$body';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors to make it adapt to dark/light mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B); // AppColors.slate900 equivalent
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B); // AppColors.slate500 equivalent
    final handleColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1); // AppColors.slate300 equivalent

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            itemTitle,
            style: TextStyle(fontSize: 13, color: subtextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(
                imageAsset: 'assets/images/icons/whatsapp.png',
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(context);
                  _launchWhatsApp();
                },
              ),
              _ShareOption(
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  Navigator.pop(context);
                  _launchFacebook();
                },
              ),
              _ShareOption(
                icon: Icons.email_rounded,
                label: 'Email',
                color: const Color(0xFFEA4335),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail();
                },
              ),
              _ShareOption(
                icon: Icons.more_horiz_rounded,
                label: 'Plus',
                color: const Color(0xFF6366F1), // AppColors.indigo equivalent
                onTap: () {
                  Navigator.pop(context);
                  Share.share(shareText, subject: itemTitle);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || imageAsset != null);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(imageAsset!, fit: BoxFit.contain),
                  )
                : Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
