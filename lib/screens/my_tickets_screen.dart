import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';
import '../services/ticket_service.dart';
import '../models/user_ticket.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();

  bool _isLoading = true;
  String? _error;
  List<UserTicket> _myTickets = [];
  UserTicketStats _stats = UserTicketStats(nombreCommandes: 0, nonUtilise: 0, utilise: 0, annule: 0);

  @override
  void initState() {
    super.initState();
    _loadTickets();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(_themeService.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(_themeService.isDarkMode),
        elevation: 0,
        title: Text(
          'Mes Tickets',
          style: TextStyle(
            fontSize: _textSizeService.getScaledFontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(_themeService.isDarkMode),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextColor(_themeService.isDarkMode),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Bouton de filtre
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: AppColors.getTextColor(_themeService.isDarkMode),
            ),
            onSelected: (value) {
              // Logique de filtrage à implémenter
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
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

    if (_myTickets.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsHeader(),
        Expanded(child: _buildTicketsList()),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final isDark = _themeService.isDarkMode;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorderColor(isDark).withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
    return Center(
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
              // Naviguer vers l'écran des événements
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
    );
  }

  Widget _buildTicketsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTickets.length,
      itemBuilder: (context, index) {
        final ticket = _myTickets[index];
        return _buildTicketCard(ticket);
      },
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
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.getBorderColor(isDark).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful vertical status indicator bar
              Container(
                width: 6,
                color: statusThemeColor,
              ),
              // Main content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top portion with details
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: statusThemeColor.withOpacity(isDark ? 0.06 : 0.03),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Creative Ticket Icon
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: iconGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: statusThemeColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.15,
                                child: const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 28,
                                  color: Colors.white,
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
                                // Date & Time indicators
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
                    
                    // Custom coupon tear dashed divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(
                          40,
                          (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0 ? Colors.transparent : AppColors.getBorderColor(isDark).withOpacity(0.3),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom portion with totals
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Quantité: ',
                                      style: TextStyle(
                                        fontSize: _textSizeService.getScaledFontSize(13),
                                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${ticket.quantity}',
                                        style: TextStyle(
                                          fontSize: _textSizeService.getScaledFontSize(14),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTextColor(isDark),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prix unitaire: ${ticket.unitPrice}',
                                  style: TextStyle(
                                    fontSize: _textSizeService.getScaledFontSize(12),
                                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ${ticket.totalPrice}',
                                  style: TextStyle(
                                    fontSize: _textSizeService.getScaledFontSize(16),
                                    fontWeight: FontWeight.bold,
                                    color: statusThemeColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.purchaseDate.isNotEmpty ? 'Acheté le ${ticket.purchaseDate}' : 'Date d\'achat N/A',
                                  style: TextStyle(
                                    fontSize: _textSizeService.getScaledFontSize(11),
                                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cancel action button
                    if (isValid) ...[
                      const Divider(height: 1, thickness: 0.5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _confirmCancelTicket(ticket),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[600],
                                backgroundColor: Colors.red[500]!.withOpacity(0.06),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.red[500]!.withOpacity(0.15), width: 1),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                              label: const Text(
                                'Annuler la réservation',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
