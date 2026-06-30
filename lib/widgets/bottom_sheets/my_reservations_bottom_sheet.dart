import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/http_service.dart';
import '../custom_loader.dart';
import '../components/bottom_spacer.dart';
import '../components/custom_error_state.dart';
import 'reusable_bottom_sheet.dart';

class MyReservationsBottomSheet extends StatefulWidget {
  final String childName;
  final String matricule;
  const MyReservationsBottomSheet({
    Key? key,
    required this.childName,
    required this.matricule,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String childName,
    required String matricule,
    String? imagePath,
    Color? imageBackgroundColor,
    double? imageBorderRadius,
  }) {
    return ReusableBottomSheet.show<void>(
      context: context,
      title: 'Mes réservations',
      subtitle: 'Réservations pour $childName',
      icon: Icons.list_alt_rounded,
      iconColor: const Color(0xFF4CAF50),
      imagePath: imagePath,
      iconBackgroundColor: imageBackgroundColor,
      imageBorderRadius: imageBorderRadius,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      contentPadding: const EdgeInsets.all(0),
      content: MyReservationsBottomSheet(
        childName: childName,
        matricule: matricule,
      ),
    );
  }

  @override
  State<MyReservationsBottomSheet> createState() => _MyReservationsBottomSheetState();
}

class _MyReservationsBottomSheetState extends State<MyReservationsBottomSheet> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reservations = [];
  int _sommeReservation = 0;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = '/vie-ecoles/reservation/eleve/${widget.matricule}';
      final response = await HttpService.get(endpoint);

      if (mounted) {
        setState(() {
          if (response['status'] == true) {
            _reservations = response['data'] is List ? response['data'] : [];
          } else {
            _reservations = [];
          }
          _sommeReservation = response['somme_reservation'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        // L'API retourne parfois un code 500 avec {"somme_reservation":0,"status":false}
        // au lieu d'un 200 OK quand il n'y a pas de réservation. On gère ce cas.
        if (errorString.contains('"somme_reservation":0') && errorString.contains('"status":false')) {
          setState(() {
            _reservations = [];
            _sommeReservation = 0;
            _isLoading = false;
            _error = null; // Pas d'erreur, juste pas de réservation
          });
        } else {
          final isNetworkError = errorString.contains('SocketException') || 
                                 errorString.contains('ClientException') ||
                                 errorString.contains('Failed host lookup') ||
                                 errorString.contains('No address associated') ||
                                 errorString.contains('Connection refused') ||
                                 errorString.contains('Network is unreachable') ||
                                 errorString.contains('Software caused connection abort');
          setState(() {
            _error = isNetworkError 
                ? 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.'
                : errorString.replaceAll('Exception: ', '');
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildContent(isDark);
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: CustomLoader(
            message: 'Chargement de vos réservations...',
            loaderColor: AppColors.screenOrange,
            backgroundColor: Colors.transparent,
            showBackground: false,
          ),
        ),
      );
    }

    if (_error != null) {
      return CustomErrorState(
        title: 'Erreur lors du chargement',
        message: _error!,
        icon: Icons.error_outline,
        iconColor: Colors.red[300],
        buttonColor: AppColors.screenOrange,
        buttonIsLight: false,
        buttonHasBorder: false,
        retryText: 'Réessayer',
        onRetry: _loadReservations,
      );
    }

    if (_reservations.isEmpty && _sommeReservation == 0) {
      return const CustomErrorState(
        title: 'Aucune réservation',
        message: 'Aucune réservation n\'a été trouvée pour cet élève.',
        icon: Icons.event_busy,
        iconColor: Colors.grey,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête résumé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50),
                  const Color(0xFF4CAF50).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Réservation',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_sommeReservation FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          if (_reservations.isNotEmpty) ...[
            Text(
              'Détails',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._reservations.map((reservation) => _buildReservationCard(reservation, isDark)).toList(),
          ],
          
        ],
      ),
    );
  }

  Widget _buildReservationCard(dynamic reservation, bool isDark) {
    // Adapter selon la structure réelle du JSON renvoyé par l'API
    final montant = reservation['montant']?.toString() ?? '0';
    final date = reservation['date_paiement'] ?? reservation['created_at'] ?? 'Date inconnue';
    final status = reservation['status'] ?? 'Complété';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.screenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : AppColors.screenDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement réservation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$montant FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
