import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../services/text_size_service.dart';
import '../services/school_service.dart';
import '../services/student_detail_service.dart';

/// Écran de détail d'un élève utilisant les informations dynamiques de l'école
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? _bulletinData;
  bool _isLoading = true;
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final SchoolService _schoolService = SchoolService();
  final StudentDetailService _studentService = StudentDetailService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charger les données de l'école d'abord
      await _schoolService.loadSchoolData();
      
      // Charger les données du bulletin
      final String jsonString = await rootBundle.loadString('assets/services/jsonOptimise.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      setState(() {
        _bulletinData = data['bulletin'];
        _isLoading = false;
      });
      
      // Afficher le rapport complet pour le débogage
      _studentService.debugPrintStudentReport(_bulletinData!);
    } catch (e) {
      print('Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDarkMode),
      appBar: AppBar(
        title: Text(
          'Détail de l\'élève',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(18),
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.getSurfaceColor(isDarkMode),
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.getTextColor(isDarkMode),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    if (_bulletinData == null) {
      return Center(
        child: Text(
          'Erreur lors du chargement des données',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(16),
            color: AppColors.getTextColor(_themeService.isDarkMode),
          ),
        ),
      );
    }

    final report = _studentService.generateStudentReport(_bulletinData!);
    final isDarkMode = _themeService.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations de l'école
          _buildSchoolHeader(isDarkMode),
          const SizedBox(height: 20),
          
          // Informations de l'élève
          _buildStudentInfo(isDarkMode),
          const SizedBox(height: 20),
          
          // Statistiques générales
          _buildStatistics(report['statistics'], isDarkMode),
          const SizedBox(height: 20),
          
          // Liste des matières
          _buildSubjectsList(report['subjects'], isDarkMode),
          const SizedBox(height: 20),
          
          // Actions
          _buildActions(report, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSchoolHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _schoolService.schoolName ?? 'École non définie',
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                'Code: ${_schoolService.schoolCode ?? 'N/A'}',
                isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Tel: ${_schoolService.schoolPhone ?? 'N/A'}',
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(bool isDarkMode) {
    final eleve = _bulletinData!['eleve'];
    final classe = _bulletinData!['classe'];
    final annee = _bulletinData!['annee'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de l\'élève',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  (eleve['prenom'] as String? ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: _textSizeService.getScaledFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${eleve['prenom']} ${eleve['nom']}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    Text(
                      'Matricule: ${eleve['matricule'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Classe: ${classe['libelle'] ?? 'N/A'}', isDarkMode),
              const SizedBox(width: 8),
              _buildInfoChip('Effectif: ${classe['effectif'] ?? 'N/A'}', isDarkMode),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoChip('Année: ${annee['libelle'] ?? 'N/A'}', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getTextColor(isDarkMode).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _textSizeService.getScaledFontSize(12),
          color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> statistics, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques générales',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Matières',
                  statistics['totalSubjects'].toString(),
                  Icons.book,
                  AppColors.info,
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Évaluations',
                  statistics['totalEvaluations'].toString(),
                  Icons.assignment,
                  AppColors.warning,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Moyenne',
                  statistics['generalAverage'],
                  Icons.trending_up,
                  AppColors.primary,
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rang',
                  statistics['ranking'].toString(),
                  Icons.emoji_events,
                  AppColors.success,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Appréciation: ${statistics['appreciation']}',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(List<dynamic> subjects, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matières',
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          ...subjects.map((subject) => _buildSubjectItem(subject, isDarkMode)).toList(),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getTextColor(isDarkMode).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['name'],
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                Text(
                  subject['category'],
                  style: TextStyle(
                    fontSize: _textSizeService.getScaledFontSize(12),
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subject['average'].toStringAsFixed(1),
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(subject['average']),
                ),
              ),
              Text(
                '${subject['evaluations']} eval.',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(10),
                  color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> report, bool isDarkMode) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportToCSV(report),
            icon: const Icon(Icons.download, size: 16),
            label: Text(
              'Exporter en CSV',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _printBulletin(report),
            icon: const Icon(Icons.print, size: 16),
            label: Text(
              'Imprimer le bulletin',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 14) return AppColors.primary;
    if (grade >= 12) return AppColors.warning;
    return AppColors.error;
  }

  void _exportToCSV(Map<String, dynamic> report) {
    final csvData = _studentService.exportToCSV(_bulletinData!);
    // TODO: Implémenter le partage/telechargement du fichier CSV
    print('CSV Export:\n$csvData');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export CSV (voir console)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _printBulletin(Map<String, dynamic> report) {
    final bulletinHeader = _studentService.generateBulletinHeader(_bulletinData!);
    final bulletinFooter = _studentService.generateBulletinFooter();
    
    print('BULLETIN À IMPRIMER:\n$bulletinHeader\n\n[CONTENU DU BULLETIN]\n\n$bulletinFooter');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bulletin prêt pour impression (voir console)'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
