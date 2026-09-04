import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;
import '../config/app_config.dart';

/// Authentification auprès de l'API de consultation (api-pedagogie.pouls-scolaire.net).
///
/// Utilise un compte de service unique (AppConfig.PEDAGOGIE_AUTH_EMAIL/PASSWORD) pour
/// obtenir un jeton Bearer en arrière-plan, commun à toutes les requêtes de
/// ConsultationApiService — il n'y a pas de login par parent pour cette API.
class PedagogieAuthService {
  static final PedagogieAuthService instance = PedagogieAuthService._internal();
  factory PedagogieAuthService() => instance;
  PedagogieAuthService._internal();

  static const String _keyToken = 'pedagogie_access_token';
  static const String _keyExpiresAt = 'pedagogie_token_expires_at';

  String? _accessToken;
  DateTime? _expiresAt;

  /// Marge de sécurité avant expiration pour déclencher un renouvellement anticipé.
  static const Duration _expiryMargin = Duration(seconds: 30);

  /// Retourne un jeton Bearer valide, en le renouvelant si besoin.
  Future<String> getValidToken() async {
    if (_accessToken == null || _expiresAt == null) {
      await _restoreFromStorage();
    }
    if (_accessToken == null || _isExpired()) {
      await _login();
    }
    return _accessToken!;
  }

  /// Force un renouvellement du jeton (utilisé après un 401 en aval).
  Future<String> forceRefresh() async {
    await _login();
    return _accessToken!;
  }

  bool _isExpired() {
    if (_expiresAt == null) return true;
    return DateTime.now().isAfter(_expiresAt!.subtract(_expiryMargin));
  }

  Future<void> _login() async {
    final uri = Uri.parse('${AppConfig.PEDAGOGIE_API_BASE_URL}/v1/auth/login');
    final requestBody = {
      'email': AppConfig.PEDAGOGIE_AUTH_EMAIL,
      'password': AppConfig.PEDAGOGIE_AUTH_PASSWORD,
    };
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🔌 API CONSULTATION — login');
    print('🔗 URL: POST $uri');
    print(
      '📦 Body: ${json.encode({...requestBody, 'password': '***'})}',
    );
    print('⏱️  ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(AppConfig.API_TIMEOUT);
    } catch (e) {
      print('💥 API CONSULTATION — login a levé une exception: $e');
      rethrow;
    }

    if (response.statusCode != 200) {
      print('❌ API CONSULTATION — login → ${response.statusCode}: ${response.body}');
      throw Exception(
        'Erreur lors de l\'authentification à l\'API de consultation: '
        '${response.statusCode} - ${response.body}',
      );
    }
    print('✅ API CONSULTATION — login → ${response.statusCode}');

    final data = json.decode(response.body) as Map<String, dynamic>;
    final token = data['accessToken'] as String?;
    final expiresIn = data['expiresIn'] as int?;
    if (token == null) {
      throw Exception('Réponse de login invalide: accessToken manquant');
    }

    _accessToken = token;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn ?? 3600));
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, _accessToken!);
    await prefs.setString(_keyExpiresAt, _expiresAt!.toIso8601String());
  }

  Future<void> _restoreFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken);
    final savedExpiresAt = prefs.getString(_keyExpiresAt);
    if (savedToken != null && savedExpiresAt != null) {
      _accessToken = savedToken;
      _expiresAt = DateTime.tryParse(savedExpiresAt);
    }
  }
}
