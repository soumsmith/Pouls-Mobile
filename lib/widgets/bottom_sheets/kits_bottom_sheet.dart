import 'package:flutter/material.dart';
import '../custom_loader.dart';
import 'bottom_sheet_header.dart';
import '../../services/theme_service.dart';
import '../../services/text_size_service.dart';
import '../../services/kits_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';
import '../section_header_widget.dart';
import '../components/bottom_spacer.dart';
import '../../models/niveau.dart';

class KitsBottomSheet extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final List<Niveau> niveaux;
  final DraggableScrollableController? draggableController;
  final ScrollController? scrollController;
  final Color primaryColor;

  const KitsBottomSheet({
    Key? key,
    required this.schoolId,
    required this.schoolName,
    required this.niveaux,
    this.draggableController,
    this.scrollController,
    this.primaryColor = const Color(0xFF8B5CF6), // Violet par défaut
  }) : super(key: key);

  @override
  State<KitsBottomSheet> createState() => _KitsBottomSheetState();
}

class _KitsBottomSheetState extends State<KitsBottomSheet> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  Niveau? _selectedNiveau;
  bool _isLoadingKits = false;
  String? _kitsError;
  List<Map<String, dynamic>> _kits = [];

  @override
  void initState() {
    super.initState();
    if (widget.niveaux.isNotEmpty) {
      _selectedNiveau = widget.niveaux.first;
      _fetchKitsForNiveau(_selectedNiveau!);
    }
  }

  Future<void> _fetchKitsForNiveau(Niveau niveau) async {
    setState(() {
      _selectedNiveau = niveau;
      _isLoadingKits = true;
      _kitsError = null;
      _kits = [];
    });

    try {
      final codeEcole = widget.schoolId;
      final niveauId = niveau.niveau ?? niveau.code ?? '';
      
      final kits = await KitsService.getKitsByNiveau(codeEcole, niveauId);
      
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
          BottomSheetHeader(
            icon: Icons.backpack_rounded,
            iconColor: widget.primaryColor,
            title: 'Kits d\'articles',
            description: 'Consultez les fournitures pour ${widget.schoolName}',
            titleColor: isDarkMode ? Colors.white : Colors.black87,
            descriptionColor: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            onClose: () => Navigator.of(context).pop(),
            iconSize: 22,
            titleFontSize: 18,
            descriptionFontSize: 14,
            titleFontWeight: FontWeight.w700,
            draggableController: widget.draggableController,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNiveauxSelection(),
                  const SizedBox(height: 24),
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

  Widget _buildNiveauxSelection() {
    final isDark = _themeService.isDarkMode;
    
    if (widget.niveaux.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: widget.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun niveau n\'a été configuré pour cette école.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: 'Sélectionnez un niveau',
          isDark: isDark,
          indicatorColor: widget.primaryColor,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.niveaux.map((niveau) {
              final isSelected = _selectedNiveau == niveau;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(niveau.niveau ?? niveau.nom ?? 'Inconnu'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && _selectedNiveau != niveau) {
                      _fetchKitsForNiveau(niveau);
                    }
                  },
                  selectedColor: widget.primaryColor.withOpacity(0.15),
                  backgroundColor: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? widget.primaryColor 
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? widget.primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKitsContent() {
    final isDark = _themeService.isDarkMode;

    if (_selectedNiveau == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Veuillez sélectionner un niveau ci-dessus pour consulter ses kits d\'articles.',
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

    if (_isLoadingKits) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CustomLoader(
            message: 'Chargement des kits...',
            loaderColor: Color(0xFF8B5CF6),
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
              onPressed: () => _fetchKitsForNiveau(_selectedNiveau!),
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
                'Il n\'y a pas encore d\'articles configurés pour le niveau ${_selectedNiveau?.niveau ?? _selectedNiveau?.nom ?? ''}.',
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
          // Extraire dynamiquement les clés possibles du JSON
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

void showKitsBottomSheet(
  BuildContext context, {
  required String schoolId,
  required String schoolName,
  required List<Niveau> niveaux,
  Color primaryColor = const Color(0xFF8B5CF6),
}) {
  showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => KitsBottomSheet(
      schoolId: schoolId,
      schoolName: schoolName,
      niveaux: niveaux,
      draggableController: DraggableScrollableController(),
      primaryColor: primaryColor,
    ),
  );
}
