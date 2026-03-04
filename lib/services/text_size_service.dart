import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TextSize {
  petit('Petit', 0.85),
  moyen('Moyen', 1.0),
  grand('Grand', 1.15),
  tresGrand('Très grand', 1.3);

  const TextSize(this.label, this.scale);
  final String label;
  final double scale;
}

class TextSizeService extends ChangeNotifier {
  static final TextSizeService _instance = TextSizeService._internal();
  factory TextSizeService() => _instance;
  TextSizeService._internal();

  TextSize _currentTextSize = TextSize.moyen;
  TextSize get currentTextSize => _currentTextSize;

  static const String _textSizeKey = 'text_size';

  Future<void> loadTextSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textSizeIndex = prefs.getInt(_textSizeKey) ?? 1; // Moyen par défaut
      _currentTextSize = TextSize.values[textSizeIndex];
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement de la taille du texte: $e');
    }
  }

  Future<void> setTextSize(TextSize textSize) async {
    try {
      _currentTextSize = textSize;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_textSizeKey, textSize.index);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du changement de taille du texte: $e');
    }
  }

  double getScale() => _currentTextSize.scale;
  String getLabel() => _currentTextSize.label;

  TextStyle getScaledTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * _currentTextSize.scale,
      height: (baseStyle.height ?? 1.4) * (1.0 / _currentTextSize.scale),
    );
  }

  double getScaledFontSize(double baseFontSize) {
    return baseFontSize * _currentTextSize.scale;
  }
}
