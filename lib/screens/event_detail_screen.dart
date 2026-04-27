import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/event_rating_comment.dart';
import '../models/ecole.dart';
import '../services/event_service.dart';
import '../services/event_rating_service.dart';
import '../services/auth_service.dart';
import '../services/ecole_api_service.dart';
import 'establishment_detail_screen.dart';
import '../widgets/components/section_row.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<Event> _schoolEvents = [];
  bool _schoolEventsLoading = true;
  String? _schoolEventsError;

  // Variables pour les commentaires et notations
  List<EventRatingComment> _comments = [];
  EventRatingSummary? _ratingSummary;
  EventRatingComment? _userComment;
  bool _commentsLoading = true;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _loadSchoolEvents();
    _loadCommentsAndRatings();
  }

  Future<void> _loadSchoolEvents() async {
    if (mounted) {
      setState(() {
        _schoolEventsLoading = true;
        _schoolEventsError = null;
      });
    }

    try {
      final events = await EventService.getEventsBySchool(widget.event.codeecole);
      if (mounted) {
        setState(() {
          _schoolEvents = events.where((e) => e.slug != widget.event.slug).toList();
          _schoolEventsLoading = false;
          _schoolEventsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _schoolEventsLoading = false;
          _schoolEventsError = e.toString();
        });
      }
    }
  }

  Future<void> _loadCommentsAndRatings() async {
    if (mounted) {
      setState(() {
        _commentsLoading = true;
        _commentsError = null;
      });
    }

    try {
      // Charger les commentaires et le résumé des notations en parallèle
      final results = await Future.wait([
        EventRatingService.getEventComments(widget.event.slug),
        EventRatingService.getEventRatingSummary(widget.event.slug),
      ]);

      // Vérifier si l'utilisateur a déjà commenté
      final currentUser = AuthService.instance.getCurrentUser();
      EventRatingComment? userComment;
      if (currentUser != null) {
        try {
          userComment = await EventRatingService.getUserComment(
            widget.event.slug,
            currentUser.id,
          );
        } catch (e) {
          // L'utilisateur n'a pas encore commenté, c'est normal
        }
      }

      if (mounted) {
        setState(() {
          _comments = results[0] as List<EventRatingComment>;
          _ratingSummary = results[1] as EventRatingSummary;
          _userComment = userComment;
          _commentsLoading = false;
          _commentsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsLoading = false;
          _commentsError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiData = widget.event.toUiMap();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App bar avec image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareEvent,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond
                  widget.event.image != null && widget.event.image!.isNotEmpty
                      ? Image.network(
                          widget.event.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: Icon(
                                Icons.event,
                                color: Colors.grey[600],
                                size: 80,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: Icon(
                            Icons.event,
                            color: Colors.grey[600],
                            size: 80,
                          ),
                        ),
                  // Overlay sombre
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  // Titre en bas
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (uiData['color'] as Color).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            uiData['type'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.event.nomecole,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
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
          ),
          // Contenu
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations principales
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date et statut
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (uiData['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: uiData['color'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uiData['date'] as String,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: uiData['color'] as Color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    uiData['time'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event.content,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A5568),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _shareEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Partager',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _contactSchool,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Contacter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _visitSchool,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A1A2A),
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.account_balance_rounded),
                            label: const Text(
                              'Visiter l\'école',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Section de notation et commentaires
                  SectionRow(title: 'AVIS ET COMMENTAIRES'),
                  const SizedBox(height: 16),
                  
                  // Résumé des notations
                  if (_ratingSummary != null) _buildRatingSummary(),
                  
                  // Bouton pour ajouter un commentaire
                  _buildAddCommentButton(),
                  
                  const SizedBox(height: 20),
                  
                  // Liste des commentaires
                  if (_comments.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentCard(_comments[index]);
                      },
                    ),
                  ] else if (!_commentsLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Soyez le premier à donner votre avis',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),

                  // Autres événements de l'école
                  if (_schoolEvents.isNotEmpty) ...[
                    SectionRow(title: 'AUTRES ÉVÉNEMENTS DE L\'ÉCOLE'),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _schoolEvents.length,
                        itemBuilder: (context, index) {
                          return _buildSchoolEventCard(_schoolEvents[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolEventCard(Event event) {
    final uiData = event.toUiMap();
    
    return GestureDetector(
      onTap: () {
        // Naviguer vers le détail de cet événement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 80,
                width: 160,
                color: Colors.grey[200],
                child: event.image != null && event.image!.isNotEmpty
                    ? Image.network(
                        event.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.event,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.event,
                        color: Colors.grey[600],
                        size: 30,
                      ),
              ),
            ),
            // Informations
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
            ),
          ],
        ),
      ),
    );
  }

  void _shareEvent() {
    _showShareMenu();
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de traction
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            
            // Titre
            const Text(
              'Partager l\'événement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez "${widget.event.title}" avec vos amis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Options de partage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _shareToWhatsApp(),
                ),
                _buildShareOption(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _shareToFacebook(),
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Email',
                  color: const Color(0xFFEA4335),
                  onTap: () => _shareToEmail(),
                ),
                _buildShareOption(
                  icon: Icons.more_horiz,
                  label: 'Plus',
                  color: const Color(0xFF6366F1),
                  onTap: () => _shareToSystem(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareToWhatsApp() async {
    final shareText = _getShareText();
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      _showErrorSnackBar('WhatsApp n\'est pas disponible');
    }
  }

  void _shareToFacebook() async {
    final shareText = _getShareText();
    final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://example.com')}&quote=${Uri.encodeComponent(shareText)}';
    
    if (await canLaunchUrl(Uri.parse(facebookUrl))) {
      await launchUrl(Uri.parse(facebookUrl));
    } else {
      _showErrorSnackBar('Facebook n\'est pas disponible');
    }
  }

  void _shareToEmail() async {
    final shareText = _getShareText();
    final subject = Uri.encodeComponent(widget.event.title);
    final body = Uri.encodeComponent(shareText);
    final emailUrl = 'mailto:?subject=$subject&body=$body';
    
    if (await canLaunchUrl(Uri.parse(emailUrl))) {
      await launchUrl(Uri.parse(emailUrl));
    } else {
      _showErrorSnackBar('L\'application email n\'est pas disponible');
    }
  }

  void _shareToSystem() {
    final shareText = _getShareText();
    Share.share(shareText, subject: widget.event.title);
  }

  String _getShareText() {
    return '''
🎓 ${widget.event.title}

📅 ${widget.event.toUiMap()['date']}
🏫 ${widget.event.nomecole}

${widget.event.content}

Découvrez plus d'événements sur notre application! 📱
    ''';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _contactSchool() async {
    // Implémenter le contact avec l'école
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact de l\'école bientôt disponible'),
        backgroundColor: Color(0xFF6366F1),
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
        MaterialPageRoute(
          builder: (_) => EstablishmentDetailScreen(ecole: ecole),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Construire le résumé des notations
  Widget _buildRatingSummary() {
    if (_ratingSummary == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Note moyenne
              Column(
                children: [
                  Text(
                    _ratingSummary!.formattedRating,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2A),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _ratingSummary!.averageRatingStars.map((star) {
                      return Icon(
                        star == 'filled' 
                            ? Icons.star 
                            : star == 'half' 
                                ? Icons.star_half 
                                : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 20,
                      );
                    }).toList(),
                  ),
                  Text(
                    '${_ratingSummary!.totalRatings} avis',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Distribution des notes
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final starCount = 5 - index;
                    final percentage = _ratingSummary!.totalRatings > 0
                        ? (_ratingSummary!.ratingDistribution[starCount] ?? 0) / _ratingSummary!.totalRatings
                        : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$starCount',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            color: const Color(0xFFFFB800),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_ratingSummary!.ratingDistribution[starCount] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construire le bouton pour ajouter un commentaire
  Widget _buildAddCommentButton() {
    final currentUser = AuthService.instance.getCurrentUser();
    final hasCommented = _userComment != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: currentUser != null ? _showAddCommentDialog : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasCommented ? Colors.grey[400] : const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          hasCommented ? 'Vous avez déjà donné votre avis' : 'Donner mon avis',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Construire une carte de commentaire
  Widget _buildCommentCard(EventRatingComment comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du commentaire
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: comment.userAvatar.isNotEmpty
                    ? NetworkImage(comment.userAvatar)
                    : null,
                child: comment.userAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Nom et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2A),
                      ),
                    ),
                    Text(
                      comment.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Étoiles de notation
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < comment.rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Commentaire
          Text(
            comment.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue pour ajouter/modifier un commentaire
  void _showAddCommentDialog() {
    final currentUser = AuthService.instance.getCurrentUser();
    if (currentUser == null) return;

    int rating = _userComment?.rating ?? 5;
    final commentController = TextEditingController(text: _userComment?.comment ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_userComment != null ? 'Modifier votre avis' : 'Donner votre avis'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection de la note
                const Text('Note', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB800),
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Champ de commentaire
                const Text('Commentaire', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Partagez votre expérience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez ajouter un commentaire'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              
              try {
                if (_userComment != null) {
                  // Modifier le commentaire existant
                  await EventRatingService.updateComment(
                    commentId: _userComment!.id,
                    rating: rating,
                    comment: commentController.text.trim(),
                  );
                } else {
                  // Ajouter un nouveau commentaire
                  await EventRatingService.addComment(
                    eventSlug: widget.event.slug,
                    userId: currentUser.id,
                    userName: '${currentUser.firstName} ${currentUser.lastName}'.trim(),
                    userAvatar: '', // TODO: Ajouter l'avatar de l'utilisateur
                    rating: rating,
                    comment: commentController.text.trim(),
                  );
                }

                // Recharger les commentaires
                await _loadCommentsAndRatings();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_userComment != null ? 'Avis modifié avec succès' : 'Avis ajouté avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(_userComment != null ? 'Modifier' : 'Publier'),
          ),
        ],
      ),
    );
  }
}
