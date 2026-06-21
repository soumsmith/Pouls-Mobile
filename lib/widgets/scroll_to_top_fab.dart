import 'package:flutter/material.dart';
import 'dart:ui';
import 'components/bottom_spacer.dart';
import '../config/app_dimensions.dart';

class ScrollToTopFab extends StatefulWidget {
  final ScrollController scrollController;
  final double showOffset;
  final double bottomSpacerHeight;
  final bool isScrollToTop;
  final bool useGlassEffect;

  const ScrollToTopFab({
    Key? key,
    required this.scrollController,
    this.showOffset = 200.0,
    this.bottomSpacerHeight = 40.0,
    this.isScrollToTop = true,
    this.useGlassEffect = false,
  }) : super(key: key);

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (widget.scrollController.hasClients) {
      if (widget.isScrollToTop) {
        if (widget.scrollController.offset >= widget.showOffset && !_showFab) {
          setState(() {
            _showFab = true;
          });
        } else if (widget.scrollController.offset < widget.showOffset &&
            _showFab) {
          setState(() {
            _showFab = false;
          });
        }
      } else {
        final maxScroll = widget.scrollController.position.maxScrollExtent;
        if (widget.scrollController.offset < maxScroll - widget.showOffset && !_showFab) {
          setState(() {
            _showFab = true;
          });
        } else if (widget.scrollController.offset >= maxScroll - widget.showOffset && _showFab) {
          setState(() {
            _showFab = false;
          });
        }
      }
    }
  }

  void _performAction() {
    if (widget.scrollController.hasClients) {
      final target = widget.isScrollToTop ? 0.0 : widget.scrollController.position.maxScrollExtent;
      widget.scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget fab = FloatingActionButton(
      mini: true,
      elevation: 0,
      highlightElevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      disabledElevation: 0,
      onPressed: _performAction,
      backgroundColor: widget.useGlassEffect
          ? (isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white.withOpacity(0.6))
          : (isDarkMode ? Colors.grey[800] : Colors.white),
      foregroundColor: Theme.of(context).primaryColor,
      shape: const CircleBorder(
        side: BorderSide.none,
      ),
      child: Icon(widget.isScrollToTop ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
    );

    if (widget.useGlassEffect) {
      fab = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: fab,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.useGlassEffect 
                  ? null 
                  : AppDimensions.getBottomSheetShadow(context),
            ),
            child: fab,
          ),
        ),
        BottomSpacer(height: widget.bottomSpacerHeight),
      ],
    );
  }
}
