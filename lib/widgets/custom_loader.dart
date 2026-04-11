import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Service pour afficher un loader au-dessus de tous les widgets (bottom sheets, modals, etc.)
class CustomLoaderOverlay {
  CustomLoaderOverlay._();

  static OverlayEntry? _overlayEntry;

  /// Affiche un loader au-dessus de tous les widgets
  static void show(
    BuildContext context, {
    String message = 'Chargement...',
    Color? backgroundColor,
    Color loaderColor = const Color(0xFF1565C0),
    double size = 56.0,
    bool showBackground = true,
  }) {
    // Masquer le loader existant s'il y en a un
    hide();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _LoaderOverlayWidget(
        message: message,
        backgroundColor: backgroundColor,
        loaderColor: loaderColor,
        size: size,
        showBackground: showBackground,
        onDismiss: hide,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Masque le loader actuellement affiché
  static void hide() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  /// Vérifie si un loader est actuellement affiché
  static bool get isVisible => _overlayEntry != null && _overlayEntry!.mounted;
}

class _LoaderOverlayWidget extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Color loaderColor;
  final double size;
  final bool showBackground;
  final VoidCallback onDismiss;

  const _LoaderOverlayWidget({
    required this.message,
    this.backgroundColor,
    required this.loaderColor,
    required this.size,
    required this.showBackground,
    required this.onDismiss,
  });

  @override
  State<_LoaderOverlayWidget> createState() => _LoaderOverlayWidgetState();
}

class _LoaderOverlayWidgetState extends State<_LoaderOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black54, // Fond semi-transparent pour bloquer l'interaction
        child: Center(
          child: CustomLoader(
            message: widget.message,
            backgroundColor: widget.backgroundColor,
            loaderColor: widget.loaderColor,
            size: widget.size,
            showBackground: widget.showBackground,
          ),
        ),
      ),
    );
  }
}

class CustomLoader extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color loaderColor;
  final double size;
  final bool showBackground;

  const CustomLoader({
    Key? key,
    required this.message,
    this.backgroundColor,
    required this.loaderColor,
    this.size = 56.0,
    this.showBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingAnimationWidget.staggeredDotsWave(
          color: loaderColor,
          size: 40,
        ),
        // Garde un espace constant pour éviter le mouvement vertical
        SizedBox(
          height: message.isNotEmpty ? 46 : 30, // Hauteur fixe totale
          child: message.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none, // Pas de soulignement
                    ),
                  ),
                )
              : null,
        ),
      ],
    );

    if (!showBackground) {
      return content;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}
