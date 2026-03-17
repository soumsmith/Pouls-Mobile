import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../utils/image_helper.dart';

class EstablishmentHeaderCard extends StatelessWidget {
  final String imageUrl;
  final String establishmentName;
  final String establishmentType;
  final String motto;
  final String address;
  final String phone;
  final String email;
  final int? effectif;
  final String? debutPreinscrit;
  final String? finPreinscrit;
  final String? debutInscrit;
  final String? finInscrit;

  const EstablishmentHeaderCard({
    super.key,
    required this.imageUrl,
    required this.establishmentName,
    required this.establishmentType,
    required this.motto,
    required this.address,
    required this.phone,
    required this.email,
    this.effectif,
    this.debutPreinscrit,
    this.finPreinscrit,
    this.debutInscrit,
    this.finInscrit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 240,
          child: Stack(
            children: [
              // Image de fond avec dégradé
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageHelper.buildNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: establishmentName,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Dégradé overlay pour améliorer la lisibilité
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu superposé
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),

                      // Badge du type d'établissement
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          establishmentType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Carte d'informations avec fond semi-transparent
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.7 : 0.7,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Nom de l'établissement
                            Text(
                              establishmentName,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Devise
                            // Text(
                            //   motto,
                            //   style: TextStyle(
                            //     color: Colors.black87,
                            //     fontSize: 14,
                            //     fontWeight: FontWeight.w500,
                            //     fontStyle: FontStyle.italic,
                            //   ),
                            //   maxLines: 2,
                            //   overflow: TextOverflow.ellipsis,
                            // ),

                            _buildInfoRow(
                              context: context,
                              icon: Icons.location_on_rounded,
                              text: address,
                              color: AppColors.primary,
                            ),

                            const SizedBox(height: 4),

                            // Effectif si disponible
                            if (effectif != null)
                              _buildInfoRow(
                                context: context,
                                icon: Icons.people_rounded,
                                text: '$effectif élèves',
                                color: AppColors.primary,
                              ),

                            // Périodes d'inscription si disponibles
                            if (debutPreinscrit != null && finPreinscrit != null) ...[
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                context: context,
                                icon: Icons.calendar_today_rounded,
                                text: 'Pré-inscription: ${_formatDate(debutPreinscrit!)} - ${_formatDate(finPreinscrit!)}',
                                color: Colors.orange,
                              ),
                            ],

                            if (debutInscrit != null && finInscrit != null) ...[
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                context: context,
                                icon: Icons.edit_calendar_rounded,
                                text: 'Inscription: ${_formatDate(debutInscrit!)} - ${_formatDate(finInscrit!)}',
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }
}
