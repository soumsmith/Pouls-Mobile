import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../models/ecole.dart';
import '../../services/pouls_scolaire_api_service.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/searchable_dropdown.dart';
import 'integration_result_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class IntegrationRequestBottomSheet extends StatefulWidget {
  /// Matricule de l'élève concerné.
  final String? matricule;

  /// Nom complet de l'élève (utilisé dans les labels).
  final String? childFullName;

  const IntegrationRequestBottomSheet({
    super.key,
    this.matricule,
    this.childFullName,
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
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IntegrationRequestBottomSheet(
        matricule: matricule,
        childFullName: childFullName,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des écoles : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      } else {
        throw Exception('Erreur ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Erreur consultation : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la consultation : $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final isDark = _themeService.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Poignée ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.screenDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── En-tête du bottom sheet ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consultation demande',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(18),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vérifier le statut d\'intégration scolaire',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(13),
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF0D47A1)),
                ),
              ],
            ),
          ),

          // ── Corps ────────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: _IntegrationRequestForm(
                ecoles: _ecoles,
                isLoadingEcoles: _isLoadingEcoles,
                isLoadingRequest: _isLoadingRequest,
                selectedEcoleName: _selectedEcoleName,
                selectedEcoleId: _selectedEcoleId,
                matricule: widget.matricule,
                isDarkMode: isDark,
                textSizeService: _textSizeService,
                onEcoleChanged: (ecoleId, ecoleName) {
                  setState(() {
                    _selectedEcoleId = ecoleId;
                    _selectedEcoleName = ecoleName;
                  });
                },
                onRetryEcoles: _loadEcoles,
                onConsultWithMatricule: (matricule) =>
                    _consultRequest(matricule),
              ),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Sélecteur d'école ──────────────────────────────────────────────
        _FieldLabel(label: 'École', required: true),
        const SizedBox(height: 6),
        _buildEcoleField(context),

        const SizedBox(height: 14),

        // ── Affichage du matricule ─────────────────────────────────────────
        _FieldLabel(
          label: 'Matricule de l\'élève',
          required: widget.matricule == null,
        ),
        const SizedBox(height: 6),
        if (widget.matricule != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.screenDivider),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.screenTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.screenDivider),
            ),
            child: TextField(
              controller: _matriculeController,
              decoration: const InputDecoration(
                hintText: 'Entrez le matricule de l\'élève',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  color: AppColors.screenOrange,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                hintStyle: TextStyle(
                  color: AppColors.screenTextSecondary,
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ── Bandeau d'info ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sélectionnez une école pour consulter le statut de la demande d\'intégration',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Bouton de consultation ─────────────────────────────────────────
        _OrangeButton(
          label: widget.isLoadingRequest
              ? 'Consultation en cours...'
              : 'Consulter la demande',
          onTap: _currentMatricule.isNotEmpty && widget.selectedEcoleId != null
              ? () => widget.onConsultWithMatricule(_currentMatricule)
              : null,
          isLoading: widget.isLoadingRequest,
          icon: Icons.search_rounded,
        ),
      ],
    );
  }

  Widget _buildEcoleField(BuildContext context) {
    if (widget.isLoadingEcoles) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.screenSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.screenDivider),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.screenOrange,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Chargement des écoles...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.ecoles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Aucune école disponible',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.screenTextPrimary,
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
      );
    }

    return SearchableDropdown(
      label: 'École',
      value: widget.selectedEcoleName ?? 'Sélectionner une école...',
      items: widget.ecoles.map((e) => e.ecoleclibelle).toList(),
      onChanged: (selected) {
        final ecole = widget.ecoles.firstWhere(
          (e) => e.ecoleclibelle == selected,
        );
        widget.onEcoleChanged(ecole.ecoleid, selected);
      },
      isDarkMode: widget.isDarkMode,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires privés
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextSecondary,
            letterSpacing: 0.2,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.screenOrange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;

  const _OrangeButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onTap != null
              ? [AppColors.screenOrange, const Color(0xFFFF7A3C)]
              : [Colors.grey.shade400, Colors.grey.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: AppColors.screenOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
