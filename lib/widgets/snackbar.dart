import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../main.dart';

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
    if (!context.mounted) return;

    final snackBar = SnackBar(
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
    );

    try {
      final state = scaffoldMessengerKey.currentState;
      if (state != null) {
        state.clearSnackBars();
        state.showSnackBar(snackBar);
        return;
      }
    } catch (e) {
      print('⚠️ Error using global ScaffoldMessenger: $e');
    }

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(snackBar);
    } catch (e) {
      print('⚠️ Error using fallback ScaffoldMessenger: $e');
    }
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
    double? minHeight,
    IconData? icon,
  }) {
    if (!context.mounted) return;
    
    try {
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
              onDismiss: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
              minHeight: minHeight,
              icon: icon,
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
    } catch (e) {
      print('⚠️ Error showing overlay snackbar: $e');
    }
  }
}

class _SnackBarOverlay extends StatefulWidget {
  final String productName;
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;
  final double? minHeight;
  final IconData? icon;

  const _SnackBarOverlay({
    required this.productName,
    required this.message,
    required this.backgroundColor,
    required this.duration,
    this.onUndo,
    required this.onDismiss,
    this.minHeight,
    this.icon,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = Color.alphaBlend(widget.backgroundColor.withOpacity(isDark ? 0.2 : 0.1), baseBg);
    final borderColor = widget.backgroundColor.withOpacity(0.2);
    
    // For text color, we try to use a slightly darker shade if it's red, otherwise the base color.
    // In dark mode, white text is more readable for the message body.
    final titleColor = widget.backgroundColor == Colors.red || widget.backgroundColor == Colors.red[400] 
        ? (isDark ? Colors.red[300]! : Colors.red[700]!) 
        : widget.backgroundColor;

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              minHeight: widget.minHeight ?? 50,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Icône ─────────────────────────────────────────────────────────────
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.backgroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(
                    Icons.info_outline,
                    color: widget.backgroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                
                // ── Contenu : texte simple, nom en gras ──────────────────────────
                Expanded(
                  child: RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      children: [
                        if (widget.productName.isNotEmpty)
                          TextSpan(
                            text: widget.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        if (widget.message.isNotEmpty) 
                          TextSpan(
                            text: widget.productName.isNotEmpty ? ' ${widget.message}' : widget.message,
                            style: TextStyle(
                              color: titleColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Bouton Annuler optionnel ──────────────────────────────────────
                if (widget.onUndo != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      widget.onUndo?.call();
                      widget.onDismiss();
                    },
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
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
                    color: isDark ? Colors.white54 : Colors.black45,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}