import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cart_service.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/new_settings_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../screens/referred_users_screen.dart';
import '../screens/subscription_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';
import 'components/bottom_spacer.dart';
import 'dart:convert';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../services/auth_service.dart';
import '../utils/auth_guard.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../screens/login_screen.dart';

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
  final bool isToggle;
  final bool toggleValue;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
    this.isToggle = false,
    this.toggleValue = false,
  });
}

// ─── Main Widget ──────────────────────────────────────────────────────────────
class BottomSheetMenu extends StatefulWidget {
  final BuildContext parentContext;
  const BottomSheetMenu({super.key, required this.parentContext});

  @override
  State<BottomSheetMenu> createState() => _BottomSheetMenuState();
}

class _BottomSheetMenuState extends State<BottomSheetMenu> {
  final CartService _cartService = MockCartService();
  final ThemeService _themeService = ThemeService();
  int _cartItemCount = 0;
  int _ticketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _loadTicketCount();
  }

  Future<void> _loadCartCount() async {
    final cart = await _cartService.getCurrentCart();
    if (mounted) setState(() => _cartItemCount = cart.totalItems);
  }

  Future<void> _loadTicketCount() async {
    final user = AuthService.instance.getCurrentUser();
    if (user != null && user.phone.isNotEmpty) {
      try {
        final url =
            '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/billetterie/ticket-commande/${user.phone}';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final nonUtilise = data['stats']?['non_utilise'] ?? 0;
          if (mounted) {
            setState(() {
              _ticketCount = nonUtilise;
            });
          }
        }
      } catch (e) {
        // fail silently
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Déconnexion ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: _kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Déconnexion',
              style: TextStyle(
                color: Colors.red[400],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // Fermer le bottom sheet menu
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(widget.parentContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop(); // Fermer le bottom sheet menu
    Navigator.of(widget.parentContext).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bottomSheetBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0x18000000),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.1)
                    : const Color(0x08000000),
                blurRadius: 8,
                offset: const Offset(0, -2),
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
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildMenuList(),
                ),
              ),
              _buildLogoutButton(),
              const SizedBox(height: 8),
              const BottomSpacer(),
            ],
          ),
        );
      },
    );
  }

  // ── Menu List ─────────────────────────────────────────────
  Widget _buildMenuList() {
    final items = _buildItems();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: List.generate(items.length, (i) {
          return _MenuTile(item: items[i], showDivider: i < items.length - 1);
        }),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loggedIn = AuthGuard.isLoggedIn();
    final accentColor = loggedIn
        ? (isDark ? Colors.red[400]! : Colors.red[600]!)
        : _kOrange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: GestureDetector(
        onTap: loggedIn ? _confirmLogout : _goToLogin,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(isDark ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                loggedIn ? Icons.logout_rounded : Icons.login_rounded,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                loggedIn ? 'Déconnexion' : 'Se connecter',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MenuItem> _buildItems() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      _MenuItem(
        title: 'Messages',
        subtitle: 'Vos messages et communications',
        icon: Icons.message_rounded,
        color: const Color(0xFF2196F3),
        onTap: () {
          Navigator.of(context).pop();
          AuthGuard.ensureLoggedIn(
            widget.parentContext,
            reason: 'Connectez-vous pour accéder à vos messages',
            onAuthenticated: () {
              MainScreenWrapper.of(
                widget.parentContext,
              ).navigateToExtraScreen(const MessagesScreen());
            },
          );
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
          AuthGuard.ensureLoggedIn(
            widget.parentContext,
            reason: 'Connectez-vous pour voir vos tickets',
            onAuthenticated: () {
              MainScreenWrapper.of(
                widget.parentContext,
              ).navigateToExtraScreen(const MyTicketsScreen());
            },
          );
        },
      ),
      _MenuItem(
        title: 'Tuteur à domicile',
        subtitle: 'Trouver un tuteur pour vos enfants',
        icon: Icons.school_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () async {
          Navigator.of(context).pop();
          final url = Uri.parse(AppConfig.TUTEUR_ADOM_URL);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ),
      _MenuItem(
        title: 'Profil',
        subtitle: 'Gérer votre profil et informations',
        icon: Icons.person_rounded,
        color: const Color(0xFF2196F3),
        onTap: () {
          Navigator.of(context).pop();
          AuthGuard.ensureLoggedIn(
            widget.parentContext,
            reason: 'Connectez-vous pour accéder à votre profil',
            onAuthenticated: () {
              MainScreenWrapper.of(
                widget.parentContext,
              ).navigateToExtraScreen(const ProfileScreen());
            },
          );
        },
      ),
      _MenuItem(
        title: 'Utilisateurs parrainés',
        subtitle: 'Voir vos filleuls et vos points',
        icon: Icons.group_add_rounded,
        color: const Color(0xFFFF6B2C),
        onTap: () {
          Navigator.of(context).pop();
          AuthGuard.ensureLoggedIn(
            widget.parentContext,
            reason: 'Connectez-vous pour voir vos utilisateurs parrainés',
            onAuthenticated: () {
              MainScreenWrapper.of(
                widget.parentContext,
              ).navigateToExtraScreen(const ReferredUsersScreen());
            },
          );
        },
      ),
      _MenuItem(
        title: 'Aide & Support',
        subtitle: 'FAQ, contact et assistance',
        icon: Icons.help_rounded,
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.of(context).pop();
          MainScreenWrapper.of(
            widget.parentContext,
          ).navigateToExtraScreen(const HelpSupportScreen());
        },
      ),
      _MenuItem(
        title: 'Paramètres',
        subtitle: 'Préférences et configuration',
        icon: Icons.settings_rounded,
        color: const Color(0xFF64748B),
        onTap: () {
          Navigator.of(context).pop();
          MainScreenWrapper.of(
            widget.parentContext,
          ).navigateToExtraScreen(const NewSettingsScreen());
        },
      ),
      _MenuItem(
        title: 'Thème sombre',
        subtitle: isDark ? 'Activé' : 'Désactivé',
        icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: const Color(0xFFF59E0B),
        isToggle: true,
        toggleValue: isDark,
        onTap: () => _themeService.toggleTheme(),
      ),
    ];
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    final textPrimary = isDark ? Colors.white : _kTextPrimary;
    final textSecondary = isDark ? Colors.white70 : _kTextSecondary;
    final surface = isDark ? const Color(0xFF222222) : _kSurface;
    final divider = isDark ? const Color(0xFF2C2C2C) : _kDivider;
    final pressedBg = isDark ? const Color(0xFF2A1F1A) : _kOrangeLight;

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
              color: _pressed ? pressedBg : Colors.transparent,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Arrow or Switch ───────────────────────
                if (item.isToggle)
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: item.toggleValue,
                      onChanged: (_) => item.onTap(),
                      activeThumbColor: item.color,
                      activeTrackColor: item.color.withOpacity(0.25),
                      inactiveThumbColor: isDark ? Colors.white54 : textSecondary,
                      inactiveTrackColor: divider,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: textSecondary,
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
            color: divider,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBorderColor = isDark ? const Color(0xFF141414) : _kCard;

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
        border: Border.all(color: badgeBorderColor, width: 1.5),
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
      constraints: const BoxConstraints(maxWidth: double.infinity),
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.40),
    builder: (_) => BottomSheetMenu(parentContext: context),
  );
}
