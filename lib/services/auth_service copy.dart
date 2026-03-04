import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OtpSendResult { success, insufficientCredits, failed }

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  bool _isLoggedIn = false;
  String? _currentUser;
  String? _userToken;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;
  String? get userToken => _userToken;

  // Initialiser le service
  Future<void> init() async {
    await loadSavedSession();
  }

  // Charger une session sauvegardée
  Future<bool> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _currentUser = prefs.getString('current_user');
      _userToken = prefs.getString('user_token');

      return _isLoggedIn && (_currentUser != null || _userToken != null);
    } catch (e) {
      debugPrint('Erreur lors du chargement de la session: $e');
      return false;
    }
  }

  // Sauvegarder la session
  Future<void> saveSession({
    required bool isLoggedIn,
    String? user,
    String? token,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('is_logged_in', isLoggedIn);
      
      if (user != null) {
        await prefs.setString('current_user', user);
        _currentUser = user;
      }
      
      if (token != null) {
        await prefs.setString('user_token', token);
        _userToken = token;
      }

      _isLoggedIn = isLoggedIn;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la session: $e');
    }
  }

  // Sauvegarder le numéro de téléphone
  Future<void> savePhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_phone', phone);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du téléphone: $e');
    }
  }

  // Charger le numéro de téléphone sauvegardé
  Future<String?> getSavedPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_phone');
    } catch (e) {
      debugPrint('Erreur lors du chargement du téléphone: $e');
      return null;
    }
  }

  // Connexion avec téléphone (envoi OTP)
  Future<OtpSendResult> loginWithPhone(String phone) async {
    try {
      // Simuler l'envoi d'OTP
      await Future.delayed(const Duration(seconds: 1));
      
      // Sauvegarder le numéro de téléphone
      await savePhone(phone);
      
      // Simulation de résultat (toujours succès pour le démo)
      return OtpSendResult.success;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      return OtpSendResult.failed;
    }
  }

  // Envoyer OTP pour inscription
  Future<OtpSendResult> sendOtp(String phone) async {
    try {
      // Simuler l'envoi d'OTP
      await Future.delayed(const Duration(seconds: 1));
      
      // Sauvegarder le numéro de téléphone
      await savePhone(phone);
      
      // Simulation de résultat (toujours succès pour le démo)
      return OtpSendResult.success;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de l\'OTP: $e');
      return OtpSendResult.failed;
    }
  }

  // Vérifier OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      // Simuler la vérification OTP
      await Future.delayed(const Duration(seconds: 1));
      
      // Code de test pour la démo
      if (otp == '123456') {
        // Créer la session après vérification réussie
        await saveSession(
          isLoggedIn: true,
          user: phone,
          token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification OTP: $e');
      return false;
    }
  }

  // Connexion (méthode originale pour compatibilité)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simuler une connexion API
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulation de validation (à remplacer par une vraie API)
      if (email.isNotEmpty && password.isNotEmpty) {
        await saveSession(
          isLoggedIn: true,
          user: email,
          token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      return false;
    }
  }

  // Inscription (méthode originale pour compatibilité)
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Simuler une inscription API
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulation de validation (à remplacer par une vraie API)
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        await saveSession(
          isLoggedIn: true,
          user: email,
          token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _isLoggedIn = false;
      _currentUser = null;
      _userToken = null;
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  // Vérifier si le token est valide
  Future<bool> isTokenValid() async {
    if (_userToken == null) return false;
    
    try {
      // Simulation de validation de token (à remplacer par une vraie API)
      return _userToken!.startsWith('mock_token_');
    } catch (e) {
      debugPrint('Erreur lors de la validation du token: $e');
      return false;
    }
  }

  // Rafraîchir le token
  Future<bool> refreshToken() async {
    try {
      // Simulation de rafraîchissement de token (à remplacer par une vraie API)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_isLoggedIn) {
        await saveSession(
          isLoggedIn: true,
          user: _currentUser,
          token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }
}
