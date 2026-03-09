import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ───────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final TextSizeService _textSizeService = TextSizeService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    final user = AuthService.instance.getCurrentUser();
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.getCurrentUser();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    children: [
                      _buildProfileHeader(user),
                      const SizedBox(height: 20),
                      _buildStatsSection(),
                      const SizedBox(height: 20),
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 20),
                      _buildQuickActionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.screenShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.screenTextPrimary),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Profil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Gérez vos informations',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit / Save button
              GestureDetector(
                onTap: () {
                  setState(() => _isEditing = !_isEditing);
                  if (!_isEditing) {
                    _showSuccess('Profil mis à jour avec succès');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isEditing ? AppColors.screenOrange : AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isEditing
                            ? AppColors.screenOrange.withOpacity(0.3)
                            : AppColors.screenShadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isEditing ? Icons.check : Icons.edit_outlined,
                    size: 16,
                    color: _isEditing ? Colors.white : AppColors.screenTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROFILE HEADER ───────────────────────────────────────────────────────
  Widget _buildProfileHeader(dynamic user) {
    final initials =
        (user?.fullName as String? ?? 'U').substring(0, 1).toUpperCase();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.6), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              user?.fullName ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined,
                      color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Parent Vérifié',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATS ────────────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    final stats = [
      {
        'value': '3',
        'label': 'Enfants',
        'icon': Icons.child_care_outlined,
        'color': const Color(0xFF4CAF50),
      },
      {
        'value': '12',
        'label': 'Établissements',
        'icon': Icons.school_outlined,
        'color': AppColors.screenOrange,
      },
      {
        'value': 'A+',
        'label': 'Note',
        'icon': Icons.grade_outlined,
        'color': const Color(0xFF9C27B0),
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Row(
            children: [
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + i * 100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.screenCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.screenShadow,
                            blurRadius: 12,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s['icon'] as IconData,
                              color: s['color'] as Color, size: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s['value'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.screenTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── PERSONAL INFO ────────────────────────────────────────────────────────
  Widget _buildPersonalInfoSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
            Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.screenOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Informations Personnelles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.screenDivider, height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildInfoField(
                    label: 'Nom Complet',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoField(
                    label: 'Email',
                    controller: TextEditingController(
                        text: AuthService.instance
                                .getCurrentUser()
                                ?.email ??
                            ''),
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoField(
                    label: 'Téléphone',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          if (!enabled)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.lock_outline, size: 11, color: AppColors.screenTextSecondary),
            ),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(
              fontSize: 14, color: AppColors.screenTextPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintStyle: const TextStyle(
                fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon,
                color: enabled ? AppColors.screenOrange : AppColors.screenTextSecondary, size: 18),
            filled: true,
            fillColor: enabled ? AppColors.screenSurface : const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenOrange, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.screenDivider.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'title': 'Partager mon profil',
        'subtitle': 'Inviter d\'autres parents',
        'icon': Icons.share_outlined,
        'color': AppColors.screenOrange,
        'isDestructive': false,
      },
      {
        'title': 'Exporter mes données',
        'subtitle': 'Télécharger toutes vos informations',
        'icon': Icons.download_outlined,
        'color': const Color(0xFFF59E0B),
        'isDestructive': false,
      },
      {
        'title': 'Supprimer mon compte',
        'subtitle': 'Action irréversible',
        'icon': Icons.delete_forever_outlined,
        'color': Colors.red,
        'isDestructive': true,
      },
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
            Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on_outlined,
                        color: AppColors.screenOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Actions Rapides',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.screenDivider, height: 1),

            ...actions.asMap().entries.map((entry) {
              final i = entry.key;
              final action = entry.value;
              final isLast = i == actions.length - 1;
              final color = action['color'] as Color;
              final isDestructive = action['isDestructive'] as bool;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleAction(action['title'] as String),
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(20))
                          : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(action['icon'] as IconData,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDestructive
                                          ? Colors.red
                                          : AppColors.screenTextPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    action['subtitle'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.screenTextSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: isDestructive
                                  ? Colors.red.withOpacity(0.5)
                                  : AppColors.screenTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 72),
                      child: Divider(color: AppColors.screenDivider, height: 1),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _handleAction(String title) {
    switch (title) {
      case 'Supprimer mon compte':
        _showDeleteConfirmation();
        break;
      default:
        _showSuccess('$title en cours...');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le compte ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées.',
          style: TextStyle(color: AppColors.screenTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.screenTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Supprimer',
                style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}