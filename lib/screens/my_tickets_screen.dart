import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_colors.dart';
import '../config/app_dimensions.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/ticket_service.dart';
import '../models/user_ticket.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/bottom_sheets/bottom_sheet_header.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<UserTicket> _myTickets = [];
  UserTicketStats _stats = UserTicketStats(nombreCommandes: 0, nonUtilise: 0, utilise: 0, annule: 0);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final currentUser = AuthService.instance.getCurrentUser();
    final phone = currentUser?.phone;

    if (phone == null || phone.isEmpty) {
      setState(() {
        _error = 'Utilisateur non connecté';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await TicketService.getUserTickets(phone);
      setState(() {
        _myTickets = response.tickets;
        _stats = response.stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmCancelTicket(UserTicket ticket) async {
    final raw = ticket.rawData;
    final currentUser = AuthService.instance.getCurrentUser();
    final String parentPhone = currentUser?.phone ?? '';

    final String evenementId = (raw['evenement_id'] ?? raw['event_id'] ?? '1').toString();
    final String participantUid = (raw['participant_uid'] ?? raw['user_id'] ?? raw['parent_id'] ?? raw['parent_uid'] ?? parentPhone).toString();
    final String ticketUid = (raw['ticket_uid'] ?? raw['uid'] ?? ticket.id).toString();

    print('📱 [TICKET CANCEL SCREEN] Clic bouton annuler...');
    print('📱 [TICKET CANCEL SCREEN] rawData de base: $raw');
    print('📱 [TICKET CANCEL SCREEN] Argument evenementId: "$evenementId"');
    print('📱 [TICKET CANCEL SCREEN] Argument participantUid (téléphone parent): "$participantUid"');
    print('📱 [TICKET CANCEL SCREEN] Argument ticketUid: "$ticketUid"');

    if (evenementId.isEmpty || participantUid.isEmpty || ticketUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible d\'annuler ce ticket : informations manquantes.'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le ticket'),
        content: Text('Voulez-vous vraiment annuler votre participation à l\'événement "${ticket.eventName}" ? Cette action est irréversible et libérera votre place.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await TicketService.cancelTicket(
        evenementId: evenementId,
        participantUid: participantUid,
        ticketUid: ticketUid,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket annulé avec succès.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation du ticket.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      await _loadTickets();
    }
  }

  List<UserTicket> _getFilteredTickets() {
    if (_searchQuery.isEmpty) {
      return _myTickets;
    }
    return _myTickets.where((ticket) {
      final name = ticket.eventName.toLowerCase();
      final school = ticket.establishment.toLowerCase();
      return name.contains(_searchQuery) || school.contains(_searchQuery);
    }).toList();
  }

  void _showTicketQRCodeBottomSheet(UserTicket ticket) {
    final isDark = _themeService.isDarkMode;
    final raw = ticket.rawData;
    final ticketCode = (raw['code_ticket'] ?? raw['ticket_code'] ?? ticket.id).toString();
    final statusPaye = (raw['statut_paye'] ?? 'non_payé').toString();
    final isPayed = statusPaye.toLowerCase() == 'paye' || statusPaye.toLowerCase() == 'payé';
    final statusLower = ticket.status.toLowerCase();
    final isValid = statusLower == 'valide' || statusLower == 'non_utilise' || statusLower == 'non_utilisé';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: AppDimensions.getBottomSheetShadow(context),
        ),
        child: Column(
          children: [
            BottomSheetHeader(
              icon: Icons.qr_code_rounded,
              iconColor: AppColors.screenOrange,
              title: 'Mon Code QR',
              description: 'Présentez ce QR Code à l\'entrée de l\'événement',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  children: [
                    // Premium QR Code Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppDimensions.getSettingsCardShadow(context),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.screenOrange.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: QrImageView(
                              data: ticketCode,
                              version: QrVersions.auto,
                              size: 180.0,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ticketCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppColors.screenOrange,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Code de réservation unique',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Event Details Section Header
                    SectionHeaderWidget(
                      title: 'Détails de l\'événement',
                      isDark: isDark,
                      indicatorColor: AppColors.screenOrange,
                    ),

                    // Event Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppDimensions.getSettingsCardShadow(context),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.event_rounded,
                            label: 'Événement',
                            value: ticket.eventName,
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildDetailRow(
                            icon: Icons.school_rounded,
                            label: 'Établissement',
                            value: ticket.establishment,
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date et horaire',
                            value: '${ticket.date} à ${ticket.time}',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment details
                    SectionHeaderWidget(
                      title: 'Informations de facturation',
                      isDark: isDark,
                      indicatorColor: AppColors.screenOrange,
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppDimensions.getSettingsCardShadow(context),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.confirmation_number_rounded,
                            label: 'Quantité',
                            value: '${ticket.quantity} place(s)',
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildDetailRow(
                            icon: Icons.sell_outlined,
                            label: 'Prix unitaire',
                            value: ticket.unitPrice,
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildDetailRow(
                            icon: Icons.payment_rounded,
                            label: 'Montant total',
                            value: ticket.totalPrice,
                            isDark: isDark,
                            valueColor: AppColors.screenOrange,
                            valueFontWeight: FontWeight.bold,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildDetailRow(
                            icon: Icons.date_range_rounded,
                            label: 'Date d\'achat',
                            value: ticket.purchaseDate.isNotEmpty ? 'Le ${ticket.purchaseDate}' : 'Date d\'achat N/A',
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Statut du paiement',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPayed
                                      ? AppColors.success.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPayed ? AppColors.success : Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isPayed ? 'Payé' : 'Non payé',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPayed ? AppColors.success : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Cancel reservation action button (Only visible in details sheet if status is Valid)
                    if (isValid) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _confirmCancelTicket(ticket);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            backgroundColor: Colors.red[500]!.withOpacity(0.06),
                            side: BorderSide(
                              color: Colors.red[500]!.withOpacity(0.2),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                          label: const Text(
                            'Annuler la réservation',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                  fontWeight: valueFontWeight ?? FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: 'Mes Tickets',
            automaticallyImplyLeading: true,
            pinned: true,
            floating: false,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list,
                  color: AppColors.screenTextPrimaryThemed(context),
                ),
                onSelected: (value) {
                  // Filtres supplémentaires optionnels
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('Tous les tickets'),
                  ),
                  const PopupMenuItem(
                    value: 'valid',
                    child: Text('Tickets valides'),
                  ),
                  const PopupMenuItem(
                    value: 'used',
                    child: Text('Tickets utilisés'),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorWidget(),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsHeader(),
                  const SizedBox(height: 16),
                  _buildSearchZone(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          if (!_isLoading && _error == null && _getFilteredTickets().isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else if (!_isLoading && _error == null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ticket = _getFilteredTickets()[index];
                    return _buildTicketCard(ticket);
                  },
                  childCount: _getFilteredTickets().length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(16),
                color: AppColors.getTextColor(_themeService.isDarkMode),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchZone() {
    final isDark = _themeService.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: 'Rechercher un ticket',
          isDark: isDark,
          indicatorColor: AppColors.screenOrange,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppDimensions.getSettingsCardShadow(context),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher par événement ou école...',
              hintStyle: TextStyle(
                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.screenOrange,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final isDark = _themeService.isDarkMode;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Commandes', _stats.nombreCommandes.toString(), isDark, Icons.shopping_bag_outlined, AppColors.primary),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('Valides', _stats.nonUtilise.toString(), isDark, Icons.check_circle_outline, AppColors.success),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('Utilisés', _stats.utilise.toString(), isDark, Icons.qr_code_scanner_outlined, Colors.grey),
          _buildStatVerticalDivider(isDark),
          _buildStatItem('Annulés', _stats.annule.toString(), isDark, Icons.cancel_outlined, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.getBorderColor(isDark).withOpacity(0.5),
    );
  }

  Widget _buildStatItem(String title, String value, bool isDark, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(11),
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.confirmation_number,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun ticket acheté',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(18),
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(_themeService.isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez nos événements et achetez vos tickets',
              style: TextStyle(
                fontSize: _textSizeService.getScaledFontSize(14),
                color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Voir les événements',
                style: TextStyle(
                  fontSize: _textSizeService.getScaledFontSize(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(UserTicket ticket) {
    final isDark = _themeService.isDarkMode;
    final statusLower = ticket.status.toLowerCase();
    final isCanceled = statusLower == 'annule' || statusLower == 'annulé';
    final isValid = statusLower == 'valide' || statusLower == 'non_utilise' || statusLower == 'non_utilisé';
    final isUsed = statusLower == 'utilise' || statusLower == 'utilisé';

    Color statusThemeColor;
    Color badgeBgColor;
    String statusLabelText;
    IconData statusIcon;

    if (isValid) {
      statusThemeColor = AppColors.success;
      badgeBgColor = AppColors.successSurface;
      statusLabelText = 'Valide';
      statusIcon = Icons.check_circle_outline;
    } else if (isCanceled) {
      statusThemeColor = AppColors.error;
      badgeBgColor = AppColors.errorSurface;
      statusLabelText = 'Annulé';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusThemeColor = Colors.grey[600]!;
      badgeBgColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
      statusLabelText = isUsed ? 'Utilisé' : (ticket.status.isNotEmpty ? ticket.status : 'N/A');
      statusIcon = Icons.qr_code_scanner_outlined;
    }

    final iconGradient = isValid
        ? AppColors.primaryGradient
        : (isCanceled ? AppColors.errorGradient : AppColors.customGreyGradient);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
          width: 0,
        ),
        boxShadow: AppDimensions.getSettingsCardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _showTicketQRCodeBottomSheet(ticket),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creative Ticket Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 28,
                        color: statusThemeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventName.isNotEmpty ? ticket.eventName : 'Ticket Événement',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(15),
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDark),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ticket.establishment.isNotEmpty ? ticket.establishment : 'Établissement scolaire',
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Date, Time & Price indicators
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: AppColors.getTextColor(isDark, type: TextType.tertiary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.date.isNotEmpty ? ticket.date : 'Date à préciser',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(11),
                                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 12,
                                color: AppColors.getTextColor(isDark, type: TextType.tertiary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.time.isNotEmpty ? ticket.time : '--:--',
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(11),
                                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sell_outlined,
                                size: 12,
                                color: AppColors.screenOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.totalPrice,
                                style: TextStyle(
                                  fontSize: _textSizeService.getScaledFontSize(11),
                                  color: AppColors.screenOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Styled Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? statusThemeColor.withOpacity(0.18) : badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusThemeColor.withOpacity(isDark ? 0.3 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 11,
                        color: statusThemeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabelText,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(10),
                          fontWeight: FontWeight.bold,
                          color: statusThemeColor,
                        ),
                      ),
                    ],
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
