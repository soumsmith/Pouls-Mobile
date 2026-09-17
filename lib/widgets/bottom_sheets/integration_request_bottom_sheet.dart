import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../models/code_dren_ecole.dart';
import '../../services/ecole_eleve_service.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/components/custom_text_input.dart';
import '../../widgets/components/custom_button.dart';
import '../../utils/notification_helper.dart';
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
      useDraggable: false,
      useKeyboardPadding: false,
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

  // ── État ───────────────────────────────────────────────────────────────────
  //
  // École trouvée par recherche directe au code DREN (api2.vie-ecoles.com,
  // même mécanisme que InscriptionBottomSheet/IntegrationBottomSheet) :
  // `_selectedEcoleCode` est directement le code legacy vie-ecoles
  // (CodeDrenEcole.code), pas besoin de résolution supplémentaire pour
  // consulter la demande.
  String? _selectedEcoleCode;
  String? _selectedEcoleName;
  bool _isLoadingRequest = false;

  // ── Consultation de la demande ────────────────────────────────────────────

  Future<void> _consultRequest(String matricule) async {
    final ecoleCode = _selectedEcoleCode;
    if (ecoleCode == null || matricule.isEmpty) return;

    setState(() => _isLoadingRequest = true);

    try {
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
        String errorMessage;
        if (isNetworkError) {
          errorMessage = 'de connexion. Veuillez vérifier votre réseau.';
        } else {
          String rawMessage = errorString;
          if (rawMessage.startsWith('Exception: ')) {
            rawMessage = rawMessage.substring('Exception: '.length);
          }
          errorMessage = ': $rawMessage';
        }
        
        NotificationHelper.showError('Erreur $errorMessage');
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
      isLoadingRequest: _isLoadingRequest,
      selectedEcoleName: _selectedEcoleName,
      selectedEcoleCode: _selectedEcoleCode,
      matricule: widget.matricule,
      childFullName: widget.childFullName,
      isDarkMode: isDark,
      textSizeService: _textSizeService,
      onEcoleChanged: (ecoleCode, ecoleName) {
        setState(() {
          _selectedEcoleCode = ecoleCode;
          _selectedEcoleName = ecoleName;
        });
      },
      onConsultWithMatricule: (matricule) => _consultRequest(matricule),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sous-widget : formulaire de consultation
// ─────────────────────────────────────────────────────────────────────────────

class _IntegrationRequestForm extends StatefulWidget {
  final bool isLoadingRequest;
  final String? selectedEcoleName;
  final String? selectedEcoleCode;
  final String? matricule;
  final String? childFullName;
  final bool isDarkMode;
  final TextSizeService textSizeService;
  final void Function(String ecoleCode, String ecoleName) onEcoleChanged;
  final Future<void> Function(String matricule) onConsultWithMatricule;

  const _IntegrationRequestForm({
    required this.isLoadingRequest,
    required this.selectedEcoleName,
    required this.selectedEcoleCode,
    required this.matricule,
    required this.childFullName,
    required this.isDarkMode,
    required this.textSizeService,
    required this.onEcoleChanged,
    required this.onConsultWithMatricule,
  });

  @override
  State<_IntegrationRequestForm> createState() =>
      _IntegrationRequestFormState();
}

class _IntegrationRequestFormState extends State<_IntegrationRequestForm> {
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _drenController = TextEditingController();
  int _currentStep = 0;
  bool _isSearchingEcole = false;
  String? _ecoleErrorMessage;

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
    _drenController.dispose();
    super.dispose();
  }

  // ── Étape 0 : recherche de l'école par code DREN (api2.vie-ecoles.com) ─────
  Future<void> _searchEcole() async {
    FocusScope.of(context).unfocus();

    final codeDren = _drenController.text.trim();
    if (codeDren.isEmpty) {
      setState(() => _ecoleErrorMessage = 'Veuillez entrer le code DREN de l\'école');
      return;
    }

    setState(() {
      _isSearchingEcole = true;
      _ecoleErrorMessage = null;
    });

    try {
      final ecole = await EcoleEleveService.rechercherParCodeDren(codeDren);
      widget.onEcoleChanged(ecole.code, ecole.nom);
    } catch (e) {
      if (mounted) {
        setState(() => _ecoleErrorMessage = _readableError(e));
      }
    } finally {
      if (mounted) setState(() => _isSearchingEcole = false);
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

        // ── Navigation buttons ────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNavigationButtons(),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0
                    ? 20.0
                    : MediaQuery.of(context).padding.bottom + 24.0,
              ),
            ],
          ),
        ),
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
        CustomTextInput(
          label: 'Code DREN de l\'école',
          hint: 'Ex: 002016',
          icon: Icons.pin_outlined,
          controller: _drenController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          required: true,
        ),
        const SizedBox(height: 12),
        if (_ecoleErrorMessage != null) ...[
          _buildInlineErrorBanner(_ecoleErrorMessage!),
          const SizedBox(height: 12),
        ],
        CustomButton(
          text: _isSearchingEcole ? 'Recherche en cours...' : 'Rechercher l\'école',
          onPressed: _isSearchingEcole ? null : _searchEcole,
          color: AppColors.integrationBlue,
          icon: Icons.search_rounded,
          isLoading: _isSearchingEcole,
        ),
        if (widget.selectedEcoleCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedEcoleName ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222222)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF333333)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrez le code DREN pour retrouver l\'école et consulter le statut de la demande d\'intégration',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
                ? const Color(0xFF222222) 
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                  ? const Color(0xFF333333) 
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded, 
                color: isDark ? Colors.white54 : Colors.grey[600], 
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le matricule permet d\'identifier l\'élève dans le système',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    fontSize: 12,
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
        return widget.selectedEcoleCode != null;
      case 1:
        return _currentMatricule.isNotEmpty;
      case 2:
        return widget.selectedEcoleCode != null && _currentMatricule.isNotEmpty;
      default:
        return false;
    }
  }
}
