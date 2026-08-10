import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../custom_text_field.dart';
import '../custom_form_button.dart';
import '../components/custom_button.dart';
import '../custom_loader.dart';
import '../snackbar.dart';
import '../share_button.dart';
import '../components/bottom_spacer.dart';
import '../components/capsule_tab_bar.dart';
import 'reusable_bottom_sheet.dart';
import '../../services/parrainage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_guard.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';
import '../../config/app_config.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';

class SponsorshipBottomSheet extends StatefulWidget {
  const SponsorshipBottomSheet({super.key});

  @override
  State<SponsorshipBottomSheet> createState() => _SponsorshipBottomSheetState();
}

class _SponsorshipBottomSheetState extends State<SponsorshipBottomSheet> {
  final TextEditingController _parentTelephoneController =
      TextEditingController();
  final TextSizeService _textSizeService = TextSizeService();
  final ThemeService _themeService = ThemeService();
  bool _parentTelephoneError = false;
  String? _generatedCode;
  bool _isLoading = false;

  @override
  void dispose() {
    _parentTelephoneController.dispose();
    super.dispose();
  }

  // Méthode pour récupérer ou générer le code
  Future<void> _fetchSponsorshipCode() async {
    if (_parentTelephoneController.text.trim().isEmpty) {
      setState(() {
        _parentTelephoneError = true;
      });
      return;
    }

    await AuthGuard.ensureLoggedIn(
      context,
      reason: 'Connectez-vous pour accéder à votre code de parrainage',
      onAuthenticatedAsync: _performFetchSponsorshipCode,
    );
  }

  Future<void> _performFetchSponsorshipCode() async {
    setState(() {
      _parentTelephoneError = false;
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => CustomLoader(
        message: 'Récupération en cours...',
        loaderColor: AppColors.screenOrange,
        size: 56.0,
        showBackground: true,
        backgroundColor: Colors.white.withOpacity(0.9),
      ),
    );

    try {
      final infoResult = await ParrainageService.getInfoParrainage(
        _parentTelephoneController.text,
      );

      Navigator.of(context).pop(); // ferme le loader

      if (infoResult['success'] == true && infoResult['data'] != null) {
        setState(() {
          _generatedCode =
              infoResult['data']['code_parrainage'] ?? 'Non disponible';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        final rawMessage = infoResult['message']?.toString() ?? '';
        String errorMessage = 'Impossible de récupérer les informations de parrainage';
        if (rawMessage.isNotEmpty) {
          errorMessage = rawMessage.replaceFirst('Exception: ', '').trim();
        }

        CartSnackBar.showOverlay(
          context,
          productName: 'Parrainage',
          message: errorMessage,
          backgroundColor: Colors.red[500],
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // ferme le loader
      setState(() {
        _isLoading = false;
      });

      final rawMessage = e.toString();
      final isNetworkError = rawMessage.contains('SocketException') || 
                             rawMessage.contains('ClientException') ||
                             rawMessage.contains('Failed host lookup') ||
                             rawMessage.contains('Network is unreachable') ||
                             rawMessage.contains('Connection refused');
                             
      String errorMessage = 'Une erreur est survenue lors de la récupération du code';
      if (isNetworkError) {
        errorMessage = 'Impossible de se connecter au serveur. Veuillez vérifier votre connexion Internet.';
      } else {
        final cleanMsg = rawMessage.replaceFirst('Exception: ', '').trim();
        if (cleanMsg.isNotEmpty) {
          errorMessage = cleanMsg;
        }
      }

      CartSnackBar.showOverlay(
        context,
        productName: 'Erreur',
        message: errorMessage,
        backgroundColor: Colors.red[500],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();

    // Pré-remplir le numéro de téléphone de l'utilisateur connecté
    if (currentUser?.phone != null && _parentTelephoneController.text.isEmpty) {
      _parentTelephoneController.text = currentUser!.phone;
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // En-tête Hero
          _buildHeroHeader(isDark),

          // Barre d'onglets
          _buildTabBar(isDark),

          // Vues des onglets
          Expanded(
            child: TabBarView(
              children: [
                _buildTabMonCode(isDark, currentUser),
                _buildTabFonctionnement(isDark),
                _buildTabRecompenses(isDark),
                _buildTabTarifs(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMPOSANT HERO HEADER ──────────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF3E2723), const Color(0xFF1A0F0D)]
                : [const Color(0xFFFFF0EB), const Color(0xFFFFE0D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF422213) : const Color(0xFFFFD0C1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.screenOrange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stars_rounded,
                color: AppColors.screenOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SUPER PARRAIN 2026',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(9),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommandez & Gagnez !',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cumulez des commissions et gagnez jusqu\'à 500 000 FCFA.',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(11),
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
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

  // ─── COMPOSANT TAB BAR ──────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return const CapsuleTabBar(
      tabs: [
        CapsuleTabItem(
          label: 'Mon Code',
          icon: Icons.vpn_key_rounded,
        ),
        CapsuleTabItem(
          label: 'Fonctionnement',
          icon: Icons.help_outline_rounded,
        ),
        CapsuleTabItem(
          label: 'Récompenses',
          icon: Icons.emoji_events_rounded,
        ),
        CapsuleTabItem(
          label: 'Tarifs & Services',
          icon: Icons.receipt_long_rounded,
        ),
      ],
    );
  }

  // ─── ONGLET 1 : MON CODE ─────────────────────────────────────────────────────
  Widget _buildTabMonCode(bool isDark, dynamic currentUser) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (_generatedCode == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(
                AppDimensions.getMediumCardBorderRadius(context),
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF404040)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: AppColors.screenOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vos informations',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Téléphone',
                  hint: 'Votre numéro de téléphone',
                  icon: Icons.phone_rounded,
                  controller: _parentTelephoneController,
                  keyboardType: TextInputType.phone,
                  required: true,
                  hasError: _parentTelephoneError,
                  iconColor: AppColors.screenOrange,
                  focusBorderColor: AppColors.screenOrange,
                  readOnly: currentUser?.phone != null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre numéro de téléphone pour obtenir votre code de parrainage personnalisé.',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Obtenir mon code de parrainage',
            color: const Color(0xFF10B981),
            icon: Icons.card_giftcard_rounded,
            onPressed: _fetchSponsorshipCode,
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(
                AppDimensions.getMediumCardBorderRadius(context),
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF404040)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'VOTRE CODE DE PARRAINAGE',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedCode!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(26),
                    fontWeight: FontWeight.w900,
                    color: AppColors.screenOrange,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Partagez ce code avec vos proches. Lors de leur inscription, ils bénéficieront d\'avantages et vous cumulerez des commissions !',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Partager via',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(13),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildShareButtons(context, _generatedCode!),
            ),
          ),
          const SizedBox(height: 16),
          if (currentUser?.phone == null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _generatedCode = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Utiliser un autre numéro'),
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
            ),
        ],
        const BottomSpacer(),
      ],
    );
  }

  // ─── ONGLET 2 : FONCTIONNEMENT ──────────────────────────────────────────────
  Widget _buildTabFonctionnement(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          'Comment ça marche ?',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(16),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommandez l\'application Parents Responsable à vos proches et recevez des récompenses exceptionnelles.',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(11),
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '1',
          title: 'Créez votre code',
          description:
              'Renseignez votre numéro de téléphone dans l\'onglet "Mon Code" pour générer votre code unique de parrainage.',
          icon: Icons.vpn_key_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          stepNumber: '2',
          title: 'Partagez avec vos proches',
          description:
              'Envoyez votre code par WhatsApp, SMS ou Email à vos amis, parents d\'élèves ou collègues.',
          icon: Icons.share_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          stepNumber: '3',
          title: 'Gagnez des commissions',
          description:
              'Recevez 10% de commission sur tous les achats de services effectués par vos filleuls pendant 2 ans !',
          icon: Icons.payments_rounded,
          isDark: isDark,
        ),
        const BottomSpacer(),
      ],
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.screenOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(13),
                  fontWeight: FontWeight.w900,
                  color: AppColors.screenOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ONGLET 3 : RÉCOMPENSES ─────────────────────────────────────────────────
  Widget _buildTabRecompenses(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wallet_giftcard_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'COMMISSION DE BASE',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(9),
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '10% de gains garantis',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(16),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gagnez 10% de commission sur chaque abonnement ou service acheté par vos filleuls pendant une durée de 2 ans.',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(11),
                  color: Colors.white.withOpacity(0.9),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Paliers de Réductions',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(15),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTierCard('10 Filleuls', '10% de réduction',
                  'Valable 30 jours', Colors.orange[800]!, isDark),
              _buildTierCard('25 Filleuls', '10% de réduction',
                  'Valable 45 jours', Colors.blue[600]!, isDark),
              _buildTierCard('40 Filleuls', '12% de réduction',
                  'Valable 60 jours', Colors.purple[600]!, isDark),
              _buildTierCard('50+ Filleuls', '15% de réduction',
                  'Valable 90 j. + Super Parrain', Colors.green[600]!, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Classement Super Parrain',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(15),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Gains annuels reversés aux meilleurs parrains (50+ parrainages) :',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(11),
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSuperParrainRankCard(
                rank: '1er Prix (Or)',
                amount: '500 000 F',
                color: const Color(0xFFFFD700),
                icon: Icons.workspace_premium_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSuperParrainRankCard(
                rank: '2e Prix (Argent)',
                amount: '300 000 F',
                color: const Color(0xFFC0C0C0),
                icon: Icons.workspace_premium_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSuperParrainRankCard(
                rank: '3e Prix (Bronze)',
                amount: '100 000 F',
                color: const Color(0xFFCD7F32),
                icon: Icons.workspace_premium_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSuperParrainRankCard(
                rank: '12 suiv. (Cuivre)',
                amount: '50 000 F',
                color: const Color(0xFFD2691E),
                icon: Icons.card_membership_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const BottomSpacer(),
      ],
    );
  }

  Widget _buildTierCard(String referrals, String discount, String duration,
      Color color, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              referrals,
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(9),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            discount,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            duration,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(9),
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperParrainRankCard({
    required String rank,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(11),
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ONGLET 4 : TARIFS & SERVICES ──────────────────────────────────────────
  Widget _buildTabTarifs(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          'Services éligibles aux commissions',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(15),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chaque souscription de vos filleuls à ces services génère une commission de 10% créditée directement sur votre compte.',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(11),
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceItem(
          name: 'Absences & Retards',
          description: 'Suivi en temps réel des présences de l\'élève',
          price: '100 F / mois',
          icon: Icons.door_sliding_rounded,
          iconColor: Colors.red[400]!,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildServiceItem(
          name: 'Bulletins & Notes',
          description: 'Accès numérique aux relevés scolaires',
          price: '150 F / mois',
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.blue[400]!,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildServiceItem(
          name: 'Performance Scolaire',
          description: 'Analyses statistiques et graphiques des résultats',
          price: '150 F / mois',
          icon: Icons.analytics_rounded,
          iconColor: Colors.green[400]!,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildServiceItem(
          name: 'Notifications WhatsApp & SMS',
          description: 'Alertes instantanées directes sur le mobile',
          price: '200 F / mois',
          icon: Icons.forum_rounded,
          iconColor: const Color(0xFF25D366),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildServiceItem(
          name: 'Cantine & Restauration',
          description: 'Réservation et paiements des repas scolaires',
          price: 'Tarif Étab.',
          icon: Icons.restaurant_rounded,
          iconColor: Colors.amber[600]!,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildServiceItem(
          name: 'Transport Scolaire',
          description: 'Abonnement et suivi de la navette de l\'école',
          price: 'Tarif Étab.',
          icon: Icons.directions_bus_rounded,
          iconColor: Colors.indigo[400]!,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        const BottomSpacer(),
      ],
    );
  }

  Widget _buildServiceItem({
    required String name,
    required String description,
    required String price,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(13),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(10),
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              fontWeight: FontWeight.w800,
              color: AppColors.screenOrange,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOUTONS DE PARTAGE DYNAMIQUES ──────────────────────────────────────────
  List<Widget> _buildShareButtons(BuildContext context, String codeParrainage) {
    final storeUrl = AppConfig.storeUrl;

    final shareButtons = [
      ShareButton(
        label: 'WhatsApp',
        icon: Icons.message_rounded,
        iconColor: const Color(0xFF25D366),
        imagePath: 'assets/images/icons/whatsapp.png',
        onTap: () async {
          final message = 'Salut !\n\n'
              'J\'utilise l\'application PARENT RESPONSABLE et je voulais partager mon code de parrainage avec toi : *$codeParrainage*.\n\n'
              'Télécharge l\'application ici :\n$storeUrl\n\n'
              'Utilise ce code lors de ton inscription pour bénéficier de plusieurs avantages !';
          final whatsappUrl =
              'https://wa.me/?text=${Uri.encodeComponent(message)}';

          if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
            await launchUrl(
              Uri.parse(whatsappUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            CartSnackBar.showOverlay(
              context,
              productName: 'Erreur',
              message: 'WhatsApp n\'est pas installé sur cet appareil',
              backgroundColor: Colors.red[500],
            );
          }
        },
      ),
      ShareButton(
        label: 'Copier',
        icon: Icons.content_copy_rounded,
        iconColor: const Color(0xFF3B82F6),
        onTap: () {
          Clipboard.setData(ClipboardData(text: codeParrainage));
          CartSnackBar.showOverlay(
            context,
            productName: 'Code de parrainage',
            message: 'copié dans le presse-papiers',
            backgroundColor: Colors.green[500],
          );
        },
      ),
      ShareButton(
        label: 'SMS',
        icon: Icons.sms_rounded,
        iconColor: const Color(0xFF2196F3),
        onTap: () async {
          final message = 'Salut !\n\n'
              'J\'utilise l\'application Parent responsable et je voulais partager mon code de parrainage avec toi : $codeParrainage.\n\n'
              'Télécharge l\'application ici :\n$storeUrl\n\n'
              'Utilise ce code lors de ton inscription pour bénéficier de plusieurs avantages !';
          final smsUrl = 'sms:?body=${Uri.encodeComponent(message)}';

          if (await canLaunchUrl(Uri.parse(smsUrl))) {
            await launchUrl(
              Uri.parse(smsUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            CartSnackBar.showOverlay(
              context,
              productName: 'Erreur',
              message:
                  'L\'application SMS n\'est pas disponible sur cet appareil',
              backgroundColor: Colors.red[500],
            );
          }
        },
      ),
      ShareButton(
        label: 'Email',
        icon: Icons.email_rounded,
        iconColor: const Color(0xFFEA4335),
        onTap: () async {
          final subject = 'Code de parrainage Parent responsable';
          final body = 'Salut !\n\n'
              'J\'utilise l\'application Parent responsable et je voulais partager mon code de parrainage avec toi : $codeParrainage.\n\n'
              'Télécharge l\'application et utilise ce code pour vous inscrire et bénéficier d\'avantages !\n\n'
              'Lien de téléchargement :\n$storeUrl\n\n'
              'À bientôt !';
          final emailUrl =
              'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

          if (await canLaunchUrl(Uri.parse(emailUrl))) {
            await launchUrl(
              Uri.parse(emailUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            CartSnackBar.showOverlay(
              context,
              productName: 'Erreur',
              message:
                  'L\'application email n\'est pas disponible sur cet appareil',
              backgroundColor: Colors.red[500],
            );
          }
        },
      ),
    ];

    return shareButtons;
  }
}

void showSponsorshipBottomSheet(
  BuildContext context, {
  String? imagePath,
  Color? imageBackgroundColor,
  double? imageBorderRadius,
}) {
  ReusableBottomSheet.show(
    context: context,
    title: 'Parrainer',
    subtitle: 'Invitez vos proches',
    icon: Icons.card_giftcard_rounded,
    iconColor: const Color(0xFFFF7A3C),
    imagePath: imagePath,
    iconBackgroundColor: imageBackgroundColor,
    imageBorderRadius: imageBorderRadius,
    initialChildSize: 0.85,
    minChildSize: 0.6,
    maxChildSize: 0.95,
    contentPadding: EdgeInsets.zero,
    wrapWithScrollView: false,
    useDraggable: false,
    content: const SponsorshipBottomSheet(),
  );
}
