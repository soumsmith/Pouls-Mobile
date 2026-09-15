import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;

import '../../models/code_dren_ecole.dart';
import '../../config/app_config.dart';
import '../../services/ecole_eleve_service.dart';
import '../../services/text_size_service.dart';
import '../../widgets/components/custom_text_input.dart';
import '../../widgets/components/custom_button.dart';
import '../../utils/notification_helper.dart';
import '../../config/app_colors.dart';
import '../../screens/eleve_inscription_detail_screen.dart';
import 'reusable_bottom_sheet.dart';

/// Wizard "Nouvelle Inscription" en 2 étapes :
///  1. Code DREN de l'école -> recherche de l'école (api2.vie-ecoles.com)
///  2. Matricule de l'élève -> recherche de l'élève dans l'école trouvée
class InscriptionBottomSheet extends StatefulWidget {
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;

  const InscriptionBottomSheet({
    super.key,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
  });

  static void show(
    BuildContext context, {
    String? imagePath,
    Color? imageBackgroundColor,
    double? imageBorderRadius,
  }) {
    ReusableBottomSheet.show(
      context: context,
      title: 'Nouvelle Inscription',
      subtitle: 'Entrez le code DREN de l\'école',
      icon: Icons.school,
      iconColor: const Color(0xFF4CAF50),
      imagePath: imagePath,
      iconBackgroundColor: imageBackgroundColor,
      imageBorderRadius: imageBorderRadius,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      contentPadding: const EdgeInsets.all(20),
      content: InscriptionBottomSheet(
        imagePath: imagePath,
        imageBackgroundColor: imageBackgroundColor,
        imageBorderRadius: imageBorderRadius,
      ),
    );
  }

  @override
  State<InscriptionBottomSheet> createState() => _InscriptionBottomSheetState();
}

class _InscriptionBottomSheetState extends State<InscriptionBottomSheet> {
  final TextSizeService _textSizeService = TextSizeService();

  // Étape courante du wizard : 0 = code DREN, 1 = matricule
  int _currentStep = 0;

  // Étape 1 : recherche de l'école par code DREN
  final TextEditingController _drenController = TextEditingController();
  bool _isSearchingEcole = false;
  CodeDrenEcole? _foundEcole;

  // Étape 2 : recherche de l'élève par matricule
  final TextEditingController _matriculeController = TextEditingController();
  bool _isSearchingEleve = false;

  @override
  void dispose() {
    _drenController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  // Étape 1 : Recherche de l'école via son code DREN
  Future<void> _searchEcole() async {
    FocusScope.of(context).unfocus();

    final codeDren = _drenController.text.trim();
    if (codeDren.isEmpty) {
      NotificationHelper.showWarning('Veuillez entrer le code DREN de l\'école');
      return;
    }

    setState(() {
      _isSearchingEcole = true;
      _foundEcole = null;
    });

    try {
      final ecole = await EcoleEleveService.rechercherParCodeDren(codeDren);
      if (mounted) {
        setState(() => _foundEcole = ecole);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(_readableError(e));
      }
    } finally {
      if (mounted) setState(() => _isSearchingEcole = false);
    }
  }

  void _goToMatriculeStep() {
    FocusScope.of(context).unfocus();
    if (_foundEcole == null) return;
    setState(() => _currentStep = 1);
  }

  void _backToEcoleStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 0);
  }

  // Étape 2 : Récupérer les détails de l'élève via l'API
  Future<Map<String, dynamic>?> _getEleveDetails(
    String matricule,
    String paramEcole,
  ) async {
    final url =
        '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/eleve/detail/$matricule?ecole=$paramEcole';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // La réponse est dans un objet "data"
      if (responseData is Map && responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }
      // Ancien format (tableau) pour compatibilité
      else if (responseData is List && responseData.isNotEmpty) {
        return responseData[0] as Map<String, dynamic>;
      }
    }

    return null;
  }

  // Navigation vers l'écran de confirmation de l'élève
  Future<void> _searchEleve() async {
    FocusScope.of(context).unfocus();

    final ecole = _foundEcole;
    if (ecole == null) return;

    if (_matriculeController.text.trim().isEmpty) {
      NotificationHelper.showWarning('Veuillez entrer le matricule de l\'élève');
      return;
    }

    setState(() => _isSearchingEleve = true);

    try {
      final matricule = _matriculeController.text.trim();

      final eleveDetail = await _getEleveDetails(matricule, ecole.code);

      if (eleveDetail == null) {
        if (mounted) {
          NotificationHelper.showError(
            'Élève non trouvé Aucun élève trouvé pour ce matricule dans cette école',
          );
        }
        return;
      }

      // Fermer le bottom sheet puis afficher l'écran de confirmation avec
      // les informations complètes de l'élève trouvé.
      if (mounted) {
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        rootNavigator.pop();
        rootNavigator.push(
          MaterialPageRoute(
            builder: (context) => EleveInscriptionDetailScreen(
              eleveDetail: eleveDetail,
              ecoleNom: ecole.nom,
              ecoleCode: ecole.code,
              paramEcole: ecole.code,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(_readableError(e));
      }
    } finally {
      if (mounted) setState(() => _isSearchingEleve = false);
    }
  }

  String _readableError(Object e) {
    final errorString = e.toString();
    final isNetworkError = errorString.contains('SocketException') ||
        errorString.contains('ClientException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('No address associated') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Network is unreachable') ||
        errorString.contains('Software caused connection abort');
    if (isNetworkError) return 'Vérifiez votre connexion internet';
    return errorString.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(isDark),
        const SizedBox(height: 20),
        if (_currentStep == 0) _buildEcoleStep(isDark) else _buildMatriculeStep(isDark),
      ],
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    Widget dot(bool active) => Container(
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.success
                : (isDark ? Colors.white24 : Colors.grey[300]),
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Row(
      children: [
        dot(_currentStep == 0),
        const SizedBox(width: 6),
        dot(_currentStep == 1),
        const SizedBox(width: 12),
        Text(
          _currentStep == 0 ? 'Étape 1/2 · École' : 'Étape 2/2 · Élève',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF8A8A9E),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Étape 1 : Code DREN
  // ---------------------------------------------------------------------
  Widget _buildEcoleStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextInput(
          label: 'Code DREN de l\'école',
          hint: 'Ex: 002016',
          icon: Icons.pin_outlined,
          controller: _drenController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          required: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchEcole(),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: _isSearchingEcole ? 'Recherche en cours...' : 'Rechercher l\'école',
          onPressed: _searchEcole,
          color: AppColors.success,
          icon: Icons.search_rounded,
          isLoading: _isSearchingEcole,
          isLight: true,
          height: 56,
          fontSize: 16,
        ),
        if (_foundEcole != null) ...[
          const SizedBox(height: 20),
          _buildEcoleFoundCard(isDark, _foundEcole!),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Continuer l\'inscription',
            onPressed: _goToMatriculeStep,
            color: AppColors.success,
            icon: Icons.arrow_forward_rounded,
            iconOnRight: true,
            height: 56,
            fontSize: 16,
          ),
        ],
      ],
    );
  }

  Widget _buildEcoleFoundCard(bool isDark, CodeDrenEcole ecole) {
    final localisation = [
      ecole.ville,
      ecole.adresse,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ecole.nom,
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2A),
                  ),
                ),
                if (localisation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    localisation,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      color: isDark ? Colors.white70 : const Color(0xFF8A8A9E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Étape 2 : Matricule de l'élève
  // ---------------------------------------------------------------------
  Widget _buildMatriculeStep(bool isDark) {
    final ecole = _foundEcole;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ecole != null)
          GestureDetector(
            onTap: _backToEcoleStep,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ecole.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(13),
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2A),
                      ),
                    ),
                  ),
                  Text(
                    'Changer',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF8A8A9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        CustomTextInput(
          label: 'Matricule de l\'élève',
          hint: 'Ex: 2024001',
          icon: Icons.person_outline,
          controller: _matriculeController,
          keyboardType: TextInputType.text,
          required: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchEleve(),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: _isSearchingEleve ? 'Recherche en cours...' : 'Rechercher l\'élève',
          onPressed: _searchEleve,
          color: AppColors.success,
          icon: Icons.search_rounded,
          isLoading: _isSearchingEleve,
          isLight: true,
          height: 56,
          fontSize: 16,
        ),
      ],
    );
  }
}
