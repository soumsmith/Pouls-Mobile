import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../screens/signup_screen.dart';

/// Bottom sheet informant l'utilisateur invité qu'une connexion est requise
/// avant de poursuivre une action. Retourne `true` si l'utilisateur choisit
/// de se connecter, `false` s'il annule/ferme le sheet.
Future<bool> showLoginRequiredBottomSheet(
  BuildContext context, {
  String? reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icône
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.screenOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: AppColors.screenOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            // Titre
            Text(
              'Connexion requise',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              reason ?? 'Vous devez être connecté pour effectuer cette action.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Bouton principal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.screenOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton créer un compte (même style que sur l'écran de connexion)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFF2F4F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop(false);
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton annuler
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
