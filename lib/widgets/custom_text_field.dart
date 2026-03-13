import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool required;
  final int maxLines;
  final bool hasError;
  final List<TextInputFormatter>? inputFormatters;
  final Color? iconColor;
  final Color? focusBorderColor;
  final bool readOnly;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.required = false,
    this.maxLines = 1,
    this.hasError = false,
    this.inputFormatters,
    this.iconColor,
    this.focusBorderColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.screenTextSecondary)),
            if (required) const Text(' *', style: TextStyle(color: AppColors.screenOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14, color: AppColors.screenTextPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon, color: hasError ? Colors.red : (iconColor ?? AppColors.screenOrange), size: 18),
            filled: true,
            fillColor: AppColors.screenSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? Colors.red : AppColors.screenDivider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? Colors.red : AppColors.screenDivider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? Colors.red : (focusBorderColor ?? AppColors.screenOrange), width: 1.5)),
          ),
        ),
      ],
    );
  }
}
