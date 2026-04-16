import 'package:flutter/material.dart';

/// 🎨 Palette de couleurs unifiée — Design System
class AppColors {
  AppColors._();

  // ================= PRINCIPALES =================

  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primarySurface = Color(0xFFE3F2FD);

  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);

  // ================= NEUTRES =================

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gris (scale complète)
  static const Color grey50 = Color(0xFFF8F9FA);
  static const Color grey100 = Color(0xFFF1F3F4);
  static const Color grey200 = Color(0xFFE8EAED);
  static const Color grey300 = Color(0xFFDADCE0);
  static const Color grey400 = Color(0xFFBDC1C6);
  static const Color grey500 = Color(0xFF9AA0A6);
  static const Color grey600 = Color(0xFF80868B);
  static const Color grey700 = Color(0xFF5F6368);
  static const Color grey800 = Color(0xFF3C4043);
  static const Color grey900 = Color(0xFF202124);

  // Noir avec opacité Material
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black38 = Color(0x61000000);
  static const Color black12 = Color(0x1F000000);

  // ================= FONCTIONNELLES =================

  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successSurface = Color(0xFFE8F5E8);

  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorSurface = Color(0xFFFFEBEE);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color warningSurface = Color(0xFFFFF3E0);

  static const Color info = Color(0xFF03A9F4);
  static const Color infoLight = Color(0xFF29B6F6);
  static const Color infoDark = Color(0xFF0288D1);
  static const Color infoSurface = Color(0xFFE1F5FE);

  // ================= PALETTE PERSONNALISÉE =================
  // Couleurs basées sur l'image fournie
  
  // Vert principal
  static const Color customGreen = Color(0xFF7CC54E);
  static const Color customGreenLight = Color(0xFF8FD966);
  static const Color customGreenDark = Color(0xFF6AB040);
  static const Color customGreenSurface = Color(0xFFF0F9E6);
  
  // Gris neutre
  static const Color customGrey = Color(0xFF888888);
  static const Color customGreyLight = Color(0xFF999999);
  static const Color customGreyDark = Color(0xFF777777);
  static const Color customGreySurface = Color(0xFFF5F5F5);
  
  // Orange vif
  static const Color customOrange = Color(0xFFF7B230);
  static const Color customOrangeLight = Color(0xFFF9C55C);
  static const Color customOrangeDark = Color(0xFFE5A028);
  static const Color customOrangeSurface = Color(0xFFFFF8E6);
  
  // Bleu clair
  static const Color customLightBlue = Color(0xFF30B2F7);
  static const Color customLightBlueLight = Color(0xFF5CC2F8);
  static const Color customLightBlueDark = Color(0xFF289CE0);
  static const Color customLightBlueSurface = Color(0xFFE6F7FF);
  
  // Orange foncé
  static const Color customDarkOrange = Color(0xFFEF6C30);
  static const Color customDarkOrangeLight = Color(0xFFF28455);
  static const Color customDarkOrangeDark = Color(0xFFD75A28);
  static const Color customDarkOrangeSurface = Color(0xFFFFF0E6);
  
  // Bleu foncé
  static const Color customDarkBlue = Color(0xFF306CB2);
  static const Color customDarkBlueLight = Color(0xFF5583C2);
  static const Color customDarkBlueDark = Color(0xFF285A9C);
  static const Color customDarkBlueSurface = Color(0xFFE6F0FF);

  // ================= BACKGROUND & SURFACE =================

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F0F0F);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLightGrey = Color(0xFF5F6368);

  // ================= TEXTE =================

  static const Color textPrimaryLight = Color(0xFF202124);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textTertiaryLight = Color(0xFF9AA0A6);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDC1C6);
  static const Color textTertiaryDark = Color(0xFF9AA0A6);

  // ================= BORDURES & DIVISEURS =================

  static const Color borderLight = Color(0xFFE8EAED);
  static const Color borderDark = Color(0xFF333333);

  static const Color dividerLight = Color(0xFFE8EAED);
  static const Color dividerDark = Color(0xFF333333);

  // ================= OMBRES =================

  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);


 /// Obtenir la couleur de fond pure pour l'AppBar selon le thème
  static Color getPureAppBarBackground(bool isDark) {
    return isDark ? pureBlack : pureWhite;
  }
  // ================= GRADIENTS =================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= GRADIENTS PERSONNALISÉS =================

  static const LinearGradient customGreenGradient = LinearGradient(
    colors: [customGreen, customGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient customGreyGradient = LinearGradient(
    colors: [customGrey, customGreyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient customOrangeGradient = LinearGradient(
    colors: [customOrange, customOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient customLightBlueGradient = LinearGradient(
    colors: [customLightBlue, customLightBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient customDarkOrangeGradient = LinearGradient(
    colors: [customDarkOrange, customDarkOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient customDarkBlueGradient = LinearGradient(
    colors: [customDarkBlue, customDarkBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= GRADIENTS COMPLÉMENTAIRES POUR BOUTONS =================

  static const LinearGradient infoGradient = LinearGradient(
    colors: [info, infoDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= COULEURS SPÉCIFIQUES AUX ÉCRANS =================
  
  // Orange principal (utilisé dans settings/establishment)
  static const Color screenOrange = Color(0xFFFF6B2C);
  static const Color screenOrangeLight = Color(0xFFFFF0E8);
  static const Color screenOrangeDark = Color(0xFFE55A2C);
  static const Color screenOrangeSurface = Color(0xFFFFF8F5);
  
  // Couleurs pour les écrans de boutique (verts et bleus)
  static const Color shopGreen = Color(0xFF4CAF50);
  static const Color shopGreenLight = Color(0xFF81C784);
  static const Color shopGreenDark = Color(0xFF388E3C);
  static const Color shopGreenSurface = Color(0xFFE8F5E8);
  
  static const Color shopBlue = Color(0xFF03A9F4);
  static const Color shopBlueLight = Color(0xFF29B6F6);
  static const Color shopBlueDark = Color(0xFF0288D1);
  static const Color shopBlueSurface = Color(0xFFE1F5FE);
  
  // Surface spécifique aux écrans
  static const Color screenSurface = Color(0xFFFFFFFF);
  static const Color screenCard = Color(0xFFFFFFFF);
  
  // Couleurs pour icônes de settings
  static const Color screenBlue = Color(0xFF2196F3);
  static const Color screenPurple = Color(0xFF9C27B0);
  static const Color screenGreen = Color(0xFF4CAF50);
  static const Color screenTextPrimary = Color(0xFF212121);
  static const Color screenTextSecondary = Color(0xFF757575);
  static const Color screenDivider = Color(0xFFE0E0E0);
  static const Color screenShadow = Color(0x1A000000);
  static const Color settingsRed = Color(0xFFF44336);
  static const Color settingsBrown = Color(0xFF795548);
  static const Color settingsGrey = Color(0xFF607D8B);
  static const Color settingsOrange = Color(0xFFFF6B2C);
  static const Color settingsBlue = Color(0xFF3B82F6);
  static const Color settingsGreen = Color(0xFF4CAF50);
  static const Color settingsPurple = Color(0xFF9C27B0);
  static const Color settingsAmber = Color(0xFFF59E0B);
  static const Color settingsCyan = Color(0xFF00BCD4);
  
  // Gris supplémentaire
  static const Color grey666 = Color(0xFF666666);
  
  // Ombres et gradients pour les écrans
  static const List<BoxShadow> screenCardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  
  static const LinearGradient screenOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF7A3C), screenOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= GRADIENTS POUR LES ÉCRANS DE BOUTIQUE =================

  static const LinearGradient shopGreenGradient = LinearGradient(
    colors: [shopGreen, shopGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shopBlueGradient = LinearGradient(
    colors: [shopBlue, shopBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shopMixedGradient = LinearGradient(
    colors: [shopBlue, shopGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= UTILITAIRES =================

  static const Color transparent = Color(0x00000000);

  static Color adaptiveColor({
    required Color lightColor,
    required Color darkColor,
    required bool isDark,
  }) {
    return isDark ? darkColor : lightColor;
  }

  static Color getBackgroundColor(bool isDark) =>
      adaptiveColor(
        lightColor: backgroundLight,
        darkColor: backgroundDark,
        isDark: isDark,
      );

  static Color getSurfaceColor(bool isDark) =>
      adaptiveColor(
        lightColor: surfaceLight,
        darkColor: surfaceDark,
        isDark: isDark,
      );

  static Color getBorderColor(bool isDark) =>
      adaptiveColor(
        lightColor: borderLight,
        darkColor: borderDark,
        isDark: isDark,
      );

  static Color getPureBackground(bool isDark) =>
      isDark ? pureBlack : pureWhite;

  static Color getTextColor(
    bool isDark, {
    TextType type = TextType.primary,
  }) {
    switch (type) {
      case TextType.primary:
        return adaptiveColor(
          lightColor: textPrimaryLight,
          darkColor: textPrimaryDark,
          isDark: isDark,
        );
      case TextType.secondary:
        return adaptiveColor(
          lightColor: textSecondaryLight,
          darkColor: textSecondaryDark,
          isDark: isDark,
        );
      case TextType.tertiary:
        return adaptiveColor(
          lightColor: textTertiaryLight,
          darkColor: textTertiaryDark,
          isDark: isDark,
        );
    }
  }

  // Opacity helpers
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);

  static Color blackWithOpacity(double opacity) =>
      Colors.black.withOpacity(opacity);

  static Color whiteWithOpacity(double opacity) =>
      Colors.white.withOpacity(opacity);
}

// ================= ENUM =================

enum TextType {
  primary,
  secondary,
  tertiary,
}

// ================= EXTENSIONS =================

extension ColorExtensions on Color {
  /// Surface douce (fond léger)
  Color toSurface() => withOpacity(0.1);

  /// Bordure colorée
  Color toBorder() => withOpacity(0.2);
}