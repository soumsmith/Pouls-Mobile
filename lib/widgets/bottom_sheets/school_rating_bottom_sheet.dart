import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/ecole.dart';
import '../../services/text_size_service.dart';
import '../../widgets/searchable_dropdown.dart';
import 'rating_bottom_sheet.dart';

/// Bottom sheet de notation avec sélection d'école pour la liste des écoles
class SchoolRatingBottomSheet extends StatefulWidget {
  /// Liste des écoles disponibles
  final List<Ecole> ecoles;

  /// Callback appelé lorsqu'un avis est soumis
  final Function(
    String schoolId,
    String schoolName,
    String rating,
    String comment,
  )?
  onRatingSubmitted;

  const SchoolRatingBottomSheet({
    super.key,
    required this.ecoles,
    this.onRatingSubmitted,
  });

  @override
  State<SchoolRatingBottomSheet> createState() =>
      _SchoolRatingBottomSheetState();

  /// Méthode statique pour afficher le bottom sheet
  static void show(
    BuildContext context, {
    required List<Ecole> ecoles,
    Function(String schoolId, String schoolName, String rating, String comment)?
    onRatingSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SchoolRatingBottomSheet(
        ecoles: ecoles,
        onRatingSubmitted: onRatingSubmitted,
      ),
    );
  }
}

class _SchoolRatingBottomSheetState extends State<SchoolRatingBottomSheet> {
  final TextSizeService _textSizeService = TextSizeService();
  Ecole? _selectedEcole;
  bool _showRatingForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showRatingForm && _selectedEcole != null) {
      // Afficher le bottom sheet de notation normal avec l'école sélectionnée
      return RatingBottomSheet(
        schoolId: _selectedEcole!.id,
        schoolName: _selectedEcole!.ecoleclibelle,
        schoolColor: _getSchoolColor(_selectedEcole!),
        onRatingSubmitted: (rating, comment) {
          Navigator.pop(context);
          widget.onRatingSubmitted?.call(
            _selectedEcole!.id,
            _selectedEcole!.ecoleclibelle,
            rating,
            comment,
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.screenBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
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
                          'Donner un avis',
                          style: TextStyle(
                            fontSize: _textSizeService.getScaledFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Sélectionnez une école',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu de sélection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez l\'école que vous souhaitez noter',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez une école dans la liste ci-dessous pour laisser votre avis et commentaire.',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(14),
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dropdown de sélection d'école
                  _buildSchoolDropdown(),

                  const SizedBox(height: 24),

                  // Bouton de continuation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedEcole != null
                          ? _proceedToRating
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.screenBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continuer vers la notation',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    if (widget.ecoles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.grey600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune école disponible',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  color: AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SearchableDropdown(
      label: 'École',
      value: _selectedEcole?.ecoleclibelle ?? 'Sélectionner une école...',
      items: widget.ecoles.map((e) => e.ecoleclibelle).toList(),
      onChanged: (selected) {
        final ecole = widget.ecoles.firstWhere(
          (e) => e.ecoleclibelle == selected,
        );
        setState(() {
          _selectedEcole = ecole;
        });
      },
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
    );
  }

  void _proceedToRating() {
    if (_selectedEcole != null) {
      setState(() {
        _showRatingForm = true;
      });
    }
  }

  Color _getSchoolColor(Ecole ecole) {
    // Logique de couleur basée sur le type d'école
    switch (ecole.type?.toLowerCase()) {
      case 'primaire':
      case 'maternelle':
        return AppColors.screenGreen;
      case 'collège':
      case 'general':
        return AppColors.screenBlue;
      case 'lycée':
      case 'technique':
        return AppColors.screenPurple;
      default:
        return AppColors.screenOrange;
    }
  }
}
