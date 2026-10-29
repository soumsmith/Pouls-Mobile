import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Fin wrapper autour de `permission_handler`/`geolocator` pour la
/// localisation — utilisé par l'écran "Écoles à proximité".
class LocationPermissionService {
  /// Vérifie d'abord le statut courant (pour ne pas re-demander
  /// inutilement), puis déclenche la demande système si besoin.
  static Future<bool> requestLocation() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;

    status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> isPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Le GPS/service de localisation du téléphone est-il activé (indépendant
  /// de la permission accordée à l'app) ?
  static Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
