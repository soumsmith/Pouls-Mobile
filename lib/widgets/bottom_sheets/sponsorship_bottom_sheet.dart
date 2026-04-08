import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../custom_text_field.dart';
import '../custom_form_button.dart';
import '../custom_snackbar.dart';
import '../custom_loader.dart';
import '../snackbar.dart';
import '../share_button.dart';
import '../../services/parrainage_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';

class SponsorshipBottomSheet extends StatefulWidget {
  const SponsorshipBottomSheet({super.key});

  @override
  State<SponsorshipBottomSheet> createState() => _SponsorshipBottomSheetState();
}

class _SponsorshipBottomSheetState extends State<SponsorshipBottomSheet> {
  final TextEditingController _parentTelephoneController = TextEditingController();
  final TextSizeService _textSizeService = TextSizeService();
  final ThemeService _themeService = ThemeService();
  bool _parentTelephoneError = false;

  @override
  void dispose() {
    _parentTelephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkMode;
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();

    // Pré-remplir le numéro de téléphone de l'utilisateur connecté
    if (currentUser?.phone != null && _parentTelephoneController.text.isEmpty) {
      _parentTelephoneController.text = currentUser!.phone;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.getLargeCardBorderRadius(context)),
        ),
        boxShadow: AppDimensions.getCustomShadow(
          context: context,
          alpha: isDark ? 0.5 : 0.22,
          blurRadius: 32,
          offset: 12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 20),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A3C), Color(0xFFFF6B2C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B2C).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      size: 18, color: Colors.white),
                ),

                const SizedBox(width: 12),

                // Title
                const Expanded(
                  child: Text(
                    'Parrainer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Vos informations
                Container(
                  padding: const EdgeInsets.all(16),
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
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vos informations',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(16),
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 12),
                      Text(
                        'Renseignez votre numéro de téléphone pour obtenir votre code de parrainage',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton d'obtention du code
                CustomFormButton(
                  text: 'Obtenir mon code de parrainage',
                  color: AppColors.screenOrange,
                  icon: Icons.card_giftcard_rounded,
                  onPressed: () async {
                    // Validation AVANT d'afficher le loader
                    if (_parentTelephoneController.text.isEmpty) {
                      CustomSnackBar.warning(
                        context,
                        'Veuillez renseigner votre numéro de téléphone',
                      );
                      return;
                    }

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
                      // Récupérer les infos de parrainage directement avec le numéro de téléphone
                      final infoResult = await ParrainageService.getInfoParrainage(
                        _parentTelephoneController.text,
                      );

                      Navigator.of(context).pop(); // ferme le loader

                      if (infoResult['success'] == true && infoResult['data'] != null) {
                        Navigator.of(context).pop(); // ferme le bottom sheet

                        // Afficher le modal avec le code de parrainage
                        _showParrainageCodeModal(
                          infoResult['data']['code_parrainage'] ?? 'Non disponible',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              infoResult['message'] ??
                                  'Impossible de récupérer les informations de parrainage',
                            ),
                            backgroundColor: Colors.red[400],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.getSmallCardBorderRadius(context),
                              ),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.of(context).pop(); // ferme le loader
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur réseau: ${e.toString()}'),
                          backgroundColor: Colors.red[400],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.getSmallCardBorderRadius(context),
                            ),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ── Parrainage Code Modal ────────────────────────────────────────────────────
  void _showParrainageCodeModal(String codeParrainage) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permet la fermeture en cliquant en dehors
      builder: (BuildContext context) {
        final isDark = _themeService.isDarkMode;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Contenu principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.getLargeCardBorderRadius(context),
                  ),
                  boxShadow: AppDimensions.getCustomShadow(
                    context: context,
                    alpha: isDark ? 0.5 : 0.22,
                    blurRadius: 32,
                    offset: 12,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon de succès
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.getHeroCardBorderRadius(context),
                        ),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        size: 40,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Titre
                    Text(
                      'Parrainage réussi!',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(20),
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Sous-titre
                    Text(
                      'Votre code de parrainage a été généré avec succès',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Code de parrainage - Grand et centré
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.getMediumCardBorderRadius(context),
                        ),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'VOTRE CODE DE PARRAINAGE',
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            codeParrainage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(28),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3B82F6),
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Boutons d'action personnalisés avec défilement horizontal
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildShareButtons(codeParrainage),
                      ),
                    )],
                ),
              ),
              // Bouton de fermeture en haut à droite
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour construire dynamiquement les boutons de partage
  List<Widget> _buildShareButtons(String codeParrainage) {
    final downloadLink = defaultTargetPlatform == TargetPlatform.android 
        ? 'https://play.google.com/store/apps/details?id=com.pouls.mobile'
        : 'https://apps.apple.com/app/parent-responsable/id123456789';

    final shareButtons = [
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
          final message = 'Salut ! J\'utilise l\'application Parent responsable et je voulais partager mon code de parrainage avec toi : $codeParrainage. Télécharge l\'application et utilise ce code pour vous inscrire et bénéficier d\'avantages !';
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
              message: 'L\'application SMS n\'est pas disponible sur cet appareil',
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
          final body = 'Salut !\n\nJ\'utilise l\'application Parent responsable et je voulais partager mon code de parrainage avec toi : $codeParrainage.\n\nTélécharge l\'application et utilise ce code pour vous inscrire et bénéficier d\'avantages !\n\nLien de téléchargement :\n$downloadLink\n\nÀ bientôt !';
          final emailUrl = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
          
          if (await canLaunchUrl(Uri.parse(emailUrl))) {
            await launchUrl(
              Uri.parse(emailUrl),
              mode: LaunchMode.externalApplication,
            );
          } else {
            CartSnackBar.showOverlay(
              context,
              productName: 'Erreur',
              message: 'L\'application email n\'est pas disponible sur cet appareil',
              backgroundColor: Colors.red[500],
            );
          }
        },
      ),
      ShareButton(
        label: 'WhatsApp',
        icon: Icons.message_rounded,
        iconColor: const Color(0xFF25D366),
        imagePath: 'assets/images//Users/logo-app.png',
        onTap: () async {
          final message = 'Salut ! J\'utilise l\'application PARENT RESPONSABLE et je voulais partager mon code de parrainage avec toi : *$codeParrainage*. Télécharge l\'application ici $downloadLink et utilise ce code pour vous inscrire et bénéficier d\'avantages !';
          final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
          
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
    ];

    return shareButtons;
  }
}

// Helper function pour afficher le bottom sheet
void showSponsorshipBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.40),
    builder: (_) => const SponsorshipBottomSheet(),
  );
}
