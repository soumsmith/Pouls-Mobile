import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_colors.dart';
import '../components/bottom_spacer.dart';
import 'bottom_sheet_header.dart';
import '../../config/app_config.dart';
import '../../models/ecole.dart';
import '../../services/pouls_scolaire_api_service.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/components/custom_select_input.dart';
import '../../widgets/components/custom_text_input.dart';
import '../../widgets/components/custom_button.dart';
import '../../widgets/snackbar.dart';
import 'integration_result_dialog.dart';
import 'reusable_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class IntegrationRequestBottomSheet extends StatefulWidget {
  /// Matricule de l'élève concerné.
  final String? matricule;

  /// Nom complet de l'élève (utilisé dans les labels).
  final String? childFullName;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;

  const IntegrationRequestBottomSheet({
    super.key,
    this.matricule,
    this.childFullName,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
  });

  // ── Méthode statique d'affichage ──────────────────────────────────────────

  /// Ouvre le bottom sheet depuis n'importe quel écran.
  ///
  /// ```dart
  /// IntegrationRequestBottomSheet.show(
  ///   context,
  ///   matricule: _matricule,
  ///   childFullName: widget.child.fullName,
  /// );
  /// ```
  static void show(
    BuildContext context, {
    String? matricule,
    String? childFullName,
    String? imagePath,
    Color? imageBackgroundColor,
    double? imageBorderRadius,
  }) {
    ReusableBottomSheet.show(
      context: context,
      title: 'Consultation demande',
      subtitle: 'Vérifier le statut d\'intégration scolaire',
      icon: Icons.school_rounded,
      iconColor: const Color(0xFF1565C0),
      imagePath: imagePath,
      iconBackgroundColor: imageBackgroundColor,
      imageBorderRadius: imageBorderRadius,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      wrapWithScrollView: false,
      contentPadding: const EdgeInsets.all(0),
      content: IntegrationRequestBottomSheet(
        matricule: matricule,
        childFullName: childFullName,
        imagePath: imagePath,
        imageBackgroundColor: imageBackgroundColor,
        imageBorderRadius: imageBorderRadius,
      ),
    );
  }

  @override
  State<IntegrationRequestBottomSheet> createState() =>
      _IntegrationRequestBottomSheetState();
}

class _IntegrationRequestBottomSheetState
    extends State<IntegrationRequestBottomSheet> {
  // ── Services ───────────────────────────────────────────────────────────────
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();

  // ── État ───────────────────────────────────────────────────────────────────
  List<Ecole> _ecoles = [];
  bool _isLoadingEcoles = false;
  int? _selectedEcoleId;
  String? _selectedEcoleName;
  bool _isLoadingRequest = false;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadEcoles();
  }

  // ── Chargement des écoles ─────────────────────────────────────────────────

  Future<void> _loadEcoles() async {
    setState(() => _isLoadingEcoles = true);
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      if (mounted) setState(() => _ecoles = ecoles);
    } catch (e) {
      debugPrint('Error loading ecoles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEcoles = false);
    }
  }

  // ── Consultation de la demande ────────────────────────────────────────────

  Future<void> _consultRequest(String matricule) async {
    if (_selectedEcoleId == null || matricule.isEmpty) return;

    setState(() => _isLoadingRequest = true);

    try {
      final ecole = _ecoles.firstWhere((e) => e.ecoleid == _selectedEcoleId);
      final ecoleCode = (ecole.paramecole?.isNotEmpty == true)
          ? ecole.paramecole!
          : ecole.ecolecode;

      final url =
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/preinscription/demande-integration/consulte'
          '?ecole=$ecoleCode&matricule=$matricule';

      debugPrint('🔍 Consultation demande intégration → $url');

      final response = await http.get(Uri.parse(url));

      debugPrint('📊 Status : ${response.statusCode}');
      debugPrint('📄 Body   : ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (mounted) _showResultDialog(data);
      } else if (response.statusCode == 404) {
        String friendlyError = 'L\'élève avec le matricule saisi n\'a pas été trouvé dans l\'école sélectionnée.';
        try {
          final errBody = json.decode(response.body);
          if (errBody is Map && errBody.containsKey('error')) {
            final errText = errBody['error'].toString();
            if (errText == 'Ecole not found') {
              friendlyError = 'L\'élève avec le matricule saisi n\'a pas été trouvé dans l\'école sélectionnée.';
            } else {
              friendlyError = errText;
            }
          }
        } catch (_) {}
        throw Exception(friendlyError);
      } else {
        throw Exception('Erreur de serveur (${response.statusCode}). Veuillez réessayer plus tard.');
      }
    } catch (e) {
      debugPrint('💥 Erreur consultation : $e');
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
          String errorMessage = errorString;
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring('Exception: '.length);
          }
          
          CartSnackBar.showOverlay(
            context,
            productName: 'Erreur',
            message: 'lors de la consultation',
            backgroundColor: Colors.red,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingRequest = false);
    }
  }

  // ── Dialog résultat ───────────────────────────────────────────────────────

  void _showResultDialog(Map<String, dynamic> data) {
    IntegrationResultDialog.show(context, data: data);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _IntegrationRequestForm(
      ecoles: _ecoles,
      isLoadingEcoles: _isLoadingEcoles,
      isLoadingRequest: _isLoadingRequest,
      selectedEcoleName: _selectedEcoleName,
      selectedEcoleId: _selectedEcoleId,
      matricule: widget.matricule,
      childFullName: widget.childFullName,
      isDarkMode: isDark,
      textSizeService: _textSizeService,
      onEcoleChanged: (ecoleId, ecoleName) {
        setState(() {
          _selectedEcoleId = ecoleId;
          _selectedEcoleName = ecoleName;
        });
      },
      onRetryEcoles: _loadEcoles,
      onConsultWithMatricule: (matricule) => _consultRequest(matricule),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sous-widget : formulaire de consultation
// ─────────────────────────────────────────────────────────────────────────────

class _IntegrationRequestForm extends StatefulWidget {
  final List<Ecole> ecoles;
  final bool isLoadingEcoles;
  final bool isLoadingRequest;
  final String? selectedEcoleName;
  final int? selectedEcoleId;
  final String? matricule;
  final String? childFullName;
  final bool isDarkMode;
  final TextSizeService textSizeService;
  final void Function(int ecoleId, String ecoleName) onEcoleChanged;
  final VoidCallback onRetryEcoles;
  final Future<void> Function(String matricule) onConsultWithMatricule;

  const _IntegrationRequestForm({
    required this.ecoles,
    required this.isLoadingEcoles,
    required this.isLoadingRequest,
    required this.selectedEcoleName,
    required this.selectedEcoleId,
    required this.matricule,
    required this.childFullName,
    required this.isDarkMode,
    required this.textSizeService,
    required this.onEcoleChanged,
    required this.onRetryEcoles,
    required this.onConsultWithMatricule,
  });

  @override
  State<_IntegrationRequestForm> createState() =>
      _IntegrationRequestFormState();
}

class _IntegrationRequestFormState extends State<_IntegrationRequestForm> {
  final TextEditingController _matriculeController = TextEditingController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.matricule != null) {
      _matriculeController.text = widget.matricule!;
    }

    _matriculeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    super.dispose();
  }

  String get _currentMatricule {
    return widget.matricule ?? _matriculeController.text.trim();
  }

  /// Génère les données pour le QR code de l'élève
  String _generateQRData() {
    final matricule = _currentMatricule;
    final fullName = widget.childFullName ?? '';
    final ecoleName = widget.selectedEcoleName ?? '';
    
    // Créer un format JSON structuré pour le QR code
    final qrData = {
      'type': 'student_identification',
      'matricule': matricule,
      'nom_complet': fullName,
      'ecole': ecoleName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return jsonEncode(qrData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Indicateur de progression ─────────────────────────────────────
        _buildProgressIndicator(),

        // ── Corps du formulaire ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
        ),

        // ── Barre de navigation inférieure ────────────────────────────────
        _buildBottomNavigation(),
        const BottomSpacer(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return GestureDetector(
                onTap: () => setState(() => _currentStep = index),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isActive
                            ? AppColors.integrationBlue
                            : (isDark ? const Color(0xFF222222) : AppColors.screenSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.integrationBlue
                              : isCompleted
                              ? Colors.green
                              : (isDark ? const Color(0xFF333333) : AppColors.screenDivider),
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.integrationBlue.withOpacity(0.25),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : isCompleted
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.25),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Icon(
                              [
                                Icons.school_outlined,
                                Icons.badge_outlined,
                                Icons.check_circle_outline,
                              ][index],
                              size: 14,
                              color: isActive
                                  ? Colors.white
                                  : (isDark ? Colors.white38 : AppColors.screenTextSecondary),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['École', 'Matricule', 'Confirmation'][index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.integrationBlue
                            : isCompleted
                            ? Colors.green
                            : (isDark ? Colors.white54 : AppColors.screenTextSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(
                    right: index < 2 ? 4 : 0,
                    left: index > 0 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : (isDark ? const Color(0xFF333333) : AppColors.screenDivider),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEcoleStep();
      case 1:
        return _buildMatriculeStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return _buildEcoleStep();
    }
  }

  Widget _buildEcoleStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isLoadingEcoles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : AppColors.screenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF333333) : AppColors.screenDivider),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.screenOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chargement des écoles...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppColors.screenTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else if (widget.ecoles.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D1E1E) : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucune école disponible',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.screenTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onRetryEcoles,
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: AppColors.screenOrange),
                  ),
                ),
              ],
            ),
          )
        else
          CustomSelectInput(
            label: 'École',
            value: widget.selectedEcoleName ?? '',
            items: widget.ecoles.map((e) => e.ecoleclibelle).toList(),
            onChanged: (selected) {
              final ecole = widget.ecoles.firstWhere(
                (e) => e.ecoleclibelle == selected,
              );
              widget.onEcoleChanged(ecole.ecoleid, selected);
            },
            isDarkMode: widget.isDarkMode,
            required: true,
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0D47A1).withOpacity(0.25) 
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                  ? const Color(0xFF1565C0).withOpacity(0.3) 
                  : const Color(0xFF1565C0).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0), 
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sélectionnez une école pour consulter le statut de la demande d\'intégration',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatriculeStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.matricule != null)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : AppColors.screenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF333333) : AppColors.screenDivider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: AppColors.screenOrange,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.matricule!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          CustomTextInput(
            label: 'Matricule de l\'élève',
            hint: 'Entrez le matricule de l\'élève',
            icon: Icons.badge_outlined,
            controller: _matriculeController,
            keyboardType: TextInputType.text,
            required: true,
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFFFFB300).withOpacity(0.15) 
                : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                  ? const Color(0xFFFFB300).withOpacity(0.3) 
                  : const Color(0xFFFFB300).withOpacity(0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFB300), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le matricule permet d\'identifier l\'élève dans le système',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF333333) : AppColors.screenDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Récapitulatif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.screenTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecapItem(
                'École',
                widget.selectedEcoleName ?? 'Non sélectionnée',
              ),
              _buildRecapItem(
                'Matricule',
                _currentMatricule.isEmpty ? 'Non renseigné' : _currentMatricule,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // QR Code section
        if (_currentMatricule.isNotEmpty && widget.childFullName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF333333) : AppColors.screenDivider),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.integrationBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'QR Code d\'identification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.screenDivider),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _generateQRData(),
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Matricule: $_currentMatricule',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.screenTextSecondary,
                        ),
                      ),
                      if (widget.childFullName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.childFullName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF4CAF50),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vérifiez les informations avant de consulter',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecapItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 8),
      child: _buildNavigationButtons(),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canNext = _validateCurrentStep();
    final isLast = _currentStep == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (_currentStep > 0)
            CustomButton(
              text: 'Précédent',
              onPressed: () => setState(() => _currentStep--),
              color: isDark ? Colors.white60 : Colors.grey[700]!,
              isLight: true,
              hasBorder: false,
              icon: Icons.arrow_back_ios_new,
              width: 120,
              height: 40,
              fontSize: 12,
            ),
          const Spacer(),
          if (!isLast)
            CustomButton(
              text: 'Suivant',
              onPressed: canNext ? () => setState(() => _currentStep++) : null,
              color: AppColors.integrationBlue,
              icon: Icons.arrow_forward_rounded,
              iconOnRight: true,
              width: 120,
              height: 40,
              fontSize: 12,
            )
          else
            CustomButton(
              text: 'Consulter',
              onPressed: canNext
                  ? () => widget.onConsultWithMatricule(_currentMatricule)
                  : null,
              color: AppColors.screenOrange,
              icon: Icons.search_rounded,
              iconOnRight: true,
              isLoading: widget.isLoadingRequest,
              width: 120,
              height: 40,
              fontSize: 12,
            ),
        ],
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return widget.selectedEcoleId != null;
      case 1:
        return _currentMatricule.isNotEmpty;
      case 2:
        return widget.selectedEcoleId != null && _currentMatricule.isNotEmpty;
      default:
        return false;
    }
  }
}
