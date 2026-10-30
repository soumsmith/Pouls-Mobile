import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/code_dren_ecole.dart';
import 'bottom_sheets/bottom_sheet_header.dart';

/// Ouvre un bottom sheet pour choisir une école parmi plusieurs résultats
/// renvoyés pour un même code DREN (un code peut être partagé par plusieurs
/// établissements distincts, ex. deux écoles d'un même groupe scolaire).
/// Retourne `null` si l'utilisateur ferme le sheet sans rien choisir.
Future<CodeDrenEcole?> pickCodeDrenEcole(
  BuildContext context,
  List<CodeDrenEcole> ecoles,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<CodeDrenEcole>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetHeader(
              icon: Icons.school_outlined,
              iconColor: AppColors.screenOrange,
              title: 'Plusieurs écoles trouvées',
              description:
                  'Ce code DREN correspond à ${ecoles.length} établissements. '
                  'Sélectionnez le vôtre.',
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: ecoles.length,
                itemBuilder: (context, index) {
                  final ecole = ecoles[index];
                  final localisation = [ecole.ville, ecole.adresse]
                      .where((v) => v != null && v.isNotEmpty)
                      .join(', ');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.screenOrange.withValues(alpha: 0.12),
                      child: const Icon(Icons.school_outlined, color: AppColors.screenOrange),
                    ),
                    title: Text(
                      ecole.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: localisation.isNotEmpty ? Text(localisation) : null,
                    onTap: () => Navigator.of(sheetContext).pop(ecole),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
