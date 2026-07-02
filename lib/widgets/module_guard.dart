import 'dart:async';
import 'package:flutter/material.dart';
import '../services/module_access_service.dart';
import '../screens/subscription_screen.dart';
import '../config/app_colors.dart';

/// Widget qui contrôle l'accès à un module basé sur son identifiant API.
///
/// Si le module est accessible → affiche le [child] normalement.
/// Si le module est verrouillé → affiche le [child] avec un cadenas en overlay.
class ModuleGuard extends StatefulWidget {
  /// L'identifiant du module tel que retourné par l'API (ex: "presence-classe")
  final String moduleIdentifiant;

  /// Le widget enfant à protéger
  final Widget child;

  /// Taille de l'icône cadenas
  final double lockIconSize;

  const ModuleGuard({
    super.key,
    required this.moduleIdentifiant,
    required this.child,
    this.lockIconSize = 20.0,
  });

  static void showLockedDialog(BuildContext context) {
    showModalBottomSheet(
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
              // Icône cadenas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              // Titre
              Text(
                'Module verrouillé',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Cette fonctionnalité nécessite un abonnement actif. Découvrez nos offres pour débloquer l\'accès complet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Découvrir les offres',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Bouton fermer
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Plus tard',
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
  }

  @override
  State<ModuleGuard> createState() => _ModuleGuardState();
}

class _ModuleGuardState extends State<ModuleGuard> {
  late final StreamSubscription<void> _subscription;
  bool _isAccessible = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _subscription = ModuleAccessService().onAccessChanged.listen((_) {
      if (mounted) {
        _checkAccess();
      }
    });
  }

  void _checkAccess() {
    final accessible = ModuleAccessService().isModuleAccessible(
      widget.moduleIdentifiant,
    );
    if (accessible != _isAccessible) {
      setState(() {
        _isAccessible = accessible;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ModuleGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleIdentifiant != widget.moduleIdentifiant) {
      _checkAccess();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccessible) {
      return widget.child;
    }

    // Module verrouillé : overlay cadenas
    return GestureDetector(
      onTap: () => ModuleGuard.showLockedDialog(context),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Le widget enfant (légèrement transparent)
          AbsorbPointer(
            absorbing: true,
            child: Opacity(opacity: 0.55, child: widget.child),
          ),
          // Badge cadenas au centre
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    255,
                    255,
                    255,
                  ).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: const Color.fromARGB(255, 236, 86, 0),
                  size: widget.lockIconSize - 3, // Encore plus petit
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
