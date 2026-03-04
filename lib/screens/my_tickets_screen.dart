import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../services/theme_service.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ThemeService _themeService = ThemeService();
  final TextSizeService _textSizeService = TextSizeService();
  
  // Données de démonstration pour les tickets achetés
  final List<Map<String, dynamic>> _myTickets = [
    {
      'id': '1',
      'eventName': 'Journée Portes Ouvertes',
      'establishment': 'École Primaire Jean Jaurès',
      'date': '15 Mars 2024',
      'time': '9h - 17h',
      'quantity': 2,
      'unitPrice': '5€',
      'totalPrice': '10€',
      'status': 'valide',
      'purchaseDate': '10 Mars 2024',
      'color': const Color(0xFF10B981),
      'image': 'https://picsum.photos/seed/event1/400/300.jpg',
    },
    {
      'id': '2',
      'eventName': 'Réunion parents-professeurs',
      'establishment': 'École Privée Saint-Exupéry',
      'date': '25 Mars 2024',
      'time': '18h',
      'quantity': 1,
      'unitPrice': 'Gratuit',
      'totalPrice': 'Gratuit',
      'status': 'valide',
      'purchaseDate': '20 Mars 2024',
      'color': const Color(0xFFF59E0B),
      'image': 'https://picsum.photos/seed/event4/400/300.jpg',
    },
    {
      'id': '3',
      'eventName': 'Fête de l\'ecole',
      'establishment': 'Groupe Scolaire Voltaire',
      'date': '28 Mars 2024',
      'time': '10h - 18h',
      'quantity': 3,
      'unitPrice': '2€',
      'totalPrice': '6€',
      'status': 'utilisé',
      'purchaseDate': '15 Mars 2024',
      'color': const Color(0xFF6366F1),
      'image': 'https://picsum.photos/seed/event5/400/300.jpg',
    },
  ];

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
      body: _myTickets.isEmpty ? _buildEmptyState() : _buildTicketsList(),
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

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String;
    final isValid = status == 'valide';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(_themeService.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid 
              ? AppColors.primary.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
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
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (ticket['color'] as Color).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Event image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: (ticket['color'] as Color).withOpacity(0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ticket['image'] != null
                        ? Image.network(
                            ticket['image'] as String,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: (ticket['color'] as Color).withOpacity(0.2),
                                child: Icon(
                                  Icons.event,
                                  color: ticket['color'] as Color,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.event,
                            color: ticket['color'] as Color,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['eventName'] as String,
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
                        ticket['establishment'] as String,
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
                            ticket['date'] as String,
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
                            ticket['time'] as String,
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
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isValid 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isValid ? 'Valide' : 'Utilisé',
                    style: TextStyle(
                      fontSize: _textSizeService.getScaledFontSize(10),
                      fontWeight: FontWeight.w600,
                      color: isValid ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Purchase details
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantité: ${ticket['quantity']}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(14),
                        color: AppColors.getTextColor(_themeService.isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prix unitaire: ${ticket['unitPrice']}',
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
                      'Total: ${ticket['totalPrice']}',
                      style: TextStyle(
                        fontSize: _textSizeService.getScaledFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: ticket['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acheté le ${ticket['purchaseDate']}',
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
