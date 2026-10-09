import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';

enum HomeBackgroundStyle {
  black('Noir', Colors.black),
  blue('Bleu', AppColors.homeBackgroundBlueSolid);

  const HomeBackgroundStyle(this.label, this.color);
  final String label;
  final Color color;
}

/// Style de fond de l'écran d'accueil, choisi par l'utilisateur (noir uni ou
/// bleu uni, sans dégradé) — même schéma que [TextSizeService].
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

  BoxDecoration get decoration => BoxDecoration(color: _style.color);

  /// Couleur de fond, à utiliser derrière l'en-tête (fond du Scaffold) pour
  /// que rien ne transparaisse dans les coins arrondis de la feuille du bas.
  Color get seamColor => _style.color;
}
