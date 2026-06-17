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

      final GlobalKey<_NotificationOverlayCardState> cardKey = GlobalKey<_NotificationOverlayCardState>();

      final overlayEntry = OverlayEntry(
        builder: (context) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          return Positioned(
            bottom: bottomPadding + 24,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: _NotificationOverlayCard(
                key: cardKey,
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
        if (cardKey.currentState != null) {
          cardKey.currentState!.dismiss();
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

  /// Méthode de repli utilisant l'ancien système de SnackBar
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
            _AnimatedIcon(icon: config.icon, color: config.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: config.textColor.withOpacity(0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                  foregroundColor: config.textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: config.textColor.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: config.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: config.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: config.borderColor,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        dismissDirection: DismissDirection.horizontal,
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

  static DateTime? _lastNoConnectionTime;

  static void showNoConnection({String? customMessage}) {
    final now = DateTime.now();
    if (_lastNoConnectionTime != null && now.difference(_lastNoConnectionTime!).inSeconds < 5) {
      return; // Ignore si on a déjà affiché l'erreur très récemment
    }
    _lastNoConnectionTime = now;
    
    show(
      message: customMessage ?? 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      type: NotificationType.noConnection,
      duration: const Duration(seconds: 5),
    );
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

  static _NotifConfig _getConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotifConfig(
          title: '✅ Succès',
          icon: Icons.check_circle_rounded,
          backgroundColor: const Color(0xFF0D3B20),
          borderColor: const Color(0xFF10B981).withOpacity(0.3),
          iconColor: const Color(0xFF34D399),
          textColor: const Color(0xFFECFDF5),
        );
      case NotificationType.error:
        return _NotifConfig(
          title: '❌ Erreur',
          icon: Icons.error_rounded,
          backgroundColor: const Color(0xFF3B1219),
          borderColor: const Color(0xFFEF4444).withOpacity(0.3),
          iconColor: const Color(0xFFF87171),
          textColor: const Color(0xFFFEF2F2),
        );
      case NotificationType.warning:
        return _NotifConfig(
          title: '⚠️ Attention',
          icon: Icons.warning_rounded,
          backgroundColor: const Color(0xFF3B2E0D),
          borderColor: const Color(0xFFF59E0B).withOpacity(0.3),
          iconColor: const Color(0xFFFBBF24),
          textColor: const Color(0xFFFFFBEB),
        );
      case NotificationType.info:
        return _NotifConfig(
          title: 'ℹ️ Information',
          icon: Icons.info_rounded,
          backgroundColor: const Color(0xFF0C2340),
          borderColor: const Color(0xFF3B82F6).withOpacity(0.3),
          iconColor: const Color(0xFF60A5FA),
          textColor: const Color(0xFFEFF6FF),
        );
      case NotificationType.timeout:
        return _NotifConfig(
          title: '⏱️ Délai dépassé',
          icon: Icons.timer_off_rounded,
          backgroundColor: const Color(0xFF3B2E0D),
          borderColor: const Color(0xFFF97316).withOpacity(0.3),
          iconColor: const Color(0xFFFB923C),
          textColor: const Color(0xFFFFF7ED),
        );
      case NotificationType.noConnection:
        return _NotifConfig(
          title: '📡 Connexion perdue',
          icon: Icons.wifi_off_rounded,
          backgroundColor: const Color(0xFF2D1B3D),
          borderColor: const Color(0xFFA855F7).withOpacity(0.3),
          iconColor: const Color(0xFFC084FC),
          textColor: const Color(0xFFFAF5FF),
        );
    }
  }
}

/// Configuration visuelle d'une notification
class _NotifConfig {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _NotifConfig({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// Widget d'icône avec animation de pulsation
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({required this.icon, required this.color});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 22,
        ),
      ),
    );
  }
}

/// Widget de carte de notification affiché en Overlay (au tout premier plan)
class _NotificationOverlayCard extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final VoidCallback onDismiss;

  const _NotificationOverlayCard({
    super.key,
    required this.message,
    required this.type,
    this.actionText,
    this.onActionPressed,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlayCard> createState() => _NotificationOverlayCardState();
}

class _NotificationOverlayCardState extends State<_NotificationOverlayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            // Dismiss on swipe left or right!
            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 250) {
              dismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: config.borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icône
                _AnimatedIcon(
                  icon: config.icon,
                  color: config.iconColor,
                ),
                const SizedBox(width: 12),
                // Message
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: TextStyle(
                          color: config.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: config.textColor.withOpacity(0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Bouton d'action optionnel
                if (widget.actionText != null && widget.onActionPressed != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      dismiss();
                      widget.onActionPressed!();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: config.textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: config.textColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      widget.actionText!,
                      style: TextStyle(
                        color: config.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
