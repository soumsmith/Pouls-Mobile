import 'package:flutter/material.dart';
import 'dart:ui'; // Pour l'effet de verre
import '../components/bottom_spacer.dart';
import '../scroll_to_top_fab.dart';
import '../../config/app_colors.dart';

class ReusableBottomSheet extends StatefulWidget {
  final Widget content;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final double? imageBorderRadius;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onClose;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool useGlassEffect;
  final EdgeInsetsGeometry contentPadding;
  final bool showScrollToTopFab;
  final Widget? fixedBottomWidget;
  final bool wrapWithScrollView;
  final bool useDraggable;
  final bool useKeyboardPadding;

  const ReusableBottomSheet({
    super.key,
    required this.content,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    this.imageBorderRadius,
    this.iconColor,
    this.iconBackgroundColor,
    this.onClose,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
    this.useGlassEffect = false,
    this.contentPadding = const EdgeInsets.all(16),
    this.showScrollToTopFab = false,
    this.fixedBottomWidget,
    this.wrapWithScrollView = true,
    this.useDraggable = true,
    this.useKeyboardPadding = true,
  });

  @override
  State<ReusableBottomSheet> createState() => _ReusableBottomSheetState();

  /// Méthode statique utilitaire pour afficher facilement le BottomSheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget content,
    required String title,
    String? subtitle,
    IconData? icon,
    String? imagePath,
    double? imageBorderRadius,
    Color? iconColor,
    Color? iconBackgroundColor,
    VoidCallback? onClose,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool isDismissible = true,
    bool useGlassEffect = false,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(16),
    bool showScrollToTopFab = false,
    Widget? fixedBottomWidget,
    bool wrapWithScrollView = true,
    bool useDraggable = true,
    bool useKeyboardPadding = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled:
          true, // Permet au bottom sheet de prendre plus de place et gérer le clavier
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        final sheet = ReusableBottomSheet(
          content: content,
          title: title,
          subtitle: subtitle,
          icon: icon,
          imagePath: imagePath,
          imageBorderRadius: imageBorderRadius,
          iconColor: iconColor,
          iconBackgroundColor: iconBackgroundColor,
          onClose: onClose,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          useGlassEffect: useGlassEffect,
          contentPadding: contentPadding,
          showScrollToTopFab: showScrollToTopFab,
          fixedBottomWidget: fixedBottomWidget,
          wrapWithScrollView: wrapWithScrollView,
          useDraggable: useDraggable,
          useKeyboardPadding: useKeyboardPadding,
        );
        return useKeyboardPadding
            ? Padding(
                // padding bottom pour éviter que le clavier ne cache le contenu
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: sheet,
              )
            : sheet;
      },
    );
  }
}

class _ReusableBottomSheetState extends State<ReusableBottomSheet> {
  ScrollController? _localScrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.useDraggable) {
      _localScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _localScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useDraggable) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bgColor = AppColors.bottomSheetBg(context);

      Widget contentContainer = Container(
        height: MediaQuery.of(context).size.height * widget.initialChildSize,
        decoration: BoxDecoration(
          color: widget.useGlassEffect ? bgColor.withOpacity(0.85) : bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            _buildHeader(context),
            Divider(
              height: 1,
              thickness: 0.7,
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  widget.wrapWithScrollView
                      ? SingleChildScrollView(
                          controller: _localScrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: widget.contentPadding,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              widget.content,
                              if (!widget.useKeyboardPadding)
                                SizedBox(
                                  height: MediaQuery.of(context).viewInsets.bottom,
                                ),
                              const BottomSpacer(),
                            ],
                          ),
                        )
                      : Padding(
                          padding: widget.contentPadding,
                          child: widget.content,
                        ),
                  if (widget.showScrollToTopFab && widget.wrapWithScrollView)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: ScrollToTopFab(
                        scrollController: _localScrollController!,
                        useGlassEffect: widget.useGlassEffect,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.fixedBottomWidget != null) widget.fixedBottomWidget!,
          ],
        ),
      );

      if (widget.useGlassEffect) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: contentContainer,
          ),
        );
      }

      return contentContainer;
    }

    // Utilisation de DraggableScrollableSheet pour rendre le bottom sheet adaptatif
    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      expand:
          false, // Important : permet au sheet de s'adapter au contenu si possible
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = AppColors.bottomSheetBg(context);

        Widget contentContainer = Container(
          decoration: BoxDecoration(
            color: widget.useGlassEffect ? bgColor.withOpacity(0.85) : bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(context),
              Divider(
                height: 1,
                thickness: 0.7,
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    widget.wrapWithScrollView
                        ? SingleChildScrollView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: widget.contentPadding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                widget.content, // Le contenu dynamique passé en paramètre
                                if (!widget.useKeyboardPadding)
                                  SizedBox(
                                    height: MediaQuery.of(context).viewInsets.bottom,
                                  ),
                                const BottomSpacer(),
                              ],
                            ),
                          )
                        : Padding(
                            padding: widget.contentPadding,
                            child: widget.content,
                          ),
                    if (widget.showScrollToTopFab && widget.wrapWithScrollView)
                      Positioned(
                        right: 16,
                        bottom: 24,
                        child: ScrollToTopFab(
                          scrollController: scrollController,
                          useGlassEffect: widget.useGlassEffect,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.fixedBottomWidget != null) widget.fixedBottomWidget!,
            ],
          ),
        );

        if (widget.useGlassEffect) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: contentContainer,
            ),
          );
        }

        return contentContainer;
      },
    );
  }

  // Petit indicateur visuel en haut pour montrer que c'est glissable
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // L'en-tête dynamique
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightGrayBg = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône ou Image dynamique
          if (widget.imagePath != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lightGrayBg,
                borderRadius: BorderRadius.circular(widget.imageBorderRadius ?? 12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  (widget.imageBorderRadius ?? 12.0) > 4
                      ? (widget.imageBorderRadius ?? 12.0) - 4
                      : 4,
                ),
                child: Image.asset(
                  widget.imagePath!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else if (widget.icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    widget.iconBackgroundColor ??
                    Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
          const SizedBox(width: 20),
          // Textes (Titre et sous-titre)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Bouton de fermeture
          Container(
            decoration: BoxDecoration(
              color: lightGrayBg,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey[500],
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: () {
                if (widget.onClose != null) {
                  widget.onClose!();
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
