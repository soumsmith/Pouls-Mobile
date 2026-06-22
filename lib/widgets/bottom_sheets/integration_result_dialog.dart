import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../services/text_size_service.dart';
import 'reusable_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget dialog de résultat de demande d'intégration
// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet affichant le résultat d'une consultation de demande d'intégration.
///
/// **Utilisation simple :**
/// ```dart
/// IntegrationResultDialog.show(
///   context,
///   data: {
///     'statut': 'Accepté',
///     'message': 'Votre demande a été acceptée.',
///     'date': '2024-09-01',   // optionnel
///   },
/// );
/// ```
class IntegrationResultDialog extends StatelessWidget {
  /// Données retournées par l'API :
  /// - `statut`  (String) — obligatoire
  /// - `message` (String) — obligatoire
  /// - `date`    (String) — optionnel
  final Map<String, dynamic> data;

  const IntegrationResultDialog({super.key, required this.data});

  // ── Méthode statique d'affichage ──────────────────────────────────────────

  /// Ouvre le bottom sheet depuis n'importe quel écran ou widget.
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> data,
  }) {
    return ReusableBottomSheet.show<void>(
      context: context,
      title: 'Résultat de la demande',
      subtitle: data['message']?.toString() ?? 'Détails de la consultation',
      icon: Icons.search_rounded,
      iconColor: const Color(0xFF1565C0),
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      contentPadding: const EdgeInsets.all(20),
      content: IntegrationResultDialog(data: data),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ResultItem(
          label: 'Statut',
          value: data['statut']?.toString() ?? 'Non spécifié',
          textSizeService: textSizeService,
        ),
        const SizedBox(height: 12),
        _ResultItem(
          label: 'Message',
          value: data['message']?.toString() ?? 'Aucun message',
          textSizeService: textSizeService,
        ),
        if (data['date'] != null) ...[
          const SizedBox(height: 12),
          _ResultItem(
            label: 'Date',
            value: data['date'].toString(),
            textSizeService: textSizeService,
          ),
        ],
        const SizedBox(height: 24),
        _CloseButton(textSizeService: textSizeService),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires privés
// ─────────────────────────────────────────────────────────────────────────────

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final TextSizeService textSizeService;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.textSizeService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: textSizeService.getScaledFontSize(12),
            fontWeight: FontWeight.w500,
            color: AppColors.screenTextSecondary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: textSizeService.getScaledFontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final TextSizeService textSizeService;

  const _CloseButton({required this.textSizeService});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.screenOrange, Color(0xFFFF7A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.screenOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Fermer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
