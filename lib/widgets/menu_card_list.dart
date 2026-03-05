import 'package:flutter/material.dart';

/// Modèle pour une carte de menu
class MenuCardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final String? badge;

  const MenuCardItem({
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

/// Widget de cartes de menu qui défilent horizontalement
class MenuCardList extends StatelessWidget {
  final List<MenuCardItem> cards;
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;
  final double cardWidth;
  final double cardHeight;

  const MenuCardList({
    super.key,
    required this.cards,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 12,
    this.cardWidth = 100,
    this.cardHeight = 60,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: cardHeight + 32, // hauteur fixe pour le conteneur
      padding: padding,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _buildMenuCard(context, card, isDark);
        },
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, MenuCardItem card, bool isDark) {
    return GestureDetector(
      onTap: card.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: card.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône en haut
              Icon(
                card.icon,
                size: 24,
                color: card.iconColor ?? Colors.grey[600],
              ),
              const SizedBox(height: 8),
              
              // Titre en gras
              Text(
                card.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: card.titleColor ?? Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 2),
              
              // Description plus petite
              Text(
                _getMenuDescription(card.label),
                style: TextStyle(
                  fontSize: 10,
                  color: card.descriptionColor ?? Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMenuDescription(String label) {
    switch (label) {
      case 'Informations':
        return 'Détails, contacts, localisation';
      case 'Communication':
        return 'Actualités, annonces, newsletters';
      case 'Niveaux':
        return 'Classes, programmes, enseignants';
      case 'Event school':
        return 'Événements, activités, calendrier';
      case 'Scolarité':
        return 'Frais, inscription, bourses';
      case 'Notes':
        return 'Avis, témoignages, évaluations';
      default:
        return 'En savoir plus...';
    }
  }
}

/// Version spécifique pour les menus d'établissement avec couleurs personnalisées
class EstablishmentMenuCards extends StatelessWidget {
  final VoidCallback? onInfos;
  final VoidCallback? onCommunication;
  final VoidCallback? onLevels;
  final VoidCallback? onEvents;
  final VoidCallback? onScolarite;
  final VoidCallback? onNotes;
  final String? activeTab;

  const EstablishmentMenuCards({
    super.key,
    this.onInfos,
    this.onCommunication,
    this.onLevels,
    this.onEvents,
    this.onScolarite,
    this.onNotes,
    this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      MenuCardItem(
        icon: Icons.info_rounded,
        label: 'Informations',
        onTap: onInfos ?? () {},
        backgroundColor: const Color(0xFFE3F2FD), // Bleu très clair
        iconColor: const Color(0xFF1976D2), // Bleu
        titleColor: const Color(0xFF0D47A1), // Bleu foncé
        descriptionColor: const Color(0xFF1565C0), // Bleu moyen
      ),
      MenuCardItem(
        icon: Icons.campaign_rounded,
        label: 'Communication',
        onTap: onCommunication ?? () {},
        backgroundColor: const Color(0xFFE8F5E8), // Vert très clair
        iconColor: const Color(0xFF2E7D32), // Vert
        titleColor: const Color(0xFF1B5E20), // Vert foncé
        descriptionColor: const Color(0xFF388E3C), // Vert moyen
      ),
      MenuCardItem(
        icon: Icons.school_rounded,
        label: 'Niveaux',
        onTap: onLevels ?? () {},
        backgroundColor: const Color(0xFFFFF3E0), // Orange très clair
        iconColor: const Color(0xFFF57C00), // Orange
        titleColor: const Color(0xFFE65100), // Orange foncé
        descriptionColor: const Color(0xFFEF6C00), // Orange moyen
      ),
      MenuCardItem(
        icon: Icons.event_rounded,
        label: 'Event school',
        onTap: onEvents ?? () {},
        backgroundColor: const Color(0xFFF3E5F5), // Violet très clair
        iconColor: const Color(0xFF7B1FA2), // Violet
        titleColor: const Color(0xFF4A148C), // Violet foncé
        descriptionColor: const Color(0xFF8E24AA), // Violet moyen
      ),
      MenuCardItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Scolarité',
        onTap: onScolarite ?? () {},
        backgroundColor: const Color(0xFFFCE4EC), // Rose très clair
        iconColor: const Color(0xFFC2185B), // Rose
        titleColor: const Color(0xFF880E4F), // Rose foncé
        descriptionColor: const Color(0xFFD81B60), // Rose moyen
      ),
      MenuCardItem(
        icon: Icons.star_rate_rounded,
        label: 'Notes',
        onTap: onNotes ?? () {},
        backgroundColor: const Color(0xFFFAFAFA), // Gris très clair
        iconColor: const Color(0xFF616161), // Gris
        titleColor: const Color(0xFF212121), // Gris foncé
        descriptionColor: const Color(0xFF757575), // Gris moyen
      ),
    ];

    return MenuCardList(
      cards: cards,
      cardWidth: 140,
      cardHeight: 100,
      spacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Version simplifiée avec couleurs par défaut
class EstablishmentMenuCardsSimple extends StatelessWidget {
  final VoidCallback? onInfos;
  final VoidCallback? onCommunication;
  final VoidCallback? onLevels;
  final VoidCallback? onEvents;
  final VoidCallback? onScolarite;
  final VoidCallback? onNotes;

  const EstablishmentMenuCardsSimple({
    super.key,
    this.onInfos,
    this.onCommunication,
    this.onLevels,
    this.onEvents,
    this.onScolarite,
    this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      MenuCardItem(
        icon: Icons.info_rounded,
        label: 'Informations',
        onTap: onInfos ?? () {},
      ),
      MenuCardItem(
        icon: Icons.campaign_rounded,
        label: 'Communication',
        onTap: onCommunication ?? () {},
      ),
      MenuCardItem(
        icon: Icons.school_rounded,
        label: 'Niveaux',
        onTap: onLevels ?? () {},
      ),
      MenuCardItem(
        icon: Icons.event_rounded,
        label: 'Event school',
        onTap: onEvents ?? () {},
      ),
      MenuCardItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Scolarité',
        onTap: onScolarite ?? () {},
      ),
      MenuCardItem(
        icon: Icons.star_rate_rounded,
        label: 'Notes',
        onTap: onNotes ?? () {},
      ),
    ];

    return MenuCardList(
      cards: cards,
      cardWidth: 140,
      cardHeight: 100,
      spacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
