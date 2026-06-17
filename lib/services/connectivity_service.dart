import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../utils/notification_helper.dart';

/// Service singleton de surveillance de la connectivité.
///
/// Les écrans s'abonnent avec [addListener] en passant un callback
/// qui sera appelé quand la connexion revient (transition offline → online).
/// Cela permet de relancer automatiquement les appels API de l'écran actif.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._internal() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onStatusChanged);
  }

  static final ConnectivityService _instance = ConnectivityService._internal();

  /// Accès au singleton
  static ConnectivityService get instance => _instance;

  StreamSubscription? _subscription;
  Timer? _debounceTimer;
  bool _isOnline = true;
  bool _isInitialCheck = true;

  /// `true` si le téléphone est actuellement connecté à internet.
  bool get isOnline => _isOnline;

  /// Liste des callbacks à appeler quand la connexion revient.
  final List<VoidCallback> _onReconnectCallbacks = [];

  /// Enregistre un callback qui sera appelé à chaque reconnexion.
  /// Typiquement appelé dans `initState()` d'un écran.
  void onReconnect(VoidCallback callback) {
    _onReconnectCallbacks.add(callback);
  }

  /// Supprime un callback de reconnexion.
  /// Typiquement appelé dans `dispose()` d'un écran.
  void removeReconnectCallback(VoidCallback callback) {
    _onReconnectCallbacks.remove(callback);
  }

  void _onStatusChanged(dynamic result) {
    // Annuler le timer précédent
    _debounceTimer?.cancel();

    // Attendre 2 secondes pour s'assurer que le basculement réseau (ex: Wifi -> 4G) est terminé
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () async {
      bool interfaceConnected = false;
      
      // Re-vérifier l'état de l'interface réseau au moment T
      final currentResult = await Connectivity().checkConnectivity();
      if (currentResult is List<ConnectivityResult>) {
        interfaceConnected = currentResult.any((r) => r != ConnectivityResult.none);
      } else if (currentResult is ConnectivityResult) {
        interfaceConnected = currentResult != ConnectivityResult.none;
      }

      bool actuallyOnline = false;

      // Si une interface est connectée, vérifier qu'elle a VRAIMENT accès à internet
      if (interfaceConnected) {
        try {
          // Un test DNS ultra-rapide et fiable vers Google
          final lookup = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
          actuallyOnline = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        } catch (_) {
          actuallyOnline = false; // Connecté au routeur/4G, mais pas d'internet réel
        }
      }

      if (_isInitialCheck) {
        _isOnline = actuallyOnline;
        _isInitialCheck = false;
        return;
      }

      if (_isOnline == actuallyOnline) return; // Pas de changement réel

      _isOnline = actuallyOnline;

      // Notifier tous les listeners (ChangeNotifier)
      notifyListeners();

      if (actuallyOnline) {
        // Afficher la notification de succès
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationHelper.showSuccess('Connexion internet rétablie.');
        });
        WidgetsBinding.instance.ensureVisualUpdate();

        print('🔄 Connexion rétablie — relancement des API des écrans actifs');
        for (final callback in List<VoidCallback>.from(_onReconnectCallbacks)) {
          try {
            callback();
          } catch (e) {
            print('⚠️ Erreur dans un callback de reconnexion: $e');
          }
        }
      } else {
        // Afficher la notification de perte de connexion
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationHelper.showNoConnection(
              customMessage: 'Connexion internet perdue. Mode hors ligne activé.');
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _onReconnectCallbacks.clear();
    super.dispose();
  }
}

/// Mixin pratique pour les State<> qui veulent recharger leurs données
/// automatiquement quand la connexion revient.
///
/// Usage :
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ConnectivityReloadMixin {
///   @override
///   void onConnectionRestored() {
///     _loadData(); // Relancer vos appels API
///   }
///
///   @override
///   void initState() {
///     super.initState();
///     registerConnectivityReload(); // ← à appeler dans initState
///     _loadData();
///   }
///
///   @override
///   void dispose() {
///     unregisterConnectivityReload(); // ← à appeler dans dispose
///     super.dispose();
///   }
/// }
/// ```
mixin ConnectivityReloadMixin<T extends StatefulWidget> on State<T> {
  VoidCallback? _connectivityCallback;

  /// Appelé automatiquement quand la connexion est rétablie.
  /// À surcharger dans l'écran pour relancer les appels API.
  void onConnectionRestored();

  /// Enregistre le callback de reconnexion. À appeler dans initState().
  void registerConnectivityReload() {
    _connectivityCallback = () {
      if (mounted) {
        print('🔄 ${T.toString()} — Reconnexion détectée, rechargement des données...');
        onConnectionRestored();
      }
    };
    ConnectivityService.instance.onReconnect(_connectivityCallback!);
  }

  /// Supprime le callback. À appeler dans dispose().
  void unregisterConnectivityReload() {
    if (_connectivityCallback != null) {
      ConnectivityService.instance.removeReconnectCallback(_connectivityCallback!);
      _connectivityCallback = null;
    }
  }
}
