import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'custom_loader.dart';

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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.screenShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.screenDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF7A3C),
                                AppColors.screenOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paiement en ligne',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.screenTextPrimary,
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              Text(
                                widget.childName != null 
                                    ? 'Entrez le montant à payer pour ${widget.childName}'
                                    : 'Entrez le montant à payer',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.screenTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.screenTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      color: AppColors.screenDivider,
                      height: 1,
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Matricule de l\'élève',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.matricule != null 
                                ? Colors.grey.withOpacity(0.3)
                                : AppColors.screenDivider,
                          ),
                        ),
                        child: TextField(
                          controller: matriculeController,
                          enabled: widget.matricule == null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Ex: 2024001',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.screenTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            filled: widget.matricule != null,
                            fillColor: widget.matricule != null 
                                ? Colors.grey.withOpacity(0.1)
                                : null,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.screenTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Montant à payer (FCFA)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.screenSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.screenDivider,
                          ),
                        ),
                        child: TextField(
                          controller: montantController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Ex: 10000',
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: AppColors.screenTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.screenTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
