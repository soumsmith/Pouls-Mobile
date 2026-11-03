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

/// Gère le pays de l'utilisateur — détecté automatiquement au premier
/// lancement (géolocalisation IP), modifiable ensuite via le sélecteur
/// manuel (login/inscription/paramètres) — et l'URL de base d'API qui en
/// découle.
///
/// Le choix est persisté et relu en mémoire dès le démarrage de l'app
/// (voir `main.dart`), avant `runApp()`, pour que `AppConfig.VIE_ECOLES_API_BASE_URL`
/// (lu de façon synchrone par ~70 services/écrans existants) renvoie
/// toujours la bonne valeur sans qu'aucun de ces appelants n'ait à changer.
class CountryService extends ChangeNotifier {
  static final CountryService instance = CountryService._internal();
  CountryService._internal();

  static const String _prefsKey = 'selected_country_code';

  /// Pays pris en charge. Le premier (Côte d'Ivoire) reste le défaut pour ne
  /// rien changer au comportement des utilisateurs existants. Pour ajouter
  /// un nouveau pays : ajouter une entrée ici, rien d'autre à toucher.
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

  /// Doit être appelé une fois, avant `runApp()`, pour que le pays (choisi
  /// manuellement ou détecté) soit déjà en mémoire au tout premier rendu.
  ///
  /// Au tout premier lancement (aucune valeur sauvegardée), le pays est
  /// détecté automatiquement via géolocalisation IP — aucune permission
  /// requise, fonctionne aussi en WiFi. Le résultat est ensuite persisté
  /// une bonne fois pour toutes : les lancements suivants ne refont jamais
  /// cet appel réseau, et l'utilisateur garde la main via le sélecteur
  /// manuel (login/inscription/paramètres) pour corriger si besoin.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefsKey);

      if (savedCode != null) {
        _selected = supportedCountries.firstWhere(
          (c) => c.code == savedCode,
          orElse: () => _defaultCountry,
        );
      } else {
        // Premier lancement : détection automatique, avec repli silencieux
        // sur le pays par défaut si tous les services de détection échouent
        // ou ne renvoient pas un pays pris en charge.
        final detectedCode = await _detectCountryCodeFromIp();
        _selected = supportedCountries.firstWhere(
          (c) => c.code == detectedCode,
          orElse: () => _defaultCountry,
        );

        // On enregistre le résultat (même le repli) pour ne plus jamais
        // relancer la détection sur cet appareil.
        await prefs.setString(_prefsKey, _selected.code);
      }
    } catch (e) {
      debugPrint('⚠️ [CountryService] Erreur chargement/détection pays: $e');
    }

    _logActiveCountry();
    notifyListeners();
  }

  /// Debug uniquement : efface le choix persisté et relance la détection
  /// IP comme au tout premier lancement (utile pour tester la détection
  /// automatique — avec un VPN — sans désinstaller l'app).
  Future<void> forceRedetect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await init();
  }

  void _logActiveCountry() {
    debugPrint(
      '🌍 [CountryService] Pays actif : ${_selected.flag} ${_selected.name} '
      '(${_selected.code}) — API de base : ${_selected.baseUrl}',
    );
  }

  /// Interroge, en cascade, un ou deux services de géolocalisation IP
  /// (tous deux en HTTPS, sans clé requise) pour deviner le pays de
  /// l'utilisateur. Chaque appel est borné à 2,5s ; si les deux échouent
  /// (service down, pas de réseau, timeout...), retourne `null` et laisse
  /// l'appelant replier sur le pays par défaut — jamais de blocage long ni
  /// de crash au démarrage à cause d'un service tiers indisponible.
  Future<String?> _detectCountryCodeFromIp() async {
    const timeout = Duration(seconds: 2, milliseconds: 500);
    const providers = <String>[
      'https://ipwho.is/',
      'https://api.country.is/',
    ];

    for (final url in providers) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(timeout);
        if (response.statusCode != 200) continue;

        final data = json.decode(response.body) as Map<String, dynamic>;
        // Selon le fournisseur, le champ s'appelle "country_code" (ipwho.is)
        // ou directement "country" (api.country.is).
        final raw = (data['country_code'] ?? data['country']) as String?;
        final code = raw?.toUpperCase();
        if (code != null && code.isNotEmpty) {
          debugPrint('🌍 [CountryService] Pays détecté via $url : $code');
          return code;
        }
      } catch (e) {
        debugPrint('⚠️ [CountryService] Échec détection via $url : $e');
        // On tente le fournisseur suivant.
      }
    }

    debugPrint(
      '⚠️ [CountryService] Aucun service de géolocalisation IP disponible, '
      'repli sur le pays par défaut.',
    );
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
