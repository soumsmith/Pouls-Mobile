import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/student_scolarite.dart';
import '../services/student_scolarite_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';

/// Écran de scolarité spécifique à un élève
class StudentScolariteScreen extends StatefulWidget {
  final Child child;

  const StudentScolariteScreen({
    super.key,
    required this.child,
  });

  @override
  State<StudentScolariteScreen> createState() => _StudentScolariteScreenState();
}

class _StudentScolariteScreenState extends State<StudentScolariteScreen>
    with TickerProviderStateMixin {
  List<StudentScolariteEntry> _scolariteEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextSizeService _textSizeService = TextSizeService();
  final StudentScolariteService _scolariteService = StudentScolariteService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadScolarite();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadScolarite() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentMatricule = widget.child.matricule ?? widget.child.id;
      
      print('🔄 Chargement de la scolarité pour ${widget.child.firstName} (matricule: $studentMatricule)');
      
      final entries = await _scolariteService.getScolariteEntriesForStudent(studentMatricule);
      
      setState(() {
        _scolariteEntries = entries;
        _isLoading = false;
      });
      
      print('✅ Scolarité chargée: ${entries.length} échéances');
    } catch (e) {
      print('❌ Erreur lors du chargement de la scolarité: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshScolarite() async {
    await _loadScolarite();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              backgroundColor: AppColors.getSurfaceColor(isDark),
              body: _buildBody(isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement de la scolarité...',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(16),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refreshScolarite,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: AppColors.getTextColor(isDark),
              ),
              label: Text(
                'Réessayer',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    if (_scolariteEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune échéance',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune échéance de scolarité trouvée pour ${widget.child.firstName}',
              style: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refreshScolarite,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: AppColors.getTextColor(isDark),
              ),
              label: Text(
                'Actualiser',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: _textSizeService.getScaledFontSize(14),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshScolarite,
      color: AppColors.primary,
      child: Column(
        children: [
          // Statistiques
          _buildStatisticsHeader(isDark),
          // Liste des échéances
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scolariteEntries.length,
              itemBuilder: (context, index) {
                final entry = _scolariteEntries[index];
                return _buildScolariteCard(entry, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(bool isDark) {
    final totalMontant = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.montant);
    final totalPaye = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.paye);
    final totalRapayer = _scolariteEntries.fold<int>(0, (sum, entry) => sum + entry.rapayer);
    final paymentPercentage = totalMontant > 0 ? (totalPaye / totalMontant) * 100 : 0.0;
    final overdueCount = _scolariteEntries.where((e) => e.isOverdue).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de la scolarité',
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', _formatAmount(totalMontant), isDark),
              ),
              Expanded(
                child: _buildStatItem('Payé', _formatAmount(totalPaye), isDark, Colors.green),
              ),
              Expanded(
                child: _buildStatItem('Restant', _formatAmount(totalRapayer), isDark, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Progression: ${paymentPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (overdueCount > 0) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$overdueCount retard(s)',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: _textSizeService.getScaledFontSize(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.getBorderColor(isDark).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: paymentPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: paymentPercentage == 100 ? Colors.green : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark, [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? AppColors.getBorderColor(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.getTextColor(isDark),
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              fontSize: _textSizeService.getScaledFontSize(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScolariteCard(StudentScolariteEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.statusColor == 'green' 
              ? Colors.green.withOpacity(0.3)
              : entry.statusColor == 'orange'
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEntryDetails(entry, isDark),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec libellé et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.libelle,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDark),
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.statusColor == 'green' 
                            ? Colors.green.withOpacity(0.1)
                            : entry.statusColor == 'orange'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.formattedStatus,
                        style: TextStyle(
                          color: entry.statusColor == 'green' 
                              ? Colors.green
                              : entry.statusColor == 'orange'
                                  ? Colors.orange
                                  : Colors.red,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Montants
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Montant: ${entry.formattedMontant}',
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark),
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Payé: ${entry.formattedPaye}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      entry.rapayer > 0 ? Icons.warning : Icons.check_circle,
                      size: 16,
                      color: entry.rapayer > 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Restant: ${entry.formattedRapayer}',
                      style: TextStyle(
                        color: entry.rapayer > 0 ? Colors.red : Colors.green,
                        fontSize: _textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date limite et rubrique
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Date limite: ${entry.formattedDateLimite}',
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        fontSize: _textSizeService.getScaledFontSize(14),
                      ),
                    ),
                    if (entry.isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EN RETARD',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: _textSizeService.getScaledFontSize(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.remise > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remise: ${_formatAmount(entry.remise)}',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: _textSizeService.getScaledFontSize(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(StudentScolariteEntry entry, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(isDark),
        title: Text(
          entry.libelle,
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Rubrique', entry.formattedRubrique, isDark),
              _buildDetailRow('Montant initial', _formatAmount(entry.montant0), isDark),
              if (entry.remise > 0)
                _buildDetailRow('Remise', _formatAmount(entry.remise), isDark),
              _buildDetailRow('Montant final', _formatAmount(entry.montant), isDark),
              _buildDetailRow('Montant payé', _formatAmount(entry.paye), isDark),
              _buildDetailRow('Restant à payer', _formatAmount(entry.rapayer), isDark),
              _buildDetailRow('Date limite', entry.formattedDateLimite, isDark),
              _buildDetailRow('Statut', entry.formattedStatus, isDark),
              _buildDetailRow('Date d\'enregistrement', entry.formattedDateenreg, isDark),
              _buildDetailRow('ID Échéance', entry.epaId.toString(), isDark),
              if (entry.isOverdue)
                _buildDetailRow('Retard', 'Oui - ${entry.daysUntilDeadline.abs()} jours', isDark, Colors.red),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.getTextColor(isDark),
              fontSize: _textSizeService.getScaledFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }
}
