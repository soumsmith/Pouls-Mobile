import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDimensions {
  // Private constructor pour empêcher l'instanciation
  AppDimensions._();

  // Breakpoints pour les différents types d'appareils
  static const double mobileBreakpoint = 600.0;
  static const double smallTabletBreakpoint = 700.0; // iPad Mini
  static const double tabletBreakpoint = 768.0;
  static const double largeTabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;

  // ===========================================================================
  // RÉSOLUTIONS D'ÉCRANS STANDARDS (En points/dp logiques)
  // Utiles pour des vérifications spécifiques, pour initialiser un package 
  // comme flutter_screenutil, ou servir de référence pour les maquettes.
  // ===========================================================================

  // --- Apple (iOS / iPadOS) ---
  /// Petits iPhone (SE 1ère gen, 5, 5s)
  static const Size iphoneSmall = Size(320, 568);
  /// iPhone standards classiques (8, SE 2/3)
  static const Size iphoneStandard = Size(375, 667);
  /// iPhone X, XS, 11 Pro, 12/13 Mini
  static const Size iphoneXFamily = Size(375, 812);
  /// iPhone 12, 13, 14, 11, XR
  static const Size iphone12Family = Size(390, 844);
  /// iPhone 14 Pro, 15, 15 Pro
  static const Size iphone14ProFamily = Size(393, 852);
  /// iPhone 8 Plus, 11 Pro Max, XS Max
  static const Size iphoneMaxOld = Size(414, 896);
  /// iPhone 12 Pro Max, 13 Pro Max, 14 Plus
  static const Size iphoneMaxNew = Size(428, 926);
  /// iPhone 14 Pro Max, 15 Plus, 15 Pro Max
  static const Size iphone14ProMaxFamily = Size(430, 932);
  
  /// iPad Mini / classiques
  static const Size ipadMini = Size(768, 1024);
  /// iPad Air / Pro 11"
  static const Size ipadPro11 = Size(834, 1194);
  /// iPad Pro 12.9"
  static const Size ipadPro12_9 = Size(1024, 1366);

  // --- Android ---
  /// Petits téléphones Android (anciens modèles ou bas de gamme)
  static const Size androidSmall = Size(360, 640);
  /// Smartphones Android standards (ex: séries Galaxy S de base)
  static const Size androidStandard = Size(360, 800);
  /// Smartphones Android modernes (ex: séries Google Pixel)
  static const Size androidModern = Size(393, 851);
  /// Phablettes et grands écrans Android (ex: Galaxy Ultra)
  static const Size androidLarge = Size(412, 915);
  /// Petites tablettes Android (7-8 pouces)
  static const Size androidTabletSmall = Size(600, 960);
  /// Grandes tablettes Android (10 pouces)
  static const Size androidTabletLarge = Size(800, 1280);



   // ===========================================================================
  // RÉSOLUTIONS D'ÉCRANS STANDARDS (En points/dp logiques)
  // ===========================================================================

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
  static const double inputFocusedBorderWidth = 0.5;

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

  // ===========================================================================
  // NOUVELLES FONCTIONS DE DÉTECTION (Étape 1 de la migration)
  // ===========================================================================

  /// Détecte un petit téléphone (ex: iPhone SE, vieux Androids)
  static bool isCompactMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= androidSmall.width; // 360 ou moins
  }

  /// Détecte un téléphone standard (ex: iPhone 13, Pixel)
  static bool isStandardMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > androidSmall.width && width <= iphone12Family.width; // entre 361 et 390
  }

  /// Détecte un grand téléphone / phablette (ex: iPhone Pro Max, Galaxy Ultra)
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > iphone12Family.width && width < tabletBreakpoint; // entre 391 et 767
  }

  // ===========================================================================
  // NOUVELLES FONCTIONS DE DIMENSIONNEMENT DYNAMIQUE (Étape 2 de la migration)
  // ===========================================================================

  /// Calcule une échelle relative à un écran de référence (ex: iPhone 12/13/14).
  /// Permet d'agrandir proportionnellement le texte et les espaces sur les grands écrans,
  /// et de les réduire sur les petits écrans.
  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // On prend iphone12Family (390px) comme base de calcul (standard actuel)
    final double baseWidth = iphone12Family.width;
    
    // Si on est sur tablette ou desktop, on capte l'échelle pour ne pas avoir de textes géants
    if (screenWidth >= tabletBreakpoint) {
      // Sur tablette, l'échelle maximale est basée sur la largeur d'un grand mobile
      // pour éviter que les éléments de base deviennent caricaturaux.
      return (iphone14ProMaxFamily.width / baseWidth) * 1.1; 
    }
    
    return screenWidth / baseWidth;
  }

  /// Retourne une valeur redimensionnée proportionnellement à la taille de l'écran.
  /// Pratique pour les polices (fontSize) ou les marges.
  static double getScaledSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// Calcule dynamiquement le nombre de colonnes d'une grille pour s'assurer
  /// que chaque élément fait AU MOINS [minItemWidth] de large, en tenant compte de l'espacement.
  static int getDynamicGridColumns(
    BuildContext context, {
    required double minItemWidth,
    double spacing = 16.0,
    double horizontalPadding = 32.0, // 16 de chaque côté par défaut
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - horizontalPadding;
    
    // Formule mathématique pour calculer le nombre de colonnes n :
    // n * minItemWidth + (n - 1) * spacing <= availableWidth
    int columns = ((availableWidth + spacing) / (minItemWidth + spacing)).floor();
    
    // On s'assure d'avoir toujours au moins 1 colonne
    return columns > 0 ? columns : 1;
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
    final width = MediaQuery.sizeOf(context).width;
    return width < 600 ? 2 : 3;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Méthodes pour obtenir des dimensions adaptatives
  static double getAdaptivePadding(BuildContext context) {
    return getScaledSize(context, defaultPadding);
  }

  static double getAdaptiveContainerPadding(BuildContext context) {
    return getScaledSize(context, spacingM);
  }

  static double getAdaptiveSpacing(BuildContext context) {
    return getScaledSize(context, spacingM);
  }

  static double getAdaptiveIconSize(BuildContext context) {
    return getScaledSize(context, 64.0);
  }

  // Dimensions pour les cartes de connexion
  static double getLoginCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth < 600) return screenWidth - (defaultPadding * 2);
    if (screenWidth < 850) return screenWidth * 0.7;
    if (screenWidth < 1100) return screenWidth * 0.6;
    return screenWidth * 0.4;
  }

  static double getLoginCardMaxWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    return screenWidth < 600 ? double.infinity : 500.0;
  }

  // Dimensions pour les formulaires
  static double getFormTitleFontSize(BuildContext context) {
    return getScaledSize(context, 24.0);
  }

  static double getFormSubtitleFontSize(BuildContext context) {
    return getScaledSize(context, 14.0);
  }

  static double getFormFieldSpacing(BuildContext context) {
    return getScaledSize(context, 32.0);
  }

  // Dimensions pour les cartes de produits (flex ratio image/texte)
  // Pour le composant ImageMenuCardExternalTitle
  static double getProductCardImageFlex(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Si mobile ou paysage, image réduite
    return width < 600 || isLandscape(context) ? 3.0 : 4.0;
  }

  // Pour le calcul du ratio de la grille selon le nombre de colonnes
  /// Plus il y a de colonnes, plus l'image est réduite pour optimiser l'espace
  static int getGridImageFlex(BuildContext context) {
    final columns = getEcolesGridColumns(context);
    // Approximation mathématique remplaçant le switch complexe
    return (8 - columns).clamp(2, 6);
  }

  // Dimensions pour le contenu responsive
  static double getResponsiveWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (screenWidth < 600) return screenWidth;
    if (screenWidth < 850) return screenWidth * 0.8;
    if (screenWidth < 1100) return screenWidth * 0.7;
    return screenWidth * 0.6;
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
    return getScaledSize(context, 140.0);
  }

  static double getSplashTitleFontSize(BuildContext context) {
    return getScaledSize(context, 24.0);
  }

  static double getSplashSubtitleFontSize(BuildContext context) {
    return getScaledSize(context, 16.0);
  }

  // ── DIMENSIONS POUR LA PAGINATION ───────────────────────────────────

  /// Nombre d'éléments par page selon le type d'appareil
  static int getEventsPerPage(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 4;
    if (width < 850) return 6;
    if (width < 1100) return 8;
    return 12;
  }

  /// Taille de l'image des événements
  static double getEventImageSize(BuildContext context) {
    return getScaledSize(context, 70.0);
  }

  /// Padding interne des cartes d'événements
  static double getEventCardPadding(BuildContext context) {
    return getScaledSize(context, 12.0);
  }


  /// Espacement entre les cartes d'événements
  static double getEventCardSpacing(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  /// Taille de police pour le titre des événements
  static double getEventTitleFontSize(BuildContext context) {
    return getScaledSize(context, 14.0);
  }

  /// Taille de police pour le sous-titre des événements
  static double getEventSubtitleFontSize(BuildContext context) {
    return getScaledSize(context, 11.0);
  }

  // ── DIMENSIONS POUR LA PAGINATION DES ÉCOLES ────────────────────────

  /// Nombre d'écoles par page selon le type d'appareil
  static int getEcolesPerPage(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 6;
    if (width < 850) return 9;
    if (width < 1100) return 12;
    return 16;
  }

  /// Espacement entre les cartes d'écoles
  static double getEcoleCardSpacing(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  /// Padding interne des cartes d'écoles
  static double getEcoleCardPadding(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  /// Taille de police pour le nom des écoles
  static double getEcoleTitleFontSize(BuildContext context) {
    return getScaledSize(context, 14.0);
  }

  /// Taille de police pour le type des écoles
  static double getEcoleTypeFontSize(BuildContext context) {
    return getScaledSize(context, 11.0);
  }

  /// Nombre de colonnes pour la grille d'écoles
  static int getEcolesGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    
    if (isPortrait(context)) {
      if (width < 600) return getMobileColumnsByResolution(context); // Mobile (2 ou 3)
      if (width < 850) return 4; // iPad
      return 6; // Desktop
    } else {
      if (width < 850) return 5; // Mobile/iPad paysage
      return 8; // Desktop paysage
    }
  }

  // ── DIMENSIONS POUR LES ARRONDIS DES CARTES ────────────────────────────────

  /// Rayon de bordure pour les petites cartes
  static double getSmallCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 15.0); // 15.0 de base
  }

  /// Rayon de bordure pour les cartes moyennes
  static double getMediumCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  /// Rayon de bordure pour les grandes cartes
  static double getLargeCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 16.0);
  }

  /// Rayon de bordure pour les cartes hero (bannière)
  static double getHeroCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 20.0);
  }

  /// Rayon de bordure pour les boutons
  static double getButtonBorderRadius(BuildContext context) {
    return getScaledSize(context, 50.0); // Pill shape maintenue
  }

  /// Rayon de bordure pour les champs de texte
  static double getTextFieldBorderRadius(BuildContext context) {
    return getScaledSize(context, 8.0);
  }

  /// Rayon de bordure pour les icônes conteneurs
  static double getIconContainerBorderRadius(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  /// Rayon de bordure pour les badges
  static double getBadgeBorderRadius(BuildContext context) {
    return getScaledSize(context, 10.0);
  }

  /// Rayon de bordure pour les conteneurs de filtre
  static double getFilterContainerBorderRadius(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  // ── DIMENSIONS POUR LES CARTES DE MENU HORIZONTAL ────────────────────────────

  /// Hauteur des cartes de menu horizontal
  static double getHorizontalMenuCardHeight(BuildContext context) {
    return getScaledSize(context, 120.0);
  }

  /// Largeur des cartes de menu horizontal
  static double getHorizontalMenuCardWidth(BuildContext context) {
    return getScaledSize(context, 120.0); // Equivalent proportionnel
  }

  /// Espacement entre les cartes de menu horizontal
  static double getHorizontalMenuCardSpacing(BuildContext context) {
    return 0.0; // Pas d'espacement de base
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

  // Ombre spécifique de l'écran des paramètres externalisée pour réutilisation
  static const double settingsCardShadowBlur = 12.0;
  static const Offset settingsCardShadowOffset = Offset(0, 4);

  static List<BoxShadow> getSettingsCardShadow(
    BuildContext context, {
    bool enabled = true,
  }) {
    if (!enabled) return [];
    return [
      BoxShadow(
        color: AppColors.settingsCardShadowColorThemed(context),
        blurRadius: settingsCardShadowBlur,
        offset: settingsCardShadowOffset,
      ),
    ];
  }

  // Ombre spécifique des bottom sheets (projetée vers le haut, offset y négatif)
  static const double bottomSheetShadowBlur = 16.0;
  static const Offset bottomSheetShadowOffset = Offset(0, -6);

  static List<BoxShadow> getBottomSheetShadow(
    BuildContext context, {
    bool enabled = true,
  }) {
    if (!enabled) return [];
    return [
      BoxShadow(
        color: AppColors.settingsCardShadowColorThemed(context),
        blurRadius: bottomSheetShadowBlur,
        offset: bottomSheetShadowOffset,
      ),
    ];
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

  /// Taille de police pour le titre de la carte d'école
  static double getEcoleCardTitleFontSize(BuildContext context) {
    return getScaledSize(context, 11.0);
  }

  /// Taille de police pour le sous-titre (adresse) de la carte d'école
  static double getEcoleCardSubtitleFontSize(BuildContext context) {
    return getScaledSize(context, 9.0);
  }

  /// Taille de police pour le type d'école (badge)
  static double getEcoleCardTypeFontSize(BuildContext context) {
    return getScaledSize(context, 8.0);
  }

  /// Hauteur dynamique pour les cartes d'établissements
  static double getEcoleCardHeight(BuildContext context) {
    final columns = getEcolesGridColumns(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final spacing = getAdaptiveGridSpacing(context);
    
    // La grille a un padding horizontal total de 32 (16 de chaque côté)
    const horizontalPadding = 32.0; 
    
    final itemWidth = (screenWidth - horizontalPadding - spacing * (columns - 1)) / columns;
    
    // Format un peu plus compact pour l'image (hauteur = 75% de la largeur)
    final imageHeight = itemWidth * 0.75;
    
    // Espace suffisant pour les lignes de titre + sous-titre + badges
    final textSpace = getScaledSize(context, 65.0); 
    
    return imageHeight + textSpace;
  }

  /// Rayon de bordure pour la carte d'école
  static double getEcoleCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 14.0);
  }

  /// Espacement intérieur de la zone d'info de la carte d'école
  static double getEcoleCardInfoPadding(BuildContext context) {
    return getScaledSize(context, 8.0);
  }

  /// Taille de l'icône de localisation
  static double getEcoleCardIconSize(BuildContext context) {
    return getScaledSize(context, 10.0);
  }

  /// Hauteur du gradient en bas de l'image
  static double getEcoleCardGradientHeight(BuildContext context) {
    return getScaledSize(context, 40.0);
  }

  /// Taille du badge de type
  static double getEcoleCardBadgePadding(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  /// Taille de l'indicateur de statut (cercle vert)
  static double getEcoleCardStatusIndicatorSize(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  // ── MÉTHODES RESPONSIVES POUR LA GRILLE D'ÉCOLES ────────────────────

  /// Ratio d'aspect pour les cartes d'écoles
  static double getEcolesGridChildAspectRatio(BuildContext context) {
    // Calcul proportionnel basé sur le nombre de colonnes
    // (Ex: 2 colonnes = 0.65, 4 colonnes = 0.75, 5 colonnes = 0.80)
    final crossAxisCount = getEcolesGridColumns(context);
    return 0.65 + (crossAxisCount - 2) * 0.05;
  }

  // ── MÉTHODES RESPONSIVES POUR LA GRILLE DE PRODUITS ────────────────────

  /// Nombre de colonnes pour la grille de produits
  static int getProductsGridColumns(BuildContext context) {
    // Calcul proportionnel basé sur l'espace disponible
    final width = MediaQuery.sizeOf(context).width;
    return width < 800 ? 3 : 4;
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

  /// Espacement entre les cartes de produits selon l'appareil,
  /// optimisé de manière proportionnelle à la taille de l'écran.
  static double getProductsGridSpacing(BuildContext context) {
    // Espacement de base de 6.0 sur un écran de référence (ex: mobile 375px)
    // Produit naturellement ~12.2 sur petite tablette, et ~16.3 sur iPad.
    return getScaledSize(context, 6.0);
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
    // Espacement de base selon l'orientation
    final double baseSpacing = AppDimensions.isLandscape(context) ? 12.0 : 20.0;
    return getScaledSize(context, baseSpacing);
  }

  static double getProductCardBorderRadius(BuildContext context) {
    return getScaledSize(context, 14.0);
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

  /// Hauteur du conteneur de filtres
  static double getFilterContainerHeight(BuildContext context) {
    return getScaledSize(context, 32.0);
  }

  /// Espacement entre les filtres
  static double getFilterSpacing(BuildContext context) {
    return getScaledSize(context, 6.0);
  }

  /// Rayon de bordure pour les filtres
  static double getFilterBorderRadius(BuildContext context) {
    return getScaledSize(context, 50.0);
  }

  /// Padding intérieur des filtres
  static double getFilterPadding(BuildContext context) {
    return getScaledSize(context, 10.0);
  }

  /// Taille de police pour les filtres
  static double getFilterFontSize(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  // ── DIMENSIONS POUR LES BADGES ────────────────────────────────────────────────

  /// Taille de police pour les badges de notification
  static double getBadgeFontSize(BuildContext context) {
    return getScaledSize(context, 10.0);
  }

  /// Taille minimale des badges de notification
  static double getBadgeMinSize(BuildContext context) {
    return getScaledSize(context, 18.0);
  }

  /// Padding intérieur des badges de notification
  static double getBadgePadding(BuildContext context) {
    return getScaledSize(context, 4.0);
  }

  // ── DIMENSIONS POUR LES BOUTONS DE DÉTAILS ───────────────────────────────────────────

  /// Taille de police pour les boutons de détails
  static double getDetailsButtonFontSize(BuildContext context) {
    return getScaledSize(context, 13.0);
  }

  /// Padding horizontal pour les boutons de détails
  static double getDetailsButtonPaddingHorizontal(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  /// Padding vertical pour les boutons de détails
  static double getDetailsButtonPaddingVertical(BuildContext context) {
    return getScaledSize(context, 8.0);
  }

  /// Rayon de bordure pour les boutons de détails
  static double getDetailsButtonBorderRadius(BuildContext context) {
    return getScaledSize(context, 16.0);
  }

  /// Espacement entre les boutons de détails
  static double getDetailsButtonSpacing(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  // ── DIMENSIONS POUR LES CARROUSELS ────────────────────────────────────────────────

  /// Hauteur du carrousel
  static double getCarouselHeight(BuildContext context) {
    return getScaledSize(context, 140.0);
  }

  // ── DIMENSIONS POUR LES CONTENEURS PRINCIPAUX ──────────────────────────────────────

  /// Padding pour les conteneurs principaux
  static double getMainContainerPadding(BuildContext context) {
    return getScaledSize(context, 8.0);
  }

  /// Rayon de bordure pour les conteneurs principaux
  static double getMainContainerBorderRadius(BuildContext context) {
    return getScaledSize(context, 16.0);
  }

  // ── DIMENSIONS POUR LES DÉTAILS DE PROFIL ───────────────────────────────────────────

  /// Padding pour les conteneurs de détails
  static double getProfileDetailsPadding(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  /// Rayon de bordure pour les conteneurs de détails
  static double getProfileDetailsBorderRadius(BuildContext context) {
    return getScaledSize(context, 12.0);
  }

  /// Espacement entre les éléments de détails
  static double getProfileDetailsSpacing(BuildContext context) {
    return getScaledSize(context, 8.0);
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

  /// Hauteur des cartes de statistiques
  static double getSummaryCardHeight(BuildContext context) {
    return getScaledSize(context, 85.0);
  }

  /// Largeur des cartes de statistiques
  static double getSummaryCardWidth(BuildContext context) {
    return getScaledSize(context, 100.0);
  }

  // ── DIMENSIONS POUR LE PAYMENT BANNER CARD ────────────────────────────────

  /// Hauteur du conteneur du PaymentBannerCard
  static double getPaymentBannerCardHeight(BuildContext context) {
    return getScaledSize(context, 130.0);
  }

  /// Largeur des cartes individuelles dans le PaymentBannerCard
  static double getPaymentBannerCardItemWidth(BuildContext context) {
    return getScaledSize(context, 70.0);
  }



  // ── DIMENSIONS POUR LES CARTES HORIZONTALES (SUIVI SCOLAIRE) ─────────────────────

  /// Hauteur des cartes horizontales de suivi scolaire
  static double getHorizontalCardHeight(BuildContext context) {
    return getScaledSize(context, 100.0);
  }

  /// Largeur des cartes horizontales de suivi scolaire
  static double getHorizontalCardWidth(BuildContext context) {
    return getScaledSize(context, 120.0);
  }

  /// Facteur de proportion pour les cartes carrées selon la taille de l'écran
  static double getSquareCardScaleFactor(BuildContext context) {
    return getScaleFactor(context); // Utilise la nouvelle fonction de migration
  }

  /// Dimensions carrées selon l'appareil (pour les cartes carrées)
  static double getSquareCardSize(BuildContext context, {double baseSize = 140.0}) {
    return getScaledSize(context, baseSize); // Utilise la nouvelle fonction de migration
  }

  /// Largeur des cartes carrées selon l'appareil
  static double getSquareCardWidthSize(BuildContext context) {
    if (isMobile(context)) {
      // Calcul dynamique pour afficher environ 4 boutons pleins (4.2 pour l'indice de défilement)
      final screenWidth = MediaQuery.of(context).size.width;
      final horizontalPadding = getPaymentBannerCardSpacing(context) * 0.9 * 2;
      // Espacement entre les éléments du ListView
      final externalSpacing = getPaymentBannerCardSpacing(context);
      final totalSpacingPerItem = externalSpacing;
      
      // En divisant par 4.2, on affiche 4 boutons entiers et un bout du 5ème.
      // Cela augmente considérablement la taille par rapport aux petites valeurs codées en dur.
      final cardWidth = (screenWidth - horizontalPadding) / 4.2 - totalSpacingPerItem;
      return cardWidth;
    }

    // Par défaut pour tablettes et desktop
    return getSquareCardSize(context, baseSize: 75.0);
  }

  /// Hauteur des cartes carrées selon l'appareil
  static double getSquareCardHeightSize(BuildContext context) {
    if (isMobile(context)) {
      // Puisque la largeur de l'image (qui est carrée) est calculée dynamiquement,
      // la hauteur de la carte doit suivre cette largeur plus l'espace du texte
      // pour éviter de laisser un grand espace vide en dessous.
      final imageSize = getSquareCardWidthSize(context);
      // Espace estimé pour le titre sur 2 ou 3 lignes avec son espacement (augmenté pour éviter l'overflow)
      final textSpace = getScaledSize(context, 55.0); 
      return imageSize + textSpace;
    }

    // Augmenter légèrement l'espace total pour éviter l'overflow du texte sur 2 lignes
    double base = isCompactMobile(context) ? 140.0 : 160.0;
    return getSquareCardSize(context, baseSize: base);
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

  /// Espacement plus aéré entre les boutons d'actions rapides
  static double getActionButtonsSpacing(BuildContext context) {
    return getPaymentBannerCardSpacing(context) * 2.0;
  }

  /// Largeur maximale recommandée pour les BottomSheets et Dialogues
  /// Permet d'éviter l'étirement plein écran inesthétique sur tablette.
  static double getBottomSheetMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity; // Pleine largeur sur mobile
    } else if (isSmallTablet(context)) {
      return 500.0; // Restreint sur iPad Mini
    } else if (isTablet(context)) {
      return 600.0; // Restreint sur iPad
    } else {
      return 700.0; // Restreint sur Desktop
    }
  }
}
