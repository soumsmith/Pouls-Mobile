import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/access_control.dart';
import '../services/access_control_service.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';

/// Écran de contrôle d'accès spécifique à un élève
class StudentAccessControlScreen extends StatefulWidget {
  final Child child;

  const StudentAccessControlScreen({
    super.key,
    required this.child,
  });

  @override
  State<StudentAccessControlScreen> createState() => _StudentAccessControlScreenState();
}

class _StudentAccessControlScreenState extends State<StudentAccessControlScreen>
    with TickerProviderStateMixin {
  List<AccessControlEntry> _accessEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextSizeService _textSizeService = TextSizeService();
  final AccessControlService _accessService = AccessControlService();
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
    
    _loadAccessControl();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessControl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentMatricule = widget.child.matricule ?? widget.child.id;
      
      print('🔄 Chargement du contrôle d\'accès pour ${widget.child.firstName} (matricule: $studentMatricule)');
      
      final entries = await _accessService.getAccessControlEntriesForStudent(studentMatricule);
      
      setState(() {
        _accessEntries = entries;
        _isLoading = false;
      });
      
      print('✅ Contrôle d\'accès chargé: ${entries.length} pointages');
    } catch (e) {
      print('❌ Erreur lors du chargement du contrôle d\'accès: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAccessControl() async {
    await _loadAccessControl();
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
              backgroundColor: AppColors.backgroundLight,
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
              'Chargement du contrôle d\'accès...',
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
              onPressed: _refreshAccessControl,
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

    if (_accessEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 64,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun pointage',
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun pointage trouvé pour ${widget.child.firstName}',
              style: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: _textSizeService.getScaledFontSize(14),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refreshAccessControl,
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
      onRefresh: _refreshAccessControl,
      color: AppColors.primary,
      child: Column(
        children: [
          // Statistiques
          _buildStatisticsHeader(isDark),
          // Liste des pointages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accessEntries.length,
              itemBuilder: (context, index) {
                final entry = _accessEntries[index];
                return _buildAccessCard(entry, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(bool isDark) {
    final totalEntries = _accessEntries.length;
    final entrees = _accessEntries.where((e) => e.isEntree).length;
    final sorties = _accessEntries.where((e) => e.isSortie).length;
    final statusOk = _accessEntries.where((e) => e.isStatusOk).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques de pointage',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: _textSizeService.getScaledFontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', totalEntries.toString(), AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('Entrées', entrees.toString(), AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('Sorties', sorties.toString(), AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('OK', statusOk.toString(), AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('KO', (totalEntries - statusOk).toString(), AppColors.error),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: _textSizeService.getScaledFontSize(20),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: _textSizeService.getScaledFontSize(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(AccessControlEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isStatusOk 
              ? AppColors.success.withOpacity(0.2)
              : AppColors.error.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec catégorie et statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: entry.isStatusOk 
                        ? AppColors.successSurface
                        : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.categoryIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.formattedCategorie,
                        style: TextStyle(
                          color: AppColors.textPrimaryLight,
                          fontSize: _textSizeService.getScaledFontSize(18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${entry.pointageId}',
                        style: TextStyle(
                          color: AppColors.textTertiaryLight,
                          fontSize: _textSizeService.getScaledFontSize(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.isStatusOk 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: entry.isStatusOk 
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.resultat,
                    style: TextStyle(
                      color: entry.isStatusOk ? AppColors.success : AppColors.error,
                      fontSize: _textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Date et heure avec design amélioré
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.formattedDate,
                    style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.formattedTime,
                    style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontSize: _textSizeService.getScaledFontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.observations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.observations,
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: _textSizeService.getScaledFontSize(13),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
