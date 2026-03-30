import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../services/text_size_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget dialog de résultat de demande d'intégration
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog affichant le résultat d'une consultation de demande d'intégration.
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

  /// Ouvre le dialog depuis n'importe quel écran ou widget.
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> data,
  }) {
    return showDialog(
      context: context,
      builder: (_) => IntegrationResultDialog(data: data),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.screenShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── En-tête ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Résultat de la demande',
                    style: TextStyle(
                      fontSize: textSizeService.getScaledFontSize(17),
                      fontWeight: FontWeight.w700,
                      color: AppColors.screenTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Séparateur décoratif ───────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(top: 14, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.screenDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Corps ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  _CloseButton(textSizeService: textSizeService),
                ],
              ),
            ),
          ],
        ),
      ),
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
