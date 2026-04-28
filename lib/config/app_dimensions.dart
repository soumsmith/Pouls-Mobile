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

  // Dimensions pour les boutons d'action (header)
  static double getActionButtonSize(BuildContext context) {
    if (isMobile(context)) {
      return 40.0; // Mobile : taille standard
    } else if (isSmallTablet(context)) {
      return 44.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 48.0; // iPad : taille plus grande
    } else {
      return 52.0; // Desktop : taille maximum
    }
  }

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
  // Utilisent la plus petite dimension pour éviter les problèmes en mode paysage
  static bool isMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallestDimension = size.width < size.height ? size.width : size.height;
    return smallestDimension < mobileBreakpoint;
  }

  static bool isSmallTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallestDimension = size.width < size.height ? size.width : size.height;
    return smallestDimension >= smallTabletBreakpoint && smallestDimension < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallestDimension = size.width < size.height ? size.width : size.height;
    return smallestDimension >= tabletBreakpoint && smallestDimension < largeTabletBreakpoint;
  }

  static bool isLargeTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallestDimension = size.width < size.height ? size.width : size.height;
    return smallestDimension >= largeTabletBreakpoint && smallestDimension < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallestDimension = size.width < size.height ? size.width : size.height;
    return smallestDimension >= desktopBreakpoint;
  }

  // Méthodes utilitaires pour l'orientation de l'écran
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Méthodes pour détecter la résolution exacte des mobiles
  static int getMobileColumnsByResolution(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = isPortrait(context) ? size.width : size.height; // Utiliser la largeur en portrait
    
    if (isMobile(context)) {
      if (width < 360) {
        return 2; // Petits téléphones (ex: iPhone SE, anciens Android)
      } else if (width < 400) {
        return 2; // Téléphones standards (ex: iPhone 12/13 mini)
      } else {
        return 2; // Grands téléphones (ex: iPhone Pro Max, Galaxy S Ultra)
      }
    }
    return 3; // Valeur par défaut si ce n'est pas un mobile
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

  // Dimensions pour les cartes de produits (flex ratio image/texte)
  // Pour le composant ImageMenuCardExternalTitle
  static double getProductCardImageFlex(BuildContext context) {
    if (isMobile(context)) {
      if (isLandscape(context)) {
        return 3.0; // Mobile paysage : image plus petite pour optimiser l'espace horizontal
      } else {
        return 3.0; // Mobile portrait : image plus grande pour meilleure visibilité
      }
    } else if (isSmallTablet(context)) {
      if (isLandscape(context)) {
        return 5.0; // iPad Mini paysage : image réduite
      } else {
        return 4.0; // iPad Mini portrait : équilibré
      }
    } else if (isTablet(context)) {
      if (isLandscape(context)) {
        return 3.0; // iPad paysage : image réduite
      } else {
        return 4.0; // iPad portrait : équilibré
      }
    } else {
      if (isLandscape(context)) {
        return 3.0; // Desktop paysage : image réduite
      } else {
        return 4.0; // Desktop portrait : équilibré
      }
    }
  }

  // Pour le calcul du ratio de la grille selon le nombre de colonnes
  /// Plus il y a de colonnes, plus l'image est réduite pour optimiser l'espace
  static int getGridImageFlex(BuildContext context) {
    final columns = getEcolesGridColumns(context);
    
    if (isMobile(context)) {
      if (isLandscape(context)) {
        // Mobile paysage : image selon nombre de colonnes
        switch (columns) {
          case 5: return 3; // 5 colonnes : image très réduite
          case 4: return 3; // 4 colonnes : image réduite
          case 3: return 2; // 3 colonnes : image modérément réduite
          case 2: return 5; // 2 colonnes : image standard
          default: return 4;
        }
      } else {
        // Mobile portrait : image selon nombre de colonnes
        switch (columns) {
          case 3: return 5; // 3 colonnes : image standard
          case 2: return 6; // 2 colonnes : image plus grande
          default: return 5;
        }
      }
    } else if (isSmallTablet(context)) {
      if (isLandscape(context)) {
        // iPad Mini paysage
        switch (columns) {
          case 5: return 2; // 5 colonnes : image très réduite
          case 4: return 3; // 4 colonnes : image réduite
          default: return 3;
        }
      } else {
        // iPad Mini portrait
        switch (columns) {
          case 4: return 4; // 4 colonnes : image standard
          default: return 4;
        }
      }
    } else if (isTablet(context)) {
      if (isLandscape(context)) {
        // iPad paysage
        switch (columns) {
          case 6: return 3; // 6 colonnes : image réduite
          case 5: return 4; // 5 colonnes : image standard
          default: return 4;
        }
      } else {
        // iPad portrait
        switch (columns) {
          case 5: return 5; // 5 colonnes : image confortable
          default: return 5;
        }
      }
    } else {
      // Desktop
      if (isLandscape(context)) {
        switch (columns) {
          case 8: return 4; // 8 colonnes : image réduite
          case 6: return 5; // 6 colonnes : image standard
          default: return 5;
        }
      } else {
        switch (columns) {
          case 6: return 6; // 6 colonnes : image grande
          default: return 6;
        }
      }
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
        horizontal: 0, //screenWidth * 0.15,
        vertical: 40.0,
      );
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: 0, //screenWidth * 0.2
        vertical: 48.0,
      );
    } else {
      return EdgeInsets.symmetric(
        horizontal: 0, // screenWidth * 0.25,
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

  // ── DIMENSIONS POUR LA PAGINATION ───────────────────────────────────

  /// Nombre d'éléments par page selon le type d'appareil
  static int getEventsPerPage(BuildContext context) {
    if (isMobile(context)) {
      return 4; // Mobile : moins d'éléments pour optimiser l'espace
    } else if (isSmallTablet(context)) {
      return 6; // iPad Mini : équilibre performance/visibilité
    } else if (isTablet(context)) {
      return 8; // iPad : écran plus grand, plus d'éléments
    } else {
      return 12; // Desktop : écran large, maximum d'éléments
    }
  }

  /// Taille de l'image des événements selon l'appareil
  static double getEventImageSize(BuildContext context) {
    if (isMobile(context)) {
      return 70.0; // Mobile : plus petit pour économiser l'espace
    } else if (isSmallTablet(context)) {
      return 80.0; // iPad Mini : taille intermédiaire
    } else if (isTablet(context)) {
      return 90.0; // iPad : taille standard
    } else {
      return 100.0; // Desktop : taille plus grande
    }
  }

  /// Padding interne des cartes d'événements selon l'appareil
  static double getEventCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : padding intermédiaire
    } else if (isTablet(context)) {
      return 16.0; // iPad : padding standard
    } else {
      return 20.0; // Desktop : padding plus généreux
    }
  }

  /// Espacement entre les cartes d'événements selon l'appareil
  static double getEventCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : très compact
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : espacement standard
    } else if (isTablet(context)) {
      return 10.0; // iPad : espacement plus généreux
    } else {
      return 12.0; // Desktop : espacement maximum
    }
  }

  /// Taille de police pour le titre des événements selon l'appareil
  static double getEventTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 15.0; // iPad Mini : taille intermédiaire
    } else if (isTablet(context)) {
      return 16.0; // iPad : taille standard
    } else {
      return 18.0; // Desktop : taille plus grande
    }
  }

  /// Taille de police pour le sous-titre des événements selon l'appareil
  static double getEventSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 13.0; // iPad : standard
    } else {
      return 14.0; // Desktop : taille normale
    }
  }

  // ── DIMENSIONS POUR LA PAGINATION DES ÉCOLES ────────────────────────

  /// Nombre d'écoles par page selon le type d'appareil
  static int getEcolesPerPage(BuildContext context) {
    if (isMobile(context)) {
      return 6; // Mobile : optimisé pour performance et espace
    } else if (isSmallTablet(context)) {
      return 9; // iPad Mini : équilibre performance/visibilité
    } else if (isTablet(context)) {
      return 12; // iPad : écran plus grand, plus d'écoles
    } else {
      return 16; // Desktop : écran large, maximum d'écoles
    }
  }

  /// Espacement entre les cartes d'écoles selon l'appareil
  static double getEcoleCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : très compact
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : compact
    } else if (isTablet(context)) {
      return 10.0; // iPad : espacement modéré
    } else {
      return 12.0; // Desktop : espacement standard
    }
  }

  /// Padding interne des cartes d'écoles selon l'appareil
  static double getEcoleCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : padding intermédiaire
    } else if (isTablet(context)) {
      return 16.0; // iPad : padding standard
    } else {
      return 20.0; // Desktop : padding plus généreux
    }
  }

  /// Taille de police pour le nom des écoles selon l'appareil
  static double getEcoleTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 15.0; // iPad Mini : taille intermédiaire
    } else if (isTablet(context)) {
      return 16.0; // iPad : taille standard
    } else {
      return 18.0; // Desktop : taille plus grande
    }
  }

  /// Taille de police pour le type des écoles selon l'appareil
  static double getEcoleTypeFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 13.0; // iPad : standard
    } else {
      return 14.0; // Desktop : taille normale
    }
  }

  /// Nombre de colonnes pour la grille d'écoles selon l'appareil et l'orientation
  static int getEcolesGridColumns(BuildContext context) {
    if (isMobile(context)) {
      if (isPortrait(context)) {
        return getMobileColumnsByResolution(context); // Mobile portrait : selon la résolution
      } else {
        return 5; // Mobile paysage : 5 colonnes
      }
    } else if (isSmallTablet(context)) {
      if (isPortrait(context)) {
        return 4; // iPad Mini portrait : 4 colonnes
      } else {
        return 5; // iPad Mini paysage : 5 colonnes
      }
    } else if (isTablet(context)) {
      if (isPortrait(context)) {
        return 5; // iPad portrait : 5 colonnes
      } else {
        return 6; // iPad paysage : 6 colonnes
      }
    } else {
      if (isPortrait(context)) {
        return 6; // Desktop portrait : 6 colonnes
      } else {
        return 8; // Desktop paysage : 8 colonnes
      }
    }
  }

  // ── DIMENSIONS POUR LES ARRONDIS DES CARTES ────────────────────────────────

  /// Rayon de bordure pour les petites cartes selon l'appareil
  static double getSmallCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 50.0; // 15.0 Mobile : coins légèrement arrondis
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 12.0; // iPad : arrondis standards
    } else {
      return 14.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les cartes moyennes selon l'appareil
  static double getMediumCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 16.0; // iPad : arrondis standards
    } else {
      return 18.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les grandes cartes selon l'appareil
  static double getLargeCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 16.0; // Mobile : arrondis notables
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 24.0; // iPad : arrondis prononcés
    } else {
      return 28.0; // Desktop : arrondis maximum
    }
  }

  /// Rayon de bordure pour les cartes hero (bannière) selon l'appareil
  static double getHeroCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 20.0; // Mobile : arrondis importants
    } else if (isSmallTablet(context)) {
      return 24.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 28.0; // iPad : arrondis prononcés
    } else {
      return 32.0; // Desktop : arrondis maximum
    }
  }

  /// Rayon de bordure pour les boutons selon l'appareil
  static double getButtonBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 50.0; // 8.0 Mobile : coins légèrement arrondis
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 12.0; // iPad : arrondis standards
    } else {
      return 14.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les champs de texte selon l'appareil
  static double getTextFieldBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : coins légèrement arrondis
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 12.0; // iPad : arrondis standards
    } else {
      return 14.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les icônes conteneurs selon l'appareil
  static double getIconContainerBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : très légers arrondis
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 9.0; // iPad : arrondis standards
    } else {
      return 10.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les badges selon l'appareil
  static double getBadgeBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 14.0; // iPad : arrondis standards
    } else {
      return 16.0; // Desktop : arrondis plus prononcés
    }
  }

  /// Rayon de bordure pour les conteneurs de filtre selon l'appareil
  static double getFilterContainerBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : arrondis intermédiaires
    } else if (isTablet(context)) {
      return 16.0; // iPad : arrondis standards
    } else {
      return 18.0; // Desktop : arrondis plus prononcés
    }
  }

  // ── DIMENSIONS POUR LES CARTES DE MENU HORIZONTAL ────────────────────────────

  /// Hauteur des cartes de menu horizontal selon l'appareil et l'orientation
  static double getHorizontalMenuCardHeight(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    if (isMobile(context)) {
      // Pour mobile, différencier portrait et paysage
      return orientation == Orientation.portrait ? 120.0 : 120.0;
    } else if (isSmallTablet(context)) {
      return 150.0; // iPad Mini : hauteur intermédiaire
    } else if (isTablet(context)) {
      return 150.0; // iPad : hauteur standard
    } else {
      return 150.0; // Desktop : hauteur plus généreuse
    }
  }

  /// Largeur des cartes de menu horizontal selon l'appareil
  static double getHorizontalMenuCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return 120.0; // Mobile : plus étroit
    } else if (isSmallTablet(context)) {
      return 150.0; // iPad Mini : largeur intermédiaire
    } else if (isTablet(context)) {
      return 150.0; // iPad : largeur standard
    } else {
      return 150.0; // Desktop : largeur plus généreuse
    }
  }

  /// Espacement entre les cartes de menu horizontal selon l'appareil
  static double getHorizontalMenuCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 0.0; // Mobile : très compact
    } else if (isSmallTablet(context)) {
      return 6.0; // iPad Mini : espacement réduit
    } else if (isTablet(context)) {
      return 0.0; // iPad : espacement standard
    } else {
      return 10.0; // Desktop : espacement modéré
    }
  }

  // ── CONFIGURATION GLOBALE POUR LES APP BARS ────────────────────────────────

  /// Configuration globale pour le centrage du titre dans les AppBars
  /// Changez cette valeur pour affecter toutes les AppBars du projet
  static bool getGlobalAppBarCenterTitle() => false;

  /// Permet de vérifier si le centrage du titre doit être appliqué globalement
  static bool shouldCenterAppBarTitle({bool? overrideValue}) {
    // Si une valeur de remplacement est fournie, l'utiliser
    if (overrideValue != null) return overrideValue;
    // Sinon, utiliser la configuration globale
    return getGlobalAppBarCenterTitle();
  }

// ── DIMENSIONS POUR LES OMBRES ────────────────────────────────────────────────

  /// Valeur de l'alpha pour les ombres principales (cartes importantes)
  static double getMainShadowAlpha(BuildContext context) {
    return isDarkMode(context) ? 0.4 : 0.1;
  }

  /// Valeur de l'alpha pour les ombres légères (cartes secondaires)
  static double getLightShadowAlpha(BuildContext context) {
    return isDarkMode(context) ? 0.15 : 0.02;
  }

  /// Valeur de l'alpha pour les ombres très légères (éléments subtils)
  static double getSubtleShadowAlpha(BuildContext context) {
    return isDarkMode(context) ? 0.08 : 0.01;
  }

  /// Rayon de flou pour les ombres principales
  static double getMainShadowBlur() => 20.0;

  /// Rayon de flou pour les ombres légères
  static double getLightShadowBlur() => 6.0;

  /// Rayon de flou pour les ombres très légères
  static double getSubtleShadowBlur() => 3.0;

  /// Décalage vertical pour les ombres principales
  static double getMainShadowOffset() => 8.0;

  /// Décalage vertical pour les ombres légères
  static double getLightShadowOffset() => 2.0;

  /// Décalage vertical pour les ombres très légères
  static double getSubtleShadowOffset() => 1.0;

  /// Vérifie si le mode sombre est activé
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Crée une ombre principale complète
  static List<BoxShadow> getMainShadow(
    BuildContext context, {
    bool enabled = true,
  }) {
    if (!enabled) return [];

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: getMainShadowAlpha(context)),
        blurRadius: getMainShadowBlur(),
        offset: Offset(0, getMainShadowOffset()),
      ),
    ];
  }

  /// Crée une ombre légère complète
  static List<BoxShadow> getLightShadow(
    BuildContext context, {
    bool enabled = true,
  }) {
    if (!enabled) return [];

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: getLightShadowAlpha(context)),
        blurRadius: getLightShadowBlur(),
        offset: Offset(0, getLightShadowOffset()),
      ),
    ];
  }

  /// Crée une ombre très légère complète
  static List<BoxShadow> getSubtleShadow(
    BuildContext context, {
    bool enabled = true,
  }) {
    if (!enabled) return [];

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: getSubtleShadowAlpha(context)),
        blurRadius: getSubtleShadowBlur(),
        offset: Offset(0, getSubtleShadowOffset()),
      ),
    ];
  }

  /// Crée une ombre personnalisée
  static List<BoxShadow> getCustomShadow({
    required BuildContext context,
    double? alpha,
    double? blurRadius,
    double? offset,
    bool enabled = true,
  }) {
    if (!enabled) return [];

    return [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: alpha ?? getLightShadowAlpha(context),
        ),
        blurRadius: blurRadius ?? getLightShadowBlur(),
        offset: Offset(0, offset ?? getLightShadowOffset()),
      ),
    ];
  }

  // ── DIMENSIONS POUR LES CARTES D'ÉCOLES ──────────────────────────────────

  /// Taille de police pour le titre de la carte d'école selon l'appareil
  static double getEcoleCardTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : taille intermédiaire
    } else if (isTablet(context)) {
      return 12.0; // iPad : taille standard
    } else {
      return 13.0; // Desktop : plus grand
    }
  }

  /// Taille de police pour le sous-titre (adresse) de la carte d'école
  static double getEcoleCardSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 9.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 10.0; // iPad : petit
    } else {
      return 11.0; // Desktop : standard
    }
  }

  /// Taille de police pour le type d'école (badge)
  static double getEcoleCardTypeFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 9.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 9.0; // iPad : petit
    } else {
      return 10.0; // Desktop : standard
    }
  }

  /// Hauteur dynamique pour les cartes d'établissements selon le nombre d'éléments par ligne
  static double getEcoleCardHeight(BuildContext context) {
    final columns = getEcolesGridColumns(context);
    
    if (isMobile(context)) {
      // Mobile : hauteur selon le nombre de colonnes
      switch (columns) {
        case 2:
          return 190.0; // 2 colonnes : hauteur standard pour bonne lisibilité
        case 3:
          return 160.0; // 3 colonnes : hauteur réduite pour optimiser l'espace
        default:
          return 190.0; // Par défaut : hauteur standard
      }
    } else if (isSmallTablet(context)) {
      // iPad Mini : hauteur selon le nombre de colonnes
      switch (columns) {
        case 4:
          return 160.0; // 4 colonnes : hauteur modérée
        case 5:
          return 140.0; // 5 colonnes : hauteur réduite
        default:
          return 160.0;
      }
    } else if (isTablet(context)) {
      // iPad : hauteur selon le nombre de colonnes
      switch (columns) {
        case 5:
          return 150.0; // 5 colonnes : hauteur équilibrée
        case 6:
          return 130.0; // 6 colonnes : hauteur optimisée
        default:
          return 150.0;
      }
    } else {
      // Desktop : hauteur selon le nombre de colonnes
      switch (columns) {
        case 6:
          return 140.0; // 6 colonnes : hauteur confortable
        case 8:
          return 120.0; // 8 colonnes : hauteur compacte
        default:
          return 140.0;
      }
    }
  }

  /// Rayon de bordure pour la carte d'école selon l'appareil
  static double getEcoleCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 14.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : arrondis standards
    } else if (isTablet(context)) {
      return 18.0; // iPad : arrondis prononcés
    } else {
      return 20.0; // Desktop : arrondis très prononcés
    }
  }

  /// Espacement intérieur de la zone d'info de la carte d'école selon l'appareil
  static double getEcoleCardInfoPadding(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : espacement réduit
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : espacement intermédiaire
    } else if (isTablet(context)) {
      return 11.0; // iPad : espacement standard
    } else {
      return 12.0; // Desktop : espacement plus grand
    }
  }

  /// Taille de l'icône de localisation selon l'appareil
  static double getEcoleCardIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 11.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 11.0; // iPad : petit
    } else {
      return 12.0; // Desktop : standard
    }
  }

  /// Hauteur du gradient en bas de l'image selon l'appareil
  static double getEcoleCardGradientHeight(BuildContext context) {
    if (isMobile(context)) {
      return 40.0; // Mobile : plus court
    } else if (isSmallTablet(context)) {
      return 48.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 48.0; // iPad : standard
    } else {
      return 56.0; // Desktop : plus haut
    }
  }

  /// Taille du badge de type selon l'appareil
  static double getEcoleCardBadgePadding(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 8.0; // iPad : petit
    } else {
      return 10.0; // Desktop : standard
    }
  }

  /// Taille de l'indicateur de statut (cercle vert) selon l'appareil
  static double getEcoleCardStatusIndicatorSize(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 8.0; // iPad : petit
    } else {
      return 10.0; // Desktop : standard
    }
  }

  // ── MÉTHODES RESPONSIVES POUR LA GRILLE D'ÉCOLES ────────────────────

  /// Ratio d'aspect pour les cartes d'écoles selon le nombre de colonnes
  static double getEcolesGridChildAspectRatio(BuildContext context) {
    final crossAxisCount = getEcolesGridColumns(context);

    // Ajuster le ratio selon le nombre de colonnes
    switch (crossAxisCount) {
      case 2: // Mobile
        return 0.65; // Format vertical pour mobile
      case 4: // Petite tablette
        return 0.75; // Format équilibré
      case 5: // Grande tablette
        return 0.8; // Format légèrement plus large
      default: // Desktop (6+ colonnes)
        return 0.85; // Format large pour desktop
    }
  }

  // ── MÉTHODES RESPONSIVES POUR LA GRILLE DE PRODUITS ────────────────────

  /// Nombre de colonnes pour la grille de produits selon l'appareil
  static int getProductsGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 3; // Mobile : 3 colonnes
    } else if (isSmallTablet(context)) {
      return 3; // iPad Mini : 3 colonnes
    } else if (isTablet(context)) {
      return 4; // iPad : 4 colonnes
    } else {
      return 4; // Desktop : 4 colonnes
    }
  }

  /// Ratio d'aspect dynamique pour les cartes de produits selon imageFlex et l'orientation
  /// Calcule le ratio proportionnellement à imageFlex pour un design équilibré
  static double getProductsGridChildAspectRatio(BuildContext context, {int imageFlex = 7}) {
    final orientation = MediaQuery.of(context).orientation;
    
    // BaseRatio dynamique calculé en fonction de imageFlex et de l'orientation
    double baseRatio;
    if (isMobile(context)) {
      if (orientation == Orientation.portrait) {
        // Mode portrait : imageFlex: 4 = ratio plus compact
        baseRatio = 0.25 * imageFlex; // imageFlex: 4 = 1.0
      } else {
        // Mode paysage : imageFlex: 4 = ratio plus large
        baseRatio = 0.35 * imageFlex; // imageFlex: 4 = 1.4
      }
    } else if (isSmallTablet(context)) {
      // iPad Mini : calcul dynamique selon orientation
      if (orientation == Orientation.portrait) {
        baseRatio = 0.3 * imageFlex; // imageFlex: 4 = 1.2
      } else {
        baseRatio = 0.4 * imageFlex; // imageFlex: 4 = 1.6
      }
    } else if (isTablet(context)) {
      if (orientation == Orientation.portrait) {
        baseRatio = 0.28 * imageFlex; // imageFlex: 4 = 1.12
      } else {
        baseRatio = 0.38 * imageFlex; // imageFlex: 4 = 1.52
      }
    } else {
      // Desktop : moins impacté par l'orientation
      baseRatio = 0.30 * imageFlex; // imageFlex: 4 = 1.2
    }
    
    final defaultFlex = imageFlex * 1.9;
    final flexRatio = imageFlex / defaultFlex;
    
    return baseRatio * flexRatio;
  }

  /// Espacement entre les cartes de produits selon l'appareil
  static double getProductsGridSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 4.0; // Mobile : plus serré pour réduire l'espace horizontal
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : standard réduit
    } else if (isTablet(context)) {
      return 12.0; // iPad : plus espacé
    } else {
      return 14.0; // Desktop : maximum d'espacement
    }
  }

  /// Espacement de grille proportionnel au imageFlex pour un design équilibré
  /// Quand imageFlex augmente, l'espacement augmente proportionnellement
  static double getProductsGridSpacingProportional(BuildContext context, int imageFlex) {
    final baseSpacing = getProductsGridSpacing(context);
    
    // Ratio de proportion : imageFlex: 2 = 50% d'espacement supplémentaire
    // Par défaut imageFlex: 7, donc on calcule le ratio proportionnel
    final defaultFlex = 1;
    final flexRatio = imageFlex / defaultFlex;
    
    // Appliquer le ratio à l'espacement de base
    // imageFlex: 2 (plus petit) = espacement réduit
    // imageFlex: 7 (défaut) = espacement normal  
    // imageFlex: 10+ (plus grand) = espacement augmenté
    return baseSpacing * flexRatio;
  }

  /// Espacement de grille adaptatif selon le nombre d'éléments par ligne
  /// Plus il y a de colonnes, plus l'espacement est réduit pour optimiser l'espace
  static double getAdaptiveGridSpacing(BuildContext context) {
    final columns = getEcolesGridColumns(context);
    
    if (isMobile(context)) {
      if (isLandscape(context)) {
        // Mobile paysage : espacement selon nombre de colonnes
        switch (columns) {
          case 5: return 25.0;  // 5 colonnes : espacement très réduit
          case 4: return 10.0; // 4 colonnes : espacement réduit
          case 3: return 12.0; // 3 colonnes : espacement standard
          case 2: return 14.0; // 2 colonnes : espacement confortable
          default: return 12.0;
        }
      } else {
        // Mobile portrait : espacement selon nombre de colonnes
        switch (columns) {
          case 3: return 20.0; // 3 colonnes : espacement confortable
          case 2: return 30.0; // 2 colonnes : espacement généreux
          default: return 20.0;
        }
      }
    } else if (isSmallTablet(context)) {
      if (isLandscape(context)) {
        // iPad Mini paysage
        switch (columns) {
          case 5: return 8.0;  // 5 colonnes : espacement très réduit
          case 4: return 10.0; // 4 colonnes : espacement réduit
          default: return 10.0;
        }
      } else {
        // iPad Mini portrait
        switch (columns) {
          case 4: return 12.0; // 4 colonnes : espacement standard
          default: return 12.0;
        }
      }
    } else if (isTablet(context)) {
      if (isLandscape(context)) {
        // iPad paysage
        switch (columns) {
          case 6: return 10.0; // 6 colonnes : espacement réduit
          case 5: return 12.0; // 5 colonnes : espacement standard
          default: return 12.0;
        }
      } else {
        // iPad portrait
        switch (columns) {
          case 5: return 16.0; // 5 colonnes : espacement confortable
          default: return 16.0;
        }
      }
    } else {
      // Desktop
      if (isLandscape(context)) {
        switch (columns) {
          case 8: return 12.0; // 8 colonnes : espacement réduit
          case 6: return 14.0; // 6 colonnes : espacement standard
          default: return 14.0;
        }
      } else {
        switch (columns) {
          case 6: return 20.0; // 6 colonnes : espacement généreux
          default: return 20.0;
        }
      }
    }
  }

  /// Rayon de bordure pour les cartes de produits selon l'appareil
  static double getProductCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 14.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 18.0; // iPad : plus grands arrondis
    } else {
      return 20.0; // Desktop : arrondis maximum
    }
  }

  
  /// Flex ratio pour la partie informations des cartes de produits
  static int getProductCardInfoFlex(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 2 : 3;
  }

  /// Taille de police pour le titre des produits selon l'appareil
  static double getProductTitleFontSize(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 11.0 : 13.0;
  }

  /// Taille de police pour le sous-titre des produits selon l'appareil
  static double getProductSubtitleFontSize(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 9.0 : 11.0;
  }

  /// Taille de police pour le prix des produits selon l'appareil
  static double getProductPriceFontSize(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 10.0 : 12.0;
  }

  /// Taille de police pour le badge de type des produits selon l'appareil
  static double getProductTypeFontSize(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 8.0 : 10.0;
  }

  /// Padding pour les cartes de produits selon l'appareil
  static EdgeInsets getProductCardPadding(BuildContext context) {
    final isCompact = getProductsGridColumns(context) == 3;
    return EdgeInsets.fromLTRB(
      isCompact ? 8.0 : 10.0,
      isCompact ? 6.0 : 8.0,
      isCompact ? 8.0 : 10.0,
      isCompact ? 8.0 : 10.0,
    );
  }

  /// Taille du point de disponibilité selon l'appareil
  static double getProductAvailabilityDotSize(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 8.0 : 10.0;
  }

  /// Padding pour le badge de type selon l'appareil
  static EdgeInsets getProductTypeBadgePadding(BuildContext context) {
    final isCompact = getProductsGridColumns(context) == 3;
    return EdgeInsets.symmetric(
      horizontal: isCompact ? 5.0 : 7.0,
      vertical: isCompact ? 2.0 : 3.0,
    );
  }

  /// Rayon de bordure pour le badge de type selon l'appareil
  static double getProductTypeBadgeBorderRadius(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 4.0 : 6.0;
  }

  // ── DIMENSIONS POUR LES FILTRES ──────────────────────────────────────

  /// Hauteur du conteneur de filtres selon l'appareil
  static double getFilterContainerHeight(BuildContext context) {
    if (isMobile(context)) {
      return 32.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 36.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 36.0; // iPad : standard
    } else {
      return 40.0; // Desktop : plus grand
    }
  }

  /// Espacement entre les filtres selon l'appareil
  static double getFilterSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 6.0; // Mobile : plus serré
    } else if (isSmallTablet(context)) {
      return 8.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 8.0; // iPad : standard
    } else {
      return 10.0; // Desktop : plus espacé
    }
  }

  /// Rayon de bordure pour les filtres selon l'appareil
  static double getFilterBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 50.0; // 8.0 Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : arrondis standards
    } else if (isTablet(context)) {
      return 10.0; // iPad : arrondis standards
    } else {
      return 12.0; // Desktop : arrondis prononcés
    }
  }

  /// Padding intérieur des filtres selon l'appareil
  static double getFilterPadding(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 14.0; // iPad : standard
    } else {
      return 16.0; // Desktop : plus grand
    }
  }

  /// Taille de police pour les filtres selon l'appareil
  static double getFilterFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 13.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 13.0; // iPad : standard
    } else {
      return 14.0; // Desktop : plus grand
    }
  }

  // ── DIMENSIONS POUR LES BADGES ────────────────────────────────────────────────

  /// Taille de police pour les badges de notification selon l'appareil
  static double getBadgeFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : très petit
    } else if (isSmallTablet(context)) {
      return 11.0; // iPad Mini : petit
    } else if (isTablet(context)) {
      return 11.0; // iPad : petit
    } else {
      return 12.0; // Desktop : standard
    }
  }

  /// Taille minimale des badges de notification selon l'appareil
  static double getBadgeMinSize(BuildContext context) {
    if (isMobile(context)) {
      return 18.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 20.0; // iPad : standard
    } else {
      return 22.0; // Desktop : plus grand
    }
  }

  /// Padding intérieur des badges de notification selon l'appareil
  static double getBadgePadding(BuildContext context) {
    if (isMobile(context)) {
      return 4.0; // Mobile : très compact
    } else if (isSmallTablet(context)) {
      return 5.0; // iPad Mini : compact
    } else if (isTablet(context)) {
      return 5.0; // iPad : compact
    } else {
      return 6.0; // Desktop : standard
    }
  }

  // ── DIMENSIONS POUR LES BOUTONS DE DÉTAILS ───────────────────────────────────────────

  /// Taille de police pour les boutons de détails selon l'appareil
  static double getDetailsButtonFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 13.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 14.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 14.0; // iPad : standard
    } else {
      return 15.0; // Desktop : plus grand
    }
  }

  /// Padding horizontal pour les boutons de détails selon l'appareil
  static double getDetailsButtonPaddingHorizontal(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 18.0; // iPad : plus grand
    } else {
      return 20.0; // Desktop : maximum
    }
  }

  /// Padding vertical pour les boutons de détails selon l'appareil
  static double getDetailsButtonPaddingVertical(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 12.0; // iPad : plus grand
    } else {
      return 14.0; // Desktop : maximum
    }
  }

  /// Rayon de bordure pour les boutons de détails selon l'appareil
  static double getDetailsButtonBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 16.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : arrondis standards
    } else if (isTablet(context)) {
      return 12.0; // iPad : arrondis prononcés
    } else {
      return 14.0; // Desktop : arrondis maximum
    }
  }

  /// Espacement entre les boutons de détails selon l'appareil
  static double getDetailsButtonSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 18.0; // iPad : plus grand
    } else {
      return 20.0; // Desktop : maximum
    }
  }

  // ── DIMENSIONS POUR LES CARROUSELS ────────────────────────────────────────────────

  /// Hauteur du carrousel selon l'appareil
  static double getCarouselHeight(BuildContext context) {
    if (isMobile(context)) {
      return 140.0; // Mobile : hauteur compacte
    } else if (isSmallTablet(context)) {
      return 220.0; // iPad Mini : hauteur intermédiaire
    } else if (isTablet(context)) {
      return 220.0; // iPad : hauteur standard
    } else {
      return 260.0; // Desktop : hauteur plus généreuse
    }
  }

  // ── DIMENSIONS POUR LES CONTENEURS PRINCIPAUX ──────────────────────────────────────

  /// Padding pour les conteneurs principaux selon l'appareil
  static double getMainContainerPadding(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 24.0; // iPad : plus grand
    } else {
      return 32.0; // Desktop : maximum
    }
  }

  /// Rayon de bordure pour les conteneurs principaux selon l'appareil
  static double getMainContainerBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 16.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : arrondis standards
    } else if (isTablet(context)) {
      return 24.0; // iPad : arrondis prononcés
    } else {
      return 28.0; // Desktop : arrondis maximum
    }
  }

  // ── DIMENSIONS POUR LES DÉTAILS DE PROFIL ───────────────────────────────────────────

  /// Padding pour les conteneurs de détails selon l'appareil
  static double getProfileDetailsPadding(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 20.0; // iPad : plus grand
    } else {
      return 24.0; // Desktop : maximum
    }
  }

  /// Rayon de bordure pour les conteneurs de détails selon l'appareil
  static double getProfileDetailsBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : arrondis modérés
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : arrondis standards
    } else if (isTablet(context)) {
      return 20.0; // iPad : arrondis prononcés
    } else {
      return 24.0; // Desktop : arrondis maximum
    }
  }

  /// Espacement entre les éléments de détails selon l'appareil
  static double getProfileDetailsSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 16.0; // iPad : plus grand
    } else {
      return 20.0; // Desktop : maximum
    }
  }

  /// Largeur pour les éléments de détail en mode deux colonnes
  static double getProfileDetailItemWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double padding =
        getProfileDetailsPadding(context) * 2; // Padding gauche et droite
    double spacing =
        getProfileDetailsSpacing(context) / 2; // Espacement entre colonnes

    if (isMobile(context)) {
      return screenWidth - padding - 32; // Mobile : pleine largeur
    } else {
      return (screenWidth - padding - spacing) /
          2; // Tablettes : moitié de largeur
    }
  }

  // ── DIMENSIONS POUR LES CARTES DE STATISTIQUES ────────────────────────────────

  /// Hauteur des cartes de statistiques selon l'appareil
  static double getSummaryCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return 85.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 95.0; // iPad Mini : hauteur standard
    } else if (isTablet(context)) {
      return 105.0; // iPad : plus grand
    } else {
      return 115.0; // Desktop : maximum
    }
  }

  /// Largeur des cartes de statistiques selon l'appareil
  static double getSummaryCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return 100.0; // Mobile : plus étroit
    } else if (isSmallTablet(context)) {
      return 160.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 180.0; // iPad : plus large
    } else {
      return 200.0; // Desktop : maximum
    }
  }

  // ── DIMENSIONS POUR LE PAYMENT BANNER CARD ────────────────────────────────

  /// Hauteur du conteneur du PaymentBannerCard selon l'appareil
  static double getPaymentBannerCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return 130.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 150.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 170.0; // iPad : plus grand
    } else {
      return 190.0; // Desktop : maximum
    }
  }

  /// Largeur des cartes individuelles dans le PaymentBannerCard selon l'appareil
  static double getPaymentBannerCardItemWidth(BuildContext context) {
    if (isMobile(context)) {
      return 70.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 85.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 100.0; // iPad : plus large
    } else {
      return 120.0; // Desktop : maximum
    }
  }



  // ── DIMENSIONS POUR LES CARTES HORIZONTALES (SUIVI SCOLAIRE) ─────────────────────

  /// Hauteur des cartes horizontales de suivi scolaire selon l'appareil
  static double getHorizontalCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return 100.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 140.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 140.0; // iPad : plus grand
    } else {
      return 130.0; // Desktop : maximum
    }
  }

  /// Largeur des cartes horizontales de suivi scolaire selon l'appareil
  static double getHorizontalCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return 120.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 140.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 160.0; // iPad : plus large
    } else {
      return 180.0; // Desktop : maximum
    }
  }

  /// Facteur de proportion pour les cartes carrées selon la taille de l'écran
  static double getSquareCardScaleFactor(BuildContext context) {
    if (isMobile(context)) {
      return 0.7; // Mobile : 70% de la taille de base
    } else if (isSmallTablet(context)) {
      return 0.85; // iPad Mini : 85% de la taille de base
    } else if (isTablet(context)) {
      return 0.95; // iPad : 95% de la taille de base
    } else {
      return 1.0; // Desktop : 100% de la taille de base
    }
  }

  /// Dimensions carrées selon l'appareil (pour les cartes carrées)
  static double getSquareCardSize(BuildContext context, {double baseSize = 140.0}) {
    return baseSize * getSquareCardScaleFactor(context);
  }

  /// Largeur des cartes carrées selon l'appareil
  static double getSquareCardWidthSize(BuildContext context) {
    return getSquareCardSize(context, baseSize: 110.0);
  }

  /// Hauteur des cartes carrées selon l'appareil
  static double getSquareCardHeightSize(BuildContext context) {
    return getSquareCardSize(context, baseSize: 156.0);
  }

  /// Taille des images des enfants selon la taille de l'écran
  static double getChildImageSize(BuildContext context) {
    if (isMobile(context)) {
      return 60.0; // Mobile : taille actuelle (bonne pour téléphone)
    } else if (isSmallTablet(context)) {
      return 75.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 90.0; // iPad : plus grand
    } else {
      return 100.0; // Desktop : maximum
    }
  }

  /// Border radius pour les images selon la taille de l'écran
  static double getImageBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 40.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 45.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 20.0; // iPad : plus grand
    } else {
      return 55.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les cartes selon la taille de l'écran
  static double getCardTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 11.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 12.0; // iPad : plus grand
    } else {
      return 13.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les titres des cartes selon la taille de l'écran
  static double getCardTitleTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : plus petit
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 13.0; // iPad : plus grand
    } else {
      return 14.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les cartes du bottom sheet selon la taille de l'écran
  static double getBottomSheetCardTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 15.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 14.0; // iPad : plus grand
    } else {
      return 18.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les noms des enfants selon la taille de l'écran
  static double getChildNameTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 11.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 12.0; // iPad : plus grand
    } else {
      return 13.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les classes des enfants selon la taille de l'écran
  static double getChildGradeTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 9.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 11.0; // iPad : plus grand
    } else {
      return 12.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les badges de notification selon la taille de l'écran
  static double getNotificationBadgeTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 9.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 10.0; // iPad : plus grand
    } else {
      return 11.0; // Desktop : maximum
    }
  }

  /// Taille du conteneur des badges de notification selon la taille de l'écran
  static double getNotificationBadgeSize(BuildContext context) {
    if (isMobile(context)) {
      return 16.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 18.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 20.0; // iPad : plus grand
    } else {
      return 22.0; // Desktop : maximum
    }
  }

  /// Taille du texte pour les titres de sections selon la taille de l'écran
  static double getSectionTitleTextSize(BuildContext context) {
    if (isMobile(context)) {
      return 11.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 13.0; // iPad : plus grand
    } else {
      return 14.0; // Desktop : maximum
    }
  }

  /// Taille de l'icône chevron des sections selon la taille de l'écran
  static double getSectionIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 18.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 22.0; // iPad : plus grand
    } else {
      return 24.0; // Desktop : maximum
    }
  }

  /// Espacement horizontal pour les sections selon la taille de l'écran
  static double getSectionHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 20.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 24.0; // iPad : plus grand
    } else {
      return 28.0; // Desktop : maximum
    }
  }

  /// Marge verticale pour les sections selon la taille de l'écran
  static double getSectionVerticalMargin(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Mobile : taille par défaut
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : légèrement plus grand
    } else if (isTablet(context)) {
      return 12.0; // iPad : plus grand
    } else {
      return 14.0; // Desktop : maximum
    }
  }

  /// Espacement horizontal entre les cartes du PaymentBannerCard selon l'appareil
  static double getPaymentBannerCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0; // Mobile : standard
    } else if (isSmallTablet(context)) {
      return 16.0; // iPad Mini : plus grand
    } else if (isTablet(context)) {
      return 45.0; // iPad : encore plus grand
    } else {
      return 24.0; // Desktop : maximum
    }
  }
}
