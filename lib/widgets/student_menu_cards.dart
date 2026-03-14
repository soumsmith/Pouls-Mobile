import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'section_title.dart';

/// Modèle pour une carte de menu d'élève
class StudentMenuCardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final String? badge;

  const StudentMenuCardItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
    this.badge,
  });
}

/// Widget de cartes de menu pour élève organisées en lignes thématiques
/// avec plusieurs lignes pour une meilleure organisation
class StudentMenuCards extends StatelessWidget {
  final List<List<dynamic>> rows; // Liste de lignes, chaque ligne contient des items
  final List<String> rowTitles; // Titres pour chaque ligne
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;
  final double cardWidth;
  final double cardHeight;
  final double rowSpacing;

  const StudentMenuCards({
    super.key,
    required this.rows,
    this.rowTitles = const [], // Optionnel, vide par défaut
    this.spacing = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 12,
    this.cardWidth = 100,
    this.cardHeight = 80,
    this.rowSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final row = entry.value;
        final isLastRow = rowIndex == rows.length - 1;
        
        return Column(
          children: [
            // Titre de section
            if (rowTitles.isNotEmpty && rowIndex < rowTitles.length)
              SectionTitle(title: rowTitles[rowIndex]),
            // Ligne de cartes
            SizedBox(
              height: cardHeight + 16,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(
                  left: padding.left,
                  right: padding.right,
                  top: rowTitles.isNotEmpty && rowIndex < rowTitles.length ? 0 : (rowIndex == 0 ? padding.top : 0),
                  bottom: isLastRow ? padding.bottom : 0,
                ),
                itemCount: row.length,
                separatorBuilder: (context, index) => SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  final item = row[index];
                  if (item is StudentMenuCardItem) {
                    return _buildMenuCard(context, item, isDark);
                  } else if (item is Widget) {
                    return item; // Rendre le widget directement
                  } else {
                    return const SizedBox.shrink(); // Gérer les cas inattendus
                  }
                },
              ),
            ),
            // Espacement entre les lignes
            if (!isLastRow) SizedBox(height: rowSpacing),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(BuildContext context, StudentMenuCardItem card, bool isDark) {
    return InkWell(
      onTap: card.onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: card.backgroundColor ?? (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône en haut
              Icon(
                card.icon,
                size: 24,
                color: card.iconColor ?? (isDark ? Colors.white70 : Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              
              // Titre en gras
              Text(
                card.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: card.titleColor ?? (isDark ? Colors.white : Colors.black87),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modèle pour un groupe de menus thématiques
class MenuGroup {
  final String title;
  final Color color;
  final List<StudentMenuCardItem> cards;

  const MenuGroup({
    required this.title,
    required this.color,
    required this.cards,
  });
}

/// Version spécifique pour les menus d'élève avec couleurs personnalisées
class StudentMenuCardsFull extends StatelessWidget {
  final VoidCallback? onNotes;
  final VoidCallback? onBulletins;
  final VoidCallback? onTimetable;
  final VoidCallback? onHomework;
  final VoidCallback? onAttendance;
  final VoidCallback? onAccessControl;
  final VoidCallback? onSanctions;
  final VoidCallback? onMessages;
  final VoidCallback? onFees;
  final VoidCallback? onDifficulties;
  final VoidCallback? onEvents;
  final VoidCallback? onSupplies;
  final VoidCallback? onOrders;
  final VoidCallback? onAccessLogs;
  final VoidCallback? onSuggestions;
  final VoidCallback? onReservations;

  const StudentMenuCardsFull({
    super.key,
    this.onNotes,
    this.onBulletins,
    this.onTimetable,
    this.onHomework,
    this.onAttendance,
    this.onAccessControl,
    this.onSanctions,
    this.onMessages,
    this.onFees,
    this.onDifficulties,
    this.onEvents,
    this.onSupplies,
    this.onOrders,
    this.onAccessLogs,
    this.onSuggestions,
    this.onReservations,
  });

  @override
  Widget build(BuildContext context) {
    // Création des lignes thématiques
    final rows = [
      // Ligne 1: Scolarité
      [
      ],
      // Ligne 2: Vie Scolaire
      [
      ],
      // Ligne 3: Communication
      [
      ],
      // Ligne 4: Services
      [
      ],
    ];

    return StudentMenuCards(
      rows: rows,
      rowTitles: [],
      cardWidth: 110,
      cardHeight: 85,
      spacing: 8,
      rowSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
