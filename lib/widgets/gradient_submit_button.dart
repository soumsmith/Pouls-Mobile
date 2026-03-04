import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum SubmitButtonType {
  primary,
  success,
  recommendation,
  sponsorship,
  rating,
}

class GradientSubmitButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final SubmitButtonType type;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isLoading;
  final double borderRadius;

  const GradientSubmitButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = SubmitButtonType.primary,
    this.icon,
    this.width,
    this.height = 50,
    this.isLoading = false,
    this.borderRadius = 16,
  }) : super(key: key);

  LinearGradient get _gradient {
    switch (type) {
      case SubmitButtonType.primary:
        return AppColors.primaryGradient;
      case SubmitButtonType.success:
        return AppColors.successGradient;
      case SubmitButtonType.recommendation:
        return AppColors.customLightBlueGradient;
      case SubmitButtonType.sponsorship:
        return AppColors.customOrangeGradient;
      case SubmitButtonType.rating:
        return AppColors.warningGradient;
    }
  }

  Color get _baseColor {
    switch (type) {
      case SubmitButtonType.primary:
        return AppColors.primary;
      case SubmitButtonType.success:
        return AppColors.success;
      case SubmitButtonType.recommendation:
        return AppColors.customLightBlue;
      case SubmitButtonType.sponsorship:
        return AppColors.customOrange;
      case SubmitButtonType.rating:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? (text.length > 20 ? 220.0 : 200.0);
    
    return SizedBox(
      width: buttonWidth,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: _baseColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Widget simplifié pour les boutons d'envoi courants
class SendButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final SubmitButtonType type;
  final bool isLoading;

  const SendButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = SubmitButtonType.primary,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientSubmitButton(
      text: text,
      onPressed: onPressed,
      type: type,
      icon: Icons.send_rounded,
      isLoading: isLoading,
    );
  }
}

// Widget spécialisé pour les recommandations
class RecommendationSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const RecommendationSubmitButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientSubmitButton(
      text: 'Envoyer la recommandation',
      onPressed: onPressed,
      type: SubmitButtonType.recommendation,
      icon: Icons.send_rounded,
      width: 220,
      isLoading: isLoading,
    );
  }
}

// Widget spécialisé pour le parrainage
class SponsorshipSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SponsorshipSubmitButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientSubmitButton(
      text: 'Envoyer l\'invitation',
      onPressed: onPressed,
      type: SubmitButtonType.sponsorship,
      icon: Icons.send_rounded,
      width: 200,
      isLoading: isLoading,
    );
  }
}

// Widget spécialisé pour les avis/notations
class RatingSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const RatingSubmitButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientSubmitButton(
      text: 'Envoyer l\'avis',
      onPressed: onPressed,
      type: SubmitButtonType.rating,
      icon: Icons.send_rounded,
      width: 200,
      isLoading: isLoading,
    );
  }
}
