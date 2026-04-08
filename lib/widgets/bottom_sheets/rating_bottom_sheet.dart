import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/text_size_service.dart';

class RatingBottomSheet extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final Color schoolColor;
  final Function(String rating, String comment)? onRatingSubmitted;
  final bool allowRating; // Permet de contrôler si l'utilisateur peut donner une note

  const RatingBottomSheet({
    Key? key,
    required this.schoolId,
    required this.schoolName,
    required this.schoolColor,
    this.onRatingSubmitted,
    this.allowRating = true,
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

    try {
      // Appeler le callback si fourni
      if (widget.onRatingSubmitted != null) {
        await widget.onRatingSubmitted!(rating, comment);
      }

      // Vider les champs
      _ratingController.clear();
      _commentController.clear();

      // Les avis seront rechargés par le parent si nécessaire

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé avec succès!'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
    
          // Liste des avis (style messages WhatsApp)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: _isLoadingAvis
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0288D1),
                      strokeWidth: 2.5,
                    ),
                  )
                : _avisError != null
                ? _buildErrorView()
                : _avis.isEmpty
                ? _buildEmptyAvisView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _avis.length,
                    itemBuilder: (context, index) {
                      final avis = _avis[index];
                      return _buildAvisBubble(avis);
                    },
                  ),
            ),
          ),

          // Barre d'envoi (style WhatsApp)
          if (widget.allowRating) _buildComposeAvisBar(),
        ],
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
                color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.screenTextPrimary,
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        MediaQuery.of(context).padding.bottom + 8,
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
                  color: const Color(0xFFF5F5F5),
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
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.screenTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Votre avis...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFBBBBBB),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _avisError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Veuillez réessayer plus tard',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Vue vide (aucun avis)
  Widget _buildEmptyAvisView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 40,
                color: Color(0xFF0288D1),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.screenTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soyez le premier à donner votre avis!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.screenTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RatingBottomSheet(
      schoolId: schoolId,
      schoolName: schoolName,
      schoolColor: schoolColor,
      onRatingSubmitted: onRatingSubmitted,
      allowRating: allowRating,
    ),
  );
}
