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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Commandes', _stats.nombreCommandes.toString()),
          _buildStatItem('Non utilisés', _stats.nonUtilise.toString()),
          _buildStatItem('Utilisés', _stats.utilise.toString()),
          _buildStatItem('Annulés', _stats.annule.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(_themeService.isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: _textSizeService.getScaledFontSize(12),
              color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
            ),
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
    final isValid = ticket.status.toLowerCase() == 'valide' || ticket.status.toLowerCase() == 'non_utilise';
    final statusLabel = ticket.status.isNotEmpty ? ticket.status : 'N/A';
    final statusColor = isValid ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? statusColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _themeService.isDarkMode ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: statusColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.confirmation_number,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventName,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(_themeService.isDarkMode),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.establishment,
                        style: TextStyle(
                          fontSize: _textSizeService.getScaledFontSize(12),
                          color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket.date,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket.time,
                            style: TextStyle(
                              fontSize: _textSizeService.getScaledFontSize(12),
                              color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(10),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantité: ${ticket.quantity}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(_themeService.isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prix unitaire: ${ticket.unitPrice}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(12),
                        color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ${ticket.totalPrice}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acheté le ${ticket.purchaseDate}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(10),
                        color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
