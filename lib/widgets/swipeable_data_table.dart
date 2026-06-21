import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Un bouton d'action affiché lors du "swipe" d'une ligne
class SwipeAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Représente une ligne de données dans notre tableau
class SwipeableDataRow {
  final String id; // Identifiant unique (très important pour le swipe)
  final List<Widget> cells; // Le contenu de chaque colonne
  final SwipeAction? leftAction; // Action quand on glisse vers la droite
  final SwipeAction? rightAction; // Action quand on glisse vers la gauche
  final VoidCallback? onTap; // Action au clic simple sur la ligne

  SwipeableDataRow({
    required this.id,
    required this.cells,
    this.leftAction,
    this.rightAction,
    this.onTap,
  });
}

/// Un tableau de données stylisé dont les lignes peuvent être glissées (swipe)
class SwipeableDataTable extends StatelessWidget {
  final List<String> headers;
  final List<SwipeableDataRow> rows;
  final bool isDarkMode;
  final List<int>? flexColumnWidths; // Largeur relative des colonnes (ex: [2, 1, 1])

  const SwipeableDataTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.isDarkMode,
    this.flexColumnWidths,
  });

  @override
  Widget build(BuildContext context) {
    // Si flexColumnWidths n'est pas fourni, toutes les colonnes font la même taille (flex = 1)
    final widths = flexColumnWidths ?? List.filled(headers.length, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. EN-TÊTE DU TABLEAU
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.grey800 : Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: AppColors.getBorderColor(isDarkMode)),
          ),
          child: Row(
            children: List.generate(headers.length, (index) {
              return Expanded(
                flex: widths[index],
                child: Text(
                  headers[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                  ),
                ),
              );
            }),
          ),
        ),

        // 2. CORPS DU TABLEAU (LES LIGNES)
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDarkMode),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(
              left: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
              right: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
              bottom: BorderSide(color: AppColors.getBorderColor(isDarkMode)),
            ),
          ),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Aucune donnée disponible",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode, type: TextType.secondary)),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.getBorderColor(isDarkMode).withOpacity(0.5),
                  ),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _buildSwipeableRow(context, row, widths);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSwipeableRow(BuildContext context, SwipeableDataRow row, List<int> widths) {
    // Le widget Dismissible permet le fameux "swipe"
    return Dismissible(
      key: ValueKey(row.id),
      // On autorise le swipe seulement s'il y a une action configurée
      direction: _getDismissDirection(row),
      
      // Ce qui s'affiche en fond quand on glisse vers la droite (Left Action)
      background: row.leftAction != null ? _buildSwipeBackground(row.leftAction!, Alignment.centerLeft) : const SizedBox(),
      
      // Ce qui s'affiche en fond quand on glisse vers la gauche (Right Action)
      secondaryBackground: row.rightAction != null ? _buildSwipeBackground(row.rightAction!, Alignment.centerRight) : const SizedBox(),
      
      // Ce qu'il se passe quand on a swipé jusqu'au bout
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && row.rightAction != null) {
          row.rightAction!.onTap();
        } else if (direction == DismissDirection.startToEnd && row.leftAction != null) {
          row.leftAction!.onTap();
        }
        // Renvoie toujours "false" pour que la ligne ne disparaisse pas visuellement
        // (à moins que l'action supprime la donnée de la liste et fasse un setState)
        return false;
      },
      
      // L'apparence normale de la ligne
      child: InkWell(
        onTap: row.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: List.generate(row.cells.length, (index) {
              return Expanded(
                flex: widths[index],
                child: row.cells[index],
              );
            }),
          ),
        ),
      ),
    );
  }

  DismissDirection _getDismissDirection(SwipeableDataRow row) {
    if (row.leftAction != null && row.rightAction != null) {
      return DismissDirection.horizontal;
    } else if (row.leftAction != null) {
      return DismissDirection.startToEnd;
    } else if (row.rightAction != null) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.none;
  }

  Widget _buildSwipeBackground(SwipeAction action, Alignment alignment) {
    return Container(
      color: action.color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
