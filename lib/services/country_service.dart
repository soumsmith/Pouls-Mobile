import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_http.dart' as http;

/// Un pays pris en charge par l'app, avec le serveur d'API à utiliser pour
/// tous les utilisateurs ayant choisi ce pays.
class AppCountry {
  final String code;
  final String name;
  final String flag;
  final String baseUrl;

  const AppCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.baseUrl,
  });
}

/// Gère le pays de l'utilisateur — détecté automatiquement via géolocalisation
/// IP et affiché sur la page d'accueil, avec sélection manuelle possible
/// (login/inscription/paramètres) pour la configuration de l'API.
///
/// Le choix est persisté et relu en mémoire dès le démarrage de l'app
/// (voir `main.dart`), avant `runApp()`, pour que `AppConfig.VIE_ECOLES_API_BASE_URL`
/// renvoie toujours la bonne valeur sans délai.
class CountryService extends ChangeNotifier {
  static final CountryService instance = CountryService._internal();
  CountryService._internal();

  static const String _prefsKey = 'selected_country_code';
  static const String _detectedCodeKey = 'detected_user_country_code';
  static const String _detectedNameKey = 'detected_user_country_name';
  static const String _detectedFlagKey = 'detected_user_country_flag';

  /// Noms des pays en français (repli si un provider renvoie l'anglais ou juste le code).
  static const Map<String, String> _countryNamesFr = {
    'CI': 'Côte d\'Ivoire',
    'BJ': 'Bénin',
    'SN': 'Sénégal',
    'ML': 'Mali',
    'BF': 'Burkina Faso',
    'TG': 'Togo',
    'NE': 'Niger',
    'GN': 'Guinée',
    'CM': 'Cameroun',
    'GA': 'Gabon',
    'CG': 'Congo',
    'CD': 'RDC',
    'TD': 'Tchad',
    'CF': 'Centrafrique',
    'FR': 'France',
    'BE': 'Belgique',
    'CH': 'Suisse',
    'CA': 'Canada',
    'US': 'États-Unis',
    'MA': 'Maroc',
    'TN': 'Tunisie',
    'DZ': 'Algérie',
    'GH': 'Ghana',
    'NG': 'Nigeria',
    'GB': 'Royaume-Uni',
  };

  /// Pays pris en charge pour l'API.
  static const List<AppCountry> supportedCountries = [
    AppCountry(
      code: 'CI',
      name: 'Côte d\'Ivoire',
      flag: '🇨🇮',
      baseUrl: 'https://api2.vie-ecoles.com/api',
    ),
    AppCountry(
      code: 'BJ',
      name: 'Bénin',
      flag: '🇧🇯',
      baseUrl: 'https://apiinter.vie-ecoles.com/api',
    ),
  ];

  static const AppCountry _defaultCountry = AppCountry(
    code: 'CI',
    name: 'Côte d\'Ivoire',
    flag: '🇨🇮',
    baseUrl: 'https://api2.vie-ecoles.com/api',
  );

  AppCountry _selected = _defaultCountry;

  // Données de localisation réelle d'où l'utilisateur utilise l'application
  String? _detectedCountryCode;
  String? _detectedCountryName;
  String? _detectedCountryFlag;

  /// Code pays d'où l'utilisateur utilise l'application (ex: 'CI', 'FR', 'BJ').
  String get detectedCountryCode => _detectedCountryCode ?? _selected.code;

  /// Nom du pays d'où l'utilisateur utilise l'application (ex: 'Côte d\'Ivoire', 'France').
  String get detectedCountryName => _detectedCountryName ?? _selected.name;

  /// Drapeau emoji du pays (ex: '🇨🇮', '🇫🇷').
  String get detectedCountryFlag => _detectedCountryFlag ?? _selected.flag;

  /// Texte formaté pour l'affichage (ex: "🇨🇮 Côte d'Ivoire").
  String get currentCountryDisplay => '$detectedCountryFlag $detectedCountryName'.trim();

  /// Convertit un code pays ISO 2 lettres en emoji drapeau universel.
  static String countryCodeToEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  /// Initialise le service : lit le cache puis lance la détection IP en arrière-plan.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Charger les valeurs en cache immédiat
      final savedCode = prefs.getString(_prefsKey);
      _detectedCountryCode = prefs.getString(_detectedCodeKey);
      _detectedCountryName = prefs.getString(_detectedNameKey);
      _detectedCountryFlag = prefs.getString(_detectedFlagKey);

      if (savedCode != null) {
        _selected = supportedCountries.firstWhere(
          (c) => c.code == savedCode,
          orElse: () => _defaultCountry,
        );
      }

      // Si aucune détection n'a encore été faite, on attend la première détection
      if (_detectedCountryCode == null) {
        await _detectAndSaveCountry(prefs, isFirstLaunch: savedCode == null);
      } else {
        // Déjà des données en cache : on rafraîchit en arrière-plan
        _detectAndSaveCountry(prefs, isFirstLaunch: false);
      }
    } catch (e) {
      debugPrint('⚠️ [CountryService] Erreur init: $e');
    }

    _logActiveCountry();
    notifyListeners();
  }

  /// Force une nouvelle détection (ex: pour tester ou changement de réseau)
  Future<bool> forceRedetect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_detectedCodeKey);
    await prefs.remove(_detectedNameKey);
    await prefs.remove(_detectedFlagKey);
    return await _detectAndSaveCountry(prefs, isFirstLaunch: false);
  }

  Future<bool> _detectAndSaveCountry(SharedPreferences prefs, {required bool isFirstLaunch}) async {
    final info = await _detectCountryFromIp();
    if (info == null) return false;

    final code = info['code'] ?? '';
    final name = info['name'] ?? '';
    final flag = info['flag'] ?? '';

    if (code.isNotEmpty) {
      _detectedCountryCode = code;
      _detectedCountryName = name.isNotEmpty ? name : (_countryNamesFr[code] ?? code);
      _detectedCountryFlag = flag.isNotEmpty ? flag : countryCodeToEmoji(code);

      await prefs.setString(_detectedCodeKey, _detectedCountryCode!);
      await prefs.setString(_detectedNameKey, _detectedCountryName!);
      await prefs.setString(_detectedFlagKey, _detectedCountryFlag!);

      if (isFirstLaunch) {
        // Si c'est le tout premier lancement, aligner aussi la sélection API si supportée
        _selected = supportedCountries.firstWhere(
          (c) => c.code == code,
          orElse: () => _defaultCountry,
        );
        await prefs.setString(_prefsKey, _selected.code);
      }

      _logActiveCountry();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _logActiveCountry() {
    debugPrint(
      '🌍 [CountryService] Pays d\'utilisation détecté : $currentCountryDisplay '
      '(code: $detectedCountryCode) — API active : ${_selected.flag} ${_selected.name} (${_selected.baseUrl})',
    );
  }

  /// Interroge en cascade les services de géolocalisation IP pour obtenir
  /// le pays réel d'où l'utilisateur utilise l'application.
  Future<Map<String, String>?> _detectCountryFromIp() async {
    const timeout = Duration(seconds: 3);

    // 1. Fournisseur ipwho.is (très riche, fournit nom en français + emoji drapeau)
    try {
      final response = await http
          .get(Uri.parse('https://ipwho.is/?lang=fr'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true || data['country_code'] != null) {
          final code = (data['country_code'] as String?)?.toUpperCase() ?? '';
          final name = (data['country'] as String?) ?? '';
          final flag = (data['flag'] is Map ? data['flag']['emoji'] as String? : null) ??
              countryCodeToEmoji(code);

          if (code.isNotEmpty) {
            return {
              'code': code,
              'name': name.isNotEmpty ? name : (_countryNamesFr[code] ?? code),
              'flag': flag,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CountryService] ipwho.is échoué: $e');
    }

    // 2. Fournisseur api.country.is (ultra rapide, très fiable)
    try {
      final response = await http
          .get(Uri.parse('https://api.country.is/'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final code = (data['country'] as String?)?.toUpperCase() ?? '';
        if (code.isNotEmpty) {
          return {
            'code': code,
            'name': _countryNamesFr[code] ?? code,
            'flag': countryCodeToEmoji(code),
          };
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CountryService] api.country.is échoué: $e');
    }

    // 3. Fournisseur ipapi.co (troisième repli)
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final code = (data['country_code'] as String?)?.toUpperCase() ?? '';
        final name = (data['country_name'] as String?) ?? '';
        if (code.isNotEmpty) {
          return {
            'code': code,
            'name': _countryNamesFr[code] ?? (name.isNotEmpty ? name : code),
            'flag': countryCodeToEmoji(code),
          };
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CountryService] ipapi.co échoué: $e');
    }

    return null;
  }

  AppCountry get selectedCountry => _selected;

  /// URL de base à utiliser pour toutes les requêtes "API de base"
  /// (vie-ecoles) — consommée par `AppConfig.VIE_ECOLES_API_BASE_URL`.
  String get baseUrl => _selected.baseUrl;

  Future<void> setCountry(String code) async {
    final country = supportedCountries.firstWhere(
      (c) => c.code == code,
      orElse: () => _defaultCountry,
    );
    if (country.code == _selected.code) return;

    _selected = country;
    notifyListeners();
    _logActiveCountry();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, country.code);
    } catch (e) {
      debugPrint('⚠️ [CountryService] Erreur sauvegarde pays: $e');
    }
  }
}
