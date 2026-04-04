import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Affiche un SnackBar identique à l'ancien rendu natif (pleine largeur,
/// collé en bas, sans marges flottantes).
///
/// Usage :
/// ```dart
/// CartSnackBar.show(context, productName: product.title);
/// ```
class CartSnackBar {
  CartSnackBar._();

  static void show(
    BuildContext context, {
    required String productName,
    String message = 'ajouté au panier',
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onUndo,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // ── Contenu : texte simple, nom en gras ──────────────────────────
        content: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' $message'),
            ],
          ),
        ),

        // ── Style identique à l'original ─────────────────────────────────
        backgroundColor: backgroundColor ?? AppColors.shopGreen,
        duration: duration,
        behavior: SnackBarBehavior.fixed, // collé en bas, pleine largeur
        elevation: 0,                     // pas d'ombre
        shape: const RoundedRectangleBorder(), // pas de bordures arrondies

        // ── Bouton Annuler optionnel ──────────────────────────────────────
        action: onUndo != null
            ? SnackBarAction(
                label: 'Annuler',
                textColor: Colors.white.withOpacity(0.85),
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  /// Affiche un SnackBar au-dessus de tous les widgets (bottom sheets, modals, etc.)
  /// Utilise un Overlay pour s'afficher au premier plan
  static void showOverlay(
    BuildContext context, {
    required String productName,
    String message = 'ajouté au panier',
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onUndo,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: _SnackBarOverlay(
            productName: productName,
            message: message,
            backgroundColor: backgroundColor ?? AppColors.shopGreen,
            duration: duration,
            onUndo: onUndo,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Auto-remove après la durée spécifiée
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _SnackBarOverlay extends StatefulWidget {
  final String productName;
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;

  const _SnackBarOverlay({
    required this.productName,
    required this.message,
    required this.backgroundColor,
    required this.duration,
    this.onUndo,
    required this.onDismiss,
  });

  @override
  State<_SnackBarOverlay> createState() => _SnackBarOverlayState();
}

class _SnackBarOverlayState extends State<_SnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Commence en bas (caché)
      end: Offset.zero, // Se termine à sa position normale
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Container(
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Contenu : texte simple, nom en gras ──────────────────────────
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: widget.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${widget.message}'),
                    ],
                  ),
                ),
              ),

              // ── Bouton Annuler optionnel ──────────────────────────────────────
              if (widget.onUndo != null) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    widget.onUndo?.call();
                    widget.onDismiss();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],

              // ── Bouton Fermer ────────────────────────────────────────────────
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}