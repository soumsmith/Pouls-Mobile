import 'package:flutter/material.dart';
import '../../models/classe_consultation.dart';
import '../../models/ecole_avec_classes.dart';
import '../components/bottom_spacer.dart';
import 'reusable_bottom_sheet.dart';

/// Couple (établissement, classe) choisi via [ClasseChoiceBottomSheet.showEcoleClasses].
class EcoleClasseChoice {
  final EcoleAvecClasses option;
  final ClasseConsultation classe;

  const EcoleClasseChoice({required this.option, required this.classe});
}

/// Sélecteur de classe (et, le cas échéant, d'établissement), partagé par
/// tous les écrans qui en ont besoin (détail de l'enfant — résolution
/// automatique et bouton "changer" — et écran "Mes Notes") pour garantir
/// exactement le même comportement partout : un élève peut avoir deux
/// classes dans la même école (cursus franco-arabe, doc
/// API-CONSULTATION-MOBILE §4.6 bis) ou être inscrit dans deux écoles
/// différentes, chacune pouvant elle-même avoir deux classes (§4). On ne
/// choisit jamais "la première" au hasard — ce n'est pas une erreur, c'est un
/// choix à faire.
class ClasseChoiceBottomSheet {
  ClasseChoiceBottomSheet._();

  /// Cas simple : un seul établissement (déjà connu de l'appelant), plusieurs
  /// classes possibles. Retourne la `ClasseConsultation` choisie, ou `null`
  /// si l'utilisateur ferme le bottom sheet sans choisir.
  static Future<ClasseConsultation?> showClasses(
    BuildContext context, {
    required List<ClasseConsultation> classes,
    String? childFirstName,
  }) async {
    if (classes.isEmpty) return null;
    final row = await _show<ClasseConsultation>(
      context,
      showEcoleName: false,
      childFirstName: childFirstName,
      rows: classes
          .map((c) => _Row(classe: c, ecoleNom: null, value: c))
          .toList(),
    );
    return row;
  }

  /// Cas combiné : plusieurs établissements possibles (un enfant peut être
  /// réellement inscrit dans deux écoles, doc §4), chacun avec une ou
  /// plusieurs classes — chaque ligne de la liste correspond directement à
  /// un couple (école, classe) réel pour le matricule, jamais une étape
  /// "école" puis une étape "classe" séparées. Retourne le couple choisi, ou
  /// `null` si l'utilisateur ferme le bottom sheet sans choisir.
  static Future<EcoleClasseChoice?> showEcoleClasses(
    BuildContext context, {
    required List<EcoleAvecClasses> options,
    String? childFirstName,
  }) async {
    if (options.isEmpty) return null;
    final showEcoleName = options.length > 1;
    final chosen = await _show<EcoleClasseChoice>(
      context,
      showEcoleName: showEcoleName,
      childFirstName: childFirstName,
      rows: [
        for (final option in options)
          for (final classe in option.classes)
            _Row(
              classe: classe,
              ecoleNom: showEcoleName ? option.ecole.nom : null,
              value: EcoleClasseChoice(option: option, classe: classe),
            ),
      ],
    );
    return chosen;
  }

  static Future<T?> _show<T>(
    BuildContext context, {
    required bool showEcoleName,
    required List<_Row<T>> rows,
    String? childFirstName,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final nomEleve = childFirstName ?? 'Cet élève';

    return ReusableBottomSheet.show<T>(
      context: context,
      title: showEcoleName
          ? 'Choisissez l\'établissement et la classe'
          : 'Choisissez la classe',
      subtitle: showEcoleName
          ? '$nomEleve semble inscrit(e) dans plusieurs écoles'
          : '$nomEleve est inscrit(e) dans deux classes cette année',
      icon: showEcoleName ? Icons.swap_horiz_rounded : Icons.class_rounded,
      iconColor: showEcoleName ? const Color(0xFF2E7D32) : const Color(0xFF1976D2),
      isDismissible: false,
      useDraggable: false,
      initialChildSize: showEcoleName ? 0.45 : 0.35,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showEcoleName
                ? 'Les notes et bulletins sont propres à chaque établissement et à chaque classe.'
                : 'Chacune a ses propres notes, son propre rang et son propre bulletin.',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  row.classe.libelle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: row.ecoleNom != null
                    ? Text(row.ecoleNom!)
                    : (row.classe.effectif != null
                        ? Text('${row.classe.effectif} élève(s)')
                        : null),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(row.value),
              ),
            ),
          ),
          const BottomSpacer(),
        ],
      ),
    );
  }
}

class _Row<T> {
  final ClasseConsultation classe;
  final String? ecoleNom;
  final T value;

  const _Row({required this.classe, required this.ecoleNom, required this.value});
}
