import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/ecole.dart';
import '../../services/text_size_service.dart';
import '../../widgets/searchable_dropdown.dart';
import 'rating_bottom_sheet.dart';
import 'reusable_bottom_sheet.dart';

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
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SchoolRatingBottomSheet(
          ecoles: ecoles,
          onRatingSubmitted: onRatingSubmitted,
        ),
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

    return ReusableBottomSheet(
      title: 'Donner un avis',
      subtitle: 'Sélectionnez une école',
      icon: Icons.school,
      iconColor: AppColors.screenBlue,
      contentPadding: const EdgeInsets.all(0),
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez l\'école que vous souhaitez noter',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez une école dans la liste ci-dessous pour laisser votre avis et commentaire.',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppColors.screenTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Dropdown de sélection d'école
            _buildSchoolDropdown(),

            const SizedBox(height: 32),

            // Bouton de continuation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedEcole != null ? _proceedToRating : null,
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
