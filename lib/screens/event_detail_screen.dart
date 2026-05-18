import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/event_rating_comment.dart';
import '../models/ecole.dart';
import '../models/ticket_category.dart';
import '../services/event_service.dart';
import '../services/event_rating_service.dart';
import '../services/auth_service.dart';
import '../services/ecole_api_service.dart';
import '../services/ticket_service.dart';
import 'establishment_detail_screen.dart';
import '../widgets/components/section_row.dart';

// ─────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────
class _AppColors {
  static const indigo = Color(0xFF6366F1);
  static const indigoDark = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFFEEF2FF);
  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEE2E2);
  static const slate900 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFF1F5F9);
  static const white = Colors.white;
  static const gold = Color(0xFFF59E0B);
  static const surface = Color(0xFFF8F8FC);
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────
  List<Event> _schoolEvents = [];
  bool _schoolEventsLoading = true;

  List<EventRatingComment> _comments = [];
  EventRatingSummary? _ratingSummary;
  EventRatingComment? _userComment;
  bool _commentsLoading = true;
  String? _commentsError;

  List<TicketCategory> _ticketCategories = [];
  bool _ticketsLoading = false;
  String? _ticketsError;
  TicketCategory? _selectedTicketCategory;
  int _selectedQuantity = 1;

  bool _isLiked = false;
  late AnimationController _likeController;
  late Animation<double> _likeAnim;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
    _loadSchoolEvents();
    _loadCommentsAndRatings();
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  // ── data loaders ───────────────────────────
  Future<void> _loadSchoolEvents() async {
    try {
      final events = await EventService.getEventsBySchool(widget.event.codeecole);
      if (mounted) {
        setState(() {
          _schoolEvents = events.where((e) => e.slug != widget.event.slug).toList();
          _schoolEventsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _schoolEventsLoading = false);
    }
  }

  Future<void> _loadCommentsAndRatings() async {
    if (mounted) setState(() { _commentsLoading = true; _commentsError = null; });
    try {
      final results = await Future.wait([
        EventRatingService.getEventComments(widget.event.slug),
        EventRatingService.getEventRatingSummary(widget.event.slug),
      ]);
      final currentUser = AuthService.instance.getCurrentUser();
      EventRatingComment? userComment;
      if (currentUser != null) {
        try {
          userComment = await EventRatingService.getUserComment(
            widget.event.slug, currentUser.id,
          );
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _comments = results[0] as List<EventRatingComment>;
          _ratingSummary = results[1] as EventRatingSummary;
          _userComment = userComment;
          _commentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _commentsLoading = false; _commentsError = e.toString(); });
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uiData = widget.event.toUiMap();
    final typeColor = uiData['color'] as Color;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(uiData, typeColor),
            SliverToBoxAdapter(child: _buildBody(typeColor)),
          ],
        ),
      ),
    );
  }

  // ── Hero SliverAppBar ───────────────────────
  Widget _buildSliverAppBar(Map<String, dynamic> uiData, Color typeColor) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      elevation: 0,
      leading: _NavIconBtn(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        _NavIconBtn(
          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _isLiked ? _AppColors.rose : Colors.white,
          onTap: _toggleLike,
          scaleAnim: _likeAnim,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _HeroBanner(event: widget.event, typeColor: typeColor, uiData: uiData),
      ),
    );
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() => _isLiked = !_isLiked);
    _likeController.forward(from: 0);
  }

  // ── Body ────────────────────────────────────
  Widget _buildBody(Color typeColor) {
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildDragHandle(),
          const SizedBox(height: 20),
          _buildActionBar(),
          const SizedBox(height: 24),
          _buildInfoCards(typeColor),
          const SizedBox(height: 20),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildTicketButton(),
          const SizedBox(height: 28),
          _buildRatingsSection(),
          const SizedBox(height: 28),
          if (_schoolEvents.isNotEmpty) _buildOtherEvents(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _AppColors.slate300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Action Bar (icônes) ─────────────────────
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionIcon(
            icon: Icons.confirmation_num_rounded,
            label: 'Ticket',
            bgColor: _AppColors.rose,
            iconColor: Colors.white,
            onTap: _showTicketBottomSheet,
          ),
          _ActionIcon(
            icon: Icons.share_rounded,
            label: 'Partager',
            bgColor: _AppColors.indigo,
            iconColor: Colors.white,
            onTap: _showShareMenu,
          ),
          _ActionIcon(
            icon: Icons.phone_rounded,
            label: 'Contacter',
            bgColor: _AppColors.emerald,
            iconColor: Colors.white,
            onTap: _contactSchool,
          ),
          _ActionIcon(
            icon: Icons.account_balance_rounded,
            label: 'École',
            bgColor: _AppColors.amber,
            iconColor: Colors.white,
            onTap: _visitSchool,
          ),
          _ActionIcon(
            icon: Icons.calendar_month_rounded,
            label: 'Agenda',
            bgColor: _AppColors.slate900,
            iconColor: Colors.white,
            onTap: _addToCalendar,
          ),
        ],
      ),
    );
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajout à l\'agenda bientôt disponible'),
        backgroundColor: _AppColors.slate900,
      ),
    );
  }

  // ── Info cards (date + lieu) ─────────────────
  Widget _buildInfoCards(Color typeColor) {
    final uiData = widget.event.toUiMap();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              icon: Icons.calendar_today_rounded,
              iconBg: _AppColors.indigoLight,
              iconColor: _AppColors.indigo,
              title: uiData['date'] as String,
              subtitle: uiData['time'] as String,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCard(
              icon: Icons.location_on_rounded,
              iconBg: _AppColors.emeraldLight,
              iconColor: _AppColors.emerald,
              title: widget.event.nomecole,
              subtitle: 'Voir sur la carte',
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ─────────────────────────────
  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _AppColors.slate900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          _ExpandableText(text: widget.event.content),
        ],
      ),
    );
  }

  // ── Ticket CTA ──────────────────────────────
  Widget _buildTicketButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _GradientButton(
        icon: Icons.confirmation_num_rounded,
        label: 'Commander un ticket',
        onTap: _showTicketBottomSheet,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Ratings Section
  // ─────────────────────────────────────────────
  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avis & commentaires',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.slate900,
                  letterSpacing: -0.3,
                ),
              ),
              if (AuthService.instance.getCurrentUser() != null)
                GestureDetector(
                  onTap: _showAddCommentDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _AppColors.indigoLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_rounded, size: 13, color: _AppColors.indigo),
                        SizedBox(width: 4),
                        Text(
                          'Donner mon avis',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_ratingSummary != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRatingSummary(),
          ),
          const SizedBox(height: 16),
        ],
        if (_commentsLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _AppColors.indigo, strokeWidth: 2),
          ))
        else if (_comments.isEmpty)
          _buildEmptyComments()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildCommentCard(_comments[i]),
          ),
      ],
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _AppColors.slate100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 28, color: _AppColors.slate500),
            ),
            const SizedBox(height: 10),
            const Text(
              'Soyez le premier à donner votre avis',
              style: TextStyle(fontSize: 13, color: _AppColors.slate500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (_ratingSummary == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.slate300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Score global
          Column(
            children: [
              Text(
                _ratingSummary!.formattedRating,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.slate900,
                  letterSpacing: -1,
                ),
              ),
              _StarRow(stars: _ratingSummary!.averageRatingStars, size: 16),
              const SizedBox(height: 4),
              Text(
                '${_ratingSummary!.totalRatings} avis',
                style: const TextStyle(fontSize: 11, color: _AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Barres
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final pct = _ratingSummary!.totalRatings > 0
                    ? (_ratingSummary!.ratingDistribution[star] ?? 0) /
                        _ratingSummary!.totalRatings
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 11, color: _AppColors.slate500)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: _AppColors.gold, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.toDouble(),
                            minHeight: 5,
                            backgroundColor: _AppColors.slate100,
                            valueColor: const AlwaysStoppedAnimation(_AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${_ratingSummary!.ratingDistribution[star] ?? 0}',
                          style: const TextStyle(fontSize: 11, color: _AppColors.slate500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(EventRatingComment comment) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.slate300.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _AppColors.indigoLight,
                backgroundImage: comment.userAvatar.isNotEmpty
                    ? NetworkImage(comment.userAvatar)
                    : null,
                child: comment.userAvatar.isEmpty
                    ? Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: _AppColors.indigo,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.slate900,
                      ),
                    ),
                    Text(
                      comment.formattedDate,
                      style: const TextStyle(fontSize: 11, color: _AppColors.slate500),
                    ),
                  ],
                ),
              ),
              _StarRow(
                stars: List.generate(5, (i) => i < comment.rating ? 'filled' : 'empty'),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.comment,
            style: const TextStyle(
              fontSize: 13.5,
              color: _AppColors.slate700,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Other Events
  // ─────────────────────────────────────────────
  Widget _buildOtherEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'Autres événements',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _AppColors.slate900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _schoolEvents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _buildSchoolEventCard(_schoolEvents[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolEventCard(Event event) {
    final uiData = event.toUiMap();
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.slate300.withOpacity(0.5)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 90,
              child: event.image != null && event.image!.isNotEmpty
                  ? Image.network(event.image!, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => _EventCardPlaceholder(color: uiData['color'] as Color))
                  : _EventCardPlaceholder(color: uiData['color'] as Color),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.slate900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 10, color: uiData['color'] as Color),
                      const SizedBox(width: 3),
                      Text(
                        uiData['date'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: uiData['color'] as Color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareBottomSheet(event: widget.event),
    );
  }

  void _contactSchool() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact de l\'école bientôt disponible'),
        backgroundColor: _AppColors.emerald,
      ),
    );
  }

  Future<void> _visitSchool() async {
    final code = widget.event.codeecole.trim();
    if (code.isEmpty) return;
    try {
      final ecoleDetail = await EcoleApiService.getEcoleDetail(code);
      final ecole = Ecole(
        pays: ecoleDetail.data.pays,
        ville: ecoleDetail.data.ville,
        adresse: ecoleDetail.data.adresse,
        parametreNom: ecoleDetail.data.nom,
        logo: ecoleDetail.data.logo ?? '',
        telephone: ecoleDetail.data.telephone,
        parametreCode: code,
        statut: ecoleDetail.data.statut,
        filiereNom: const [],
        imagefond: ecoleDetail.image,
        paramecole: null,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EstablishmentDetailScreen(ecole: ecole)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  Ticket Bottom Sheet
  // ─────────────────────────────────────────────
  Future<void> _showTicketBottomSheet() async {
    await _loadTicketCategories();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TicketBottomSheet(
        ticketCategories: _ticketCategories,
        ticketsLoading: _ticketsLoading,
        ticketsError: _ticketsError,
        selectedCategory: _selectedTicketCategory,
        selectedQuantity: _selectedQuantity,
        onCategorySelected: (cat) => setState(() {
          _selectedTicketCategory = cat;
          _selectedQuantity = 1;
        }),
        onQuantityChanged: (q) => setState(() => _selectedQuantity = q),
        onPurchase: _purchaseTicket,
        onRetry: _loadTicketCategories,
      ),
    );
  }

  Future<void> _loadTicketCategories() async {
    if (mounted) {
      setState(() {
        _ticketsLoading = true;
        _ticketsError = null;
        _selectedTicketCategory = null;
        _selectedQuantity = 1;
      });
    }
    try {
      final id = widget.event.id ?? widget.event.slug;
      final categories = await TicketService.getTicketCategories(id, fallbackSlug: widget.event.slug);
      if (mounted) setState(() { _ticketCategories = categories; _ticketsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _ticketsLoading = false; _ticketsError = e.toString(); });
    }
  }

  Future<void> _purchaseTicket() async {
    if (_selectedTicketCategory == null) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => _ConfirmTicketDialog(
        category: _selectedTicketCategory!,
        quantity: _selectedQuantity,
        onConfirm: _executeTicketPurchase,
      ),
    );
  }

  Future<void> _executeTicketPurchase() async {
    if (_selectedTicketCategory == null) return;
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) {
      _showSnack('Utilisateur non connecté', Colors.red);
      return;
    }
    if (mounted) Navigator.pop(context);
    if (mounted) Navigator.pop(context); // close bottom sheet
    _showLoadingDialog();
    try {
      final tickets = {_selectedTicketCategory!.id: _selectedQuantity};
      final id = widget.event.id ?? widget.event.slug;
      await TicketService.purchaseTicket(
        eventId: id, tickets: tickets, phoneNumber: currentUser.phone,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          'Ticket${_selectedQuantity > 1 ? 's commandés' : ' commandé'} avec succès!',
          _AppColors.emerald,
        );
        setState(() { _selectedTicketCategory = null; _selectedQuantity = 1; });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Erreur: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LoadingDialog(),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Comment bottom sheet ────────────────────
  void _showAddCommentDialog() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _CommentBottomSheet(
          existingComment: _userComment,
          onSave: (rating, comment) async {
            Navigator.pop(context);
            try {
              if (_userComment != null) {
                await EventRatingService.updateComment(
                  commentId: _userComment!.id, rating: rating, comment: comment,
                );
              } else {
                await EventRatingService.addComment(
                  eventSlug: widget.event.slug,
                  userId: currentUser.id,
                  userName: '${currentUser.firstName} ${currentUser.lastName}'.trim(),
                  userAvatar: '',
                  rating: rating,
                  comment: comment,
                );
              }
              await _loadCommentsAndRatings();
              _showSnack(
                _userComment != null ? 'Avis modifié' : 'Avis publié',
                _AppColors.emerald,
              );
            } catch (e) {
              _showSnack('Erreur: $e', Colors.red);
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Hero Banner
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final Event event;
  final Color typeColor;
  final Map<String, dynamic> uiData;

  const _HeroBanner({required this.event, required this.typeColor, required this.uiData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        event.image != null && event.image!.isNotEmpty
            ? Image.network(event.image!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder())
            : _buildPlaceholder(),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 36,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      uiData['type'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Titre
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Sous-titre
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.nomecole,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Icon(Icons.event_rounded, color: Colors.white24, size: 80),
    );
  }
}

// ─────────────────────────────────────────────
//  Small reusable widgets
// ─────────────────────────────────────────────

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Animation<double>? scaleAnim;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
    );
    if (scaleAnim != null) {
      return ScaleTransition(scale: scaleAnim!, child: btn);
    }
    return btn;
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.slate300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _AppColors.slate500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_AppColors.indigo, _AppColors.indigoDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _AppColors.indigo.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final List<String> stars;
  final double size;

  const _StarRow({required this.stars, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars.map((s) {
        return Icon(
          s == 'filled' ? Icons.star_rounded
              : s == 'half' ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: _AppColors.gold,
          size: size,
        );
      }).toList(),
    );
  }
}

class _EventCardPlaceholder extends StatelessWidget {
  final Color color;
  const _EventCardPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.12),
      child: Icon(Icons.event_rounded, color: color.withOpacity(0.4), size: 32),
    );
  }
}

// ─────────────────────────────────────────────
//  Share Bottom Sheet (extracted)
// ─────────────────────────────────────────────
class _ShareBottomSheet extends StatelessWidget {
  final Event event;
  const _ShareBottomSheet({required this.event});

  String get _shareText => '''
🎓 ${event.title}

📅 ${event.toUiMap()['date']}
🏫 ${event.nomecole}

${event.content}

Découvrez plus d'événements sur notre application! 📱
''';

  Future<void> _launchWhatsApp() async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(_shareText)}';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  Future<void> _launchFacebook() async {
    final url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://example.com')}&quote=${Uri.encodeComponent(_shareText)}';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  Future<void> _launchEmail() async {
    final subject = Uri.encodeComponent(event.title);
    final body = Uri.encodeComponent(_shareText);
    final url = 'mailto:?subject=$subject&body=$body';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: _AppColors.slate300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Partager l\'événement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _AppColors.slate900)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(icon: Icons.message_rounded, label: 'WhatsApp',
                  color: const Color(0xFF25D366), onTap: () { Navigator.pop(context); _launchWhatsApp(); }),
              _ShareOption(icon: Icons.facebook_rounded, label: 'Facebook',
                  color: const Color(0xFF1877F2), onTap: () { Navigator.pop(context); _launchFacebook(); }),
              _ShareOption(icon: Icons.email_rounded, label: 'Email',
                  color: const Color(0xFFEA4335), onTap: () { Navigator.pop(context); _launchEmail(); }),
              _ShareOption(icon: Icons.more_horiz_rounded, label: 'Plus',
                  color: _AppColors.indigo,
                  onTap: () { Navigator.pop(context); Share.share(_shareText, subject: event.title); }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: _AppColors.slate500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ticket Bottom Sheet (extracted)
// ─────────────────────────────────────────────
class _TicketBottomSheet extends StatefulWidget {
  final List<TicketCategory> ticketCategories;
  final bool ticketsLoading;
  final String? ticketsError;
  final TicketCategory? selectedCategory;
  final int selectedQuantity;
  final ValueChanged<TicketCategory> onCategorySelected;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const _TicketBottomSheet({
    required this.ticketCategories,
    required this.ticketsLoading,
    required this.ticketsError,
    required this.selectedCategory,
    required this.selectedQuantity,
    required this.onCategorySelected,
    required this.onQuantityChanged,
    required this.onPurchase,
    required this.onRetry,
  });

  @override
  State<_TicketBottomSheet> createState() => _TicketBottomSheetState();
}

class _TicketBottomSheetState extends State<_TicketBottomSheet> {
  TicketCategory? _selectedCategory;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _qty = widget.selectedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _AppColors.slate300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Sélectionner un ticket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _AppColors.slate900)),
          const SizedBox(height: 4),
          const Text('Choisissez votre catégorie et la quantité',
              style: TextStyle(fontSize: 13, color: _AppColors.slate500)),
          const SizedBox(height: 20),

          if (widget.ticketsLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: _AppColors.indigo, strokeWidth: 2),
            ))
          else if (widget.ticketsError != null)
            _buildError()
          else if (widget.ticketCategories.isEmpty)
            _buildEmpty()
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.ticketCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildCategoryTile(widget.ticketCategories[i]),
              ),
            ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AppColors.slate700,
                    side: const BorderSide(color: _AppColors.slate300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedCategory != null ? widget.onPurchase : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _AppColors.slate300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Commander', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(TicketCategory category) {
    final isSelected = _selectedCategory?.id == category.id;
    return GestureDetector(
      onTap: () {
        setState(() { _selectedCategory = category; _qty = 1; });
        widget.onCategorySelected(category);
        widget.onQuantityChanged(1);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.indigoLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _AppColors.indigo : _AppColors.slate300.withOpacity(0.5),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _AppColors.indigo : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _AppColors.indigo : _AppColors.slate300,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.slate900)),
                      if (category.description.isNotEmpty)
                        Text(category.description,
                            style: const TextStyle(fontSize: 11, color: _AppColors.slate500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${category.price}€',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: _AppColors.rose)),
                    Text('${category.quantity} dispo',
                        style: const TextStyle(fontSize: 11, color: _AppColors.slate500)),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantité',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.slate700)),
                  Row(
                    children: [
                      _QtyBtn(
                        icon: Icons.remove_rounded,
                        enabled: _qty > 1,
                        onTap: () {
                          if (_qty > 1) {
                            setState(() => _qty--);
                            widget.onQuantityChanged(_qty);
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$_qty',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: _AppColors.slate900)),
                      ),
                      _QtyBtn(
                        icon: Icons.add_rounded,
                        enabled: _qty < category.quantity,
                        onTap: () {
                          if (_qty < category.quantity) {
                            setState(() => _qty++);
                            widget.onQuantityChanged(_qty);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: _AppColors.rose),
            const SizedBox(height: 10),
            Text(widget.ticketsError ?? '', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _AppColors.slate500)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: widget.onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.indigo, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: _AppColors.slate100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.confirmation_num_outlined, size: 28, color: _AppColors.slate500),
            ),
            const SizedBox(height: 10),
            const Text('Aucune catégorie disponible',
                style: TextStyle(fontSize: 13, color: _AppColors.slate500)),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: enabled ? _AppColors.indigo : _AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: enabled ? Colors.white : _AppColors.slate300, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Confirm Ticket Dialog
// ─────────────────────────────────────────────
class _ConfirmTicketDialog extends StatelessWidget {
  final TicketCategory category;
  final int quantity;
  final VoidCallback onConfirm;

  const _ConfirmTicketDialog({required this.category, required this.quantity, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final total = (category.price * quantity).toStringAsFixed(2);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmer la commande',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _AppColors.slate900)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _AppColors.slate900)),
                  if (category.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(category.description,
                        style: const TextStyle(fontSize: 12, color: _AppColors.slate500)),
                  ],
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Prix unitaire', value: '${category.price}€'),
                  _SummaryRow(label: 'Quantité', value: '$quantity'),
                  const Divider(height: 16, color: _AppColors.slate300),
                  _SummaryRow(label: 'Total', value: '$total€', bold: true, valueColor: _AppColors.rose),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _AppColors.slate300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Annuler', style: TextStyle(color: _AppColors.slate700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.indigo, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Commander', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _AppColors.slate500)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? _AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading Dialog
// ─────────────────────────────────────────────
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _AppColors.indigo, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Traitement en cours…',
                style: TextStyle(fontSize: 14, color: _AppColors.slate700, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Expandable Text
// ─────────────────────────────────────────────
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const _ExpandableText({required this.text, this.maxLines = 4});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              color: _AppColors.slate700,
              height: 1.65,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 14.5,
              color: _AppColors.slate700,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Voir moins' : 'Voir plus',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.indigo,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _expanded ? 0.5 : 0,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _AppColors.indigo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Comment Bottom Sheet
// ─────────────────────────────────────────────
class _CommentBottomSheet extends StatefulWidget {
  final EventRatingComment? existingComment;
  final void Function(int rating, String comment) onSave;

  const _CommentBottomSheet({this.existingComment, required this.onSave});

  @override
  State<_CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<_CommentBottomSheet> {
  late int _rating;
  late TextEditingController _controller;

  static const _labels = ['Mauvais', 'Passable', 'Bien', 'Très bien', 'Excellent'];

  @override
  void initState() {
    super.initState();
    _rating = widget.existingComment?.rating ?? 0;
    _controller = TextEditingController(text: widget.existingComment?.comment ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingComment != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _AppColors.indigoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rate_review_rounded,
                    color: _AppColors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Modifier votre avis' : 'Donner votre avis',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.slate900,
                    ),
                  ),
                  const Text(
                    'Votre opinion compte beaucoup',
                    style: TextStyle(fontSize: 12, color: _AppColors.slate500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Étoiles
          const Text(
            'Votre note',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.slate700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = i + 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? _AppColors.gold : _AppColors.slate300,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_rating),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _AppColors.amberLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _labels[_rating - 1],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.amber,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Champ commentaire
          const Text(
            'Votre commentaire',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.slate700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(fontSize: 14, color: _AppColors.slate900),
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience avec cet événement…',
              hintStyle: const TextStyle(color: _AppColors.slate500, fontSize: 13),
              filled: true,
              fillColor: _AppColors.slate100,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _AppColors.indigo, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AppColors.slate700,
                    side: const BorderSide(color: _AppColors.slate300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _rating > 0 && _controller.text.trim().isNotEmpty
                      ? () => widget.onSave(_rating, _controller.text.trim())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _AppColors.slate300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? 'Modifier' : 'Publier',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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