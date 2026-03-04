import 'package:flutter/material.dart';

class AppDimensions {
  // Private constructor pour empêcher l'instanciation
  AppDimensions._();

  // Breakpoints pour les différents types d'appareils
  static const double mobileBreakpoint = 600.0;
  static const double smallTabletBreakpoint = 700.0; // iPad Mini
  static const double tabletBreakpoint = 768.0;
  static const double largeTabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;

  // Dimensions générales
  static const double defaultPadding = 24.0;
  static const double defaultMargin = 16.0;
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  // Dimensions pour les cartes
  static const double cardElevation = 4.0;
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double cardBorderRadius = 12.0;

  // Dimensions pour les boutons
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonBorderRadiusXS = 8.0;
  static const double buttonBorderRadius = 16.0;
  static const double buttonBorderRadiusL = 32.0;
  static const double buttonPadding = 16.0;
  static const double buttonPaddingHorizontal = 24.0;
  static const double buttonPaddingVertical = 12.0;

  // Dimensions pour les champs de texte
  static const double textFieldHeight = 56.0;
  static const double textFieldBorderRadius = 8.0;
  static const double textFieldPadding = 16.0;

  // Dimensions pour les espacements
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Méthodes utilitaires pour obtenir les dimensions selon le contexte
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallTabletBreakpoint && width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < largeTabletBreakpoint;
  }

  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largeTabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Méthodes pour obtenir des dimensions adaptatives
  static double getAdaptivePadding(BuildContext context) {
    if (isMobile(context)) {
      return defaultPadding;
    } else if (isSmallTablet(context)) {
      return defaultPadding * 1.2; // iPad Mini - padding intermédiaire réduit
    } else if (isTablet(context)) {
      return defaultPadding * 1.5;
    } else {
      return defaultPadding * 2;
    }
  }

  static double getAdaptiveContainerPadding(BuildContext context) {
    if (isMobile(context)) {
      return spacingM;
    } else if (isSmallTablet(context)) {
      return (spacingM + spacingL) / 2; // iPad Mini - padding intermédiaire
    } else if (isTablet(context)) {
      return spacingL;
    } else {
      return spacingXL;
    }
  }

  static double getAdaptiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return spacingM;
    } else if (isSmallTablet(context)) {
      return (spacingM + spacingL) / 2; // iPad Mini - espacement intermédiaire
    } else if (isTablet(context)) {
      return spacingL;
    } else {
      return spacingXL;
    }
  }

  static double getAdaptiveIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 64.0;
    } else if (isSmallTablet(context)) {
      return 80.0; // iPad Mini - icône intermédiaire
    } else if (isTablet(context)) {
      return 96.0;
    } else {
      return 112.0;
    }
  }

  // Dimensions pour les cartes de connexion
  static double getLoginCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth - (defaultPadding * 2);
    } else if (isSmallTablet(context)) {
      return screenWidth * 0.7; // iPad Mini - largeur intermédiaire
    } else if (isTablet(context)) {
      return screenWidth * 0.6;
    } else {
      return screenWidth * 0.4;
    }
  }

  static double getLoginCardMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else {
      return 500.0;
    }
  }

  // Dimensions pour les formulaires
  static double getFormTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isSmallTablet(context)) {
      return 28.0; // iPad Mini - police intermédiaire
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 36.0;
    }
  }

  static double getFormSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0;
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini - police intermédiaire
    } else {
      return 18.0;
    }
  }

  static double getFormFieldSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 32.0;
    } else if (isSmallTablet(context)) {
      return 40.0; // iPad Mini - espacement intermédiaire
    } else if (isTablet(context)) {
      return 48.0;
    } else {
      return 56.0;
    }
  }

  // Dimensions pour le contenu responsive
  static double getResponsiveWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth;
    } else if (isSmallTablet(context)) {
      return screenWidth * 0.8;
    } else if (isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return screenWidth * 0.6;
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return const EdgeInsets.all(24.0);
    } else if (isSmallTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.15,
        vertical: 40.0,
      );
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.2,
        vertical: 48.0,
      );
    } else {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.25,
        vertical: 56.0,
      );
    }
  }


  static EdgeInsets getHomePageResponsivePadding(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return const EdgeInsets.all(0);
    } else if (isSmallTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: 0 ,//screenWidth * 0.15,
        vertical: 40.0,
      );
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: 0, //screenWidth * 0.2
        vertical: 48.0,
      );
    } else {
      return EdgeInsets.symmetric(
        horizontal:  0 ,// screenWidth * 0.25,
        vertical: 56.0,
      );
    }
  }

  // Dimensions pour les marges de sécurité (safe areas)
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Dimensions pour le contenu scrollable
  static double getMaxContentHeight(BuildContext context) {
    final screenHeight = getScreenHeight(context);
    final safeAreaPadding = getSafeAreaPadding(context);
    return screenHeight - safeAreaPadding.top - safeAreaPadding.bottom;
  }

  // Dimensions pour le splash screen
  static double getSplashLogoSize(BuildContext context) {
    if (isMobile(context)) {
      return 140.0;
    } else if (isSmallTablet(context)) {
      return 180.0; // iPad Mini - logo intermédiaire
    } else if (isTablet(context)) {
      return 220.0;
    } else {
      return 260.0;
    }
  }

  static double getSplashTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 24.0;
    } else if (isSmallTablet(context)) {
      return 28.0; // iPad Mini - police intermédiaire
    } else if (isTablet(context)) {
      return 32.0;
    } else {
      return 36.0;
    }
  }

  static double getSplashSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isSmallTablet(context)) {
      return 18.0; // iPad Mini - police intermédiaire
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 22.0;
    }
  }
}
