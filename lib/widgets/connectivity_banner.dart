import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Bannière de connectivité style YouTube.
///
/// - **Perte de connexion** : bannière sombre qui glisse depuis le haut
///   avec le message « Aucune connexion Internet ».
/// - **Retour de la connexion** : bannière verte avec le message
///   « De nouveau connecté à Internet » qui disparaît automatiquement.
///
/// Usage : Insérer en haut du Stack dans un Scaffold / MainScreenWrapper.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ConnectivityStatus>? _sub;

  /// null  → rien à afficher
  /// false → déconnecté
  /// true  → reconnecté (temporaire)
  bool? _showConnected;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  Timer? _autoDismissTimer;

  // Couleurs
  static const _offlineColor = Color(0xFFD32F2F); // rouge erreur
  static const _onlineColor = Color(0xFF2E7D32); // vert foncé

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // caché au-dessus
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _sub = ConnectivityService().statusStream.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    _autoDismissTimer?.cancel();

    if (status == ConnectivityStatus.disconnected) {
      // ── Perte de connexion ──
      setState(() => _showConnected = false);
      _slideController.forward();

      // Auto-dismiss après 3 secondes
      _autoDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _slideController.reverse().then((_) {
            if (mounted) setState(() => _showConnected = null);
          });
        }
      });
    } else {
      // ── Retour de la connexion ──
      setState(() => _showConnected = true);
      _slideController.forward();

      // Auto-dismiss après 3 secondes
      _autoDismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _slideController.reverse().then((_) {
            if (mounted) setState(() => _showConnected = null);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _sub?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rien à afficher
    if (_showConnected == null) return const SizedBox.shrink();

    final isOnline = _showConnected == true;
    final bgColor = isOnline ? _onlineColor : _offlineColor;
    final icon = isOnline ? Icons.wifi : Icons.wifi_off_rounded;
    final text = isOnline
        ? 'De nouveau connecté à Internet'
        : 'Aucune connexion Internet';

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 6,
        color: bgColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
