import 'package:flutter/material.dart';
import '../custom_loader.dart';
import 'bottom_sheet_header.dart';
import '../../services/theme_service.dart';
import '../../services/kits_service.dart';
import '../../config/app_dimensions.dart';
import '../section_header_widget.dart';
import '../components/bottom_spacer.dart';
import '../components/custom_error_state.dart';
import 'reusable_bottom_sheet.dart';

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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKitsContent(),
          const BottomSpacer(),
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
      return CustomErrorState(
        title: 'Erreur de chargement',
        message: _kitsError!,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red[400],
        buttonColor: Colors.red[50],
        buttonIsLight: true,
        buttonHasBorder: true,
        retryText: 'Réessayer',
        onRetry: _fetchKits,
      );
    }

    if (_kits.isEmpty) {
      return CustomErrorState(
        title: 'Aucun kit disponible',
        message: 'Il n\'y a pas encore d\'articles configurés pour la classe de ${widget.niveau}.',
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
  ReusableBottomSheet.show(
    context: context,
    title: 'Kits Scolaires',
    subtitle: 'Kits pour $childName ($niveau)',
    icon: Icons.backpack_rounded,
    iconColor: primaryColor,
    initialChildSize: 0.8,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    contentPadding: EdgeInsets.zero,
    content: ChildKitsBottomSheet(
      schoolId: schoolId,
      niveau: niveau,
      childName: childName,
      primaryColor: primaryColor,
    ),
  );
}
