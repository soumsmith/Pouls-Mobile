import 'package:flutter/material.dart';
import 'package:parents_responsable/config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SELECTABLE ITEM CARD — Composant unifié et réutilisable
// ═══════════════════════════════════════════════════════════════════════════════
//
// Usage :
//   • Écran d'inscription (scolarité, services, zones, échéances)
//   • Tout autre écran nécessitant une carte à sélection unique ou multiple
//
// Paramètres obligatoires : title, onTap
// Paramètres optionnels   : voir [SelectableItemCard]
// ─────────────────────────────────────────────────────────────────────────────

// ─── ENUM : variante visuelle ─────────────────────────────────────────────────

enum ItemCardVariant {
  /// Checkbox + libellé + méta (date, badge) + valeur monétaire
  /// → Échéances scolarité / services
  echeance,

  /// Icône + titre + badge catégorie + prix
  /// → Services (cantine, transport, autres)
  service,

  /// Icône + titre + sous-titre
  /// → Zones de transport
  zone,

  /// Icône + titre + sous-titre (générique)
  /// → Extensible vers d'autres écrans
  generic,
}

// ─── ENUM : type de sélection ─────────────────────────────────────────────────

enum ItemCardSelectionStyle {
  /// Cercle coché (checkbox-like) — scolarité, échéances
  checkbox,

  /// Cercle coché en bas à droite de l'icône — services
  badgeCheck,

  /// Cercle coché à droite — zones
  trailingCheck,
}

// ─── MODÈLE DE CONFIGURATION ──────────────────────────────────────────────────

/// Configuration complète d'une [SelectableItemCard].
/// Permet de décrire n'importe quel item sans logique métier dans le widget.
class ItemCardConfig {
  // Identité
  final String title;
  final String? subtitle;
  final String? trailingLabel; // ex : montant formaté
  final String? badgeLabel;    // ex : "CANTINE", "TRANS", "Obligatoire"

  // État
  final bool selected;
  final bool locked;           // si true : sélectionné + icône cadenas, non cliquable

  // Apparence
  final ItemCardVariant variant;
  final ItemCardSelectionStyle selectionStyle;
  final IconData? leadingIcon;
  final Color? accentColor;    // surcharge de AppColors.shopBlue
  final Color? badgeColor;     // couleur du badge (défaut : accentColor)
  final bool showLeadingIcon;

  // Animation
  final int animationIndex;    // décalage pour l'animation d'entrée (0 = pas de décalage)

  // Callbacks
  final VoidCallback? onTap;

  const ItemCardConfig({
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.badgeLabel,
    this.selected = false,
    this.locked = false,
    this.variant = ItemCardVariant.generic,
    this.selectionStyle = ItemCardSelectionStyle.checkbox,
    this.leadingIcon,
    this.accentColor,
    this.badgeColor,
    this.showLeadingIcon = true,
    this.animationIndex = 0,
    this.onTap,
  });

  ItemCardConfig copyWith({
    String? title,
    String? subtitle,
    String? trailingLabel,
    String? badgeLabel,
    bool? selected,
    bool? locked,
    ItemCardVariant? variant,
    ItemCardSelectionStyle? selectionStyle,
    IconData? leadingIcon,
    Color? accentColor,
    Color? badgeColor,
    bool? showLeadingIcon,
    int? animationIndex,
    VoidCallback? onTap,
  }) {
    return ItemCardConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      trailingLabel: trailingLabel ?? this.trailingLabel,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      selected: selected ?? this.selected,
      locked: locked ?? this.locked,
      variant: variant ?? this.variant,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      leadingIcon: leadingIcon ?? this.leadingIcon,
      accentColor: accentColor ?? this.accentColor,
      badgeColor: badgeColor ?? this.badgeColor,
      showLeadingIcon: showLeadingIcon ?? this.showLeadingIcon,
      animationIndex: animationIndex ?? this.animationIndex,
      onTap: onTap ?? this.onTap,
    );
  }
}

// ─── WIDGET PRINCIPAL ─────────────────────────────────────────────────────────

/// Carte sélectionnable unifiée.
///
/// Exemple minimal :
/// ```dart
/// SelectableItemCard(
///   config: ItemCardConfig(
///     title: 'Frais de scolarité T1',
///     subtitle: 'Limite : 31/08/2025',
///     trailingLabel: '150 000 FCFA',
///     selected: true,
///     variant: ItemCardVariant.echeance,
///     selectionStyle: ItemCardSelectionStyle.checkbox,
///     onTap: () => setState(() => item.selected = !item.selected),
///   ),
/// )
/// ```
class SelectableItemCard extends StatelessWidget {
  final ItemCardConfig config;

  const SelectableItemCard({Key? key, required this.config}) : super(key: key);

  // ── Couleur principale (accent ou défaut) ──────────────────────────────────
  Color get _accent => config.accentColor ?? AppColors.shopBlue;

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: config.locked ? null : config.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: config.selected ? _accent.withOpacity(0.4) : Colors.transparent,
            width: config.selected ? 1.5 : 0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _buildContent(),
        ),
      ),
    );

    // Animation d'entrée décalée
    if (config.animationIndex == 0) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + config.animationIndex * 65),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: card,
    );
  }

  // ── Sélecteur de layout selon la variante ──────────────────────────────────

  Widget _buildContent() {
    switch (config.variant) {
      case ItemCardVariant.echeance:
        return _buildEcheanceLayout();
      case ItemCardVariant.service:
        return _buildServiceLayout();
      case ItemCardVariant.zone:
        return _buildZoneLayout();
      case ItemCardVariant.generic:
        return _buildGenericLayout();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT : ÉCHEANCE
  // [○] Libellé                               150 000 FCFA
  //     📅 Limite : 31/08/2025  [Obligatoire]
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEcheanceLayout() {
    return Row(
      children: [
        _buildCheckCircle(size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (config.subtitle != null) ...[
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppColors.screenTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      config.subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.screenTextSecondary,
                      ),
                    ),
                  ],
                                  ],
              ),
            ],
          ),
        ),
        if (config.trailingLabel != null || config.badgeLabel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (config.trailingLabel != null)
                Text(
                  config.trailingLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.shopGreen,
                  ),
                ),
              if (config.badgeLabel != null) ...[
                const SizedBox(height: 2),
                _buildBadge(
                  config.badgeLabel!,
                  bgColor: (config.badgeColor ?? Colors.red).withOpacity(0.1),
                  textColor: config.badgeColor ?? Colors.red,
                ),
              ],
            ],
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT : SERVICE
  // [🍽️]  Cantine Standard          150 000 FCFA
  //        [CANTINE]                        [✓]
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildServiceLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône principale
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: config.selected ? _accent.withOpacity(0.12) : AppColors.screenSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            config.leadingIcon ?? Icons.grid_view_rounded,
            color: config.selected ? _accent : AppColors.screenTextSecondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title on one line with ellipsis
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Price below title
              if (config.trailingLabel != null || config.badgeLabel != null) 
                Row(
                  children: [
                    if (config.trailingLabel != null)
                      Text(
                        config.trailingLabel!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.shopGreen,
                        ),
                      ),
                    if (config.badgeLabel != null) ...[
                      const SizedBox(width: 6),
                      _buildBadge(
                        config.badgeLabel!,
                        bgColor: _accent.withOpacity(0.1),
                        textColor: _accent,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildCheckCircle(size: 22),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT : ZONE
  // [📍] Quartier Résidentiel Nord           [✓]
  //      Code : QRN-01
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildZoneLayout() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: config.selected ? _accent.withOpacity(0.12) : AppColors.screenSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            config.leadingIcon ?? Icons.location_on_rounded,
            color: config.selected ? _accent : AppColors.screenTextSecondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (config.subtitle != null)
                Text(
                  config.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (config.selected) _buildCheckCircle(size: 22),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT : GENERIC
  // [🏫] Titre principal                     Valeur
  //      Sous-titre optionnel
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGenericLayout() {
    return Row(
      children: [
        if (config.showLeadingIcon) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.selected ? _accent.withOpacity(0.12) : AppColors.screenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              config.leadingIcon ?? Icons.circle_outlined,
              color: config.selected ? _accent : AppColors.screenTextSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.screenTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (config.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  config.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.screenTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (config.trailingLabel != null)
          Text(
            config.trailingLabel!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
        if (config.selectionStyle != ItemCardSelectionStyle.badgeCheck) ...[
          const SizedBox(width: 10),
          _buildCheckCircle(size: 22),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOUS-COMPOSANTS PARTAGÉS
  // ══════════════════════════════════════════════════════════════════════════

  /// Cercle de sélection (checkbox / check trailing)
  Widget _buildCheckCircle({required double size}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.selected ? _accent : Colors.transparent,
        border: Border.all(
          color: config.selected ? _accent : AppColors.screenDivider,
          width: 2,
        ),
      ),
      child: config.selected
          ? Icon(
              config.locked ? Icons.lock_rounded : Icons.check_rounded,
              color: Colors.white,
              size: size * 0.50,
            )
          : null,
    );
  }

  /// Badge coloré (catégorie, statut obligatoire, etc.)
  Widget _buildBadge(String label, {required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER — Entête de groupe réutilisable
// ═══════════════════════════════════════════════════════════════════════════════
//
// Affiche une icône colorée + titre + compteur ou badge à droite.
// Utilisé pour regrouper des cartes (ex: "Services Cantine  2 sélectionné(s)").

class ItemSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? trailingLabel;
  final EdgeInsetsGeometry padding;

  const ItemSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.trailingLabel,
    this.padding = const EdgeInsets.only(bottom: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.shopBlue;
    final bg = iconBgColor ?? color.withOpacity(0.1);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
          ),
          if (trailingLabel != null)
            Text(
              trailingLabel!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FACTORIES — Helpers pour instancier facilement les configs métier
// ═══════════════════════════════════════════════════════════════════════════════

class ItemCardFactory {
  ItemCardFactory._();

  /// Carte d'échéance scolaire ou service
  static ItemCardConfig echeance({
    required String libelle,
    required String montantFormate,
    required String dateLimite,
    required bool selected,
    required VoidCallback? onToggle,
    bool obligatoire = false,
    int index = 0,
  }) {
    return ItemCardConfig(
      title: libelle,
      subtitle: 'Limite : $dateLimite',
      trailingLabel: montantFormate,
      badgeLabel: obligatoire ? 'Obligatoire' : null,
      selected: selected,
      locked: obligatoire,
      variant: ItemCardVariant.echeance,
      selectionStyle: ItemCardSelectionStyle.checkbox,
      showLeadingIcon: false,
      animationIndex: index,
      onTap: onToggle,
    );
  }

  /// Carte de service (cantine / transport / autre)
  static ItemCardConfig service({
    required String designation,
    required String type,       // ex : 'CANTINE', 'TRANS'
    required String prixFormate,
    required bool selected,
    required VoidCallback? onTap,
    IconData? icon,
    int index = 0,
  }) {
    return ItemCardConfig(
      title: designation,
      trailingLabel: prixFormate,
      badgeLabel: type,
      selected: selected,
      variant: ItemCardVariant.service,
      selectionStyle: ItemCardSelectionStyle.badgeCheck,
      leadingIcon: icon ?? _serviceIcon(type),
      showLeadingIcon: true,
      animationIndex: index,
      onTap: onTap,
    );
  }

  /// Carte de zone de transport
  static ItemCardConfig zone({
    required String nom,
    required String code,
    required bool selected,
    required VoidCallback? onTap,
    int index = 0,
  }) {
    return ItemCardConfig(
      title: nom,
      subtitle: 'Code : $code',
      selected: selected,
      variant: ItemCardVariant.zone,
      selectionStyle: ItemCardSelectionStyle.trailingCheck,
      leadingIcon: Icons.location_on_rounded,
      showLeadingIcon: true,
      animationIndex: index,
      onTap: onTap,
    );
  }

  /// Icône par défaut selon le type de service
  static IconData _serviceIcon(String type) {
    switch (type.toUpperCase()) {
      case 'CANTINE':
        return Icons.restaurant_rounded;
      case 'TRANS':
        return Icons.directions_bus_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}