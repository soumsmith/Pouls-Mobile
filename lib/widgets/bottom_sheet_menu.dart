import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/text_size_service.dart';
import '../services/cart_service.dart';
import '../screens/tutor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/new_settings_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../widgets/main_screen_wrapper.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';

class BottomSheetMenu extends StatefulWidget {
  const BottomSheetMenu({super.key});

  @override
  State<BottomSheetMenu> createState() => _BottomSheetMenuState();
}

class _BottomSheetMenuState extends State<BottomSheetMenu> {
  final TextSizeService _textSizeService = TextSizeService();
  final CartService _cartService = MockCartService();
  int _cartItemCount = 0;
  int _unreadMessageCount = 0;
  int _ticketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    await Future.wait([
      _loadCartItemCount(),
      _loadMessageCount(),
      _loadTicketCount(),
    ]);
  }

  Future<void> _loadMessageCount() async {
    try {
      // Simuler un comptage de messages non lus
      if (mounted) {
        setState(() {
          _unreadMessageCount = 5; // Valeur de démonstration
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des messages: $e');
    }
  }

  Future<void> _loadTicketCount() async {
    try {
      // Simuler un comptage de tickets
      if (mounted) {
        setState(() {
          _ticketCount = 2; // Valeur de démonstration
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des tickets: $e');
    }
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
    
    return AnimatedBuilder(
      animation: _textSizeService,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              _buildHandleBar(context),
              
              // Header
              _buildHeader(context),
              
              // Menu Items
              _buildMenuItems(context),
              
              // Bottom Padding
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.getBorderColor(isDark).withOpacity(0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.toSurface(),
                  AppColors.primary.toSurface().withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.menu,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Menu',
              style: _textSizeService.getScaledTextStyle(
                TextStyle(
                  fontSize: AppTypography.titleLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.getSurfaceColor(isDark).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {
        'title': 'Messages',
        'subtitle': 'Vos messages et communications',
        'icon': Icons.message_outlined,
        'color': 0xFF2196F3,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MessagesScreen()),
          );
        },
        'showBadge': true,
        'badgeCount': _unreadMessageCount,
      },
      {
        'title': 'Mes Tickets',
        'subtitle': 'Voir vos tickets achetés',
        'icon': Icons.confirmation_number,
        'color': 0xFF10B981,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
          );
        },
        'showBadge': true,
        'badgeCount': _ticketCount,
      },
      {
        'title': 'Boutique (Libouli)',
        'subtitle': 'Accéder à la boutique en ligne',
        'icon': Icons.shopping_bag_outlined,
        'color': 0xFF6366F1,
        'onTap': () {
          Navigator.of(context).pop();
          // Mettre à jour l'index pour sélectionner l'onglet boutique
          final mainScreenWrapper = MainScreenWrapper.maybeOf(context);
          if (mainScreenWrapper != null) {
            mainScreenWrapper.updateCurrentIndex(1);
          } else {
            // Si pas de MainScreenWrapper, retourner à l'écran principal avec boutique sélectionnée
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainScreenWrapper(initialIndex: 1)
              ),
              (route) => false,
            );
          }
        },
        'showBadge': true,
        'badgeCount': _cartItemCount,
      },
      {
        'title': 'Tuteur à domicile',
        'subtitle': 'Trouver un tuteur pour vos enfants',
        'icon': Icons.school_outlined,
        'color': 0xFF8B5CF6,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MainScreenWrapper(child: TutorScreen())),
          );
        },
        'showBadge': true,
        'badgeCount': 1,
      },
      {
        'title': 'Profil',
        'subtitle': 'Gérer votre profil et informations',
        'icon': Icons.person_outline,
        'color': 0xFF2196F3,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        'showBadge': true,
        'badgeCount': 0,
      },
      {
        'title': 'Aide & Support',
        'subtitle': 'FAQ, contact et assistance',
        'icon': Icons.help_outline,
        'color': 0xFF4CAF50,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          );
        },
        'showBadge': true,
        'badgeCount': 0,
      },
      {
        'title': 'Paramètres',
        'subtitle': 'Préférences et configuration',
        'icon': Icons.settings_outlined,
        'color': 0xFF64748B,
        'onTap': () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewSettingsScreen()),
          );
        },
        'showBadge': true,
        'badgeCount': 0,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 6),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;
            
            return _MenuItemTile(
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              icon: item['icon'] as IconData,
              color: Color(item['color'] as int),
              onTap: item['onTap'] as VoidCallback,
              showDivider: !isLast,
              textSizeService: _textSizeService,
              showBadge: item['showBadge'] as bool? ?? false,
              badgeCount: item['badgeCount'] as int? ?? 0,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;
  final TextSizeService textSizeService;
  final bool showBadge;
  final int badgeCount;

  const _MenuItemTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.showDivider,
    required this.textSizeService,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Icon
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 24,
                        ),
                      ),
                      if (widget.showBadge && widget.badgeCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            height: 22,
                            constraints: const BoxConstraints(minWidth: 22),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
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
                  const SizedBox(width: 12),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: widget.textSizeService.getScaledTextStyle(
                            TextStyle(
                              fontSize: AppTypography.titleSmall,
                              color: AppColors.getTextColor(isDark),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: widget.textSizeService.getScaledTextStyle(
                            AppTypography.overline.copyWith(
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDivider) ...[
          const SizedBox(height: 2),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 64),
            decoration: BoxDecoration(
              color: AppColors.getBorderColor(isDark).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }
}

// Utility function to show the bottom sheet
void showMenuBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => const BottomSheetMenu(),
  );
}
