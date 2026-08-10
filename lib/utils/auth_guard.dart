import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../widgets/bottom_sheets/login_required_bottom_sheet.dart';

/// Centralise la vérification de connexion pour les actions qui nécessitent
/// un compte (ajout d'enfant, formulaires, avis, commande...).
///
/// Si l'utilisateur n'est pas connecté, affiche d'abord un bottom sheet
/// explicatif ; seulement s'il confirme, pousse [LoginScreen] par-dessus
/// l'écran/bottom sheet appelant (jamais de pushAndRemoveUntil) afin que
/// l'état de saisie local survive au détour par le login, puis exécute
/// [onAuthenticated]/[onAuthenticatedAsync] une fois la connexion confirmée.
class AuthGuard {
  AuthGuard._();

  static bool isLoggedIn() => AuthService.instance.getCurrentUser() != null;

  static Future<bool> ensureLoggedIn(
    BuildContext context, {
    String? reason,
    VoidCallback? onAuthenticated,
    Future<void> Function()? onAuthenticatedAsync,
  }) async {
    var user = AuthService.instance.getCurrentUser();
    if (user == null) {
      await AuthService.instance.loadSavedSession();
      user = AuthService.instance.getCurrentUser();
    }

    if (user != null) {
      await onAuthenticatedAsync?.call();
      onAuthenticated?.call();
      return true;
    }

    if (!context.mounted) return false;

    final wantsToLogin = await showLoginRequiredBottomSheet(
      context,
      reason: reason,
    );
    if (!wantsToLogin || !context.mounted) return false;

    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LoginScreen(popOnSuccess: true, reason: reason),
      ),
    );

    if (loggedIn == true && context.mounted) {
      await onAuthenticatedAsync?.call();
      onAuthenticated?.call();
      return true;
    }
    return false;
  }
}
