import 'package:flutter/material.dart';
import '../custom_loader.dart';
import 'bottom_sheet_header.dart';
import '../../models/student_scolarite.dart';
import '../../services/theme_service.dart';
import '../../services/text_size_service.dart';
import '../../config/app_colors.dart';

/// Bottom sheet réutilisable et amélioré pour afficher la scolarité d'un élève
/// Fusionne le design de _showFeesBottomSheet avec les fonctionnalités de ScolariteBottomSheet
class EnhancedScolariteBottomSheet extends StatefulWidget {
  final String childName;
  final String? childMatricule;
  final List<StudentScolariteEntry> scolariteEntries;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final VoidCallback? onClose;
  final String? title;
  final String? description;
  final DraggableScrollableController? draggableController;
  final ScrollController? scrollController;
  
  // Paramètres de personnalisation du design
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData? iconData;
  final double? height;

  const EnhancedScolariteBottomSheet({
    Key? key,
    required this.childName,
    this.childMatricule,
    required this.scolariteEntries,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onClose,
    this.title,
    this.description,
    this.draggableController,
    this.scrollController,
    this.primaryColor,
    this.backgroundColor,
    this.iconColor,
    this.iconData,
    this.height,
  }) : super(key: key);

  @override
  State<EnhancedScolariteBottomSheet> createState() => _EnhancedScolariteBottomSheetState();
}

class _EnhancedScolariteBottomSheetState extends State<EnhancedScolariteBottomSheet> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  // Couleurs par défaut pour les frais scolaires
  Color get _primaryColor => widget.primaryColor ?? const Color(0xFF10B981);
  Color get _iconColor => widget.iconColor ?? const Color(0xFF065F46);
  IconData get _iconData => widget.iconData ?? Icons.payments_rounded;
  String get _defaultTitle => widget.title ?? 'Frais scolaires';
  String get _defaultDescription => widget.description ?? 'Consultez les frais de scolarité et paiements';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInlineHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineHeader() {
    final isDarkMode = _themeService.isDarkMode;
    
    return BottomSheetHeader(
      icon: _iconData,
      iconColor: _primaryColor,
      title: _defaultTitle,
      description: _defaultDescription,
      titleColor: isDarkMode ? Colors.white : Colors.black87,
      descriptionColor: isDarkMode ? Colors.grey[300] : Colors.grey[600],
      onClose: widget.onClose ?? () => Navigator.of(context).pop(),
      iconSize: 22,
      titleFontSize: 18,
      descriptionFontSize: 14,
      titleFontWeight: FontWeight.w700,
      draggableController: widget.draggableController,
      //padding: const EdgeInsets.all(20),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CustomLoader(
            message: 'Chargement des frais scolaires...',
            loaderColor: AppColors.screenOrange,
            showBackground: false,
          ),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: _themeService.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.scolariteEntries.isEmpty) {
      // Vérifier si le matricule est disponible
      if (widget.childMatricule == null || widget.childMatricule!.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Matricule non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le matricule de l\'enfant n\'est pas configuré. Veuillez contacter l\'administration.',
                style: TextStyle(
                  fontSize: 14,
                  color: _themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        height: widget.height != null 
            ? widget.height! * 0.6 
            : MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconData, size: 48, color: _primaryColor),
              const SizedBox(height: 12),
              Text(
                'Aucune échéance disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: _themeService.isDarkMode
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.onRefresh != null)
                ElevatedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return _buildScolariteContent();
  }

  Widget _buildScolariteContent() {
    // Statistiques
    final totalMontant = widget.scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.montant,
    );
    final totalPaye = widget.scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.paye,
    );
    final totalRapayer = widget.scolariteEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.rapayer,
    );
    final paymentPercentage = totalMontant > 0
        ? (totalPaye / totalMontant) * 100
        : 0.0;
    final overdueCount = widget.scolariteEntries.where((e) => e.isOverdue).length;
    final isDarkMode = _themeService.isDarkMode;

    // Custom feedback based on progression
    String progressText;
    IconData progressIcon;
    Color progressColor;
    if (paymentPercentage >= 100) {
      progressText = 'Félicitations ! Scolarité entièrement réglée. 🎉';
      progressIcon = Icons.stars_rounded;
      progressColor = Colors.green;
    } else if (overdueCount > 0) {
      progressText = 'Attention : Vous avez des paiements en retard.';
      progressIcon = Icons.warning_amber_rounded;
      progressColor = Colors.red;
    } else if (paymentPercentage > 50) {
      progressText = 'En bonne voie ! Plus de la moitié a été payée. 👍';
      progressIcon = Icons.thumb_up_rounded;
      progressColor = _primaryColor;
    } else {
      progressText = 'Échéances en cours de règlement.';
      progressIcon = Icons.hourglass_top_rounded;
      progressColor = Colors.amber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte de statistiques premium
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF2A2A3A)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et header de carte
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.iconData ?? Icons.payments_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résumé de la scolarité',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Élève : ${widget.childName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (paymentPercentage >= 100)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Soldée',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              
              // Capsule grid of values
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _formatAmount(totalMontant),
                      _primaryColor,
                      Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatItem(
                      'Payé',
                      _formatAmount(totalPaye),
                      Colors.green,
                      Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatItem(
                      'Restant',
                      _formatAmount(totalRapayer),
                      totalRapayer > 0 ? Colors.red : Colors.grey,
                      Icons.pending_actions_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Progression Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(progressIcon, color: progressColor, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                progressText,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[300] : const Color(0xFF475569),
                                  fontSize: _textSizeService.getScaledFontSize(11),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${paymentPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: _textSizeService.getScaledFontSize(12),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Track
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2D2D3D)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: paymentPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.8),
                              paymentPercentage == 100 ? Colors.green : _primaryColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Titre liste des échéances
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Détail des échéances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155),
              letterSpacing: -0.3,
            ),
          ),
        ),
        
        // Liste des échéances
        ...widget.scolariteEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildScolariteEntryCard(entry),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    final isDarkMode = _themeService.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScolariteEntryCard(StudentScolariteEntry entry) {
    final isDarkMode = _themeService.isDarkMode;
    final isOverdue = entry.isOverdue;
    final hasRemaining = entry.rapayer > 0;
    
    // Status color & labeling
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (!hasRemaining) {
      statusColor = Colors.green;
      statusText = 'Soldé';
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'En retard';
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = Colors.amber[700]!;
      statusText = 'À payer';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2A2A3A) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status vertical colored strip
              Container(
                width: 6,
                color: statusColor,
              ),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.libelle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Premium Status badge chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Single beautiful date indicator
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Échéance : ${entry.formattedDateLimite}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverdue 
                                  ? Colors.red 
                                  : (isDarkMode ? Colors.grey[400] : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Thin custom divider line
                      Container(
                        height: 1,
                        color: isDarkMode ? const Color(0xFF2A2A3A) : const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(height: 12),
                      
                      // Amounts row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmountItem(
                              'Montant Total',
                              _formatAmount(entry.montant),
                              isDarkMode ? Colors.grey[300]! : const Color(0xFF475569),
                              Icons.receipt_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildAmountItem(
                              'Déjà Payé',
                              _formatAmount(entry.paye),
                              Colors.green,
                              Icons.check_circle_outline_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildAmountItem(
                              'Reste à Payer',
                              _formatAmount(entry.rapayer),
                              entry.rapayer > 0 ? Colors.red : Colors.grey,
                              Icons.hourglass_bottom_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountItem(String label, String value, Color color, IconData icon) {
    final isDarkMode = _themeService.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 11,
              color: isDarkMode ? Colors.grey[500] : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString()}F';
  }
}

/// Fonction utilitaire pour afficher le bottom sheet de scolarité amélioré
void showEnhancedScolariteBottomSheet(
  BuildContext context, {
  required String childName,
  String? childMatricule,
  required List<StudentScolariteEntry> scolariteEntries,
  bool isLoading = false,
  String? errorMessage,
  VoidCallback? onRefresh,
  VoidCallback? onClose,
  String? title,
  String? description,
  Color? primaryColor,
  Color? backgroundColor,
  Color? iconColor,
  IconData? iconData,
  double? height,
}) {
  final draggableController = DraggableScrollableController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      controller: draggableController,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => EnhancedScolariteBottomSheet(
        childName: childName,
        childMatricule: childMatricule,
        scolariteEntries: scolariteEntries,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRefresh: onRefresh,
        onClose: onClose,
        title: title,
        description: description,
        primaryColor: primaryColor,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        iconData: iconData,
        height: height,
        draggableController: draggableController,
        scrollController: controller,
      ),
    ),
  );
}

/// Fonction utilitaire simplifiée pour les frais scolaires (fusion avec _showFeesBottomSheet)
void showFeesBottomSheet(
  BuildContext context, {
  required String childName,
  String? childMatricule,
  required List<StudentScolariteEntry> scolariteEntries,
  bool isLoading = false,
  String? errorMessage,
  VoidCallback? onRefresh,
  VoidCallback? onClose,
}) {
  showEnhancedScolariteBottomSheet(
    context,
    childName: childName,
    childMatricule: childMatricule,
    scolariteEntries: scolariteEntries,
    isLoading: isLoading,
    errorMessage: errorMessage,
    onRefresh: onRefresh,
    onClose: onClose,
    title: 'Frais scolaires',
    description: 'Consultez les frais de scolarité et paiements',
    primaryColor: const Color(0xFF10B981),
    backgroundColor: const Color(0xFFECFDF5),
    iconColor: const Color(0xFF065F46),
    iconData: Icons.payments_rounded,
    height: MediaQuery.of(context).size.height * 0.8,
  );
}
