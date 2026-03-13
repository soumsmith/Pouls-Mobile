import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CustomFileField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? fileName;
  final VoidCallback onTap;

  const CustomFileField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    this.fileName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.screenTextSecondary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.screenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fileName != null ? AppColors.screenOrange : AppColors.screenDivider, width: fileName != null ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.screenOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName ?? hint,
                    style: TextStyle(fontSize: 13, color: fileName != null ? AppColors.screenTextPrimary : const Color(0xFFBBBBBB)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.cloud_upload_outlined, color: fileName != null ? AppColors.screenOrange : AppColors.screenTextSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
