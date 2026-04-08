import 'package:flutter/material.dart';
import '../services/text_size_service.dart';

class ShareButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color iconColor;
  final String? imagePath;
  final VoidCallback onTap;
  final double? width;

  const ShareButton({
    super.key,
    required this.label,
    this.icon,
    required this.iconColor,
    this.imagePath,
    required this.onTap,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    final textSizeService = TextSizeService();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        // padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 224, 222, 222),
                borderRadius: BorderRadius.circular(50),
              ),
              child: _buildButtonContent(),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: textSizeService.getScaledFontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    // Si un chemin d'image est fourni, afficher l'image
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          imagePath!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si l'image ne peut pas être chargée, afficher l'icône par défaut
            return _buildDefaultIcon();
          },
        ),
      );
    }
    
    // Sinon, afficher l'icône
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Icon(
      icon ?? Icons.share_rounded,
      size: 20,
      color: iconColor,
    );
  }
}
