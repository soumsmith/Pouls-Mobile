import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_card.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';

/// Écran d'affichage des frais de scolarité
class FeesScreen extends StatefulWidget {
  final String childId;

  const FeesScreen({
    super.key,
    required this.childId,
  });

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  List<Fee> _fees = [];
  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;
      final fees = await apiService.getFeesForChild(widget.childId);
      
      setState(() {
        _fees = fees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fees.isEmpty) {
      return _buildEmptyState();
    }

    // Trier les frais par date
    final sortedFees = List<Fee>.from(_fees)
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.getPureBackground(true),
                  AppColors.primary.withOpacity(0.05),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: sortedFees.length,
        itemBuilder: (context, index) {
          final fee = sortedFees[index];
          final isLast = index == sortedFees.length - 1;
          
          return _buildTimelineItem(fee, isLast);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun frais enregistré',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les frais de scolarité apparaîtront ici',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(14),
              color: AppColors.getTextColor(isDark, type: TextType.secondary).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Fee fee, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Ligne de timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Point de timeline
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: fee.isPaid ? const Color(0xFF48BB78) : const Color(0xFFED8936),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fee.isPaid ? const Color(0xFF9AE6B4) : const Color(0xFFFBD38D),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: fee.isPaid ? const Color(0xFF48BB78) : const Color(0xFFED8936),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Ligne verticale
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Contenu de la carte
          Expanded(
            child: _buildFeeTimelineCard(fee),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeTimelineCard(Fee fee) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut et type
            Row(
              children: [
                Expanded(
                  child: Text(
                    fee.type,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextColor(isDark, type: TextType.primary),
                    ),
                  ),
                ),
                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: fee.isPaid 
                        ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E8))
                        : (isDark ? const Color(0xFFE65100) : const Color(0xFFFFF3E0)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fee.isPaid 
                          ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784))
                          : (isDark ? const Color(0xFFFF9800) : const Color(0xFFFFB74D)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        fee.isPaid ? Icons.check_circle_outline : Icons.schedule_outlined,
                        size: 14,
                        color: fee.isPaid 
                            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                            : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fee.isPaid ? 'Payé' : 'En attente',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(11),
                          fontWeight: FontWeight.w600,
                          color: fee.isPaid 
                              ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                              : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Montant
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${fee.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(20),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Informations de date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: isDark ? const Color(0xFFA0AEC0) : const Color(0xFF4A5568),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Échéance: ${_formatDate(fee.dueDate)}',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(13),
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (fee.isPaid && fee.paidDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: const Color(0xFF48BB78),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payé le: ${_formatDate(fee.paidDate!)}',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(13),
                            color: const Color(0xFF48BB78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Informations supplémentaires si payé
            if (fee.isPaid) ...[
              const SizedBox(height: 12),
              if (fee.paymentMethod != null || fee.reference != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A202C) : const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF48BB78),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (fee.paymentMethod != null)
                        Row(
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Méthode: ${fee.paymentMethod}',
                              style: TextStyle(
                                fontSize: _textSizeService.getScaledFontSize(12),
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (fee.reference != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Référence: ${fee.reference}',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(12),
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

