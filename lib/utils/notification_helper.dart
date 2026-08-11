import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

/// Types de notification
enum NotificationType {
  success,
  error,
  warning,
  info,
  timeout,
  noConnection,
}

/// Helper centralisé pour afficher des notifications dans toute l'application.
///
/// Modèle visuel unique pour toute l'app : bandeau plein largeur en haut de
/// l'écran, couleur pleine selon le type, icône + texte blancs, glissement
/// depuis le haut — le même style que la bannière de connectivité
/// (« Aucune connexion Internet » / « De nouveau connecté à Internet »,
/// voir [ConnectivityBanner]). C'est le seul modèle de notification à
/// utiliser dans toute l'application, à la place de tout SnackBar custom.
///
/// Utilise un Overlay Entry global (via le [navigatorKey] de main.dart) pour s'afficher
/// au tout premier plan, au-dessus de tous les bottom sheets, modales et claviers.
///
/// Possède un mécanisme de repli (fallback) sur [ScaffoldMessenger] si l'overlay n'est pas disponible.
class NotificationHelper {
  NotificationHelper._();

  static OverlayEntry? _currentOverlayEntry;
  static Timer? _autoDismissTimer;

  /// Annule et ferme la notification active avec une animation
  static void dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    if (_currentOverlayEntry != null) {
      _currentOverlayEntry!.remove();
      _currentOverlayEntry = null;
    }
  }

  /// Affiche une notification globale (sans besoin de BuildContext) au premier plan
  static void show({
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    // 1. Annuler la notification précédente
    dismiss();

    // 2. Fonction interne pour insérer la notification dans l'overlay
    void doInsert() {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null) {
        // Repli (fallback) sur le ScaffoldMessenger classique
        _showFallbackSnackBar(
          message: message,
          type: type,
          duration: duration,
          actionText: actionText,
          onActionPressed: onActionPressed,
        );
        return;
      }

      final GlobalKey<_NotificationBannerState> bannerKey =
          GlobalKey<_NotificationBannerState>();

      final overlayEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: _NotificationBanner(
                key: bannerKey,
                message: message,
                type: type,
                actionText: actionText,
                onActionPressed: onActionPressed,
                onDismiss: () {
                  if (_currentOverlayEntry != null) {
                    _currentOverlayEntry!.remove();
                    _currentOverlayEntry = null;
                  }
                },
              ),
            ),
          );
        },
      );

      _currentOverlayEntry = overlayEntry;
      overlay.insert(overlayEntry);

      // Forcer Flutter à repeindre immédiatement (critique pour les callbacks platform)
      WidgetsBinding.instance.ensureVisualUpdate();

      // 3. Fermeture automatique après la durée
      _autoDismissTimer = Timer(duration, () {
        if (bannerKey.currentState != null) {
          bannerKey.currentState!.dismiss();
        } else {
          dismiss();
        }
      });
    }

    // Si l'overlay est déjà prêt, insérer tout de suite
    if (navigatorKey.currentState?.overlay != null) {
      doInsert();
    } else {
      // Sinon attendre le prochain frame pour que l'overlay soit construit
      WidgetsBinding.instance.addPostFrameCallback((_) => doInsert());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  /// Affiche une notification avec un BuildContext (alternative locale)
  static void showWithContext({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    show(
      message: message,
      type: type,
      duration: duration,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  /// Méthode de repli utilisant l'ancien système de SnackBar — même style
  /// (bandeau plein largeur, couleur pleine) que la version Overlay.
  static void _showFallbackSnackBar({
    required String message,
    required NotificationType type,
    required Duration duration,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) return;

    final config = _getConfig(type);
    state.hideCurrentSnackBar();

    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  state.hideCurrentSnackBar();
                  onActionPressed();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: config.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.fixed,
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  // ─── Méthodes de raccourci ─────────────────────────────────────────

  static void showTimeout({String? customMessage}) {
    show(
      message: customMessage ?? 'Le serveur met trop de temps à répondre. Vérifiez votre connexion et réessayez.',
      type: NotificationType.timeout,
      duration: const Duration(seconds: 5),
    );
  }

  static void showNoConnection({String? customMessage}) {
    // Désactivé : L'application utilise déjà la bannière globale
    // ConnectivityBanner en haut de l'écran pour ce cas précis — qui suit
    // exactement le même style visuel que ce helper. Éviter le doublon.
  }

  static void showServerError({String? customMessage, int? statusCode}) {
    final msg = customMessage ??
      (statusCode != null
        ? 'Le serveur a retourné une erreur ($statusCode). Veuillez réessayer plus tard.'
        : 'Une erreur serveur est survenue. Veuillez réessayer plus tard.');
    show(
      message: msg,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    );
  }

  static void showSuccess(String message) {
    show(message: message, type: NotificationType.success);
  }

  static void showInfo(String message) {
    show(message: message, type: NotificationType.info);
  }

  static void showWarning(String message) {
    show(message: message, type: NotificationType.warning);
  }

  static void showError(String message) {
    show(message: message, type: NotificationType.error);
  }

  // ─── Configuration visuelle ────────────────────────────────────────
  // Un seul modèle pour toute l'app : couleur pleine + icône/texte blancs,
  // identique à ConnectivityBanner (mêmes couleurs pour success/error).

  static _NotifConfig _getConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const _NotifConfig(
          icon: Icons.check_circle_rounded,
          backgroundColor: Color(0xFF2E7D32), // identique à ConnectivityBanner (en ligne)
        );
      case NotificationType.error:
        return const _NotifConfig(
          icon: Icons.error_rounded,
          backgroundColor: Color(0xFFD32F2F), // identique à ConnectivityBanner (hors ligne)
        );
      case NotificationType.warning:
        return const _NotifConfig(
          icon: Icons.warning_rounded,
          backgroundColor: Color(0xFFF57C00),
        );
      case NotificationType.info:
        return const _NotifConfig(
          icon: Icons.info_rounded,
          backgroundColor: Color(0xFF0288D1),
        );
      case NotificationType.timeout:
        return const _NotifConfig(
          icon: Icons.timer_off_rounded,
          backgroundColor: Color(0xFFF57C00),
        );
      case NotificationType.noConnection:
        return const _NotifConfig(
          icon: Icons.wifi_off_rounded,
          backgroundColor: Color(0xFFD32F2F),
        );
    }
  }
}

/// Configuration visuelle d'une notification (bandeau plein, texte/icône blancs)
class _NotifConfig {
  final IconData icon;
  final Color backgroundColor;

  const _NotifConfig({
    required this.icon,
    required this.backgroundColor,
  });
}

/// Bandeau de notification affiché en Overlay (au tout premier plan) —
/// même style visuel que [ConnectivityBanner] : plein largeur, couleur
/// pleine, icône + texte blancs centrés, glissement depuis le haut.
class _NotificationBanner extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    super.key,
    required this.message,
    required this.type,
    this.actionText,
    this.onActionPressed,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Méthode d'animation de sortie fluide
  void dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = NotificationHelper._getConfig(widget.type);

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 6,
        color: config.backgroundColor,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Dismiss sur swipe vers le haut
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              dismiss();
            }
          },
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(config.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.actionText != null && widget.onActionPressed != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        dismiss();
                        widget.onActionPressed!();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: Text(
                        widget.actionText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
