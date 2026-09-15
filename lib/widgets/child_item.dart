import 'package:flutter/material.dart';
import '../models/child.dart';
import '../config/app_colors.dart';
import '../utils/child_photo.dart';
import 'custom_card.dart';

/// Widget pour afficher un enfant dans une carte
class ChildItem extends StatelessWidget {
  final Child child;
  final VoidCallback? onTap;

  const ChildItem({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Log pour déboguer
    final childName = child.fullName;
    final photoUrl = child.photoUrl;
    print('🖼️ ChildItem.build pour $childName');
    print('   photoUrl: ${photoUrl ?? "null"}');
    print('   photoUrl isNotEmpty: ${photoUrl?.isNotEmpty ?? false}');
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo de l'élève depuis urlPhoto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image(
                          // Optimiser le cache (2x pour les écrans haute résolution)
                          image: ResizeImage(
                            childPhotoProvider(photoUrl),
                            width: 120,
                            height: 120,
                          ),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback vers l'icône si le chargement échoue
                            print('⚠️ Erreur lors du chargement de la photo pour $childName');
                            print('   URL: $photoUrl');
                            print('   Erreur: $error');
                            print('   StackTrace: $stackTrace');
                            return Container(
                              color: AppColors.primaryLight.toSurface(),
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.getTextColor(isDark, type: TextType.secondary),
                              ),
                            );
                          },
                          loadingBuilder: (context, imageChild, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Photo chargée avec succès pour $childName');
                              return imageChild;
                            }
                            // Afficher un indicateur de chargement
                            final progress = loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null;
                            if (progress != null) {
                              print('⏳ Chargement de la photo pour $childName: ${(progress * 100).toStringAsFixed(0)}%');
                            }
                            return Container(
                              color: AppColors.primaryLight.toSurface(),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        // Placeholder si pas de photo
                        color: AppColors.primaryLight.toSurface(),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de l'enfant
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        child.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(isDark),
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nom de l'établissement
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        child.establishment,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Classe
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Classe: ${child.grade}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bouton "Voir plus" centré
          Center(
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Voir plus'),
            ),
          ),
        ],
      ),
    );
  }
}

