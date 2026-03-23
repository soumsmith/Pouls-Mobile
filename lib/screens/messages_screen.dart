import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/message_service.dart';
import '../services/ecoles_api_service.dart';
import '../services/auth_service.dart';
import '../services/message_api_service.dart';
import '../models/ecole.dart';
import '../models/conversation.dart';
import '../config/app_colors.dart';
import '../services/text_size_service.dart';
import '../widgets/searchable_dropdown.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  Pour activer l'enregistrement natif (micro appui-long) :
//    1. flutter pub add record path_provider
//    2. Décommente les 2 lignes ci-dessous
//    3. Décommente les blocs marqués [RECORD] dans le code
// ══════════════════════════════════════════════════════════════════════════════
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';

// ─── ENUM : types de pièce jointe ────────────────────────────────────────────
enum AttachmentType { none, image, audio }

/// Écran de messagerie — style WhatsApp
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  // ─── Conversations ──────────────────────────────────────────────────────
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  final MessageApiService _messageApiService = MessageApiService();
  final List<String> _filters = ['Tous', 'Non lus', 'Lus'];

  // ─── Formulaire ─────────────────────────────────────────────────────────
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  bool _isSending = false;

  // ─── Pièce jointe ───────────────────────────────────────────────────────
  AttachmentType _attachmentType = AttachmentType.none;
  File? _attachedFile;

  // ─── Enregistrement audio ───────────────────────────────────────────────
  // [RECORD] AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordedPath;

  // ─── Écoles & destinataires ─────────────────────────────────────────────
  List<Ecole> _ecoles = [];
  String? _selectedEcoleName;
  String? _selectedEcoleCode;
  bool _isLoadingEcoles = false;
  final EcolesApiService _ecolesApiService = EcolesApiService();
  String? _selectedDestinataire;

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

  // ════════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // [RECORD] _audioRecorder = AudioRecorder();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadNotifications();
    _loadEcoles();
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
    _matriculeController.dispose();
    _recordTimer?.cancel();
    // [RECORD] _audioRecorder?.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════════════════════════════════════

  void _loadUserInfo() {
    if (AuthService.instance.getCurrentUser() != null) setState(() {});
  }

  Future<void> _loadEcoles({StateSetter? sheetSetState}) async {
    if (_isLoadingEcoles) return;
    void upd(VoidCallback fn) {
      if (mounted) setState(fn);
      sheetSetState?.call(fn);
    }
    upd(() => _isLoadingEcoles = true);
    try {
      final ecoles = await _ecolesApiService.getAllEcoles();
      upd(() {
        _ecoles = ecoles;
        _isLoadingEcoles = false;
      });
    } catch (_) {
      upd(() => _isLoadingEcoles = false);
    }
  }

  List<Conversation> get _filteredItems {
    var items = _conversations;
    if (_selectedFilter == 'Non lus') {
      items = items.where((c) => c.hasUnreadMessages).toList();
    } else if (_selectedFilter == 'Lus') {
      items = items.where((c) => !c.hasUnreadMessages).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      items = items
          .where((c) =>
      c.subject.toLowerCase().contains(q) ||
          c.student.fullName.toLowerCase().contains(q) ||
          c.school.nom.toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _messageApiService.getCurrentUserMessages();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {});
    _showSuccess('Tous les messages marqués comme lus');
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SNACKBARS
  // ════════════════════════════════════════════════════════════════════════════

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80, // Espace pour le FAB
        top: 16,
      ),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.green[500],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80, // Espace pour le FAB
        top: 16,
      ),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0288D1), strokeWidth: 2.5),
      );
    }
    _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(children: [
        _buildAppBar(),
        _buildSearchBar(),
        _buildFilters(),
        _buildCountRow(),
        Expanded(child: _buildMessageList()),
      ]),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final unreadCount = _conversations.where((c) => c.hasUnreadMessages).length;
    return Container(
      color: AppColors.screenSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            _iconBtn(Icons.arrow_back_ios_new, 16, () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Messages',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.screenTextPrimary, letterSpacing: -0.5)),
                Text(
                  '${_conversations.length} message${_conversations.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
                ),
              ]),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              }),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _isSearching ? const Color(0xFFB3E5FC) : AppColors.screenCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Icon(Icons.search, size: 18,
                    color: _isSearching ? const Color(0xFF0288D1) : AppColors.screenTextPrimary),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _markAllAsRead,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFFB3E5FC), borderRadius: BorderRadius.circular(12)),
                  child: Stack(children: [
                    const Center(child: Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFF0288D1))),
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: Color(0xFF0288D1), shape: BoxShape.circle),
                        child: Center(
                          child: Text('$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.screenCard, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, size: size, color: AppColors.screenTextPrimary),
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
            color: AppColors.screenCard, borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: AppColors.screenTextPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Rechercher un message...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1), size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                  onTap: () => setState(() => _searchController.clear()),
                  child: const Icon(Icons.close, color: AppColors.screenTextSecondary, size: 16))
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF0288D1) : AppColors.screenCard,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : [const BoxShadow(color: AppColors.screenShadow, blurRadius: 4, offset: Offset(0, 1))],
                ),
                child: Text(filter,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.screenTextSecondary)),
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
      child: Row(children: [
        Text('$count message${count > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─── LISTE DES MESSAGES ───────────────────────────────────────────────────
  Widget _buildMessageList() {
    final items = _filteredItems;
    if (items.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMessageCard(items[index], index),
    );
  }

  Widget _buildMessageCard(Conversation conversation, int index) {
    final isRead = !conversation.hasUnreadMessages;
    final title = conversation.subject;
    final body = conversation.lastMessage?.body ?? 'Aucun message';
    final sender = '${conversation.student.fullName} - ${conversation.school.nom}';
    final timestamp = conversation.lastMessageAt;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
      child: GestureDetector(
        onTap: () => _showNotificationDetail(conversation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.screenCard,
            borderRadius: BorderRadius.circular(20),
            border: isRead ? null : Border.all(color: const Color(0xFF0288D1).withOpacity(0.2), width: 1.5),
            boxShadow: const [BoxShadow(color: AppColors.screenShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isRead ? const Color(0xFFF5F5F5) : const Color(0xFFB3E5FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getSenderIcon(sender), size: 20,
                      color: isRead ? AppColors.screenTextSecondary : const Color(0xFF0288D1)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(fontSize: 15,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                              color: AppColors.screenTextPrimary, letterSpacing: -0.3),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    if (!isRead)
                      Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF0288D1), shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 2),
                  Text(sender,
                      style: const TextStyle(fontSize: 12, color: AppColors.screenTextSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
              const SizedBox(height: 10),
              Text(body,
                  style: TextStyle(fontSize: 13, height: 1.4,
                      color: isRead ? AppColors.screenTextSecondary : AppColors.screenTextPrimary,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.schedule_outlined, size: 13, color: AppColors.screenTextSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(timestamp),
                    style: const TextStyle(fontSize: 11, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (!isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFB3E5FC), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Non lu',
                        style: TextStyle(fontSize: 10, color: Color(0xFF0288D1), fontWeight: FontWeight.w700)),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  IconData _getSenderIcon(String sender) {
    final s = sender.toLowerCase();
    if (s.contains('direction') || s.contains('directeur')) return Icons.account_balance_outlined;
    if (s.contains('professeur') || s.contains('prof')) return Icons.school_outlined;
    if (s.contains('cantine')) return Icons.restaurant_outlined;
    if (s.contains('infirmier') || s.contains('médecin')) return Icons.medical_services_outlined;
    return Icons.person_outline;
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(color: Color(0xFFB3E5FC), shape: BoxShape.circle),
          child: const Icon(Icons.mail_outline, size: 48, color: Color(0xFF0288D1)),
        ),
        const SizedBox(height: 24),
        const Text('Aucun message',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.screenTextPrimary)),
        const SizedBox(height: 8),
        const Text('Vos messages apparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.screenTextSecondary, height: 1.5)),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _showComposeMessageBottomSheet,
        child: Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0288D1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Nouveau message',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  COMPOSE BOTTOM SHEET — style WhatsApp
  // ════════════════════════════════════════════════════════════════════════════

  void _showComposeMessageBottomSheet() {
    _attachmentType = AttachmentType.none;
    _attachedFile = null;
    _recordedPath = null;
    _subjectController.clear();
    _messageController.clear();
    _matriculeController.clear();
    _selectedDestinataire = null;

    String? localEcoleName = _selectedEcoleName;
    String? localEcoleCode = _selectedEcoleCode;
    String? localDestinataire;
    bool localShowSetup = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (_ecoles.isEmpty && !_isLoadingEcoles) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadEcoles(sheetSetState: setSheetState);
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.93,
                maxChildSize: 0.97,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return Column(children: [
                    _buildSheetHeaderWA(
                      localEcoleName: localEcoleName,
                      localDestinataire: localDestinataire,
                      localEcoleCode: localEcoleCode,
                      localShowSetup: localShowSetup,
                      setSheetState: setSheetState,
                      onEcoleChanged: (name, code) {
                        setSheetState(() { localEcoleName = name; localEcoleCode = code; });
                        setState(() { _selectedEcoleName = name; _selectedEcoleCode = code; });
                      },
                      onDestChanged: (d) {
                        setSheetState(() => localDestinataire = d);
                        setState(() => _selectedDestinataire = d);
                      },
                      onToggleSetup: () => setSheetState(() => localShowSetup = !localShowSetup),
                    ),
                    Expanded(child: _buildConversationArea(scrollController)),
                    _buildWhatsAppComposeBar(
                      setSheetState: setSheetState,
                      onSend: () {
                        if (localEcoleName == null ||
                            localDestinataire == null ||
                            _matriculeController.text.trim().isEmpty) {
                          setSheetState(() => localShowSetup = true);
                          _showError('Veuillez compléter École, Destinataire et Matricule');
                          return;
                        }
                        _selectedEcoleName = localEcoleName;
                        _selectedEcoleCode = localEcoleCode;
                        _selectedDestinataire = localDestinataire;
                        _sendMessage(context);
                      },
                    ),
                  ]);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── HEADER SETUP ─────────────────────────────────────────────────────────
  Widget _buildSheetHeaderWA({
    required String? localEcoleName,
    required String? localDestinataire,
    required String? localEcoleCode,
    required bool localShowSetup,
    required StateSetter setSheetState,
    required void Function(String name, String code) onEcoleChanged,
    required void Function(String dest) onDestChanged,
    required VoidCallback onToggleSetup,
  }) {
    final currentUser = AuthService.instance.getCurrentUser();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.5)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Poignée
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          )),
        ),

        // Titre + chips résumé
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0288D1), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nouveau message', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimary, letterSpacing: -0.4)),
              if (!localShowSetup && (localEcoleName != null || localDestinataire != null))
                GestureDetector(
                  onTap: onToggleSetup,
                  child: Row(children: [
                    if (localDestinataire != null) _chip(localDestinataire!),
                    if (localEcoleName != null) ...[
                      const SizedBox(width: 4),
                      _chip(
                        localEcoleName!.length > 12
                            ? '${localEcoleName!.substring(0, 12)}\u2026'
                            : localEcoleName!,
                        icon: Icons.school_outlined,
                      ),
                    ],
                  ]),
                )
              else
                const Text('Définissez le destinataire',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0288D1))),
            ])),
            GestureDetector(
              onTap: onToggleSetup,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
                child: Icon(localShowSetup ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18, color: AppColors.screenTextSecondary),
              ),
            ),
          ]),
        ),

        // Formulaire dépliable
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: localShowSetup ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF0288D1)),
                  const SizedBox(width: 8),
                  Text(currentUser?.fullName ?? 'Non connecté',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.screenTextPrimary)),
                  const Spacer(),
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.screenTextSecondary),
                  const SizedBox(width: 4),
                  Text(currentUser?.phone ?? '-',
                      style: const TextStyle(fontSize: 12, color: AppColors.screenTextSecondary)),
                ]),
              ),
              const SizedBox(height: 10),

              // École
              _isLoadingEcoles
                  ? _buildLoadingField('Chargement des écoles...')
                  : _ecoles.isEmpty
                  ? _buildInfoTile(icon: Icons.school_outlined, label: 'École', value: 'Aucune école disponible')
                  : SearchableDropdown(
                key: ValueKey('ecole_${_ecoles.length}'),
                label: 'École *',
                value: localEcoleName ?? 'Sélectionner une école...',
                items: _ecoles.map((e) => e.ecoleclibelle).toList(),
                onChanged: (name) {
                  final ecole = _ecoles.firstWhere((e) => e.ecoleclibelle == name);
                  onEcoleChanged(name, ecole.ecolecode);
                },
                isDarkMode: false,
              ),
              const SizedBox(height: 8),

              // Destinataire
              SearchableDropdown(
                key: ValueKey('dest_$localDestinataire'),
                label: 'Destinataire *',
                value: localDestinataire ?? 'Sélectionner un destinataire...',
                items: _destinataires,
                onChanged: onDestChanged,
                isDarkMode: false,
              ),
              const SizedBox(height: 8),

              // Matricule + Sujet
              Row(children: [
                Expanded(child: _buildCompactTextField(
                    controller: _matriculeController, hint: 'Matricule élève *', icon: Icons.badge_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactTextField(
                    controller: _subjectController, hint: 'Sujet du message', icon: Icons.title_outlined)),
              ]),
            ]),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ]),
    );
  }

  // ─── ZONE CONVERSATION ────────────────────────────────────────────────────
  Widget _buildConversationArea(ScrollController scrollController) {
    if (_conversations.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 64, height: 64,
            decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, size: 28, color: Color(0xFF0288D1))),
        const SizedBox(height: 12),
        const Text('Démarrez une conversation',
            style: TextStyle(fontSize: 14, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w500)),
      ]));
    }
    final conv = _conversations.first;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: conv.messages.length,
      itemBuilder: (context, i) {
        final msg = conv.messages[i];
        final isMe = msg.senderPseudo.toLowerCase()
            .contains(AuthService.instance.getCurrentUser()?.fullName.toLowerCase() ?? '');
        return _buildBubble(text: msg.body, isMe: isMe, time: _formatDate(conv.lastMessageAt));
      },
    );
  }

  Widget _buildBubble({required String text, required bool isMe, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 30, height: 30, margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: Color(0xFFB3E5FC), shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 16, color: Color(0xFF0288D1)),
            ),
          Flexible(child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF0288D1) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(text, style: TextStyle(fontSize: 14, height: 1.4,
                  color: isMe ? Colors.white : AppColors.screenTextPrimary)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 10,
                  color: isMe ? Colors.white.withOpacity(0.65) : AppColors.screenTextSecondary)),
            ]),
          )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BARRE DE COMPOSITION WHATSAPP
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildWhatsAppComposeBar({
    required StateSetter setSheetState,
    required VoidCallback onSend,
  }) {
    final bool hasContent = _messageController.text.trim().isNotEmpty
        || _attachedFile != null
        || _recordedPath != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_attachedFile != null || _recordedPath != null)
          _buildAttachmentPreview(setSheetState),
        if (_isRecording) _buildRecordingIndicator(setSheetState),

        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Bouton pièce jointe
          GestureDetector(
            onTap: () => _showAttachmentMenu(setSheetState),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(22)),
              child: Icon(
                _attachedFile != null
                    ? (_attachmentType == AttachmentType.image ? Icons.image : Icons.attach_file)
                    : Icons.attach_file_outlined,
                size: 20,
                color: _attachedFile != null ? const Color(0xFF0288D1) : AppColors.screenTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Input texte
          Expanded(child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14, color: AppColors.screenTextPrimary),
              decoration: const InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setSheetState(() {}),
            ),
          )),
          const SizedBox(width: 8),

          // Envoyer OU Micro
          hasContent
              ? GestureDetector(
            onTap: _isSending ? null : onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1), borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: _isSending
                  ? const Padding(padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          )
              : GestureDetector(
            // appui long = enregistrement natif (nécessite record package)
            onLongPressStart: (_) => _startRecording(setSheetState),
            onLongPressEnd: (_) => _stopRecording(setSheetState),
            onLongPressCancel: () => _cancelRecording(setSheetState),
            // appui simple = choisir un fichier audio existant
            onTap: () async {
              await _pickAudio();
              setSheetState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF0288D1),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                  color: (_isRecording ? const Color(0xFFEF4444) : const Color(0xFF0288D1)).withOpacity(0.35),
                  blurRadius: _isRecording ? 12 : 8,
                  spreadRadius: _isRecording ? 2 : 0,
                  offset: const Offset(0, 3),
                )],
              ),
              child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic, color: Colors.white, size: 20),
            ),
          ),
        ]),

        if (!_isRecording && !hasContent)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Appui long sur le micro pour enregistrer · Appui simple pour choisir un audio',
              style: TextStyle(fontSize: 10, color: AppColors.screenTextSecondary.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
          ),
      ]),
    );
  }

  // ─── APERÇU PIÈCE JOINTE ─────────────────────────────────────────────────
  Widget _buildAttachmentPreview(StateSetter setSheetState) {
    final isRecordedAudio = _recordedPath != null && _attachedFile == null;
    final fileName = isRecordedAudio
        ? 'Note vocale (${_formatDuration(_recordDuration)})'
        : _attachedFile!.path.split('/').last;
    final isImg = _attachmentType == AttachmentType.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.2), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(
            isRecordedAudio ? Icons.mic : isImg ? Icons.image_outlined : Icons.attach_file,
            size: 18, color: const Color(0xFF0288D1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(fileName,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0288D1), fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
        GestureDetector(
          onTap: () => setSheetState(() {
            _attachedFile = null;
            _attachmentType = AttachmentType.none;
            _recordedPath = null;
            _recordDuration = Duration.zero;
          }),
          child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close, size: 14, color: Color(0xFF0288D1))),
        ),
      ]),
    );
  }

  // ─── INDICATEUR ENREGISTREMENT ────────────────────────────────────────────
  Widget _buildRecordingIndicator(StateSetter setSheetState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 0.5),
      ),
      child: Row(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 700),
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Text('Enregistrement en cours...',
            style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600))),
        Text(_formatDuration(_recordDuration),
            style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _cancelRecording(setSheetState),
          child: const Text('Annuler',
              style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ─── MENU PIÈCE JOINTE ────────────────────────────────────────────────────
  void _showAttachmentMenu(StateSetter setSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _attachMenuOption(icon: Icons.image_outlined, label: 'Image', color: const Color(0xFF4CAF50),
                onTap: () async { Navigator.pop(context); await _pickImage(); setSheetState(() {}); }),
            _attachMenuOption(icon: Icons.audio_file_outlined, label: 'Audio', color: const Color(0xFF9C27B0),
                onTap: () async { Navigator.pop(context); await _pickAudio(); setSheetState(() {}); }),
            _attachMenuOption(icon: Icons.insert_drive_file_outlined, label: 'Document', color: const Color(0xFF2196F3),
                onTap: () async { Navigator.pop(context); await _pickAudio(); setSheetState(() {}); }),
          ]),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  Widget _attachMenuOption({
    required IconData icon, required String label, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 60, height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.screenTextPrimary)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ENREGISTREMENT AUDIO
  //  Sans record : appui simple sur micro = file_picker audio
  //  Avec record : appui long = enregistrement natif (décommente les blocs [RECORD])
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _startRecording(StateSetter setSheetState) async {
    // [RECORD] Décommente après: flutter pub add record path_provider
    // try {
    //   final hasPermission = await _audioRecorder!.hasPermission();
    //   if (!hasPermission) { _showError('Permission micro refusée'); return; }
    //   final dir = await getTemporaryDirectory();
    //   final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    //   await _audioRecorder!.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    //   _recordDuration = Duration.zero;
    //   _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    //     setSheetState(() => _recordDuration += const Duration(seconds: 1));
    //   });
    //   setSheetState(() => _isRecording = true);
    //   setState(() => _isRecording = true);
    // } catch (e) { _showError('Erreur micro: $e'); }
  }

  Future<void> _stopRecording(StateSetter setSheetState) async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    // [RECORD] final path = await _audioRecorder?.stop();
    // [RECORD] if (path != null) { _recordedPath = path; _attachedFile = File(path); _attachmentType = AttachmentType.audio; }
    setSheetState(() => _isRecording = false);
    setState(() => _isRecording = false);
  }

  Future<void> _cancelRecording(StateSetter setSheetState) async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    // [RECORD] await _audioRecorder?.stop();
    setSheetState(() { _isRecording = false; _recordDuration = Duration.zero; _recordedPath = null; });
    setState(() { _isRecording = false; _recordDuration = Duration.zero; _recordedPath = null; });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── ENVOI ────────────────────────────────────────────────────────────────
  void _sendMessage(BuildContext sheetContext) async {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) { _showError('Veuillez vous connecter'); return; }

    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    final ecoleCode = _selectedEcoleCode ?? 'gainhs';
    final matricule = _matriculeController.text.trim();

    final bool hasAudio = _attachmentType == AttachmentType.audio && _attachedFile != null;
    final bool hasImage = _attachmentType == AttachmentType.image && _attachedFile != null;

    if (message.isEmpty && !hasAudio && !hasImage) {
      _showError('Écrivez un message ou joignez un fichier');
      return;
    }

    setState(() => _isSending = true);
    try {
      final messageService = MessageService();
      Map<String, dynamic> result;

      if (hasAudio) {
        result = await messageService.sendVoiceMessage(
          userPhoneNumber: currentUser.phone,
          content: message.isNotEmpty ? message : 'Note vocale',
          subject: subject.isNotEmpty ? subject : 'Message vocal',
          codeEcole: ecoleCode, matricule: matricule, audioFile: _attachedFile!,
        );
      } else if (hasImage) {
        result = await messageService.sendImageMessage(
          userPhoneNumber: currentUser.phone,
          content: message.isNotEmpty ? message : 'Image jointe',
          subject: subject.isNotEmpty ? subject : 'Message avec image',
          codeEcole: ecoleCode, matricule: matricule, imageFile: _attachedFile!,
        );
      } else {
        result = await messageService.sendTextMessage(
          userPhoneNumber: currentUser.phone,
          content: message,
          subject: subject.isNotEmpty ? subject : 'Message',
          codeEcole: ecoleCode, matricule: matricule,
        );
      }

      if (result['success'] == true) {
        _loadNotifications();
        _subjectController.clear();
        _messageController.clear();
        _matriculeController.clear();
        setState(() {
          _selectedEcoleName = null; _selectedEcoleCode = null; _selectedDestinataire = null;
          _attachedFile = null; _attachmentType = AttachmentType.none;
          _recordedPath = null; _recordDuration = Duration.zero;
        });
        if (mounted) Navigator.of(sheetContext).pop();
        _showSuccess(result['message'] ?? 'Message envoyé !');
      } else {
        _showError(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── PICK IMAGE / AUDIO ───────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'gif']);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _attachmentType = AttachmentType.image;
          _recordedPath = null;
        });
      }
    } catch (e) { _showError('Erreur: $e'); }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['webm', 'mp3', 'wav', 'm4a']);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _attachmentType = AttachmentType.audio;
          _recordedPath = null;
        });
      }
    } catch (e) { _showError('Erreur: $e'); }
  }

  // ─── HELPERS UI ───────────────────────────────────────────────────────────
  Widget _chip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: const Color(0xFF0288D1)), const SizedBox(width: 3)],
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF0288D1), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller, required String hint, required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13, color: AppColors.screenTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
        prefixIcon: Icon(icon, color: const Color(0xFF0288D1), size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        filled: true, fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5)),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF0288D1), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14,
            color: AppColors.screenTextPrimary, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildLoadingField(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5)),
      child: Row(children: [
        const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0288D1))),
        const SizedBox(width: 12),
        Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.screenTextSecondary)),
      ]),
    );
  }

  // ─── DETAIL BOTTOM SHEET ──────────────────────────────────────────────────
  void _showNotificationDetail(Conversation conversation) async {
    final title = conversation.subject;
    final body = conversation.lastMessage?.body ?? 'Aucun message dans cette conversation';
    final timestamp = conversation.lastMessageAt;
    final sender = '${conversation.student.fullName} - ${conversation.school.nom}';
    final isRead = !conversation.hasUnreadMessages;

    if (!isRead) {
      try {
        await _messageApiService.markConversationAsRead(conversation.id, conversation.parentId);
        _loadNotifications();
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: AppColors.screenCard, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: SafeArea(top: false, child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.screenDivider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFB3E5FC), borderRadius: BorderRadius.circular(14)),
                child: Icon(_getSenderIcon(sender), color: const Color(0xFF0288D1), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.screenTextPrimary, letterSpacing: -0.4)),
              Text(sender, style: const TextStyle(fontSize: 12, color: AppColors.screenTextSecondary)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.screenSurface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.screenDivider)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.schedule_outlined, size: 14, color: AppColors.screenTextSecondary),
              const SizedBox(width: 6),
              Text(_formatDate(timestamp),
                  style: const TextStyle(fontSize: 12, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.screenDivider),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 14, color: AppColors.screenTextPrimary, height: 1.6)),
          if (conversation.messages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.screenDivider),
            const Text('Messages dans cette conversation :',
                style: TextStyle(fontSize: 12, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...conversation.messages.take(3).map((msg) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(msg.senderPseudo, style: const TextStyle(
                    fontSize: 11, color: AppColors.screenTextSecondary, fontWeight: FontWeight.w500)),
                Text(msg.body, style: const TextStyle(fontSize: 12, color: AppColors.screenTextPrimary)),
              ]),
            )),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(color: const Color(0xFF0288D1), borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: const Text('Fermer',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ])),
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