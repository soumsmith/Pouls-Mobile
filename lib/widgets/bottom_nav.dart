import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../config/app_colors.dart';

// ─── DESIGN TOKENS (identiques au CartScreen) ────────────────────────────────
const _kOrange = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);
const _kCard = Colors.white;
const _kShadow = Color(0x0D000000);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);

const _kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFF7A3C), _kOrange],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Couleurs spécifiques pour la boutique ───────────────────────────────────
const _kShopGreen = Color(0xFF4CAF50);
const _kShopGreenLight = Color(0xFF81C784);

const _kShopGreenGradient = LinearGradient(
  colors: [_kShopGreenLight, _kShopGreen],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Nav Items Definition ─────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = [
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Accueil',
  ),
  _NavItem(
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag_rounded,
    label: 'Boutique',
  ),
  _NavItem(
    icon: Icons.business_outlined,
    activeIcon: Icons.business_rounded,
    label: 'Établissements',
  ),
  _NavItem(
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
    label: 'Plus',
  ),
];

// ─── BottomNav Widget ─────────────────────────────────────────────────────────
class BottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> with TickerProviderStateMixin {
  final CartService _cartService = MockCartService();
  int _cartItemCount = 0;
  Timer? _cartTimer;

  // Un controller d'animation par item pour le bounce au tap
  late List<AnimationController> _bounceControllers;
  late List<Animation<double>> _bounceAnims;

  @override
  void initState() {
    super.initState();

    // Initialiser les animations de bounce
    _bounceControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _bounceAnims = _bounceControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(
            begin: 1.0,
            end: 0.80,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 0.80,
            end: 1.08,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.08,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.elasticOut)),
          weight: 25,
        ),
      ]).animate(c);
    }).toList();

    _loadCartCount();
    _setupCartListener();
  }

  @override
  void dispose() {
    _cartTimer?.cancel();
    for (final c in _bounceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupCartListener() {
    _cartTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final cart = await _cartService.getCurrentCart();
      if (mounted && cart.totalItems != _cartItemCount) {
        setState(() => _cartItemCount = cart.totalItems);
      }
    });
  }

  Future<void> _loadCartCount() async {
    final cart = await _cartService.getCurrentCart();
    if (mounted) setState(() => _cartItemCount = cart.totalItems);
  }

  void _handleTap(int index) {
    // Lance l'animation de bounce sur l'item tapé
    _bounceControllers[index].forward(from: 0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Container(
      // Hauteur fixe + padding système en bas
      height: 70,
      margin: EdgeInsets.fromLTRB(
        isAndroid ? 0 : 16,
        12 + bottomPadding,
        isAndroid ? 0 : 16,
        0, //12 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.92),
        borderRadius: isAndroid ? BorderRadius.zero : BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 48,
            offset: Offset(0, 20),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isAndroid ? BorderRadius.zero : BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              _navItems.length,
              (i) => Expanded(
                child: _NavItemWidget(
                  item: _navItems[i],
                  isSelected: widget.currentIndex == i,
                  bounceAnim: _bounceAnims[i],
                  showBadge: i == 1, // Boutique = index 1
                  badgeCount: i == 1 ? _cartItemCount : 0,
                  onTap: () => _handleTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single Nav Item ──────────────────────────────────────────────────────────
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Animation<double> bounceAnim;
  final bool showBadge;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.bounceAnim,
    required this.showBadge,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon avec bounce ───────
            AnimatedBuilder(
              animation: bounceAnim,
              builder: (_, child) =>
                  Transform.scale(scale: bounceAnim.value, child: child),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 24,
                    color: isSelected
                        ? (item.label == 'Boutique' ? _kShopGreen : _kOrange)
                        : _kTextSecondary,
                  ),

                  // Badge panier (top-right)
                  if (showBadge && badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: _Badge(count: badgeCount),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            // ── Label ─────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (item.label == 'Boutique' ? _kShopGreen : _kOrange)
                    : _kTextSecondary,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              child: Text(item.label, maxLines: 1),
            ),

            // ── Dot indicateur sous le label ──────────────────
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 16 : 0,
              height: isSelected ? 3 : 0,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? (item.label == 'Boutique'
                          ? _kShopGreenGradient
                          : _kOrangeGradient)
                    : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: count > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B2C), Color(0xFFFF6B2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kCard, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B2C).withOpacity(0.40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
