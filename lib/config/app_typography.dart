import 'package:flutter/material.dart';
import '../services/text_size_service.dart';

/// Constantes de typographie standardisées pour toute l'application
class AppTypography {
  static final TextSizeService _textSizeService = TextSizeService();

  // Tailles de police principales (scalables)
  static double get displayLarge => _textSizeService.getScaledFontSize(32);
  static double get displayMedium => _textSizeService.getScaledFontSize(28);
  static double get displaySmall => _textSizeService.getScaledFontSize(24);
  
  static double get headlineLarge => _textSizeService.getScaledFontSize(22);
  static double get headlineMedium => _textSizeService.getScaledFontSize(20);
  static double get headlineSmall => _textSizeService.getScaledFontSize(18);
  
  static double get titleLarge => _textSizeService.getScaledFontSize(18);
  static double get titleMedium => _textSizeService.getScaledFontSize(16);
  static double get titleSmall => _textSizeService.getScaledFontSize(14);
  
  static double get bodyLarge => _textSizeService.getScaledFontSize(16);
  static double get bodyMedium => _textSizeService.getScaledFontSize(14);
  static double get bodySmall => _textSizeService.getScaledFontSize(12);
  
  static double get labelLarge => _textSizeService.getScaledFontSize(14);
  static double get labelMedium => _textSizeService.getScaledFontSize(12);
  static double get labelSmall => _textSizeService.getScaledFontSize(10);

  // Poids de police standardisés
  static const FontWeight displayWeight = FontWeight.w700;
  static const FontWeight headlineWeight = FontWeight.w600;
  static const FontWeight titleWeight = FontWeight.w600;
  static const FontWeight bodyWeight = FontWeight.w400;
  static const FontWeight labelWeight = FontWeight.w500;

  // Styles pré-définis
  static TextStyle get appBarTitle => TextStyle(
    fontSize: headlineMedium,
    fontWeight: headlineWeight,
  );

  static TextStyle get cardTitle => TextStyle(
    fontSize: titleMedium,
    fontWeight: titleWeight,
  );

  static TextStyle get cardSubtitle => TextStyle(
    fontSize: bodySmall,
    fontWeight: bodyWeight,
  );

  static TextStyle get buttonText => TextStyle(
    fontSize: labelLarge,
    fontWeight: titleWeight,
  );

  static TextStyle get caption => TextStyle(
    fontSize: labelSmall,
    fontWeight: bodyWeight,
  );

  static TextStyle get overline => TextStyle(
    fontSize: labelSmall,
    fontWeight: labelWeight,
  );
}
