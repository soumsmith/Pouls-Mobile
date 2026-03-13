import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../services/message_service.dart';
import '../services/ecoles_api_service.dart';
import '../services/auth_service.dart';
import '../models/ecole.dart';
import '../config/app_colors.dart';
import '../config/app_typography.dart';
import '../services/text_size_service.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/searchable_dropdown.dart';

// ─── DESIGN TOKENS (centralisés dans AppColors) ────────────────────────────────

/// Écran de messagerie - redesigné avec le même langage visuel que CartScreen
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  bool _isSearching = false;

  final List<String> _filters = ['Tous', 'Non lus', 'Lus'];

  // Controllers pour le formulaire d'envoi
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();

  File? _attachedFile;
  String? _fileType;
  bool _isSending = false;

  List<Ecole> _ecoles = [];
  String? _selectedEcoleName;
  String? _selectedEcoleCode;
  bool _isLoadingEcoles = false;
  final EcolesApiService _ecolesApiService = EcolesApiService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _destinataires = [
    'Direction',
    'Secrétariat',
    'Surveillance générale',
    'Professeur de mathématiques',
    'Professeur de français',
    'Professeur d\'histoire-géographie',
    'Professeur de physique-chimie',
    'Professeur de SVT',
    'Professeur d\'anglais',
    'Professeur d\'espagnol',
    'Professeur d\'allemand',
    'Professeur de philosophie',
    'Professeur d\'EPS',
    'Professeur de musique',
    'Professeur d\'arts plastiques',
    'Censeur',
    'Surveillant',
    'Conseiller principal d\'éducation',
    'Infirmière scolaire',
    'Assistante sociale',
    'Bibliothécaire',
    'Administrateur',
    'Personnel de cantine',
    'Personnel d\'entretien',
    'Autre',
  ];
  String? _selectedDestinataire;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadNotifications();
    _loadEcoles(); // Préchargement au démarrage (sans sheetSetState)
    _loadUserInfo();
    _searchController.addListener(() => setState(() {}));
    _textSizeService.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    _phoneNumberController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  void _loadUserInfo() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _phoneNumberController.text = currentUser.phone;
        _recipientController.text = currentUser.fullName;
      });
    }
  }

  // ─── FIX : _loadEcoles accepte un sheetSetState optionnel ────────────────
  Future<void> _loadEcoles({StateSetter? sheetSetState}) async {
    if (_isLoadingEcoles) return;

    // Met à jour à la fois le widget parent ET le bottom sheet si fourni
    void updateState(VoidCallback fn) {
      if (mounted) setState(fn);
      sheetSetState?.call(fn);
    }

    updateState(() => _isLoadingEcoles = true);
    try {
      final ecoles = await _ecolesApiService.getAllEcoles();
      updateState(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
      });
    } catch (e) {
      updateState(() => _isLoadingEcoles = false);
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _notifications;
    if (_selectedFilter == 'Non lus') {
      items = items.where((n) => !(n['isRead'] as bool)).toList();
    } else if (_selectedFilter == 'Lus') {
      items = items.where((n) => (n['isRead'] as bool)).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      items = items
          .where((n) =>
              (n['title'] as String).toLowerCase().contains(q) ||
              (n['body'] as String).toLowerCase().contains(q) ||
              (n['sender'] as String).toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      const parentId = 'parent1';
      final db = DatabaseService.instance;
      final notifications = await db.getNotificationsByParent(parentId);
      if (notifications.isEmpty) {
        await _addDemoNotifications(parentId);
        final updated = await db.getNotificationsByParent(parentId);
        setState(() {
          _notifications = updated;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des messages');
    }
  }

  Future<void> _addDemoNotifications(String parentId) async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final demos = [
      {
        'id': 'demo_1',
        'title': 'Réunion parents-professeurs',
        'body':
            'Une réunion est programmée pour le vendredi 28 février à 18h. Merci de confirmer votre présence.',
        'timestamp':
            now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'sender': 'Direction de l\'établissement',
        'isRead': false,
      },
      {
        'id': 'demo_2',
        'title': 'Note de mathématiques',
        'body':
            'Votre enfant a obtenu 15/20 au dernier contrôle de mathématiques. Félicitations !',
        'timestamp':
            now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'sender': 'M. Dubois - Professeur de mathématiques',
        'isRead': false,
      },
      {
        'id': 'demo_3',
        'title': 'Sortie scolaire',
        'body':
            'Une sortie au musée est organisée le mercredi prochain. N\'oubliez pas d\'envoyer l\'autorisation signée.',
        'timestamp':
            now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        'sender': 'Mme Martin - Professeur d\'histoire',
        'isRead': true,
      },
      {
        'id': 'demo_4',
        'title': 'Menu de la cantine',
        'body':
            'Menu du jour : Poulet rôti, haricots verts, fromage et fruit de saison.',
        'timestamp':
            now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        'sender': 'Service de cantine',
        'isRead': true,
      },
    ];
    for (final n in demos) {
      await db.saveNotification(
        id: n['id'] as String,
        title: n['title'] as String,
        body: n['body'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(n['timestamp'] as int),
        sender: n['sender'] as String,
        parentId: parentId,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await DatabaseService.instance.markAllNotificationsAsRead('parent1');
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
        }
      });
      _showSuccess('Tous les messages ont été marqués comme lus');
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[500],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── BUILD PRINCIPAL ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.screenSurface,
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(color: AppColors.screenOrange, strokeWidth: 2.5),
      );
    }

    _notifications.sort((a, b) {
      final dA =
          DateTime.fromMillisecondsSinceEpoch(a['timestamp'] as int);
      final dB =
          DateTime.fromMillisecondsSinceEpoch(b['timestamp'] as int);
      return dB.compareTo(dA);
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildFilters(),
          _buildCountRow(),
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final unreadCount =
        _notifications.where((n) => !(n['isRead'] as bool)).length;

    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.screenTextPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_notifications.length} message${_notifications.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Search button
              GestureDetector(
                onTap: () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchController.clear();
                }),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSearching ? AppColors.screenOrangeLight : AppColors.screenCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.screenShadow,
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: _isSearching ? AppColors.screenOrange : AppColors.screenTextPrimary,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.mark_email_read_outlined,
                              size: 18, color: AppColors.screenOrange),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.screenOrange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearching ? 60 : 0,
      child: _isSearching
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.screenCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.screenShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimary,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un message...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.screenTextSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.screenOrange, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _searchController.clear()),
                            child: const Icon(Icons.close,
                                color: AppColors.screenTextSecondary, size: 16),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ─── FILTRES ──────────────────────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final selected = filter == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : AppColors.screenCard,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.screenOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          const BoxShadow(
                              color: AppColors.screenShadow,
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.screenTextSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── COMPTEUR ─────────────────────────────────────────────────────────────
  Widget _buildCountRow() {
    final count = _filteredItems.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            '$count message${count > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.screenTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LISTE DES MESSAGES ───────────────────────────────────────────────────
  Widget _buildMessageList() {
    final items = _filteredItems;
    if (items.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _buildMessageCard(items[index], index),
    );
  }

  Widget _buildMessageCard(
      Map<String, dynamic> notification, int index) {
    final isRead = notification['isRead'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final sender =
        notification['sender'] as String? ?? 'Établissement';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        notification['timestamp'] as int);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showNotificationDetail(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: isRead
                ? null
                : Border.all(
                    color: AppColors.screenOrange.withOpacity(0.2), width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.screenShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar icône
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isRead
                            ? const Color(0xFFF5F5F5)
                            : AppColors.screenOrangeLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSenderIcon(sender),
                        size: 20,
                        color: isRead ? AppColors.screenTextSecondary : AppColors.screenOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Titre + expéditeur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppColors.screenTextPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.screenOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sender,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.screenTextSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isRead ? AppColors.screenTextSecondary : AppColors.screenTextPrimary,
                    height: 1.4,
                    fontWeight: isRead
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 13, color: AppColors.screenTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(timestamp),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (!isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.screenOrangeLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Non lu',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.screenOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSenderIcon(String sender) {
    final s = sender.toLowerCase();
    if (s.contains('direction') || s.contains('directeur')) {
      return Icons.account_balance_outlined;
    } else if (s.contains('professeur') || s.contains('prof')) {
      return Icons.school_outlined;
    } else if (s.contains('cantine')) {
      return Icons.restaurant_outlined;
    } else if (s.contains('infirmier') || s.contains('médecin')) {
      return Icons.medical_services_outlined;
    }
    return Icons.person_outline;
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.screenOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_outline,
                size: 48, color: AppColors.screenOrange),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun message',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos messages apparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.screenTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: _buildOrangeButton(
              label: 'Nouveau message',
              onTap: _showComposeMessageBottomSheet,
              trailing: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _showComposeMessageBottomSheet,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.screenOrange.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Nouveau message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ORANGE BUTTON (identique CartScreen) ─────────────────────────────────
  Widget _buildOrangeButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A3C), AppColors.screenOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.screenOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ─── COMPOSE BOTTOM SHEET ─────────────────────────────────────────────────
  void _showComposeMessageBottomSheet() {
    String? localSelectedEcoleName = _selectedEcoleName;
    String? localSelectedEcoleCode = _selectedEcoleCode;
    String? localSelectedDestinataire = _selectedDestinataire;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // ─── FIX : Si les écoles ne sont pas chargées, lancer le chargement
          // en passant setSheetState pour que le sheet se rebuilde au retour
          if (_ecoles.isEmpty && !_isLoadingEcoles) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadEcoles(sheetSetState: setSheetState);
            });
          } else if (_isLoadingEcoles) {
            // Un chargement est déjà en cours (lancé par initState) :
            // on attend sa fin puis on notifie le sheet
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              while (_isLoadingEcoles) {
                await Future.delayed(const Duration(milliseconds: 100));
              }
              if (mounted) setSheetState(() {});
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.screenCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.92,
              maxChildSize: 0.96,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header fixe
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.screenDivider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.screenOrangeLight,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.screenOrange,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nouveau message',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.screenTextPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Text(
                                      'Remplissez vos informations',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.screenTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.screenDivider, height: 1),
                        ],
                      ),
                    ),

                    // Formulaire scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Vos coordonnées'),
                            const SizedBox(height: 12),

                            // Nom (read-only)
                            _buildInfoTile(
                              icon: Icons.person_outline,
                              label: 'Nom complet',
                              value: AuthService.instance
                                      .getCurrentUser()
                                      ?.fullName ??
                                  'Non connecté',
                            ),
                            const SizedBox(height: 10),

                            // Téléphone (read-only)
                            _buildInfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Téléphone',
                              value: AuthService.instance
                                      .getCurrentUser()
                                      ?.phone ??
                                  '-',
                            ),

                            const SizedBox(height: 24),
                            _sectionLabel('Destinataire'),
                            const SizedBox(height: 12),

                            // École
                            _buildSheetLabel(
                                'École', required: true),
                            const SizedBox(height: 6),
                            _isLoadingEcoles
                                ? _buildLoadingField(
                                    'Chargement des écoles...')
                                : _ecoles.isEmpty
                                    ? _buildInfoTile(
                                        icon: Icons.school_outlined,
                                        label: 'École',
                                        value:
                                            'Aucune école disponible')
                                    : SearchableDropdown(
                                        key: ValueKey(
                                            'ecole_${_ecoles.length}'),
                                        label: 'École *',
                                        value: localSelectedEcoleName ??
                                            'Sélectionner une école...',
                                        items: _ecoles
                                            .map((e) => e.ecoleclibelle)
                                            .toList(),
                                        onChanged: (name) {
                                          final ecole =
                                              _ecoles.firstWhere((e) =>
                                                  e.ecoleclibelle ==
                                                  name);
                                          setSheetState(() {
                                            localSelectedEcoleName =
                                                name;
                                            localSelectedEcoleCode =
                                                ecole.ecolecode;
                                          });
                                          setState(() {
                                            _selectedEcoleName = name;
                                            _selectedEcoleCode =
                                                ecole.ecolecode;
                                          });
                                        },
                                        isDarkMode: false,
                                      ),
                            const SizedBox(height: 12),

                            // Destinataire
                            _buildSheetLabel('Destinataire',
                                required: true),
                            const SizedBox(height: 6),
                            SearchableDropdown(
                              key: ValueKey(
                                  'dest_$localSelectedDestinataire'),
                              label: 'Destinataire *',
                              value: localSelectedDestinataire ??
                                  'Sélectionner un destinataire...',
                              items: _destinataires,
                              onChanged: (dest) {
                                setSheetState(() =>
                                    localSelectedDestinataire = dest);
                                setState(() {
                                  _selectedDestinataire = dest;
                                  _recipientController.text = dest;
                                });
                              },
                              isDarkMode: false,
                            ),
                            const SizedBox(height: 12),

                            // Matricule
                            _buildFormTextField(
                              controller: _matriculeController,
                              label: 'Matricule élève',
                              hint: 'Ex: 67894F',
                              icon: Icons.badge_outlined,
                              required: true,
                            ),

                            const SizedBox(height: 24),
                            _sectionLabel('Votre message'),
                            const SizedBox(height: 12),

                            _buildFormTextField(
                              controller: _subjectController,
                              label: 'Sujet',
                              hint: 'Objet du message',
                              icon: Icons.title_outlined,
                              required: true,
                            ),
                            const SizedBox(height: 12),
                            _buildFormTextField(
                              controller: _messageController,
                              label: 'Message',
                              hint: 'Tapez votre message ici...',
                              icon: Icons.message_outlined,
                              required: true,
                              maxLines: 5,
                            ),

                            const SizedBox(height: 24),
                            _sectionLabel('Messages rapides'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'Demande de rendez-vous',
                                'Absence de mon enfant',
                                'Question sur les devoirs',
                                'Information médicale',
                                'Demande de document',
                              ]
                                  .map((msg) =>
                                      _buildQuickMessageChip(msg))
                                  .toList(),
                            ),

                            const SizedBox(height: 24),
                            _sectionLabel('Pièce jointe'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAttachmentButton(
                                    icon: Icons.image_outlined,
                                    label: 'Image',
                                    selected: _fileType == 'image',
                                    onTap: () async {
                                      await _pickImage();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildAttachmentButton(
                                    icon: Icons.mic_outlined,
                                    label: 'Audio',
                                    selected: _fileType == 'audio',
                                    onTap: () async {
                                      await _pickAudio();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_attachedFile != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.screenOrangeLight,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _fileType == 'image'
                                          ? Icons.image_outlined
                                          : Icons.mic_outlined,
                                      color: AppColors.screenOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _attachedFile!.path
                                            .split('/')
                                            .last,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.screenOrange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _removeAttachment();
                                        setSheetState(() {});
                                      },
                                      child: const Icon(Icons.close,
                                          size: 16, color: AppColors.screenOrange),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Bouton d'envoi fixe
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      decoration: const BoxDecoration(
                        color: AppColors.screenCard,
                        border: Border(
                            top: BorderSide(color: AppColors.screenDivider)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: _buildOrangeButton(
                          label: 'Envoyer le message',
                          isLoading: _isSending,
                          onTap:
                              _isSending ? null : _sendMessage,
                          trailing: const Icon(
                              Icons.send_outlined,
                              color: Colors.white,
                              size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ─── SHEET HELPERS ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.screenTextPrimary,
          letterSpacing: -0.3,
        ),
      );

  Widget _buildSheetLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.screenTextSecondary,
            letterSpacing: 0.2,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: AppColors.screenOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.screenOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.screenTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          if (required)
            const Text(' *',
                style: TextStyle(
                    color: AppColors.screenOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
              fontSize: 14,
              color: AppColors.screenTextPrimary,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: AppColors.screenOrange, size: 18),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.screenDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.screenOrange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingField(String msg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.screenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.screenDivider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.screenOrange),
          ),
          const SizedBox(width: 12),
          Text(msg,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.screenTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildQuickMessageChip(String msg) {
    return GestureDetector(
      onTap: () {
        _subjectController.text = msg;
        _messageController.text =
            'Je vous contacte concernant : $msg';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.screenCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.screenDivider),
          boxShadow: const [
            BoxShadow(
                color: AppColors.screenShadow,
                blurRadius: 4,
                offset: Offset(0, 1))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 12, color: AppColors.screenOrange),
            const SizedBox(width: 4),
            Text(
              msg,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.screenTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.screenOrangeLight : AppColors.screenSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.screenOrange : AppColors.screenDivider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.screenOrange : AppColors.screenTextSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.screenOrange : AppColors.screenTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  void _sendMessage() async {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      _showError('Veuillez vous connecter pour envoyer un message');
      return;
    }
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty ||
        _selectedEcoleName == null ||
        _matriculeController.text.trim().isEmpty) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setState(() => _isSending = true);
    try {
      final messageService = MessageService();
      final codeEcole = _selectedEcoleCode ?? 'gainhs';
      final matricule = _matriculeController.text.trim();

      Map<String, dynamic> result;
      if (_attachedFile != null) {
        if (_fileType == 'image') {
          result = await messageService.sendImageMessage(
            userPhoneNumber: currentUser.phone,
            content: _messageController.text.trim(),
            subject: _subjectController.text.trim(),
            codeEcole: codeEcole,
            matricule: matricule,
            imageFile: _attachedFile!,
          );
        } else {
          result = await messageService.sendVoiceMessage(
            userPhoneNumber: currentUser.phone,
            content: _messageController.text.trim(),
            subject: _subjectController.text.trim(),
            codeEcole: codeEcole,
            matricule: matricule,
            audioFile: _attachedFile!,
          );
        }
      } else {
        result = await messageService.sendTextMessage(
          userPhoneNumber: currentUser.phone,
          content: _messageController.text.trim(),
          subject: _subjectController.text.trim(),
          codeEcole: codeEcole,
          matricule: matricule,
        );
      }

      if (result['success'] == true) {
        final dest = _recipientController.text.trim();
        final newMessage = {
          'id': 'sent_${DateTime.now().millisecondsSinceEpoch}',
          'title': _subjectController.text,
          'body': _messageController.text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sender':
              '${currentUser.fullName} → ${dest.isEmpty ? 'Destinataire' : dest}',
          'isRead': true,
        };
        setState(() => _notifications.insert(0, newMessage));
        _subjectController.clear();
        _messageController.clear();
        _recipientController.clear();
        _phoneNumberController.clear();
        _matriculeController.clear();
        setState(() {
          _selectedEcoleName = null;
          _selectedEcoleCode = null;
        });
        _removeAttachment();
        if (mounted) Navigator.of(context).pop();
        _showSuccess(result['message'] ?? 'Message envoyé avec succès !');
      } else {
        _showError(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _fileType = 'image';
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webm', 'mp3', 'wav', 'm4a'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _fileType = 'audio';
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du fichier audio: $e');
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _fileType = null;
    });
  }

  // ─── DETAIL BOTTOM SHEET ──────────────────────────────────────────────────
  void _showNotificationDetail(
      Map<String, dynamic> notification) async {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        notification['timestamp'] as int);
    final sender = notification['sender'] as String? ??
        'Direction de l\'établissement';
    final data = notification['data'] as Map<String, dynamic>?;
    final notificationId = notification['id'] as String;
    final isRead = notification['isRead'] as bool? ?? false;

    if (!isRead) {
      try {
        await DatabaseService.instance
            .markNotificationAsRead(notificationId);
        setState(() => notification['isRead'] = true);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.screenCard,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.screenDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.screenOrangeLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getSenderIcon(sender),
                        color: AppColors.screenOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.screenTextPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          sender,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.screenTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.screenSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.screenDivider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 14, color: AppColors.screenTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(timestamp),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.screenTextSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.screenDivider),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.screenTextPrimary,
                  height: 1.6,
                ),
              ),
              if (data != null && data.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.screenDivider),
                ...data.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${e.key}: ${e.value}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.screenTextSecondary)),
                    )),
              ],
              const SizedBox(height: 24),
              _buildOrangeButton(
                label: 'Fermer',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }
}