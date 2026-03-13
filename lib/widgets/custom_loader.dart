import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
