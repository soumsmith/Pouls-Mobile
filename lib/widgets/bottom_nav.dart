import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../services/cart_service.dart';

/// Barre de navigation inférieure
class BottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final TextSizeService? textSizeService;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.textSizeService,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final CartService _cartService = MockCartService();
  int _cartItemCount = 0;
  Timer? _cartTimer;

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
    _setupCartListener();
  }

  @override
  void dispose() {
    _cartTimer?.cancel();
    super.dispose();
  }

  void _setupCartListener() {
    // Écouter les changements du panier toutes les secondes
    _cartTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final cart = await _cartService.getCurrentCart();
      if (mounted && cart.totalItems != _cartItemCount) {
        setState(() {
          _cartItemCount = cart.totalItems;
        });
      }
    });
  }

  Future<void> _loadCartItemCount() async {
    final cart = await _cartService.getCurrentCart();
    if (mounted) {
      setState(() {
        _cartItemCount = cart.totalItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(
                context: context,
                icon: Icons.home,
                label: 'Accueil',
                isSelected: widget.currentIndex == 0,
                isDark: isDark,
                onTap: () => widget.onTap(0),
              ),
              _buildDockItem(
                context: context,
                icon: Icons.shopping_bag,
                label: 'Boutique',
                isSelected: widget.currentIndex == 1,
                isDark: isDark,
                onTap: () => widget.onTap(1),
                showBadge: true,
                badgeCount: _cartItemCount,
              ),
              _buildDockItem(
                context: context,
                icon: Icons.business,
                label: 'Établissements',
                isSelected: widget.currentIndex == 2,
                isDark: isDark,
                onTap: () => widget.onTap(2),
              ),
              _buildDockItem(
                context: context,
                icon: Icons.more_horiz,
                label: 'Plus',
                isSelected: widget.currentIndex == 3,
                isDark: isDark,
                onTap: () => widget.onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final baseFontSize = 14.0;
    final scaledFontSize = baseFontSize * textScaleFactor.clamp(0.8, 1.5);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                  ),
                  if (showBadge && badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 20,
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: scaledFontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

