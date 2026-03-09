import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/text_size_screen.dart';
import '../config/app_typography.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({super.key});

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen>
    with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  // États locaux des toggles
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color ?? AppColors.screenOrange,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.getCurrentUser();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: AnimatedBuilder(
        animation: Listenable.merge([_themeService, _textSizeService]),
        builder: (context, child) {
          return Scaffold(
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
                          _buildUserProfileCard(user),
                          const SizedBox(height: 20),
                          _buildCategory(
                            title: 'Compte',
                            icon: Icons.manage_accounts_outlined,
                            index: 0,
                            items: [
                              _SettingsItem(
                                title: 'Profil',
                                subtitle: 'Informations personnelles',
                                icon: Icons.person_outline,
                                color: const Color(0xFF3B82F6),
                                onTap: _navigateToProfile,
                              ),
                              _SettingsItem(
                                title: 'Sécurité',
                                subtitle: 'Mot de passe et authentification',
                                icon: Icons.security_outlined,
                                color: const Color(0xFF4CAF50),
                                onTap: () => _showSnack(
                                    'Paramètres de sécurité bientôt disponibles !'),
                              ),
                              _SettingsItem(
                                title: 'Confidentialité',
                                subtitle: 'Gestion des données et permissions',
                                icon: Icons.privacy_tip_outlined,
                                color: const Color(0xFF9C27B0),
                                onTap: () => _showSnack(
                                    'Paramètres de confidentialité bientôt disponibles !'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategory(
                            title: 'Apparence',
                            icon: Icons.palette_outlined,
                            index: 1,
                            items: [
                              _SettingsItem(
                                title: 'Thème',
                                subtitle: isDark ? 'Mode sombre' : 'Mode clair',
                                icon: isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color: AppColors.settingsAmber,
                                isToggle: true,
                                toggleValue: isDark,
                                onTap: () => _themeService.toggleTheme(),
                              ),
                              _SettingsItem(
                                title: 'Langue',
                                subtitle: 'Français',
                                icon: Icons.language_outlined,
                                color: AppColors.settingsCyan,
                                onTap: () => _showSnack(
                                    'Choix de langue bientôt disponible !'),
                              ),
                              _SettingsItem(
                                title: 'Taille du texte',
                                subtitle: _textSizeService.getLabel(),
                                icon: Icons.text_fields_outlined,
                                color: AppColors.settingsGrey,
                                onTap: _showTextSizeSettings,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategory(
                            title: 'Notifications',
                            icon: Icons.notifications_outlined,
                            index: 2,
                            items: [
                              _SettingsItem(
                                title: 'Notifications push',
                                subtitle: 'Alertes en temps réel',
                                icon: Icons.notifications_outlined,
                                color: AppColors.settingsRed,
                                isToggle: true,
                                toggleValue: _pushNotifications,
                                onTap: () => setState(
                                    () => _pushNotifications = !_pushNotifications),
                              ),
                              _SettingsItem(
                                title: 'Email',
                                subtitle: 'Notifications par email',
                                icon: Icons.email_outlined,
                                color: AppColors.settingsBlue,
                                isToggle: true,
                                toggleValue: _emailNotifications,
                                onTap: () => setState(() =>
                                    _emailNotifications = !_emailNotifications),
                              ),
                              _SettingsItem(
                                title: 'SMS',
                                subtitle: 'Alertes par SMS',
                                icon: Icons.sms_outlined,
                                color: AppColors.settingsGreen,
                                isToggle: true,
                                toggleValue: _smsNotifications,
                                onTap: () => setState(
                                    () => _smsNotifications = !_smsNotifications),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategory(
                            title: 'Support',
                            icon: Icons.support_agent_outlined,
                            index: 3,
                            items: [
                              _SettingsItem(
                                title: 'Aide & Support',
                                subtitle: 'FAQ, contact et ressources',
                                icon: Icons.help_outline,
                                color: AppColors.settingsBlue,
                                onTap: _navigateToHelpSupport,
                              ),
                              _SettingsItem(
                                title: 'Signaler un problème',
                                subtitle: 'Nous faire remonter un bug',
                                icon: Icons.bug_report_outlined,
                                color: AppColors.settingsOrange,
                                onTap: () => _showSnack(
                                    'Formulaire de signalement bientôt disponible !'),
                              ),
                              _SettingsItem(
                                title: 'Suggestions',
                                subtitle: 'Proposer des améliorations',
                                icon: Icons.lightbulb_outline,
                                color: AppColors.settingsPurple,
                                onTap: () => _showSnack(
                                    'Formulaire de suggestions bientôt disponible !'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategory(
                            title: 'À propos',
                            icon: Icons.info_outline,
                            index: 4,
                            items: [
                              _SettingsItem(
                                title: 'Version',
                                subtitle: '1.0.0',
                                icon: Icons.info_outline,
                                color: AppColors.settingsGrey,
                                onTap: _showVersionInfo,
                              ),
                              _SettingsItem(
                                title: 'Conditions d\'utilisation',
                                subtitle: 'Mentions légales et CGU',
                                icon: Icons.description_outlined,
                                color: AppColors.settingsBrown,
                                onTap: () => _showSnack(
                                    'Conditions d\'utilisation bientôt disponibles !'),
                              ),
                              _SettingsItem(
                                title: 'Politique de confidentialité',
                                subtitle: 'Comment nous protégeons vos données',
                                icon: Icons.shield_outlined,
                                color: const Color(0xFF4CAF50),
                                onTap: () => _showSnack(
                                    'Politique de confidentialité bientôt disponible !'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Personnalisez votre expérience',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── USER PROFILE CARD ────────────────────────────────────────────────────
  Widget _buildUserProfileCard(dynamic user) {
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
      child: GestureDetector(
        onTap: _navigateToProfile,
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 2.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Voir le profil →',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CATEGORY ─────────────────────────────────────────────────────────────
  Widget _buildCategory({
    required String title,
    required IconData icon,
    required int index,
    required List<_SettingsItem> items,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label de section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.screenOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.screenOrange),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.screenTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Carte
          Container(
            decoration: BoxDecoration(
              color: AppColors.screenCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isFirst = i == 0;
                final isLast = i == items.length - 1;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        borderRadius: BorderRadius.vertical(
                          top: isFirst ? const Radius.circular(20) : Radius.zero,
                          bottom: isLast ? const Radius.circular(20) : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Icône
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon,
                                    color: item.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              // Texte
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.screenTextPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.screenTextSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Toggle ou chevron
                              if (item.isToggle)
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: item.toggleValue,
                                    onChanged: (_) => item.onTap(),
                                    activeColor: item.color,
                                    activeTrackColor:
                                        item.color.withOpacity(0.25),
                                    inactiveThumbColor: AppColors.screenTextSecondary,
                                    inactiveTrackColor:
                                        AppColors.screenDivider,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                              else
                                const Icon(Icons.arrow_forward_ios,
                                    size: 13, color: AppColors.screenTextSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Padding(
                        padding: EdgeInsets.only(left: 70),
                        child: Divider(color: AppColors.screenDivider, height: 1),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOGOUT BUTTON ────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: GestureDetector(
        onTap: _confirmLogout,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_outlined, color: Colors.red[400], size: 18),
              const SizedBox(width: 10),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 15,
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

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Déconnexion ?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: AppColors.screenTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.screenTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Déconnexion',
                style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateToProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _navigateToHelpSupport() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
  }

  void _showTextSizeSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TextSizeScreen()));
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Version de l\'application',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _versionRow('Version', '1.0.0'),
            const SizedBox(height: 8),
            _versionRow('Build', '20240124'),
            const SizedBox(height: 8),
            _versionRow('Mode',
                AppConfig.MOCK_MODE ? 'Développement' : 'Production'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('OK', style: TextStyle(color: AppColors.screenOrange)),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextPrimary,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─── DATA MODEL ───────────────────────────────────────────────────────────────
class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isToggle;
  final bool toggleValue;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
  });
}