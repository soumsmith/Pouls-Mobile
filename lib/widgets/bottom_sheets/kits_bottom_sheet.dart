import 'package:flutter/material.dart';
import '../custom_loader.dart';
import '../../services/theme_service.dart';
import '../../services/text_size_service.dart';
import '../../services/kits_service.dart';
import '../../services/niveau_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_dimensions.dart';
import '../section_header_widget.dart';
import '../components/bottom_spacer.dart';
import '../components/custom_error_state.dart';
import '../../models/niveau.dart';
import 'reusable_bottom_sheet.dart';

class KitsBottomSheet extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final List<Niveau> niveaux;
  final Color primaryColor;

  const KitsBottomSheet({
    Key? key,
    required this.schoolId,
    required this.schoolName,
    required this.niveaux,
    this.primaryColor = const Color(0xFF8B5CF6), // Violet par défaut
  }) : super(key: key);

  @override
  State<KitsBottomSheet> createState() => _KitsBottomSheetState();
}

class _KitsBottomSheetState extends State<KitsBottomSheet> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  List<Niveau> _niveaux = [];
  bool _isLoadingNiveaux = false;
  String? _niveauxError;

  Niveau? _selectedNiveau;
  bool _isLoadingKits = false;
  String? _kitsError;
  List<Map<String, dynamic>> _kits = [];

  @override
  void initState() {
    super.initState();
    if (widget.niveaux.isNotEmpty) {
      _niveaux = widget.niveaux;
      _selectedNiveau = widget.niveaux.first;
      _fetchKitsForNiveau(_selectedNiveau!);
    } else {
      _fetchNiveaux();
    }
  }

  Future<void> _fetchNiveaux() async {
    setState(() {
      _isLoadingNiveaux = true;
      _niveauxError = null;
    });

    try {
      final niveaux = await NiveauService.getNiveauxByEcole(widget.schoolId);
      if (mounted) {
        setState(() {
          _niveaux = niveaux;
          _isLoadingNiveaux = false;
          if (_niveaux.isNotEmpty) {
            _selectedNiveau = _niveaux.first;
            _fetchKitsForNiveau(_selectedNiveau!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMessage = e.toString();
          if (errorMessage.contains('SocketException') || 
              errorMessage.contains('ClientException') || 
              errorMessage.contains('Failed host lookup') ||
              errorMessage.contains('Network is unreachable') ||
              errorMessage.contains('Connection refused')) {
            _niveauxError = "Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.";
          } else {
            _niveauxError = "Une erreur est survenue lors de la récupération des niveaux.";
          }
          _isLoadingNiveaux = false;
        });
      }
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
      final niveauId = niveau.code ?? niveau.niveau ?? '';
      
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
          String errorMessage = e.toString();
          if (errorMessage.contains('SocketException') || 
              errorMessage.contains('ClientException') || 
              errorMessage.contains('Failed host lookup') ||
              errorMessage.contains('Network is unreachable') ||
              errorMessage.contains('Connection refused')) {
            _kitsError = "Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.";
          } else {
            _kitsError = "Une erreur est survenue lors de la récupération des kits scolaires. Veuillez réessayer.";
          }
          _isLoadingKits = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingNiveaux) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CustomLoader(
            message: 'Chargement des niveaux...',
            loaderColor: Color(0xFF8B5CF6),
            size: 56.0,
            showBackground: false,
          ),
        ),
      );
    }

    if (_niveauxError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CustomErrorState(
          message: _niveauxError!,
          onRetry: _fetchNiveaux,
          iconColor: widget.primaryColor,
          buttonColor: widget.primaryColor,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNiveauxSelection(),
        const SizedBox(height: 24),
        if (_niveaux.isNotEmpty) _buildKitsContent(),
      ],
    );
  }

  Widget _buildNiveauxSelection() {
    final isDark = _themeService.isDarkMode;
    
    if (_niveaux.isEmpty) {
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
            children: _niveaux.map((niveau) {
              final isSelected = _selectedNiveau == niveau;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(niveau.nom ?? niveau.niveau ?? 'Inconnu'),
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
      return CustomErrorState(
        title: 'Erreur de chargement',
        message: _kitsError!,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red[400],
        buttonColor: Colors.red[50],
        buttonIsLight: true,
        buttonHasBorder: true,
        retryText: 'Réessayer',
        onRetry: () => _fetchKitsForNiveau(_selectedNiveau!),
      );
    }

    if (_kits.isEmpty) {
      return CustomErrorState(
        title: 'Aucun kit disponible',
        message: 'Il n\'y a pas encore d\'articles configurés pour le niveau ${_selectedNiveau?.nom ?? _selectedNiveau?.niveau ?? ''}.',
        icon: Icons.inventory_2_outlined,
        iconColor: widget.primaryColor,
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
  ReusableBottomSheet.show(
    context: context,
    title: 'Kits d\'articles',
    subtitle: 'Consultez les fournitures pour $schoolName',
    icon: Icons.backpack_rounded,
    iconColor: primaryColor,
    initialChildSize: 0.6,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    contentPadding: const EdgeInsets.all(20),
    content: KitsBottomSheet(
      schoolId: schoolId,
      schoolName: schoolName,
      niveaux: niveaux,
      primaryColor: primaryColor,
    ),
  );
}
