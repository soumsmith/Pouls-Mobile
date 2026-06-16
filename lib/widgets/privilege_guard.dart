import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../screens/subscription_screen.dart';

class PrivilegeGuard extends StatelessWidget {
  final String requiredLevel;
  final Widget child;
  final Widget? fallback;
  final bool showLockOverlay;

  const PrivilegeGuard({
    super.key,
    required this.requiredLevel,
    required this.child,
    this.fallback,
    this.showLockOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = SubscriptionService.instance.hasPrivilege(requiredLevel);

    if (hasAccess) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    if (showLockOverlay) {
      return Stack(
        children: [
          // Flouter légèrement le contenu
          Opacity(
            opacity: 0.3,
            child: child,
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.amber.shade800,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fonctionnalité Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      child: const Text('Découvrir les offres'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Si on ne veut pas d'overlay et pas de fallback, on renvoie simplement rien.
    return const SizedBox.shrink();
  }
}
