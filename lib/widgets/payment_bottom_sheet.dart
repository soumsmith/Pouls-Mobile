import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'custom_loader.dart';
import 'bottom_sheets/bottom_sheet_header.dart';
import 'components/custom_text_input.dart';

class PaymentBottomSheet extends StatefulWidget {
  final String? childName;
  final String? matricule;
  final String? debutReservation;
  final String? finReservation;
  final String? title;
  final String? description;
  final IconData? icon;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;
  final dynamic montantReservation;
  final Future<Map<String, dynamic>?> Function()? loadReservationData;

  /// Appelé au tap "Payer". Retourne `true` si c'est un paiement en ligne
  /// (le sheet reste ouvert pour le polling) ou `false` pour un paiement
  /// cash (le sheet se ferme normalement).
  ///
  /// Le callback doit lancer l'opération et renvoyer un [PaymentResult].
  final Future<PaymentResult> Function(String montant, String matricule)
  onPayment;

  const PaymentBottomSheet({
    super.key,
    this.childName,
    this.matricule,
    this.debutReservation,
    this.finReservation,
    this.title,
    this.description,
    this.icon,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
    this.montantReservation,
    this.loadReservationData,
    required this.onPayment,
  });

  static Future<void> show({
    required BuildContext context,
    String? childName,
    String? matricule,
    String? debutReservation,
    String? finReservation,
    String? title,
    String? description,
    IconData? icon,
    String? imagePath,
    Color? imageBackgroundColor,
    double? imageBorderRadius,
    dynamic montantReservation,
    Future<Map<String, dynamic>?> Function()? loadReservationData,
    required Future<PaymentResult> Function(String montant, String matricule)
    onPayment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PaymentBottomSheet(
          childName: childName,
          matricule: matricule,
          debutReservation: debutReservation,
          finReservation: finReservation,
          title: title,
          description: description,
          icon: icon,
          imagePath: imagePath,
          imageBackgroundColor: imageBackgroundColor,
          imageBorderRadius: imageBorderRadius,
          montantReservation: montantReservation,
          loadReservationData: loadReservationData,
          onPayment: onPayment,
        );
      },
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

/// Résultat retourné par le callback onPayment.
class PaymentResult {
  /// true  → paiement en ligne lancé, NE PAS fermer le sheet
  /// false → paiement cash / erreur, fermer le sheet normalement
  final bool isOnlinePayment;
  final String? errorMessage;

  const PaymentResult.online() : isOnlinePayment = true, errorMessage = null;

  const PaymentResult.cash() : isOnlinePayment = false, errorMessage = null;

  const PaymentResult.error(String message)
    : isOnlinePayment = false,
      errorMessage = message;
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final TextEditingController montantController = TextEditingController();
  final TextEditingController matriculeController = TextEditingController();
  bool isLoading = false;
  bool isFetchingData = false;
  
  String? _debutReservation;
  String? _finReservation;
  dynamic _montantReservation;

  @override
  void initState() {
    super.initState();
    
    _debutReservation = widget.debutReservation;
    _finReservation = widget.finReservation;
    _montantReservation = widget.montantReservation;
    
    if (widget.matricule != null) {
      matriculeController.text = widget.matricule!;
    }
    
    _updateMontantController();
    
    if (widget.loadReservationData != null) {
      _loadData();
    }
  }
  
  void _updateMontantController() {
    if (_montantReservation != null && _montantReservation.toString() != '0') {
      montantController.text = _montantReservation.toString();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isFetchingData = true;
    });
    try {
      final data = await widget.loadReservationData!();
      if (data != null && mounted) {
        setState(() {
          if (data['debutReservation'] != null) _debutReservation = data['debutReservation'];
          if (data['finReservation'] != null) _finReservation = data['finReservation'];
          if (data['montantReservation'] != null) _montantReservation = data['montantReservation'];
          _updateMontantController();
        });
      }
    } catch (e) {
      print('Erreur loadReservationData: $e');
    } finally {
      if (mounted) {
        setState(() {
          isFetchingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    montantController.dispose();
    matriculeController.dispose();
    super.dispose();
  }

  Future<void> _effectuerPaiement() async {
    if (montantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (matriculeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le matricule de l\'élève'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await widget.onPayment(
        montantController.text.trim(),
        matriculeController.text.trim(),
      );

      if (!mounted) return;

      if (result.isOnlinePayment) {
        // ─── Paiement en ligne ────────────────────────────────────────────
        // Le sheet reste ouvert. L'écran parent a déjà lancé le polling et
        // fermera le sheet lui-même lorsque le paiement sera confirmé.
        // On arrête juste le loader.
        setState(() => isLoading = false);
      } else if (result.errorMessage != null) {
        // ─── Erreur ───────────────────────────────────────────────────────
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        // ─── Paiement cash / succès immédiat ──────────────────────────────
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildModernPaymentButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomLoader(
                    message: '',
                    loaderColor: Colors.white,
                    size: 22,
                    showBackground: false,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.payment_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  bool get _isReservationClosed {
    final now = DateTime.now();
    bool isClosed = false;

    if (_finReservation != null && _finReservation!.isNotEmpty) {
      try {
        final finDate = DateTime.parse(_finReservation!);
        if (now.isAfter(finDate)) isClosed = true;
      } catch (_) {}
    }

    if (_debutReservation != null && _debutReservation!.isNotEmpty) {
      try {
        final debutDate = DateTime.parse(_debutReservation!);
        if (now.isBefore(debutDate)) isClosed = true;
      } catch (_) {}
    }

    return isClosed;
  }

  bool get _isBeforeDebut {
    if (_debutReservation == null || _debutReservation!.isEmpty) return false;
    try {
      final debutDate = DateTime.parse(_debutReservation!);
      return DateTime.now().isBefore(debutDate);
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBg = isDark ? Colors.grey[900] : Colors.white;
    final isClosed = _isReservationClosed;
    final isBefore = _isBeforeDebut;

    return Container(
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHeader(
            icon: widget.icon ?? Icons.payment,
            iconColor: const Color(0xFFFF7A3C),
            imagePath: widget.imagePath,
            imageBackgroundColor: widget.imageBackgroundColor,
            imageBorderRadius: widget.imageBorderRadius,
            title: widget.title ?? 'Paiement en ligne',
            description: widget.description ?? (widget.childName != null
                ? 'Entrez le montant à payer pour ${widget.childName}'
                : 'Entrez le montant à payer'),
            onClose: () => Navigator.of(context).pop(),
            titleColor:
                isDark ? Colors.white : AppColors.screenTextPrimary,
            descriptionColor:
                isDark ? Colors.white70 : AppColors.screenTextSecondary,
            titleFontSize: 18,
            descriptionFontSize: 13,
            titleFontWeight: FontWeight.w800,
          ),
          
          if (isFetchingData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Center(
                child: CustomLoader(
                  message: 'Vérification de la période de réservation...',
                  loaderColor: AppColors.screenOrange,
                ),
              ),
            )
          else if (isClosed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isBefore ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBefore ? Icons.hourglass_empty_rounded : Icons.event_busy_rounded,
                      size: 48,
                      color: isBefore ? Colors.orange[400] : Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isBefore ? 'Réservation non commencée' : 'Période de réservation terminée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBefore 
                        ? 'La période de réservation pour cette école commencera le ${_formatDate(_debutReservation)}.'
                        : 'La période de réservation pour cette école s\'est terminée le ${_formatDate(_finReservation)}. Les paiements ne sont plus autorisés.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (_montantReservation != null && _montantReservation.toString() != '0')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Montant de la réservation : $_montantReservation FCFA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  CustomTextInput(
                    label: 'Matricule de l\'élève',
                    hint: 'Ex: 2024001',
                    icon: Icons.person_outline,
                    controller: matriculeController,
                    keyboardType: TextInputType.text,
                    readOnly: widget.matricule != null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextInput(
                    label: 'Montant à payer (FCFA)',
                    hint: 'Ex: 10000',
                    icon: Icons.attach_money,
                    controller: montantController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 24),
                  _buildModernPaymentButton(
                    label: isLoading ? '' : 'Procéder au paiement',
                    onTap: isLoading ? null : _effectuerPaiement,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.screenOrange.withOpacity(0.1)
                          : AppColors.screenOrangeLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.screenOrange
                            .withOpacity(isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.screenOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le paiement sera traité via notre partenaire WicPay',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.screenOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}