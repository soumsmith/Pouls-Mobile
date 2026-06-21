import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// État de la connexion réseau
enum ConnectivityStatus {
  connected,
  disconnected,
}

/// Service singleton qui vérifie le véritable accès à internet
/// en ouvrant un Socket vers un serveur fiable (Google DNS).
/// C'est la méthode la plus fiable sur émulateur.
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
    
    // On lance une vérification en boucle toutes les 3 secondes.
    // Infaillible sur émulateur même quand l'hôte coupe le Wi-Fi.
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final hasNet = await _hasRealInternetAccess();
      _applyState(hasNet);
    });
  }

  /// Tente d'ouvrir une connexion TCP rapide sur le port 53 (DNS) de Google.
  /// Ne dépend pas de la résolution DNS locale de l'émulateur (qui est souvent buggée).
  Future<bool> _hasRealInternetAccess() async {
    try {
      // 8.8.8.8 est le DNS de Google, ultra rapide et fiable
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
      debugPrint('🌐 ✅ CONNEXION RÉTABLIE ! (Ping 8.8.8.8 réussi)');
      
      if (wasOffline) {
        for (final cb in List<VoidCallback>.from(_reconnectCallbacks)) {
          try { cb(); } catch (e) { debugPrint('⚠️ callback error: $e'); }
        }
      }
    } else {
      _statusController.add(ConnectivityStatus.disconnected);
      debugPrint('🌐 ❌ CONNEXION PERDUE ! (Ping 8.8.8.8 échoué)');
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
