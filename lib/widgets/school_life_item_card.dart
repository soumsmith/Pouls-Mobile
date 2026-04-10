import 'package:flutter/material.dart';
import '../services/text_size_service.dart';

class SchoolLifeItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? iconData;
  final String? imagePath;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;
  final String buttonText;

  const SchoolLifeItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconData,
    this.imagePath,
    required this.isDark,
    required this.color,
    required this.onTap,
    this.buttonText = 'Obtenir',
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        //margin: const EdgeInsets.symmetric(vertical: 2),
        // decoration: BoxDecoration(
        //   color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        //   borderRadius: BorderRadius.circular(12),
        //   border: Border.all(
        //     color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        //     width: 1,
        //   ),
        // ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          child: Row(
            children: [
              // Icon or Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildImageOrIcon(),
              ),
              const SizedBox(width: 12),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: textSizeService.getScaledFontSize(12),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Button (now decorative)
              SizedBox(
                width: 90,
                child: TextButton(
                  onPressed: null, // Disable button click
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    textStyle: TextStyle(
                      fontSize: textSizeService.getScaledFontSize(12),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: color.withOpacity(0.3), width: 1),
                    ),
                    minimumSize: const Size(90, 32),
                  ),
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour gérer l'affichage de l'image ou de l'icône
  Widget _buildImageOrIcon() {
    // Priorité à l'image si elle est spécifiée
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imagePath!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si l'image ne se charge pas, afficher l'icône de secours
            return Icon(
              iconData ?? Icons.image,
              color: color,
              size: 20,
            );
          },
        ),
      );
    }

    // Sinon, afficher l'icône si disponible
    if (iconData != null) {
      return Icon(
        iconData,
        color: color,
        size: 20,
      );
    }

    // Icône par défaut si aucun des deux n'est spécifié
    return Icon(
      Icons.image,
      color: color,
      size: 20,
    );
  }
}
