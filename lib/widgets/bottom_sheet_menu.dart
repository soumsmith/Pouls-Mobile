import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cart_service.dart';
import '../screens/tutor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/new_settings_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/orders_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/bottom_sheets/sponsorship_bottom_sheet.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';

// ─── DESIGN TOKENS (identiques au CartScreen) ────────────────────────────────
const _kOrange = Color(0xFFFF6B2C);
const _kOrangeLight = Color(0xFFFFF0E8);
const _kSurface = Color(0xFFF8F8F8);
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF8A8A8A);
const _kDivider = Color(0xFFF0F0F0);
const _kShadow = Color(0x0D000000);

const _kOrangeGradient = LinearGradient(
  colors: [Color(0xFFFF7A3C), _kOrange],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Menu Item Model ──────────────────────────────────────────────────────────
class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class BottomSheetMenu extends StatefulWidget {
  const BottomSheetMenu({super.key});

  @override
  State<BottomSheetMenu> createState() => _BottomSheetMenuState();
}

class _BottomSheetMenuState extends State<BottomSheetMenu>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = MockCartService();
  int _cartItemCount = 0;
  int _unreadMessages = 5; // demo
  int _ticketCount = 2; // demo

  late AnimationController _sheetController;
  late Animation<double> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sheetAnim = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    );
    _sheetController.forward();
    _loadCartCount();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    final cart = await _cartService.getCurrentCart();
    if (mounted) setState(() => _cartItemCount = cart.totalItems);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _sheetAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              icon: Icons.grid_view_rounded,
              iconColor: _kOrange,
              title: 'Menu',
              description: 'Navigation principale',
              onClose: () => Navigator.of(context).pop(),
            ),
            _buildMenuList(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ── Menu List ─────────────────────────────────────────────
  Widget _buildMenuList() {
    final items = _buildItems();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: List.generate(items.length, (i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + i * 55),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - v)),
                child: child,
              ),
            ),
            child: _MenuTile(item: items[i], showDivider: i < items.length - 1),
          );
        }),
      ),
    );
  }

  List<_MenuItem> _buildItems() => [
    _MenuItem(
      title: 'Messages',
      subtitle: 'Vos messages et communications',
      icon: Icons.message_rounded,
      color: const Color(0xFF2196F3),
      badgeCount: _unreadMessages,
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
      },
    ),
    _MenuItem(
      title: 'Mes Tickets',
      subtitle: 'Voir vos tickets achetés',
      icon: Icons.confirmation_number_rounded,
      color: const Color(0xFF10B981),
      badgeCount: _ticketCount,
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => OrdersScreen()));
      },
    ),
    _MenuItem(
      title: 'Tuteur à domicile',
      subtitle: 'Trouver un tuteur pour vos enfants',
      icon: Icons.school_rounded,
      color: const Color(0xFF8B5CF6),
      badgeCount: 1,
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MainScreenWrapper(child: TutorScreen()),
          ),
        );
      },
    ),
    _MenuItem(
      title: 'Profil',
      subtitle: 'Gérer votre profil et informations',
      icon: Icons.person_rounded,
      color: const Color(0xFF2196F3),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
    ),
    _MenuItem(
      title: 'Aide & Support',
      subtitle: 'FAQ, contact et assistance',
      icon: Icons.help_rounded,
      color: const Color(0xFF4CAF50),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
      },
    ),
    _MenuItem(
      title: 'Paramètres',
      subtitle: 'Préférences et configuration',
      icon: Icons.settings_rounded,
      color: const Color(0xFF64748B),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewSettingsScreen()));
      },
    ),
  ];
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
class _MenuTile extends StatefulWidget {
  final _MenuItem item;
  final bool showDivider;

  const _MenuTile({required this.item, required this.showDivider});

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Column(
      children: [
        // ── Row ───────────────────────────────────────────
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            item.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _pressed ? _kOrangeLight : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // ── Icon box ──────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(item.icon, color: item.color, size: 24),

                    // Badge
                    if (item.badgeCount > 0)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: _Badge(
                          count: item.badgeCount,
                          // La boutique/cart utilise orange, les autres rouge
                          isOrange: item.color == _kOrange,
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Texts ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Arrow ─────────────────────────────────
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Divider ───────────────────────────────────────
        if (widget.showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 70, right: 4),
            color: _kDivider,
          ),
      ],
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  final bool isOrange;
  const _Badge({required this.count, this.isOrange = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: isOrange
            ? _kOrangeGradient
            : const LinearGradient(
                colors: [Color(0xFFFF3B2C), Color(0xFFFF6060)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kCard, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isOrange ? _kOrange : const Color(0xFFFF3B2C)).withOpacity(
              0.35,
            ),
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
    );
  }
}

// ─── Helper function ──────────────────────────────────────────────────────────
void showMenuBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.40),
    builder: (_) => const BottomSheetMenu(),
  );
}
