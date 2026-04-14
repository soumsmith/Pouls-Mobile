import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'custom_loader.dart';
import 'bottom_sheets/bottom_sheet_header.dart';
import 'components/custom_text_input.dart';

class PaymentBottomSheet extends StatefulWidget {
  final String? childName;
  final String? matricule;
  final Future<void> Function(String montant, String matricule) onPayment;

  const PaymentBottomSheet({
    super.key,
    this.childName,
    this.matricule,
    required this.onPayment,
  });

  static Future<void> show({
    required BuildContext context,
    String? childName,
    String? matricule,
    required Future<void> Function(String montant, String matricule) onPayment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PaymentBottomSheet(
          childName: childName,
          matricule: matricule,
          onPayment: onPayment,
        );
      },
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final TextEditingController montantController = TextEditingController();
  final TextEditingController matriculeController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.matricule != null) {
      matriculeController.text = widget.matricule!;
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

    setState(() {
      isLoading = true;
    });

    try {
      await widget.onPayment(montantController.text, matriculeController.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.screenCard,
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
            icon: Icons.payment,
            iconColor: const Color(0xFFFF7A3C),
            title: 'Paiement en ligne',
            description: widget.childName != null
                ? 'Entrez le montant à payer pour ${widget.childName}'
                : 'Entrez le montant à payer',
            onClose: () => Navigator.of(context).pop(),
            titleColor: AppColors.screenTextPrimary,
            descriptionColor: AppColors.screenTextSecondary,
            titleFontSize: 18,
            descriptionFontSize: 13,
            titleFontWeight: FontWeight.w800,
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
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
                  keyboardType: TextInputType.number,
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
                    color: AppColors.screenOrangeLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.screenOrange.withOpacity(0.2),
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
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}