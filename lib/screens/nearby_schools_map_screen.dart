import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ecole.dart';
import '../services/ecole_api_service.dart';
import '../services/location_permission_service.dart';
import 'establishment_detail_screen.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';

const List<double> _kRadiusOptionsKm = [1, 2, 5, 10, 20];

enum _LocationFlowState {
  checking,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  locationFailed,
  ready,
}

/// Carte interactive des écoles à proximité de la position GPS de
/// l'utilisateur — rayon de recherche ajustable, envoyé à l'API
/// `/ecoles/list` (paramètres `latitude`/`longitude`/`rayon`).
class NearbySchoolsMapScreen extends StatefulWidget {
  const NearbySchoolsMapScreen({super.key});

  @override
  State<NearbySchoolsMapScreen> createState() => _NearbySchoolsMapScreenState();
}

class _NearbySchoolsMapScreenState extends State<NearbySchoolsMapScreen> {
  final MapController _mapController = MapController();

  _LocationFlowState _flowState = _LocationFlowState.checking;
  Position? _userPosition;
  double _radiusKm = 5;

  List<Ecole> _schools = [];
  bool _isLoadingSchools = false;
  String? _schoolsError;

  /// Centre géographique utilisé pour la dernière recherche d'écoles —
  /// initialement la position GPS, puis le centre de la carte lorsque
  /// l'utilisateur déplace la carte et relance une recherche sur la zone.
  LatLng? _searchCenter;
  LatLng? _pendingSearchCenter;
  bool _showSearchAreaButton = false;

  @override
  void initState() {
    super.initState();
    _initLocationFlow();
  }

  Future<void> _initLocationFlow() async {
    setState(() => _flowState = _LocationFlowState.checking);

    final serviceEnabled = await LocationPermissionService.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => _flowState = _LocationFlowState.serviceDisabled);
      return;
    }

    final granted = await LocationPermissionService.requestLocation();
    if (!mounted) return;
    if (!granted) {
      final permanentlyDenied = await LocationPermissionService.isPermanentlyDenied();
      if (!mounted) return;
      setState(() {
        _flowState = permanentlyDenied
            ? _LocationFlowState.permissionPermanentlyDenied
            : _LocationFlowState.permissionDenied;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _searchCenter = LatLng(position.latitude, position.longitude);
        _flowState = _LocationFlowState.ready;
      });
      _loadNearbySchools();
    } catch (_) {
      if (!mounted) return;
      setState(() => _flowState = _LocationFlowState.locationFailed);
    }
  }

  Future<void> _loadNearbySchools({LatLng? center}) async {
    final searchCenter = center ?? _searchCenter;
    if (searchCenter == null) return;

    setState(() {
      _isLoadingSchools = true;
      _schoolsError = null;
      _searchCenter = searchCenter;
      _showSearchAreaButton = false;
    });

    try {
      final schools = await EcoleApiService.getEcoles(
        perPage: 100,
        pays: 'ci',
        latitude: searchCenter.latitude,
        longitude: searchCenter.longitude,
        rayon: _radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _schools = schools.where((s) => s.latitude != null && s.longitude != null).toList();
        _isLoadingSchools = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
        _schoolsError = e.toString();
      });
    }
  }

  void _onRadiusSelected(double km) {
    if (km == _radiusKm) return;
    setState(() => _radiusKm = km);
    _loadNearbySchools();
  }

  void _recenterOnMe() {
    final position = _userPosition;
    if (position == null) return;
    final userLatLng = LatLng(position.latitude, position.longitude);
    _mapController.move(userLatLng, 14);
    _loadNearbySchools(center: userLatLng);
  }

  /// Appelé à chaque déplacement/zoom de la carte. Lorsque l'utilisateur a
  /// déplacé la carte à la main (`hasGesture`) suffisamment loin du dernier
  /// centre de recherche, on propose un bouton "Rechercher dans cette zone"
  /// plutôt que de relancer l'appel API à chaque pixel déplacé.
  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final lastCenter = _searchCenter;
    if (lastCenter == null) return;

    final movedMeters = const Distance().as(
      LengthUnit.Meter,
      lastCenter,
      camera.center,
    );
    final thresholdMeters = (_radiusKm * 1000 * 0.3).clamp(300, 5000);

    _pendingSearchCenter = camera.center;
    final shouldShow = movedMeters > thresholdMeters;
    if (shouldShow != _showSearchAreaButton) {
      setState(() => _showSearchAreaButton = shouldShow);
    }
  }

  void _searchInCurrentArea() {
    final center = _pendingSearchCenter ?? _mapController.camera.center;
    _loadNearbySchools(center: center);
  }

  void _zoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + 1).clamp(1, 18));
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom - 1).clamp(1, 18));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenSurfaceThemed(context),
      appBar: AppBar(
        title: const Text('Écoles à proximité'),
        backgroundColor: AppColors.screenSurfaceThemed(context),
        elevation: 0,
        foregroundColor: AppColors.screenTextPrimaryThemed(context),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_flowState) {
      case _LocationFlowState.checking:
        return const Center(child: CircularProgressIndicator(color: AppColors.screenOrange));
      case _LocationFlowState.serviceDisabled:
        return _buildStatusScreen(
          icon: Icons.location_off_rounded,
          title: 'Localisation désactivée',
          message: 'Activez le GPS de votre téléphone pour voir les écoles à proximité de votre position.',
          primaryLabel: 'Activer la localisation',
          onPrimary: () async {
            await LocationPermissionService.openLocationSettings();
          },
          secondaryLabel: 'Réessayer',
          onSecondary: _initLocationFlow,
        );
      case _LocationFlowState.permissionDenied:
        return _buildStatusScreen(
          icon: Icons.location_disabled_rounded,
          title: 'Autorisation requise',
          message: 'L\'application a besoin d\'accéder à votre position pour trouver les écoles proches de vous.',
          primaryLabel: 'Autoriser',
          onPrimary: _initLocationFlow,
        );
      case _LocationFlowState.permissionPermanentlyDenied:
        return _buildStatusScreen(
          icon: Icons.location_disabled_rounded,
          title: 'Autorisation bloquée',
          message: 'La localisation a été refusée définitivement. Autorisez-la depuis les réglages de votre téléphone.',
          primaryLabel: 'Ouvrir les réglages',
          onPrimary: () async {
            await LocationPermissionService.openSettings();
          },
          secondaryLabel: 'Réessayer',
          onSecondary: _initLocationFlow,
        );
      case _LocationFlowState.locationFailed:
        return _buildStatusScreen(
          icon: Icons.gps_off_rounded,
          title: 'Position indisponible',
          message: 'Impossible de récupérer votre position actuelle. Vérifiez votre GPS et réessayez.',
          primaryLabel: 'Réessayer',
          onPrimary: _initLocationFlow,
        );
      case _LocationFlowState.ready:
        return _buildMap();
    }
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.screenOrange),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimaryThemed(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.screenTextSecondaryThemed(context),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.screenOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel, style: const TextStyle(color: AppColors.screenOrange)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final position = _userPosition!;
    final userLatLng = LatLng(position.latitude, position.longitude);
    final searchCenter = _searchCenter ?? userLatLng;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 13,
            onPositionChanged: _onMapPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.groupegain.parents_responsable',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: searchCenter,
                  radius: _radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: AppColors.screenOrange.withOpacity(0.08),
                  borderStrokeWidth: 1.5,
                  borderColor: AppColors.screenOrange.withOpacity(0.4),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: userLatLng,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
                ..._schools.map(
                  (school) => Marker(
                    key: ValueKey('school-${school.parametreCode}'),
                    point: LatLng(school.latitude!, school.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showSchoolBottomSheet(school),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildRadiusSelector(),
        if (_showSearchAreaButton)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _searchInCurrentArea,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.search_rounded, color: AppColors.screenOrange, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Rechercher dans cette zone',
                          style: TextStyle(
                            color: AppColors.screenOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 150,
          child: Column(
            children: [
              _buildMapIconButton(
                heroTag: 'zoom_in',
                icon: Icons.add_rounded,
                onPressed: _zoomIn,
              ),
              const SizedBox(height: 8),
              _buildMapIconButton(
                heroTag: 'zoom_out',
                icon: Icons.remove_rounded,
                onPressed: _zoomOut,
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 90,
          child: FloatingActionButton(
            heroTag: 'recenter_on_me',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.screenOrange,
            onPressed: _recenterOnMe,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
        if (_isLoadingSchools)
          const Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.screenOrange),
            ),
          ),
        if (_schoolsError != null)
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Impossible de charger les écoles à proximité.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadNearbySchools,
                    child: const Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          )
        else if (!_isLoadingSchools && _schools.isEmpty)
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aucune école trouvée dans ce rayon. Essayez un rayon plus large.',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRadiusSelector() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _kRadiusOptionsKm.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final km = _kRadiusOptionsKm[index];
            final isSelected = km == _radiusKm;
            return GestureDetector(
              onTap: () => _onRadiusSelected(km),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.screenOrange : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1)} km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.screenOrange,
        elevation: 2,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }

  void _showSchoolBottomSheet(Ecole school) {
    final textSizeService = TextSizeService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(
                icon: Icons.school_rounded,
                iconColor: AppColors.screenOrange,
                title: school.parametreNom,
                description: school.adresse.isNotEmpty ? school.adresse : school.ville,
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              if (school.distance != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.screenOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'À ${school.distance!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w700,
                          color: AppColors.screenOrange,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EstablishmentDetailScreen(ecole: school),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Voir l\'établissement', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
