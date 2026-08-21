import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;

import '../../models/ecole.dart';
import '../../config/app_config.dart';
import '../../services/pouls_scolaire_api_service.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/components/custom_select_input.dart';
import '../../widgets/components/custom_text_input.dart';
import '../../widgets/components/custom_button.dart';
import '../../widgets/components/custom_error_state.dart';
import '../../utils/notification_helper.dart';
import '../../config/app_colors.dart';
import '../../screens/eleve_inscription_detail_screen.dart';
import 'reusable_bottom_sheet.dart';

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
      subtitle: 'Sélectionnez une école et entrez le matricule',
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
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();

  // État
  List<Ecole> _ecoles = [];
  bool _isLoadingEcoles = false;
  bool _hasAttemptedLoad = false;
  String? _selectedEcoleCode;
  String? _selectedEcoleName;
  String? _selectedParamEcole;
  bool _isLoadingInscription = false;
  final TextEditingController _matriculeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEcoles();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    super.dispose();
  }

  // Chargement des écoles
  Future<void> _loadEcoles() async {
    setState(() => _isLoadingEcoles = true);
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      if (mounted) {
        setState(() {
          _ecoles = ecoles;
          _hasAttemptedLoad = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading ecoles: $e');
      if (mounted) {
        setState(() {
          _hasAttemptedLoad = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingEcoles = false);
    }
  }

  // Récupérer l'UID de l'élève via l'API
  Future<Map<String, dynamic>?> _getEleveDetails(
    String matricule,
    String paramEcole,
  ) async {
    try {
      final url =
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/eleve/detail/$matricule?ecole=$paramEcole';

      print('Recherche détails élève: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Status recherche élève: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Réponse API: ${responseData}');

        // La réponse est dans un objet "data"
        if (responseData is Map && responseData.containsKey('data')) {
          final eleveDetail = responseData['data'] as Map<String, dynamic>;
          print('Élève trouvé: ${eleveDetail['uid']}');
          return eleveDetail;
        }
        // Ancien format (tableau) pour compatibilité
        else if (responseData is List && responseData.isNotEmpty) {
          final eleveDetail = responseData[0] as Map<String, dynamic>;
          print('Élève trouvé: ${eleveDetail['uid']}');
          return eleveDetail;
        }
      }

      print('Aucun élève trouvé pour le matricule: $matricule');
      return null;
    } catch (e) {
      print('Erreur recherche élève: $e');
      return null;
    }
  }

  // Navigation vers l'écran d'inscription
  Future<void> _searchEleve() async {
    // Fermer le clavier
    FocusScope.of(context).unfocus();

    if (_selectedParamEcole == null ||
        _matriculeController.text.trim().isEmpty) {
      NotificationHelper.showWarning(
        'Attention Veuillez sélectionner une école et entrer un matricule',
      );
      return;
    }

    setState(() => _isLoadingInscription = true);

    try {
      final matricule = _matriculeController.text.trim();

      // Récupérer les détails de l'élève
      final eleveDetail = await _getEleveDetails(
        matricule,
        _selectedParamEcole!,
      );

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
              ecoleNom: _selectedEcoleName ?? '',
              ecoleCode: _selectedEcoleCode,
              paramEcole: _selectedParamEcole,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        final isNetworkError = errorString.contains('SocketException') || 
                               errorString.contains('ClientException') ||
                               errorString.contains('Failed host lookup') ||
                               errorString.contains('No address associated') ||
                               errorString.contains('Connection refused') ||
                               errorString.contains('Network is unreachable') ||
                               errorString.contains('Software caused connection abort');
        if (!isNetworkError) {
          NotificationHelper.showError('Erreur lors de l\'inscription');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingInscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection de l'école
        if (_isLoadingEcoles && !_hasAttemptedLoad)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : const Color(0xFF1A1A2A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chargement des écoles...',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: isDark ? Colors.white70 : const Color(0xFF8A8A9E),
                  ),
                ),
              ],
            ),
          )
        else if (_isLoadingEcoles && _ecoles.isEmpty)
          CustomErrorState(
            title: 'Chargement des écoles...',
            message: 'Veuillez patienter pendant le chargement...',
            onRetry: _loadEcoles,
            retryText: 'Réessayer',
            buttonIsLight: true,
            buttonWidth: 200,
            isLoading: true,
          )
        else if (_isLoadingEcoles)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : const Color(0xFF1A1A2A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chargement des écoles...',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    color: isDark ? Colors.white70 : const Color(0xFF8A8A9E),
                  ),
                ),
              ],
            ),
          )
        else if (_ecoles.isEmpty)
          CustomErrorState(
            title: 'Aucune école disponible',
            message: 'Impossible de charger la liste des écoles pour le moment.',
            onRetry: _loadEcoles,
            retryText: 'Réessayer',
            buttonIsLight: true,
            buttonWidth: 200,
            isLoading: false,
          )
        else
          CustomSelectInput(
            label: 'École',
            value: _selectedEcoleName ?? '',
            items: _ecoles.map((e) => e.ecoleclibelle).toList(),
            onChanged: (value) {
              final ecole = _ecoles.firstWhere(
                (e) => e.ecoleclibelle == value,
                orElse: () => _ecoles.first,
              );
              setState(() {
                _selectedEcoleCode = ecole.ecolecode;
                _selectedEcoleName = ecole.ecoleclibelle;
                _selectedParamEcole =
                    ecole.paramecole?.isNotEmpty == true
                    ? ecole.paramecole
                    : ecole.ecolecode;
              });
            },
            isDarkMode: isDark,
            required: true,
          ),
        const SizedBox(height: 24),

        // Champ matricule
        CustomTextInput(
          label: 'Matricule de l\'élève',
          hint: 'Ex: 2024001',
          icon: Icons.person_outline,
          controller: _matriculeController,
          keyboardType: TextInputType.text,
          required: true,
        ),
        const SizedBox(height: 32),

        // Bouton de recherche
        CustomButton(
          text: _isLoadingInscription
              ? 'Recherche en cours...'
              : 'Rechercher l\'élève',
          onPressed: _searchEleve,
          color: AppColors.success,
          icon: Icons.search_rounded,
          isLoading: _isLoadingInscription,
          isLight: true,
          height: 56,
          fontSize: 16,
        ),
      ],
    );
  }
}
