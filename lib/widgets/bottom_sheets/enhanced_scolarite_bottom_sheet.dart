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
    final sheetHeight = widget.height ?? (MediaQuery.of(context).size.height * 0.8);

    return Container(
      height: sheetHeight,
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

    return Column(
      children: [
        // Carte de statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _themeService.isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconData, color: _primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Résumé de la scolarité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      _formatAmount(totalMontant),
                      _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Payé',
                      _formatAmount(totalPaye),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Restant',
                      _formatAmount(totalRapayer),
                      Colors.red,
                    ),
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
                          color: _themeService.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (overdueCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                      color:
                          (_themeService.isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[300])!
                              .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: paymentPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: paymentPercentage == 100
                              ? Colors.green
                              : _primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste de toutes les échéances
        ...widget.scolariteEntries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScolariteEntryCard(entry),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _themeService.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScolariteEntryCard(StudentScolariteEntry entry) {
    final isDarkMode = _themeService.isDarkMode;
    final isOverdue = entry.isOverdue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : (isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.libelle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.formattedDateLimite,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'En retard',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAmountItem('Total', _formatAmount(entry.montant), Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAmountItem('Payé', _formatAmount(entry.paye), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAmountItem('Restant', _formatAmount(entry.rapayer), 
                    entry.rapayer > 0 ? Colors.red : Colors.grey),
              ),
            ],
          ),
          if (entry.dateLimite.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Échéance: ${entry.formattedDateLimite}',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red : (isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _themeService.isDarkMode
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: EnhancedScolariteBottomSheet(
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
        ),
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
