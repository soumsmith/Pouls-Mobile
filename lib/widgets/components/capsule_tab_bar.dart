import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/text_size_service.dart';

class CapsuleTabItem {
  final String label;
  final IconData? icon;

  const CapsuleTabItem({
    required this.label,
    this.icon,
  });
}

class CapsuleTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<CapsuleTabItem> tabs;
  final TabController? controller;
  final bool isScrollable;
  final ValueChanged<int>? onTap;

  const CapsuleTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextSizeService textSizeService = TextSizeService();
    
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : null,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF4B5563),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: -12, vertical: 2),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.screenOrange,
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelStyle: TextStyle(
          fontSize: textSizeService.getScaledFontSize(12),
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: textSizeService.getScaledFontSize(12),
          fontWeight: FontWeight.w600,
        ),
        onTap: onTap,
        tabs: tabs.map((tabItem) {
          return Tab(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tabItem.icon != null) ...[
                  Icon(tabItem.icon, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(tabItem.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
