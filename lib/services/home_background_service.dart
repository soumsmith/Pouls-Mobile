import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';

enum HomeBackgroundStyle {
  black('Noir', null),
  blue('Bleu', AppColors.homeBackgroundBlueGradient),
  green('Vert', AppColors.homeBackgroundGreenGradient),
  orange('Orange', AppColors.homeBackgroundOrangeGradient);

  const HomeBackgroundStyle(this.label, this.gradient);
  final String label;
  final LinearGradient? gradient;
}

/// Style de fond de l'écran d'accueil, choisi par l'utilisateur (noir uni,
/// ou dégradé bleu/vert/orange) — même schéma que [TextSizeService].
class HomeBackgroundService extends ChangeNotifier {
  static final HomeBackgroundService _instance =
      HomeBackgroundService._internal();
  factory HomeBackgroundService() => _instance;
  HomeBackgroundService._internal();

  HomeBackgroundStyle _style = HomeBackgroundStyle.black;
  HomeBackgroundStyle get style => _style;

  static const String _prefsKey = 'home_background_style';

  Future<void> loadStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_prefsKey) ?? 0;
      _style = HomeBackgroundStyle.values[
          index >= 0 && index < HomeBackgroundStyle.values.length
              ? index
              : 0];
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du fond d\'accueil: $e');
    }
  }

  Future<void> setStyle(HomeBackgroundStyle style) async {
    try {
      _style = style;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, style.index);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du changement du fond d\'accueil: $e');
    }
  }

  BoxDecoration get decoration => _style.gradient != null
      ? BoxDecoration(gradient: _style.gradient)
      : const BoxDecoration(color: Colors.black);

  /// Couleur du dégradé au point le plus bas de l'écran (ou noir) : à
  /// utiliser derrière l'en-tête (fond du Scaffold) pour que rien ne
  /// transparaisse dans les coins arrondis de la feuille du bas. Le
  /// dégradé va de `begin` à `end` : la couleur en bas dépend donc de
  /// l'orientation (`begin`/`end` bottomCenter ↔ topCenter).
  Color get seamColor {
    final gradient = _style.gradient;
    if (gradient == null) return Colors.black;
    return gradient.begin == Alignment.bottomCenter
        ? gradient.colors.first
        : gradient.colors.last;
  }
}
