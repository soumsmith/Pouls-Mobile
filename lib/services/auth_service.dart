import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'sms_service.dart';
import 'database_service.dart';
import 'http_service.dart';
import 'cart_service.dart';

/// Résultat de la connexion directe
enum DirectLoginResult {
  success,
  userNotFound,
  error,
}

/// Résultat de l'envoi d'OTP
enum OtpSendResult {
  success,
  insufficientCredits,
  error,
}

/// Service d'authentification
/// 
/// TODO: En production, implémenter :
/// - POST /api/auth/login avec email/password
/// - Stockage sécurisé du token JWT (flutter_secure_storage)
/// - Refresh token automatique
/// - Déconnexion avec invalidation du token
class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  // Token stocké en mémoire (mock)
  // TODO: Utiliser flutter_secure_storage pour stocker le token de manière sécurisée
  String? _token;
  User? _currentUser;
  
  // Clés pour le stockage persistant
  static const String _keyPhone = 'saved_phone';
  static const String _keyUser = 'saved_user';
  static const String _keyToken = 'saved_token';
  
  // Coût d'un SMS OTP (en crédits)
  static const int _smsOtpCost = 1;
  
  // Service SMS (par défaut en mode mock)
  // TODO: En production, remplacer par un vrai service SMS
  SmsService _smsService = MockSmsService();
  
  /// Configure le service SMS à utiliser
  /// 
  /// Permet de changer de MockSmsService vers un vrai service en production
  void setSmsService(SmsService smsService) {
    _smsService = smsService;
  }

  /// Connecte l'utilisateur directement avec l'API sans OTP
  /// 
  /// Endpoint: POST /api/vie-ecoles/auth/parent/connexion
  /// Body: { "numero": "+2250748011247" }
  /// Response: { "status": true, "data": { "token": "...", "user": {...} } }
  Future<DirectLoginResult> loginDirectly(String phone) async {
    try {
      print('🔐 Tentative de connexion directe avec: $phone');
      
      final response = await HttpService.post(
        '/api/vie-ecoles/auth/parent/connexion',
        body: {
          'numero': phone,
        },
      );

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;
        
        if (token != null && userData != null) {
          // Créer l'utilisateur à partir des données de l'API
          _currentUser = User.fromJson(userData);
          _token = token;
          
          // Sauvegarder la session
          await _saveSession();
          
          // Sauvegarder l'utilisateur dans la base de données locale
          await DatabaseService.instance.saveUser(_currentUser!);
          
          // Recharger le panier pour l'utilisateur connecté
          await MockCartService().reloadCartForCurrentUser();
          
          print('✅ Connexion réussie pour: ${_currentUser!.fullName}');
          return DirectLoginResult.success;
        }
      }
      
      return DirectLoginResult.error;
    } catch (e) {
      print('❌ Erreur lors de la connexion directe: $e');
      
      // Vérifier si c'est l'erreur "Aucun parent lié à ce numéro"
      if (e.toString().contains('Aucun parent lié à ce numéro de téléphone')) {
        return DirectLoginResult.userNotFound;
      }
      
      return DirectLoginResult.error;
    }
  }

  /// Tente de se connecter avec un numéro de téléphone
  /// Envoie un code OTP pour la connexion
  /// 
  /// TODO: Endpoint: POST /api/auth/login
  /// Body: { "phone": "+2250748011247" }
  /// Response: { "success": true, "message": "OTP sent" }
  Future<OtpSendResult> loginWithPhone(String phone) async {
    // Vérifier les crédits avant l'envoi
    final hasCredits = await hasEnoughSmsCredits(phone);
    if (!hasCredits) {
      return OtpSendResult.insufficientCredits;
    }
    
    // Vérifier que le service SMS est disponible
    if (!_smsService.isAvailable) {
      print('⚠️  Service SMS non disponible');
      return OtpSendResult.error;
    }
    
    // Générer le code OTP
    final otpCode = _generateOtp();
    _pendingPhone = phone;
    _pendingOtp = otpCode;
    
    // Envoyer le SMS via le service SMS
    final smsSent = await _smsService.sendOtpSms(phone, otpCode);
    
    if (!smsSent) {
      print('❌ Échec de l\'envoi du SMS');
      return OtpSendResult.error;
    }
    
    // Déduire les crédits après l'envoi réussi
    await _deductSmsCredits(phone);
    
    return OtpSendResult.success;
  }

  /// Vérifie l'OTP et connecte l'utilisateur
  /// 
  /// TODO: Endpoint: POST /api/auth/verify-otp-and-login
  /// Body: { "phone": "...", "otp": "123456" }
  /// Response: { "token": "JWT_TOKEN", "user": {...} }
  Future<bool> verifyOtpAndLogin(String phone, String otp) async {
    // Simule un délai réseau
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Mock: vérifie l'OTP (accepte 123456 ou si le téléphone correspond)
    if (_pendingPhone == phone && _pendingOtp == otp) {
      // Charge l'utilisateur depuis le stockage ou crée un utilisateur par défaut
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString(_keyUser);
      
      if (savedUserJson != null) {
        // Utilisateur existant, charge ses données
        final userMap = json.decode(savedUserJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        _token = prefs.getString(_keyToken) ?? 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Nouvel utilisateur (ne devrait pas arriver en login, mais au cas où)
        _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
        final remainingCredits = _phoneCredits[phone] ?? 0;
        _currentUser = User(
          id: 'parent_${phone.replaceAll(RegExp(r'[^0-9]'), '')}', // ID basé sur le téléphone
          email: '$phone@parent.local',
          firstName: 'Parent',
          lastName: 'Utilisateur',
          phone: phone,
          smsCredits: remainingCredits,
        );
        
        // Sauvegarder l'utilisateur dans la base de données
        await DatabaseService.instance.saveUser(_currentUser!);
      }
      
      // Sauvegarder la session
      await _saveSession();
      
      // Recharger le panier pour l'utilisateur connecté
      await MockCartService().reloadCartForCurrentUser();
      
      // Réinitialise les données temporaires
      _pendingPhone = null;
      _pendingOtp = null;
      
      return true;
    }
    
    // Pour les tests, accepte aussi 123456 directement
    if (otp == '123456') {
      // Charge l'utilisateur depuis le stockage ou crée un utilisateur par défaut
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString(_keyUser);
      
      if (savedUserJson != null) {
        // Utilisateur existant, charge ses données
        final userMap = json.decode(savedUserJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        _token = prefs.getString(_keyToken) ?? 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Nouvel utilisateur
        _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
        final remainingCredits = _phoneCredits[phone] ?? 0;
        _currentUser = User(
          id: 'parent_${phone.replaceAll(RegExp(r'[^0-9]'), '')}', // ID basé sur le téléphone
          email: '$phone@parent.local',
          firstName: 'Parent',
          lastName: 'Utilisateur',
          phone: phone,
          smsCredits: remainingCredits,
        );
        
        // Sauvegarder l'utilisateur dans la base de données
        await DatabaseService.instance.saveUser(_currentUser!);
      }
      
      // Sauvegarder la session
      await _saveSession();
      
      // Recharger le panier pour l'utilisateur connecté
      await MockCartService().reloadCartForCurrentUser();
      
      return true;
    }
    
    return false;
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    // Nettoyer le panier de l'utilisateur avant la déconnexion
    await MockCartService().clearCurrentUserCart();
    
    _token = null;
    _currentUser = null;
    // Supprimer la session sauvegardée
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
  }
  
  /// Sauvegarde la session actuelle
  Future<void> _saveSession() async {
    if (_currentUser == null || _token == null) {
      print('❌ Impossible de sauvegarder la session: utilisateur ou token null');
      return;
    }
    
    print('💾 Sauvegarde de la session...');
    print('   - Utilisateur: ${_currentUser!.firstName} ${_currentUser!.lastName}');
    print('   - Téléphone: ${_currentUser!.phone}');
    print('   - Token: ${_token!.substring(0, 20)}...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, _currentUser!.phone);
    await prefs.setString(_keyUser, json.encode(_currentUser!.toJson()));
    await prefs.setString(_keyToken, _token!);
    
    print('✅ Session sauvegardée avec succès');
  }
  
  /// Charge la session sauvegardée
  Future<bool> loadSavedSession() async {
    try {
      print('🔄 Chargement de la session sauvegardée...');
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString(_keyPhone);
      final savedUserJson = prefs.getString(_keyUser);
      final savedToken = prefs.getString(_keyToken);
      
      print('📱 Téléphone sauvegardé: $savedPhone');
      print('🔑 Token sauvegardé: ${savedToken != null ? 'Oui' : 'Non'}');
      print('👤 Utilisateur sauvegardé: ${savedUserJson != null ? 'Oui' : 'Non'}');
      
      if (savedPhone != null && savedToken != null) {
        // Essayer de charger depuis la base de données d'abord
        User? user = await DatabaseService.instance.getUserByPhone(savedPhone);
        
        if (user == null && savedUserJson != null) {
          // Fallback sur SharedPreferences si pas dans la DB
          print('⚠️ Utilisateur non trouvé dans la DB, utilisation de SharedPreferences');
          final userMap = json.decode(savedUserJson) as Map<String, dynamic>;
          user = User.fromJson(userMap);
          // Sauvegarder dans la DB pour la prochaine fois
          await DatabaseService.instance.saveUser(user);
        }
        
        if (user != null) {
          _currentUser = user;
          _token = savedToken;
          print('✅ Session chargée avec succès pour: ${user.firstName} ${user.lastName}');
          
          // Recharger le panier pour l'utilisateur connecté
          await MockCartService().reloadCartForCurrentUser();
          
          return true;
        } else {
          print('❌ Aucun utilisateur trouvé dans les sources de données');
        }
      } else {
        print('⚠️ Informations de session incomplètes - phone: $savedPhone, token: $savedToken');
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors du chargement de la session: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Récupère le numéro de téléphone sauvegardé (pour pré-remplir le formulaire)
  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isLoggedIn => _token != null && _currentUser != null;

  /// Récupère le token JWT actuel
  /// 
  /// TODO: En production, récupérer depuis flutter_secure_storage
  String? getToken() => _token;

  /// Récupère l'utilisateur actuel
  User? getCurrentUser() => _currentUser;

  /// Vérifie si le token est valide
  /// 
  /// TODO: En production, vérifier l'expiration du JWT
  bool isTokenValid() {
    if (_token == null) return false;
    // Mock: considère le token toujours valide
    return true;
  }

  // Stockage temporaire pour l'inscription
  String? _pendingPhone;
  String? _pendingOtp;
  
  // Stockage temporaire des crédits SMS par téléphone (pour l'inscription)
  final Map<String, int> _phoneCredits = {};

  /// Récupère les crédits SMS d'un utilisateur par son numéro de téléphone
  /// 
  /// TODO: Endpoint: GET /api/auth/sms-credits?phone={phone}
  /// Response: { "smsCredits": 10 }
  Future<int> getSmsCreditsByPhone(String phone) async {
    // Si l'utilisateur est connecté et que le téléphone correspond, utiliser ses crédits
    if (_currentUser != null && _currentUser!.phone == phone) {
      return _currentUser!.smsCredits;
    }
    
    // Sinon, vérifier dans le stockage temporaire (pour l'inscription)
    if (_phoneCredits.containsKey(phone)) {
      return _phoneCredits[phone]!;
    }
    
    // Mock: Par défaut, on attribue 10 crédits pour les nouveaux utilisateurs
    // TODO: En production, récupérer depuis l'API
    _phoneCredits[phone] = 10;
    return 10;
  }

  /// Vérifie si l'utilisateur a suffisamment de crédits SMS
  Future<bool> hasEnoughSmsCredits(String phone) async {
    final credits = await getSmsCreditsByPhone(phone);
    return credits >= _smsOtpCost;
  }

  /// Déduit les crédits SMS après l'envoi d'un OTP
  Future<void> _deductSmsCredits(String phone) async {
    // Si l'utilisateur est connecté et que le téléphone correspond
    if (_currentUser != null && _currentUser!.phone == phone) {
      final newCredits = _currentUser!.smsCredits - _smsOtpCost;
      _currentUser = _currentUser!.copyWith(smsCredits: newCredits);
      return;
    }
    
    // Sinon, mettre à jour le stockage temporaire
    final currentCredits = await getSmsCreditsByPhone(phone);
    _phoneCredits[phone] = currentCredits - _smsOtpCost;
  }

  /// Génère un code OTP aléatoire à 6 chiffres
  String _generateOtp() {
    // En mode développement, on retourne toujours 123456 pour faciliter les tests
    // TODO: En production, générer un code aléatoire sécurisé
    if (_smsService is MockSmsService) {
      return '123456';
    }
    
    // Génération d'un code OTP aléatoire à 6 chiffres
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 900000 + 100000).toString();
    return otp;
  }

  /// Envoie un code OTP au numéro de téléphone
  /// 
  /// TODO: Endpoint: POST /api/auth/send-otp
  /// Body: { "phone": "+2250748011247" }
  /// Response: { "success": true, "message": "OTP sent" }
  /// 
  /// Retourne OtpSendResult.success si l'envoi a réussi,
  /// OtpSendResult.insufficientCredits si les crédits sont insuffisants,
  /// OtpSendResult.error en cas d'erreur
  Future<OtpSendResult> sendOtp(String phone) async {
    // Vérifier les crédits avant l'envoi
    final hasCredits = await hasEnoughSmsCredits(phone);
    if (!hasCredits) {
      return OtpSendResult.insufficientCredits;
    }
    
    // Vérifier que le service SMS est disponible
    if (!_smsService.isAvailable) {
      print('⚠️  Service SMS non disponible');
      return OtpSendResult.error;
    }
    
    // Générer le code OTP
    final otpCode = _generateOtp();
    _pendingPhone = phone;
    _pendingOtp = otpCode;
    
    // Envoyer le SMS via le service SMS
    final smsSent = await _smsService.sendOtpSms(phone, otpCode);
    
    if (!smsSent) {
      print('❌ Échec de l\'envoi du SMS');
      return OtpSendResult.error;
    }
    
    // Déduire les crédits après l'envoi réussi
    await _deductSmsCredits(phone);
    
    return OtpSendResult.success;
  }

  /// Vérifie l'OTP et crée le compte
  /// 
  /// TODO: Endpoint: POST /api/auth/verify-otp-and-signup
  /// Body: { "phone": "...", "otp": "123456", "firstName": "...", "lastName": "...", "email": "..." }
  /// Response: { "token": "JWT_TOKEN", "user": {...} }
  Future<bool> verifyOtpAndCreateAccount({
    required String phone,
    required String otp,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    // Simule un délai réseau
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Mock: vérifie l'OTP (accepte 123456 ou si le téléphone correspond)
    if (_pendingPhone == phone && _pendingOtp == otp) {
      // Crée le compte et connecte l'utilisateur
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      // Récupérer les crédits restants du téléphone
      final remainingCredits = _phoneCredits[phone] ?? 0;
      
      _currentUser = User(
        id: 'parent_${phone.replaceAll(RegExp(r'[^0-9]'), '')}', // ID basé sur le téléphone
        email: email ?? '$phone@parent.local',
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        smsCredits: remainingCredits,
      );
      
      // Sauvegarder l'utilisateur dans la base de données
      await DatabaseService.instance.saveUser(_currentUser!);
      
      // Sauvegarder la session
      await _saveSession();
      
      // Recharger le panier pour l'utilisateur connecté
      await MockCartService().reloadCartForCurrentUser();
      
      // Réinitialise les données temporaires
      _pendingPhone = null;
      _pendingOtp = null;
      _phoneCredits.remove(phone);
      
      return true;
    }
    
    // Pour les tests, accepte aussi 123456 directement
    if (otp == '123456') {
      // Récupérer les crédits restants du téléphone
      final remainingCredits = _phoneCredits[phone] ?? 0;
      
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = User(
        id: 'parent_${phone.replaceAll(RegExp(r'[^0-9]'), '')}', // ID basé sur le téléphone
        email: email ?? '$phone@parent.local',
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        smsCredits: remainingCredits,
      );
      
      // Sauvegarder l'utilisateur dans la base de données
      await DatabaseService.instance.saveUser(_currentUser!);
      
      // Sauvegarder la session
      await _saveSession();
      
      // Recharger le panier pour l'utilisateur connecté
      await MockCartService().reloadCartForCurrentUser();
      
      // Réinitialise les données temporaires
      _phoneCredits.remove(phone);
      
      return true;
    }
    
    return false;
  }
}

