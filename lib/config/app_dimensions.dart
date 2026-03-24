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
      return 8.0; // Mobile : compact
    } else if (isSmallTablet(context)) {
      return 10.0; // iPad Mini : espacement standard
    } else if (isTablet(context)) {
      return 12.0; // iPad : espacement plus généreux
    } else {
      return 16.0; // Desktop : espacement maximum
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

  /// Nombre de colonnes pour la grille d'écoles selon l'appareil
  static int getEcolesGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 3; // Mobile : 2 colonnes
    } else if (isSmallTablet(context)) {
      return 4; // iPad Mini : 3 colonnes
    } else if (isTablet(context)) {
      return 4; // iPad : 4 colonnes
    } else {
      return 5; // Desktop : 5 colonnes
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
  
  /// Hauteur des cartes de menu horizontal selon l'appareil
  static double getHorizontalMenuCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return 110.0; // Mobile : plus compact
    } else if (isSmallTablet(context)) {
      return 90.0; // iPad Mini : hauteur intermédiaire
    } else if (isTablet(context)) {
      return 100.0; // iPad : hauteur standard
    } else {
      return 110.0; // Desktop : hauteur plus généreuse
    }
  }

  /// Largeur des cartes de menu horizontal selon l'appareil
  static double getHorizontalMenuCardWidth(BuildContext context) {
    if (isMobile(context)) {
      return 120.0; // Mobile : plus étroit
    } else if (isSmallTablet(context)) {
      return 140.0; // iPad Mini : largeur intermédiaire
    } else if (isTablet(context)) {
      return 160.0; // iPad : largeur standard
    } else {
      return 180.0; // Desktop : largeur plus généreuse
    }
  }

  /// Espacement entre les cartes de menu horizontal selon l'appareil
  static double getHorizontalMenuCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 0.0; // Mobile : très compact
    } else if (isSmallTablet(context)) {
      return 6.0; // iPad Mini : espacement réduit
    } else if (isTablet(context)) {
      return 8.0; // iPad : espacement standard
    } else {
      return 10.0; // Desktop : espacement modéré
    }
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
  static List<BoxShadow> getMainShadow(BuildContext context, {bool enabled = true}) {
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
  static List<BoxShadow> getLightShadow(BuildContext context, {bool enabled = true}) {
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
  static List<BoxShadow> getSubtleShadow(BuildContext context, {bool enabled = true}) {
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
      case 4: // Mobile
        return 0.75; // Plus haut pour éviter l'overflow
      case 3: // Mobile avec plus d'espace ou iPad Mini
        return 0.62; // Encore plus haut pour éviter l'overflow
      default: // iPad (4 colonnes) ou Desktop (5+ colonnes)
        return 0.65; // Plus haut pour tablette/desktop
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

  /// Ratio d'aspect pour les cartes de produits selon le nombre de colonnes
  static double getProductsGridChildAspectRatio(BuildContext context) {
    final crossAxisCount = getProductsGridColumns(context);
    
    // Ajuster le ratio selon le nombre de colonnes
    switch (crossAxisCount) {
      case 3: // Mobile et iPad Mini
        return 0.65; // Plus compact pour éviter l'overflow
      case 4: // iPad et Desktop
        return 0.75; // Ratio standard
      default:
        return 0.75; // Valeur par défaut
    }
  }

  /// Espacement entre les cartes de produits selon l'appareil
  static double getProductsGridSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 10.0; // Mobile : plus serré
    } else if (isSmallTablet(context)) {
      return 12.0; // iPad Mini : standard
    } else if (isTablet(context)) {
      return 14.0; // iPad : plus espacé
    } else {
      return 16.0; // Desktop : maximum d'espacement
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

  /// Flex ratio pour la partie image des cartes de produits
  static int getProductCardImageFlex(BuildContext context) {
    return getProductsGridColumns(context) == 3 ? 4 : 5;
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
}
