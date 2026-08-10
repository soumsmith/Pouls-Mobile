import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/text_size_service.dart';
import '../../services/avis_service.dart';
import '../../utils/auth_guard.dart';
import '../components/custom_error_state.dart';
import 'reusable_bottom_sheet.dart';

class RatingBottomSheet extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final Color schoolColor;
  final Function(String rating, String comment)? onRatingSubmitted;
  final bool allowRating;
  final String? imagePath;
  final Color? imageBackgroundColor;
  final double? imageBorderRadius;
  final bool popOnSuccess;

  const RatingBottomSheet({
    Key? key,
    required this.schoolId,
    required this.schoolName,
    required this.schoolColor,
    this.onRatingSubmitted,
    this.allowRating = true,
    this.imagePath,
    this.imageBackgroundColor,
    this.imageBorderRadius,
    this.popOnSuccess = false,
  }) : super(key: key);

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  final TextSizeService _textSizeService = TextSizeService();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoadingAvis = false;
  List<Map<String, dynamic>> _avis = [];
  String? _avisError;

  @override
  void initState() {
    super.initState();
    _loadAvis();
  }

  Future<void> _loadAvis() async {
    setState(() {
      _isLoadingAvis = true;
      _avisError = null;
    });
    try {
      final loadedAvis = await AvisService().getAvisForUI(widget.schoolId);
      if (mounted) {
        setState(() {
          _avis = loadedAvis;
          _isLoadingAvis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _avisError = e.toString();
          _isLoadingAvis = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendAvis() async {
    final rating = _ratingController.text;
    final comment = _commentController.text;

    if (rating.isEmpty || int.tryParse(rating) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez donner une note'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (comment.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez laisser un commentaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await AuthGuard.ensureLoggedIn(
      context,
      reason: 'Connectez-vous pour laisser un avis',
      onAuthenticatedAsync: _performSendAvis,
    );
  }

  Future<void> _performSendAvis() async {
    final rating = _ratingController.text;
    final comment = _commentController.text;

    try {
      // Appeler le callback si fourni
      if (widget.onRatingSubmitted != null) {
        await widget.onRatingSubmitted!(rating, comment);
      }

      // Vider les champs
      _ratingController.clear();
      _commentController.clear();

      // Recharger les avis localement
      _loadAvis();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.popOnSuccess && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ReusableBottomSheet(
      title: widget.schoolName,
      subtitle: 'Avis et notes',
      icon: Icons.rate_review_outlined,
      iconColor: widget.schoolColor,
      imagePath: widget.imagePath,
      iconBackgroundColor: widget.imageBackgroundColor,
      imageBorderRadius: widget.imageBorderRadius,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      useDraggable: false,
      wrapWithScrollView: false,
      contentPadding: const EdgeInsets.all(0),
      fixedBottomWidget: widget.allowRating ? _buildComposeAvisBar() : null,
      content: _isLoadingAvis
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF0288D1),
                  strokeWidth: 2.5,
                ),
              ),
            )
          : _avisError != null
              ? _buildErrorView()
              : _avis.isEmpty
                  ? _buildEmptyAvisView()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: _avis.length,
                      itemBuilder: (context, index) {
                        final avis = _avis[index];
                        return _buildAvisBubble(avis);
                      },
                    ),
    );
  }

  // Bulle d'avis (style WhatsApp)
  Widget _buildAvisBubble(Map<String, dynamic> avis) {
    final String auteur = avis['auteur'] ?? 'Anonyme';
    final String contenu = avis['content'] ?? '';
    final int note = avis['statut'] ?? 0;
    final String date = avis['date'] ?? '';
    final Color color = avis['color'] as Color? ?? widget.schoolColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar de l'école (toujours à gauche)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_outlined, size: 16, color: color),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et étoiles
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          auteur,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0288D1),
                          ),
                        ),
                      ),
                      _buildStarRating(note, const Color(0xFFF59E0B), 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Contenu du message
                  Text(
                    contenu,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? Colors.white70
                          : AppColors.screenTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date
                  Text(
                    _formatAvisDate(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.screenTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Barre de composition (style WhatsApp)
  Widget _buildComposeAvisBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom +
            8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélection des étoiles
          StatefulBuilder(
            builder: (context, setState) {
              final currentRating = int.tryParse(_ratingController.text) ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Votre note:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.screenTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          _ratingController.text = (index + 1).toString();
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < currentRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 24,
                            color: index < currentRating
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          // Barre de texte et envoi
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Champ de texte
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 100,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE8E8E8),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : AppColors.screenTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Votre avis...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFFBBBBBB),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton d'envoi
              GestureDetector(
                onTap: _sendAvis,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Vue d'erreur
  Widget _buildErrorView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: CustomErrorState(
        title: 'Erreur de chargement',
        message: _avisError!,
        icon: Icons.error_outline,
        iconColor: Colors.red[400],
      ),
    );
  }

  // Vue vide (aucun avis)
  Widget _buildEmptyAvisView() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: CustomErrorState(
        title: 'Aucun avis pour le moment',
        message: 'Soyez le premier à donner votre avis!',
        icon: Icons.rate_review_outlined,
        iconColor: Color(0xFF0288D1),
      ),
    );
  }

  // Widget d'étoiles
  Widget _buildStarRating(int rating, Color color, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: color,
        );
      }),
    );
  }

  // Formatage de date
  String _formatAvisDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Aujourd'hui";
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? 'Il y a 1 semaine' : 'Il y a $weeks semaines';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

// Fonction utilitaire pour afficher le bottom sheet
void showRatingBottomSheet(
  BuildContext context, {
  required String schoolId,
  required String schoolName,
  required Color schoolColor,
  Function(String rating, String comment)? onRatingSubmitted,
  bool allowRating = true,
  String? imagePath,
  Color? imageBackgroundColor,
  double? imageBorderRadius,
  bool popOnSuccess = true,
}) {
  showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: double.infinity),
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RatingBottomSheet(
      schoolId: schoolId,
      schoolName: schoolName,
      schoolColor: schoolColor,
      onRatingSubmitted: onRatingSubmitted,
      allowRating: allowRating,
      imagePath: imagePath,
      imageBackgroundColor: imageBackgroundColor,
      imageBorderRadius: imageBorderRadius,
      popOnSuccess: popOnSuccess,
    ),
  );
}
