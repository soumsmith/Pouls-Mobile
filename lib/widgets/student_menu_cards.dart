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
        StudentMenuCardItem(
          icon: Icons.bar_chart_rounded,
          label: 'Mes Notes',
          onTap: onNotes ?? () {},
          backgroundColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1976D2),
          titleColor: const Color(0xFF0D47A1),
        ),
        StudentMenuCardItem(
          icon: Icons.description_rounded,
          label: 'Bulletins',
          onTap: onBulletins ?? () {},
          backgroundColor: const Color(0xFFE8F5E8),
          iconColor: const Color(0xFF2E7D32),
          titleColor: const Color(0xFF1B5E20),
        ),
        StudentMenuCardItem(
          icon: Icons.calendar_today_rounded,
          label: 'Emploi du temps',
          onTap: onTimetable ?? () {},
          backgroundColor: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFF57C00),
          titleColor: const Color(0xFFE65100),
        ),
        StudentMenuCardItem(
          icon: Icons.edit_note_rounded,
          label: 'Devoirs',
          onTap: onHomework ?? () {},
          backgroundColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF7B1FA2),
          titleColor: const Color(0xFF4A148C),
        ),
      ],
      // Ligne 2: Vie Scolaire
      [
        StudentMenuCardItem(
          icon: Icons.person_off_rounded,
          label: 'Présence',
          onTap: onAttendance ?? () {},
          backgroundColor: const Color(0xFFE0F2F1),
          iconColor: const Color(0xFF00796B),
          titleColor: const Color(0xFF004D40),
        ),
        StudentMenuCardItem(
          icon: Icons.fingerprint_rounded,
          label: 'Contrôle d\'accès',
          onTap: onAccessControl ?? () {},
          backgroundColor: const Color(0xFFFCE4EC),
          iconColor: const Color(0xFFC2185B),
          titleColor: const Color(0xFF880E4F),
        ),
        StudentMenuCardItem(
          icon: Icons.warning_rounded,
          label: 'Sanctions',
          onTap: onSanctions ?? () {},
          backgroundColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFD32F2F),
          titleColor: const Color(0xFFB71C1C),
        ),
        StudentMenuCardItem(
          icon: Icons.psychology_rounded,
          label: 'Difficultés',
          onTap: onDifficulties ?? () {},
          backgroundColor: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF9C27B0),
          titleColor: const Color(0xFF6A1B9A),
        ),
      ],
      // Ligne 3: Communication
      [
        StudentMenuCardItem(
          icon: Icons.message_rounded,
          label: 'Messages',
          onTap: onMessages ?? () {},
          backgroundColor: const Color(0xFFE1F5FE),
          iconColor: const Color(0xFF0288D1),
          titleColor: const Color(0xFF01579B),
        ),
        StudentMenuCardItem(
          icon: Icons.event_rounded,
          label: 'Événements',
          onTap: onEvents ?? () {},
          backgroundColor: const Color(0xFFE8EAF6),
          iconColor: const Color(0xFF3F51B5),
          titleColor: const Color(0xFF283593),
        ),
        StudentMenuCardItem(
          icon: Icons.lightbulb_rounded,
          label: 'Suggestions',
          onTap: onSuggestions ?? () {},
          backgroundColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFFFB300),
          titleColor: const Color(0xFFFF6F00),
        ),
      ],
      // Ligne 4: Services
      [
        StudentMenuCardItem(
          icon: Icons.payments_rounded,
          label: 'Scolarité',
          onTap: onFees ?? () {},
          backgroundColor: const Color(0xFFF9FBE7),
          iconColor: const Color(0xFFFBC02D),
          titleColor: const Color(0xFFF57F17),
        ),
        StudentMenuCardItem(
          icon: Icons.inventory_2_rounded,
          label: 'Fournitures',
          onTap: onSupplies ?? () {},
          backgroundColor: const Color(0xFFEFEBE9),
          iconColor: const Color(0xFF795548),
          titleColor: const Color(0xFF4E342E),
        ),
        StudentMenuCardItem(
          icon: Icons.shopping_cart_rounded,
          label: 'Commandes',
          onTap: onOrders ?? () {},
          backgroundColor: const Color(0xFFE0F7FA),
          iconColor: const Color(0xFF00ACC1),
          titleColor: const Color(0xFF00838F),
        ),
        StudentMenuCardItem(
          icon: Icons.event_seat_rounded,
          label: 'Réservations',
          onTap: onReservations ?? () {},
          backgroundColor: const Color(0xFFE8F5E8),
          iconColor: const Color(0xFF4CAF50),
          titleColor: const Color(0xFF2E7D32),
        ),
        StudentMenuCardItem(
          icon: Icons.security_rounded,
          label: 'Logs d\'accès',
          onTap: onAccessLogs ?? () {},
          backgroundColor: const Color(0xFFEEEEEE),
          iconColor: const Color(0xFF616161),
          titleColor: const Color(0xFF212121),
        ),
      ],
    ];

    return StudentMenuCards(
      rows: rows,
      rowTitles: [
        'Scolarité',
        'Vie Scolaire',
        'Communication',
        'Services',
      ],
      cardWidth: 110,
      cardHeight: 85,
      spacing: 8,
      rowSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
