import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service pour gérer les notifications Push avec OneSignal (SDK v5.x)
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  /// App ID OneSignal
  static const String appId = '1caa5070-bc9c-4720-a6a4-9d5189401ff0';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialiser le SDK OneSignal
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Activer les logs en mode Debug
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // 2. Initialisation de OneSignal
      OneSignal.initialize(appId);

      // 3. Demander les permissions de notification
      await OneSignal.Notifications.requestPermission(true);

      // 4. Écouter les notifications reçues au premier plan (Foreground)
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('🔔 [OneSignal] Notification reçue au premier plan: ${event.notification.title}');
        // Afficher la notification normalement
        event.notification.display();
      });

      // 5. Écouter les clics sur les notifications
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('🔔 [OneSignal] Notification cliquée: ${event.notification.title}');
        final data = event.notification.additionalData;
        if (data != null) {
          debugPrint('📦 [OneSignal] Données additionnelles: $data');
          _handleNotificationData(data);
        }
      });

      // 6. Écouter les changements d'état des permissions
      OneSignal.Notifications.addPermissionObserver((permission) {
        debugPrint('🔔 [OneSignal] État permission modifié: $permission');
      });

      _isInitialized = true;
      debugPrint('✅ [OneSignal] Service initialisé avec succès (App ID: $appId)');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de l\'initialisation: $e');
    }
  }

  /// Connecter/Identifier un utilisateur avec son identifiant unique
  void login(String externalUserId) {
    if (externalUserId.isEmpty) return;
    try {
      OneSignal.login(externalUserId);
      debugPrint('👤 [OneSignal] Utilisateur connecté (external_id: $externalUserId)');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du login de l\'utilisateur: $e');
    }
  }

  /// Déconnecter l'utilisateur courant
  void logout() {
    try {
      OneSignal.logout();
      debugPrint('👤 [OneSignal] Utilisateur déconnecté');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du logout de l\'utilisateur: $e');
    }
  }

  /// Ajouter un tag utilisateur
  void addTag(String key, String value) {
    try {
      OneSignal.User.addTagWithKey(key, value);
      debugPrint('🏷️ [OneSignal] Tag ajouté: $key = $value');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de l\'ajout du tag: $e');
    }
  }

  /// Ajouter plusieurs tags utilisateur
  void addTags(Map<String, String> tags) {
    try {
      OneSignal.User.addTags(tags);
      debugPrint('🏷️ [OneSignal] Tags ajoutés: $tags');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de l\'ajout des tags: $e');
    }
  }

  /// Supprimer un tag utilisateur
  void removeTag(String key) {
    try {
      OneSignal.User.removeTag(key);
      debugPrint('🏷️ [OneSignal] Tag supprimé: $key');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de la suppression du tag: $e');
    }
  }

  /// Définir l'adresse email de l'utilisateur
  void setEmail(String email) {
    if (email.isEmpty) return;
    try {
      OneSignal.User.addEmail(email);
      debugPrint('📧 [OneSignal] Email enregistré: $email');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de l\'enregistrement de l\'email: $e');
    }
  }

  /// Définir le numéro de téléphone (au format E.164 ex: +2250709236146)
  void setSms(String phoneNumber) {
    if (phoneNumber.isEmpty) return;
    try {
      OneSignal.User.addSms(phoneNumber);
      debugPrint('📱 [OneSignal] SMS enregistré: $phoneNumber');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors de l\'enregistrement du numéro SMS: $e');
    }
  }

  /// Gérer le clic sur une notification et les données associées
  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    try {
      final String? urlString = data['url'] ?? data['link'] ?? data['store_url'];
      if (urlString != null && urlString.isNotEmpty) {
        final uri = Uri.tryParse(urlString);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur de traitement des données de notification: $e');
    }
  }
}
