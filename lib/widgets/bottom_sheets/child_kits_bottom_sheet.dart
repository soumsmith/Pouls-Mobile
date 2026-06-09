import 'package:flutter/material.dart';
import '../custom_loader.dart';
import 'bottom_sheet_header.dart';
import '../../services/theme_service.dart';
import '../../services/kits_service.dart';
import '../../config/app_dimensions.dart';
import '../section_header_widget.dart';
import '../components/bottom_spacer.dart';

class ChildKitsBottomSheet extends StatefulWidget {
  final String schoolId;
  final String niveau;
  final String childName;
  final Color primaryColor;

  const ChildKitsBottomSheet({
    Key? key,
    required this.schoolId,
    required this.niveau,
    required this.childName,
    this.primaryColor = const Color(0xFF673AB7),
  }) : super(key: key);

  @override
  State<ChildKitsBottomSheet> createState() => _ChildKitsBottomSheetState();
}

class _ChildKitsBottomSheetState extends State<ChildKitsBottomSheet> {
  final ThemeService _themeService = ThemeService();

  bool _isLoadingKits = true;
  String? _kitsError;
  List<Map<String, dynamic>> _kits = [];

  @override
  void initState() {
    super.initState();
    _fetchKits();
  }

  Future<void> _fetchKits() async {
    setState(() {
      _isLoadingKits = true;
      _kitsError = null;
    });

    try {
      final kits = await KitsService.getKitsByNiveau(widget.schoolId, widget.niveau);
      if (mounted) {
        setState(() {
          _kits = kits;
          _isLoadingKits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kitsError = e.toString().replaceAll('Exception: ', '');
          _isLoadingKits = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHeader(
            icon: Icons.backpack_rounded,
            iconColor: widget.primaryColor,
            title: 'Kits Scolaires',
            description: 'Kits pour ${widget.childName} (${widget.niveau})',
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKitsContent(),
                  const BottomSpacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitsContent() {
    final isDark = _themeService.isDarkMode;

    if (_isLoadingKits) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CustomLoader(
            message: 'Chargement des kits...',
            loaderColor: Color(0xFF673AB7),
            showBackground: false,
          ),
        ),
      );
    }

    if (_kitsError != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
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
              _kitsError!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchKits,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
              ),
            )
          ],
        ),
      );
    }

    if (_kits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun kit disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Il n\'y a pas encore d\'articles configurés pour la classe de ${widget.niveau}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Affichage de la liste des kits
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: 'Articles du kit',
          isDark: isDark,
          indicatorColor: widget.primaryColor,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        ..._kits.map((kit) {
          final nom = kit['nom_article'] ?? kit['nom'] ?? kit['titre'] ?? kit['article'] ?? kit['libelle'] ?? 'Article inconnu';
          final quantite = kit['quantite'] ?? kit['qte'] ?? kit['quantity'] ?? '1';
          final description = kit['description'] ?? kit['details'];
          final prix = kit['prix'] ?? kit['montant'] ?? kit['price'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.transparent : Colors.grey[200]!,
              ),
              boxShadow: AppDimensions.getSettingsCardShadow(context),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_rounded,
                    color: widget.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Qté: $quantite',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (prix != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$prix XOF',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.primaryColor,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

void showChildKitsBottomSheet(
  BuildContext context, {
  required String schoolId,
  required String niveau,
  required String childName,
  Color primaryColor = const Color(0xFF673AB7),
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 40,
      ),
      child: ChildKitsBottomSheet(
        schoolId: schoolId,
        niveau: niveau,
        childName: childName,
        primaryColor: primaryColor,
      ),
    ),
  );
}
