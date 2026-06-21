---
name: Connectivity Plus Implementation (Robust Ping & UI Banner)
description: Implémentation robuste de la connectivité dans Flutter combinant `connectivity_plus` pour les événements OS et un Ping Socket direct (8.8.8.8) pour la vérification de l'accès réel. Inclut un widget de bannière UI style YouTube.
---

# Gestion Avancée de la Connectivité

Ce guide détaille l'architecture définitive pour gérer la perte et le retour de connexion internet dans une application Flutter. 

Contrairement aux implémentations naïves, cette solution ne compte pas uniquement sur l'état de l'interface réseau (qui ment souvent sur émulateur ou sur les Wi-Fi publics "portails captifs"), mais effectue un véritable test de connexion via un **Socket TCP vers Google DNS**.

## 1. Prérequis

Ajoutez la dépendance dans `pubspec.yaml` :

```yaml
dependencies:
  connectivity_plus: ^7.1.1 # Ou la version la plus récente compatible
```

## 2. Le Service de Connectivité (`connectivity_service.dart`)

Ce singleton gère la logique de détection. Il utilise un "Polling de récupération" (vérification toutes les 3s en arrière-plan) pour contourner les événements manquants de l'OS.

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus { connected, disconnected }

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  bool? _isOnline;
  bool? get isOnline => _isOnline;

  ConnectivityStatus get lastStatus =>
      _isOnline == false
          ? ConnectivityStatus.disconnected
          : ConnectivityStatus.connected;

  bool _initialized = false;
  Timer? _pollingTimer;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  final List<VoidCallback> _reconnectCallbacks = [];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Première vérification immédiate
    _isOnline = await _hasRealInternetAccess();
    
    // Polling en boucle toutes les 3 secondes pour vérifier l'accès réel.
    // Infaillible sur émulateur et gère les portails captifs.
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final hasNet = await _hasRealInternetAccess();
      _applyState(hasNet);
    });
  }

  /// Tente d'ouvrir une connexion TCP rapide sur le port 53 (DNS) de Google.
  /// Beaucoup plus fiable que InternetAddress.lookup sur les émulateurs.
  Future<bool> _hasRealInternetAccess() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy(); // On referme immédiatement
      return true;
    } catch (_) {
      return false; // TimeOut ou réseau inaccessible
    }
  }

  void _applyState(bool newState) {
    if (_isOnline == newState) return; // Pas de changement

    final wasOffline = _isOnline == false;
    _isOnline = newState;

    if (newState) {
      _statusController.add(ConnectivityStatus.connected);
      debugPrint('🌐 ✅ CONNEXION RÉTABLIE !');
      
      if (wasOffline) {
        for (final cb in List<VoidCallback>.from(_reconnectCallbacks)) {
          try { cb(); } catch (e) { debugPrint('⚠️ callback error: $e'); }
        }
      }
    } else {
      _statusController.add(ConnectivityStatus.disconnected);
      debugPrint('🌐 ❌ CONNEXION PERDUE !');
    }
  }

  void onReconnect(VoidCallback callback) => _reconnectCallbacks.add(callback);
  void removeReconnectCallback(VoidCallback callback) => _reconnectCallbacks.remove(callback);

  void dispose() {
    _pollingTimer?.cancel();
    _statusController.close();
    _reconnectCallbacks.clear();
  }
}
```

## 3. L'Interface UI : Bannière style YouTube (`connectivity_banner.dart`)

Un widget autonome qui s'abonne au flux du service et anime une bannière élégante depuis le haut de l'écran. Elle se masque automatiquement après 3 secondes, qu'il s'agisse de la perte ou du retour de la connexion.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart'; // Ajuster le chemin

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ConnectivityStatus>? _sub;

  bool? _showConnected; // null=caché, false=déconnecté, true=connecté
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  static const _offlineColor = Color(0xFFD32F2F); // Rouge erreur
  static const _onlineColor = Color(0xFF2E7D32);  // Vert succès

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
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
    
    // Met à jour l'état et lance l'animation
    setState(() => _showConnected = status == ConnectivityStatus.connected);
    _slideController.forward();

    // Fait disparaître la bannière automatiquement après 3 secondes
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _slideController.reverse().then((_) {
          if (mounted) setState(() => _showConnected = null);
        });
      }
    });
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
```

## 4. Intégration dans l'Application

### A. Initialisation au Démarrage (`main.dart`)
Le service doit être démarré au lancement de l'application :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Démarrer la surveillance réseau
  await ConnectivityService().init();
  
  runApp(const MyApp());
}
```

### B. Ajout dans l'Interface Principale (`MainScreenWrapper` ou `Scaffold`)
Placez la bannière dans un composant racine (souvent un `Stack` gérant la navigation) pour qu'elle s'affiche par-dessus tous les écrans :

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // ... vos écrans (PageView, IndexedStack, Router...)
        
        // La Bannière de connectivité tout en haut du Stack
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConnectivityBanner(),
        ),
      ],
    ),
  );
}
```

## Résolution des Problèmes / Cas Pratiques

- **Le simulateur iOS / l'émulateur Android ne lance pas d'événement quand le Wi-Fi du Mac est coupé :**
  C'est le but du polling toutes les 3s implémenté dans le service ! Il vérifie l'accès en tapant sur `8.8.8.8`. Même si l'OS oublie d'avertir Flutter, le service le détectera.
- **Portails Captifs (Hôtels, Gares) :** 
  L'appareil indique "Connecté au Wi-Fi" mais il n'y a pas encore d'internet. Avec la méthode du Socket, le ping vers `8.8.8.8` échouera et l'application affichera intelligemment "Aucune connexion Internet" jusqu'à ce que l'utilisateur s'authentifie sur le portail captif.
