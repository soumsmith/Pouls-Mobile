import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/child.dart';
import '../../models/ecole.dart';
import '../../config/app_config.dart';
import '../../services/pouls_scolaire_api_service.dart';
import '../../services/text_size_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../screens/inscription_screen.dart' as inscription;

class InscriptionBottomSheet extends StatefulWidget {
  const InscriptionBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InscriptionBottomSheet(),
    );
  }

  @override
  State<InscriptionBottomSheet> createState() => _InscriptionBottomSheetState();
}

class _InscriptionBottomSheetState extends State<InscriptionBottomSheet> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final PoulsScolaireApiService _poulsApiService = PoulsScolaireApiService();

  // État
  List<Ecole> _ecoles = [];
  bool _isLoadingEcoles = false;
  String? _selectedEcoleCode;
  String? _selectedEcoleName;
  String? _selectedParamEcole;
  bool _isLoadingInscription = false;
  final TextEditingController _matriculeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEcoles();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    super.dispose();
  }

  // Chargement des écoles
  Future<void> _loadEcoles() async {
    setState(() => _isLoadingEcoles = true);
    try {
      final ecoles = await _poulsApiService.getAllEcoles();
      if (mounted) setState(() => _ecoles = ecoles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des écoles : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingEcoles = false);
    }
  }

  // Récupérer l'UID de l'élève via l'API
  Future<Map<String, dynamic>?> _getEleveDetails(
    String matricule,
    String paramEcole,
  ) async {
    try {
      final url =
          '${AppConfig.VIE_ECOLES_API_BASE_URL}/vie-ecoles/eleve/detail/$matricule?ecole=$paramEcole';

      print('Recherche détails élève: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Status recherche élève: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Réponse API: ${responseData}');

        // La réponse est dans un objet "data"
        if (responseData is Map && responseData.containsKey('data')) {
          final eleveDetail = responseData['data'] as Map<String, dynamic>;
          print('Élève trouvé: ${eleveDetail['uid']}');
          return eleveDetail;
        }
        // Ancien format (tableau) pour compatibilité
        else if (responseData is List && responseData.isNotEmpty) {
          final eleveDetail = responseData[0] as Map<String, dynamic>;
          print('Élève trouvé: ${eleveDetail['uid']}');
          return eleveDetail;
        }
      }

      print('Aucun élève trouvé pour le matricule: $matricule');
      return null;
    } catch (e) {
      print('Erreur recherche élève: $e');
      return null;
    }
  }

  // Navigation vers l'écran d'inscription
  Future<void> _startInscription() async {
    if (_selectedParamEcole == null ||
        _matriculeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner une école et entrer un matricule',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoadingInscription = true);

    try {
      final matricule = _matriculeController.text.trim();

      // Récupérer les détails de l'élève
      final eleveDetail = await _getEleveDetails(
        matricule,
        _selectedParamEcole!,
      );

      if (eleveDetail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun élève trouvé pour ce matricule dans cette école',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Créer un objet Child avec les informations
      final child = Child(
        id: eleveDetail['id_eleve']?.toString() ?? '',
        firstName: eleveDetail['prenoms'] ?? '',
        lastName: eleveDetail['nom'] ?? '',
        establishment: _selectedEcoleName ?? '',
        grade: eleveDetail['classe'] ?? '',
        parentId:
            eleveDetail['pere']?.toString() ??
            '', // Utiliser le nom du père comme parent_id
        matricule: matricule,
        ecoleCode: _selectedEcoleCode,
        paramEcole: _selectedParamEcole,
      );

      // Naviguer vers l'écran d'inscription
      if (mounted) {
        // Utiliser le root navigator pour naviguer et fermer le bottom sheet
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => inscription.InscriptionWizardScreen(
              child: child,
              uid: eleveDetail['uid']?.toString(),
              eleveDetail: eleveDetail,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingInscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: _kSheetCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nouvelle Inscription',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    18,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : _kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sélectionnez une école et entrez le matricule',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(
                                    13,
                                  ),
                                  color: isDark
                                      ? Colors.white70
                                      : _kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white70 : _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sélection de l'école
                      Text(
                        'École',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? _kDarkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLoadingEcoles
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: _isLoadingEcoles
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isDark
                                                  ? Colors.white
                                                  : _kTextPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Chargement des écoles...',
                                      style: TextStyle(
                                        fontSize: _textSizeService
                                            .getScaledFontSize(14),
                                        color: isDark
                                            ? Colors.white70
                                            : _kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SearchableDropdown(
                                label: 'École',
                                items: _ecoles
                                    .map((e) => e.ecoleclibelle)
                                    .toList(),
                                value: _selectedEcoleName ?? '',
                                onChanged: (value) {
                                  final ecole = _ecoles.firstWhere(
                                    (e) => e.ecoleclibelle == value,
                                    orElse: () => _ecoles.first,
                                  );
                                  setState(() {
                                    _selectedEcoleCode = ecole.ecolecode;
                                    _selectedEcoleName = ecole.ecoleclibelle;
                                    _selectedParamEcole =
                                        ecole.paramecole?.isNotEmpty == true
                                        ? ecole.paramecole
                                        : ecole.ecolecode;
                                  });
                                },
                                isDarkMode: isDark,
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Champ matricule
                      Text(
                        'Matricule de l\'élève',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? _kDarkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _matriculeController,
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(16),
                            color: isDark ? Colors.white : _kTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: 2024001',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white70 : _kTextSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: isDark ? Colors.white70 : _kTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton d'inscription
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoadingInscription
                              ? null
                              : _startInscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoadingInscription
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Inscription en cours...',
                                      style: TextStyle(
                                        fontSize: _textSizeService
                                            .getScaledFontSize(16),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.app_registration,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Commencer l\'inscription',
                                      style: TextStyle(
                                        fontSize: _textSizeService
                                            .getScaledFontSize(16),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Constantes de design
const _kSheetCard = Color(0xFFFFFFFF);
const _kDarkCard = Color(0xFF1E1E2A);
const _kTextPrimary = Color(0xFF1A1A2A);
const _kTextSecondary = Color(0xFF8A8A9E);
