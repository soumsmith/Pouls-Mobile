import '../models/ad_model.dart';
import '../config/app_config.dart';

class AdInjector {
  /// Insère les publicités dans une liste de contenus tous les [interval] éléments.
  /// La logique : Contenu 1 à 6 -> Pub, Contenu 7 à 12 -> Pub, etc.
  static List<dynamic> injectAds<T>(List<T> items, List<AdModel> ads, {int? interval}) {
    if (!AppConfig.SHOW_ADS || ads.isEmpty || items.isEmpty) return List<dynamic>.from(items);
    
    final effectiveInterval = interval ?? AppConfig.AD_INTERVAL;
    List<dynamic> result = [];
    
    for (int i = 0; i < items.length; i++) {
      if (i > 0 && i % effectiveInterval == 0) {
        // Insérer un groupe de publicités (carrousel)
        result.add(AdGroup(ads));
      }
      result.add(items[i]);
    }
    
    // Si la liste se termine pile sur un multiple (ex: 6 éléments),
    // on peut optionnellement ajouter une pub à la fin.
    if (items.length % effectiveInterval == 0) {
      result.add(AdGroup(ads));
    }
    
    return result;
  }
}
